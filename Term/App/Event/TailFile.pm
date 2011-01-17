package Term::App::Event::TailFile;

use Moose;

use AnyEvent::Handle;

use Scalar::Util qw( weaken );

extends 'Term::App::Event';

has 'filename' => (is => 'ro', isa => 'Str', required => 1);
has 'pid' => (is => 'rw', isa => 'Int');

sub _build_event {
  my $self = shift;

  weaken($self);

  my $filename = $self->filename;

  my $fh;

  if (my $pid = open $fh, "tail -n +0 -F $filename |") {
    $self->pid($pid);
  } else {
    $self->log("Couldn't tail file $filename: $!");
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
