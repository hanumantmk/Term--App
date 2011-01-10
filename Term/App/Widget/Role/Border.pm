package Term::App::Widget::Role::Border;

use strict;

use Moose::Role;

around render => sub {
  my ($orig, $self) = @_;

  my $rows = $self->rows;
  my $cols = $self->cols;

  my $border = '+' . ('-' x ($cols - 2)) . '+';

  my @lines = @{$self->$orig()};

  if (scalar(@lines) < $rows - 3) {
    (@lines) = (@lines, ('') x (($rows - 3) - scalar(@lines)));
  } elsif (scalar(@lines) > $rows - 3) {
    splice(@lines, $rows-3);
  }

  [ 
    $border,
    (map {
      sprintf("|%-" . ($cols - 2) . "s|", $_);
    } @lines),
    $border,
  ];
};

no Moose;

1;
