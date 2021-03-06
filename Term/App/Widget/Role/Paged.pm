package Term::App::Widget::Role::Paged;

use strict;

use Moose::Role;

use Scalar::Util qw( weaken );

use List::Util qw( max min );
use List::MoreUtils qw( firstidx );

has row => (is => 'rw', isa => 'Int', default => 0);
has col => (is => 'rw', isa => 'Int', default => 0);
has has_scrollbar => (is => 'rw', isa => 'Int', default => 1);
has search_string => (is => 'rw', isa => 'Str');

has '_row_diff' => (is => 'rw', isa => 'Int');
has '_col_diff' => (is => 'rw', isa => 'Int');

use constant ADDITIONAL_BINDINGS => {
  '/'           => 'start_search',
  'n'           => 'search_again',
  'left_arrow'  => 'left',
  'right_arrow' => 'right',
  'up_arrow'    => 'up',
  'down_arrow'  => 'down',
  'page_up'     => 'page_up',
  'page_down'   => 'page_down',
  'home'        => 'home',
  'end'         => 'end',
};

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

sub _search {
  my ($self, $string) = @_;

  $self->col(0);
  $self->row($self->row + 1);

  my $idx = firstidx { join('', map { defined $_ ? ref $_ ? $_->[0] : $_ : ' ' } @$_) =~ /$string/ } @{$self->_render};

  if ($idx >= 0) {
    $self->row($idx + $self->row);
  } else {
    $self->row(0);

    $self->row(firstidx { join('', map { defined $_ ? ref $_ ? $_->[0] : $_ : ' ' } @$_) =~ /$string/ } @{$self->_render});
  }

  $self->app->draw;
}

sub search_again {
  my $self = shift;

  $self->_search($self->search_string) if ($self->search_string);
}

sub start_search {
  my $self = shift;

  weaken($self);

  $self->ask("Search String", sub {
    my $string = shift;

    $self->search_string($string);

    $self->_search($string);
  });
}

around render => sub {
  my ($orig, $self) = @_;

  my $rows = $self->rows;
  my $cols = $self->cols;

  my @lines = @{$self->$orig()};

  if ($self->has_scrollbar) {
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
  }

  if (my $ss = $self->search_string) {
    foreach my $line (@lines) {
      my $string = join('', map {
	defined $_
	  ? ref $_
	    ? $_->[0]
	    : $_
	  : ' '
      } @$line );

      if ($string =~ /$ss/) {
	for (my $i = $-[0]; $i < $+[0]; $i++) {
	  if (! ref $line->[$i]) {
	    $line->[$i] = [$line->[$i]];
	  }
	  $line->[$i][1]{color} = 'yellow';
	}
      }
    }
  }

  \@lines;
};

around _render => sub {
  my ($orig, $self) = @_;

  my @lines = @{$self->$orig()};
  if (! @lines) {
    $self->_row_diff(0);
    $self->_col_diff(0);
    return \@lines;
  }

  $self->row < 0 and $self->row(scalar(@lines));

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
