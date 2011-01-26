package Term::App::Event;

use Moose;

use AnyEvent;

has 'callback' => (is => 'rw', isa => 'CodeRef', required => 1);
has _event => (is => 'ro', builder => '_build_event', lazy => 1);
has app => (is => 'rw', weak_ref => 1, handles => { log => 'log' } );

sub register {
  my ($self, $app) = @_;

  $self->app($app);

  $self->_event;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
