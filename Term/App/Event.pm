package Term::App::Event;

use Moose;

use AnyEvent;

has 'callback' => (is => 'rw', isa => 'CodeRef', required => 1);
has _event => (is => 'ro', builder => '_build_event', lazy => 1);

sub register {
  my $self = shift;

  $self->_event;
}

no Moose;

1;
