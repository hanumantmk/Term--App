package Term::App::Event::Timer;

use Moose;

use AnyEvent;

extends 'Term::App::Event';

has 'seconds' => (is => 'ro', required => 1);

sub _build_event {
  my $self = shift;

  AnyEvent->timer(
    after    => $self->seconds,
    interval => $self->seconds,
    cb       => $self->callback,
  );
}

no Moose;

1;
