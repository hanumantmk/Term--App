package Term::App::Widget::Container::LeftToRight;

use strict;

use List::Util qw( reduce max );

use Moose;

extends 'Term::App::Widget::Container';

sub _render {
  my $self = shift;

  my $cols = int($self->cols / scalar(@{$self->children}));
  my $rows = $self->rows;

  reduce {
    [map {
      sprintf("%-." . $self->cols . "s", $a->[$_] . $b->[$_]);
    } (0..(max(scalar(@$a), scalar(@$b)) - 1))];
  } map {
    $_->rows($rows);
    $_->cols($cols);

    $_->render;
  } @{$self->children};
}

no Moose;

1;
