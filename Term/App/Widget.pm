package Term::App::Widget;

use strict;

use Moose;

use Moose::Util qw( apply_all_roles );

use List::Util qw( reduce max );

has rows => (is => 'ro', isa => 'Int');
has cols => (is => 'ro', isa => 'Int');

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

sub receive_key_events { }

sub BUILD {
  my $self = shift;

  $self->{plugins} and apply_all_roles($self, @{$self->{plugins}});
}

no Moose;

1;
