package Log::Watcher;

use strict;

use AnyEvent;
use Term::Pager;
use Term::ReadKey;

use constant ARROW_ESCAPE => chr(27) . chr(91);
use constant LEFT_ARROW   => ARROW_ESCAPE . chr(68);
use constant RIGHT_ARROW  => ARROW_ESCAPE . chr(67);
use constant UP_ARROW     => ARROW_ESCAPE . chr(65);
use constant DOWN_ARROW   => ARROW_ESCAPE . chr(66);

sub new {
  my ($class, $opts) = @_;

  $opts ||= {};

  $opts->{file} or die "No file to watch";
  -e $opts->{file} or die "No such file " . $opts->{file};

  $opts->{callback} or die "No callback specified";
  ref $opts->{callback} eq 'CODE' or die "callback must be a code ref";

  $opts->{pager} = Term::Pager->new;

  bless $opts, $class;
}

sub process {
  my ($self, $input) = @_;

  while ($input) {
    if (substr($input, 0, 3) eq LEFT_ARROW) {
      substr($input, 0, 3) = '';
      $self->{pager}->left;
    } elsif (substr($input, 0, 3) eq RIGHT_ARROW) {
      substr($input, 0, 3) = '';
      $self->{pager}->right;
    } elsif (substr($input, 0, 3) eq UP_ARROW) {
      substr($input, 0, 3) = '';
      $self->{pager}->up;
    } elsif (substr($input, 0, 3) eq DOWN_ARROW) {
      substr($input, 0, 3) = '';
      $self->{pager}->down;
    } elsif (substr($input, 0, 1) eq 'h') {
      substr($input, 0, 1) = '';
      $self->{pager}->left;
    } elsif (substr($input, 0, 1) eq 'l') {
      substr($input, 0, 1) = '';
      $self->{pager}->right;
    } elsif (substr($input, 0, 1) eq 'j') {
      substr($input, 0, 1) = '';
      $self->{pager}->down;
    } elsif (substr($input, 0, 1) eq 'k') {
      substr($input, 0, 1) = '';
      $self->{pager}->up;
    } elsif (substr($input, 0, 1) eq 'q') {
      ReadMode 0;
      exit 0;
    } else {
      $input = '';
    }
  }

  return;
}

sub loop {
  my $self = shift;

  my $output = '';

  open FILE, "tail -f -n +0 " . $self->{file} . " | " or die "couldn't open file " . $self->{file} . ": $!";

  ReadMode 4;

  my $user = AnyEvent->io(
    fh   => \*STDIN,
    poll => 'r',
    cb   => sub {
      my $input;
      while (sysread(\*STDIN, $input, 4096)) {
	$self->process($input);
	$self->{pager}->print($output);
      }
    },
  );

  my $old_input  = '';

  my $log = AnyEvent->io(
    fh   => \*FILE,
    poll => 'r',
    cb   => sub {
      my $input      = '';
      my $next_input = '';

      if (my $read = sysread(\*FILE, $input, 4096)) {
	if (! ($input =~ /\n/)) {
	  $old_input .= $input;
	  return;
	} elsif (substr($input,-1) ne "\n") {
	  ($next_input) = ($input =~ /\n(.*?)$/);
	  $input =~ s/\n.*?$//;
	} else {
	  chomp($input);
	  $next_input = '';
	}

	$input = $old_input . $input;
	$old_input = $next_input;

	foreach my $line (split /\n/, $input, -1) {
	  if (my $r = $self->{callback}->($line)) {
	    $output = $r;
	    $self->{pager}->print($output);
	  }
	}
      }
    },
  );

  AnyEvent->condvar->recv;
}

1;
