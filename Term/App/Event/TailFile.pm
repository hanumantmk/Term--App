package Term::App::Event::TailFile;

use Moose;

use AnyEvent::Handle;

use Scalar::Util qw( weaken );

extends 'Term::App::Event::ReadPipe';

has 'filename' => (is => 'ro', isa => 'Str', required => 1);

sub _build_command {
  my $self = shift;

  "tail -n +0 -F " . $self->filename . " 2>/dev/null";
}

no Moose;

1;
