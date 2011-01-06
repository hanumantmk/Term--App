package Term::App::Widget::Container::LeftToRight;

use strict;

use Moose;

use List::Util qw( reduce max );

extends 'Term::App::Widget';

has children => (is => 'ro', isa => 'ArrayRef[Term::App]', default => sub { [] });

sub render {
  my $self = shift;

  reduce {
    [map {
      ($a->[$_] || '') . ($b->[$_] || '')
    } (0..max(scalar(@$a), scalar(@$b)))];
  } map { $_->render } @{$self->children};
}

no Moose;

1;
