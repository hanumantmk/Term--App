package Term::App::Widget::Container::LeftToRight;

use strict;

use List::Util qw( reduce max sum );

use Moose;

extends 'Term::App::Widget::Container';

sub _render {
  my $self = shift;

  my $sum_weight = sum(map { $_->weight } @{$self->children});
  my $cols = $self->cols;
  my $available_cols = $cols;

  foreach my $child (grep { $_->preferred_cols } @{$self->children}) {
    if ($available_cols >= $child->preferred_cols) {
      $available_cols -= $child->preferred_cols;
      $child->cols($child->preferred_cols);
    } else {
      $child->cols($available_cols);
      $available_cols = 0;
    }
  }

  my $rows = $self->rows;

  my $reduction = reduce {
    [map {
      [@{$a->[$_]}, @{$b->[$_]}];
    } (0..(max(scalar(@$a), scalar(@$b)) - 1))];
  } map {
    $_->rows($rows);

    if (! defined $_->preferred_cols) {
      $_->cols(int($available_cols * ($_->weight / $sum_weight)));
    }

    $_->render;
  } @{$self->children};

  $reduction;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
