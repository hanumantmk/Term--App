package Term::App::Widget::Role::Paged;

use strict;

use Moose::Role;

use List::Util qw( max min );

has row => (is => 'rw', isa => 'Int', default => 0);
has col => (is => 'rw', isa => 'Int', default => 0);

has '_row_diff' => (is => 'rw', isa => 'Int');
has '_col_diff' => (is => 'rw', isa => 'Int');

sub left {
  my $self = shift;

  $self->col and $self->col($self->col - 1);
}

sub right {
  my $self = shift;

  $self->col($self->col + 1);
}

sub up {
  my $self = shift;

  $self->row and $self->row($self->row - 1);
}

sub page_up {
  my $self = shift;

  if ($self->row >= $self->rows) {
    $self->row($self->row - $self->rows);
  } else {
    $self->row(0);
  }
}

sub page_down {
  my $self = shift;

  $self->row($self->row + $self->rows);
}

sub down {
  my $self = shift;

  $self->row($self->row + 1);
}

around render => sub {
  my ($orig, $self) = @_;

  my $rows = $self->rows;
  my $cols = $self->cols;

  my @lines = @{$self->$orig()};

  if ($self->_row_diff > 0) {
    $rows--;
    my $size = int($rows * ($rows / ($rows + $self->_row_diff)));
    my $percent = $self->row / $self->_row_diff;
    my $start = int($percent * $rows) - int($percent * $size);
    my $end = $start + $size;

    for (my $i = $start; $i < $end; $i++) {
      substr($lines[$i], -1, 1, '[');
    }
  }

  if ($self->_col_diff > 0) {
    $lines[-1] = ' ' x $cols;
    $cols--;
    my $size = int($cols * ($cols / ($cols + $self->_col_diff)));
    my $percent = $self->col / $self->_col_diff;
    my $start = int($percent * $cols) - int($percent * $size);
    substr($lines[-1], $start, $size, '=' x $size);
  }

  \@lines;
};

around _render => sub {
  my ($orig, $self) = @_;

  my @lines = @{$self->$orig()};

  my $row_diff = scalar(@lines) - $self->rows;
  $self->_row_diff($row_diff);
  my $col_diff = max(map { length($_) } @lines) - $self->cols;
  $self->_col_diff($col_diff);

  if ($row_diff > 0) {
    $self->row(min($row_diff, $self->row));
    splice(@lines, 0, $self->row);
  } else {
    $self->row(0);
  }

  if ($col_diff > 0) {
    $self->col(min($col_diff, $self->col));
    @lines = map {
      substr($_, 0, $self->col) = '';

      $_;
    } @lines;
  } else {
    $self->col(0);
  }

  \@lines;
};

no Moose;

1;
