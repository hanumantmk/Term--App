package Term::App::Event::ReadPipe;

use Moose;

use AnyEvent::Handle;

use Scalar::Util qw( weaken );

extends 'Term::App::Event';

has 'command' => (is => 'ro', isa => 'Str', lazy => 1, builder => "_build_command");
has 'pid' => (is => 'rw', isa => 'Int');

sub _build_command {
  my $self = shift;

  $self->log("_build_command must be implemented or command must be passed");

  return undef;
}

sub _build_event {
  my $self = shift;

  $self->command or return;

  weaken($self);

  my $fh;

  if (my $pid = open $fh, $self->command . " |") {
    $self->pid($pid);
  } else {
    $self->log("Couldn't open pipe [" . $self->command . "] : $!");
    return;
  }

  AnyEvent::Handle->new(
    fh   => $fh,
    on_read => sub {
      my $hdl = shift;

      $hdl->push_read(line => sub {
	my ($hdl, $line) = @_;
	$self->callback->($line);
      });
    },
  );
}

sub DESTROY {
  my $self = shift;

  kill 15, $self->pid;
}

no Moose;

1;
