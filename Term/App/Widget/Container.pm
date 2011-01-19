package Term::App::Widget::Container;

use strict;

use Moose;

extends 'Term::App::Widget';

has children => (is => 'rw', isa => 'ArrayRef', default => sub { [] });

override receive_key_events => sub {
  my ($self, $tokens) = @_;

  super;

  $_->receive_key_events($tokens) for $self->focused;
};

sub focused {
  my $self = shift;

  grep { $_->has_focus } @{$self->children};
}

override assign_app => sub {
  my ($self, $app) = @_;

  super;

  foreach my $child (@{$self->children}) {
    $child->assign_app($app);
  }
};

sub BUILD {
  my $self = shift;

  foreach my $child (@{$self->children}) {
    $child->parent($self);
  }
}

no Moose;

1;
