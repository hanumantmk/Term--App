package Term::App::Widget::Container;

use strict;

use Moose;

extends 'Term::App::Widget';

has children => (is => 'rw', isa => 'ArrayRef[Term::App::Widget]', default => sub { [] });

sub receive_key_events {
  my ($self, $tokens) = @_;

  $_->receive_key_events($tokens) for $self->focused;
}

sub focused {
  my $self = shift;

  grep { $_->has_focus } @{$self->children};
}

sub BUILD {
  my $self = shift;

  $_->app($self->app) for @{$self->children};
}

no Moose;

1;
