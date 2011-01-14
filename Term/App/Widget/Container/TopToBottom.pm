package Term::App::Widget::Container::TopToBottom;

use strict;

use List::Util qw( sum );

use Moose;

extends 'Term::App::Widget::Container';

sub _render {
  my $self = shift;

  my $sum_weight = sum(map { $_->weight } @{$self->children});
  my $rows = $self->rows;
  my $available_rows = $rows;

  foreach my $child (grep { $_->preferred_rows } @{$self->children}) {
    if ($available_rows >= $child->preferred_rows) {
      $available_rows -= $child->preferred_rows;
      $child->rows($child->preferred_rows);
    } else {
      $child->rows($available_rows);
      $available_rows = 0;
    }
  }

  my $cols = $self->cols;

  [map {
    $_->cols($cols);

    if (! $_->preferred_rows) {
      $_->rows(int($available_rows * ($_->weight / $sum_weight)));
    }

    @{$_->render};
  } @{$self->children}];
}

no Moose;

1;
