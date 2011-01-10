package Term::App::Widget;

use strict;

use Moose;

use Moose::Util qw( apply_all_roles );

use List::Util qw( reduce max );

has rows => (is => 'rw', isa => 'Int');
has cols => (is => 'rw', isa => 'Int');

has bindings => (is => 'ro', isa => 'HashRef', default => sub { {} } );
has plugins => (is => 'ro', isa => 'ArrayRef', default => sub { [] } );

sub render {
  my $self = shift;

  my @lines = @{inner()};

  if (scalar(@lines) > $self->rows) {
    splice(@lines, $self->rows - 1);
  }

  [map {
    if (length($_) > $self->cols) {
      substr($_, $self->cols - 1) = '';
    }

    $_;
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

  apply_all_roles($self, map { "Term::App::Widget::Role::$_" } @{$self->plugins});
}

no Moose;

1;
