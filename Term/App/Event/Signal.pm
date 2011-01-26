package Term::App::Event::Signal;

use Moose;

use AnyEvent;

extends 'Term::App::Event';

has 'signal' => (is => 'ro', required => 1);

sub _build_event {
  my $self = shift;

  AnyEvent->signal(
    signal => $self->signal,
    cb     => $self->callback,
  );
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
