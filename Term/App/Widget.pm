package Term::App::Widget;

use strict;

use Moose;

use Moose::Util qw( apply_all_roles );

use List::Util qw( reduce max );

extends 'Term::App::Widget';

has rows => (is => 'ro', isa => 'Int');
has cols => (is => 'ro', isa => 'Int');

sub render { confess "Must be implemented in the child" }

sub BUILD {
  my $self = shift;

  $self->{plugins} and apply_all_roles($self, @{$self->{plugins}});
}

no Moose;

1;
