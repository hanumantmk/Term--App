package Term::App::Widget::Role::Paged;

use strict;

use Moose::Role;

use Scalar::Util qw( weaken );

use List::Util qw( max min );
use List::MoreUtils qw( firstidx );

has row => (is => 'rw', isa => 'Int', default => 0);
has col => (is => 'rw', isa => 'Int', default => 0);
has has_scrollbar => (is => 'rw', isa => 'Int', default => 1);

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

sub home {
  my $self = shift;

  $self->row(0);
}

sub end {
  my $self = shift;

  $self->row(-1);
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

sub start_search {
  my $self = shift;

  weaken($self);

  $self->ask("Search String", sub {
    my $string = shift;

    my @lines = @{$self->_render};

    $self->row((firstidx { join('', defined $_ ? ref $_ ? $_->[0] : $_ : ' ') =~ /$string/ } @lines) - 1);
  });
}

around render => sub {
  my ($orig, $self) = @_;

  my $rows = $self->rows;
  my $cols = $self->cols;

  my @lines = @{$self->$orig()};

  if (! $self->has_scrollbar) {
    return \@lines;
  }

  if ($self->_row_diff > 0) {
    $self->_col_diff > 0 and $rows--;
    my $size = int($rows * ($rows / ($rows + $self->_row_diff)));
    my $percent = $self->row / $self->_row_diff;
    my $start = int(($percent * $rows) - ($percent * $size));
    my $end = $start + $size;

    my $i = 0;
    foreach my $line (@lines) {
      if ($i >= $start && $i < $end) {
	$line->[-1] = '[';
      } else {
	$line->[-1] = undef;
      }
      $i++;
    }
  }

  if ($self->_col_diff > 0) {
    $lines[-1] = [(undef) x $cols];
    $self->_row_diff > 0 and $cols--;
    my $size = int($cols * ($cols / ($cols + $self->_col_diff)));
    my $percent = $self->col / $self->_col_diff;
    my $start = int(($percent * $cols) - ($percent * $size));
    splice(@{$lines[-1]}, $start, $size, [('=') x $size]);
  }

  \@lines;
};

around _render => sub {
  my ($orig, $self) = @_;

  my @lines = @{$self->$orig()};
  @lines or return \@lines;

  $self->row == -1 and $self->row(scalar(@lines));

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
      splice(@$_, 0, $self->col);

      $_;
    } @lines;
  } else {
    $self->col(0);
  }

  \@lines;
};

no Moose;

1;
