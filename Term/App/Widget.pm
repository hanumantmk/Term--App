package Term::App::Widget;

use strict;

use Moose;

use Moose::Util qw( apply_all_roles );

use Scalar::Util qw( weaken );

has rows => (is => 'rw', isa => 'Int');
has cols => (is => 'rw', isa => 'Int');

has preferred_rows => (is => 'rw', isa => 'Int');
has preferred_cols => (is => 'rw', isa => 'Int');

has bindings => (is => 'ro', isa => 'HashRef', default => sub { {} } );
has plugins => (is => 'ro', isa => 'ArrayRef', default => sub { [] } );
has events => (is => 'ro', isa => 'ArrayRef', default => sub { [] } );

has has_focus => (is => 'rw', isa => 'Int');
has weight => (is => 'rw', isa => 'Int', default => 1);

has app => (is => 'rw', weak_ref => 1);

sub render {
  my $self = shift;

  return [] if ($self->rows < 1);
  return [('') x $self->rows] if ($self->cols < 1);

  my @lines = @{$self->_render};

  if (scalar(@lines) > $self->rows) {
    splice(@lines, $self->rows - 1);
  } elsif (scalar(@lines) < $self->rows) {
    push @lines, (('') x ($self->rows - scalar(@lines)));
  }

  [map {
    substr(sprintf("%-" . $self->cols ."s", $_), 0, $self->cols);
  } @lines];
}

sub receive_key_events {
  my ($self, $tokens) = @_;

  foreach my $token (@$tokens) {
    if (my $sub = $self->bindings->{$token}) {
      $self->$sub($token);
    }
  }
}

sub BUILD {
  my $self = shift;

  weaken($self);

  apply_all_roles($self, map { "Term::App::Widget::Role::$_" } @{$self->plugins}) if @{$self->plugins};

  foreach my $event (@{$self->events}) {
    my $cb = $event->callback;
    $event->callback(sub {
      $cb->($self,@_);
    });
    $event->register;
  }
}

no Moose;

1;
