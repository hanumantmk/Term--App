package Term::App::Widget::Role::Border;

use strict;

use Moose::Role;

around render => sub {
  my ($orig, $self) = @_;

  my $rows = $self->rows;
  my $cols = $self->cols;

  my $border = '+' . ('-' x ($cols - 2)) . '+';

  $self->rows($rows - 2);
  $self->cols($cols - 2);

  my @lines = @{$self->$orig()};

  $self->rows($rows);
  $self->cols($cols);

  [ 
    $self->make_cells($border),
    (map { $self->make_cells("|", $_, "|") } @lines),
    $self->make_cells($border),
  ];
};

no Moose;

1;
