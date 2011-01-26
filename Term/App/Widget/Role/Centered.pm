package Term::App::Widget::Role::Centered;

use strict;

use List::MoreUtils qw( apply after_incl );

use Moose::Role;

around _render => sub {
  my ($orig, $self) = @_;

  my @lines =
    reverse
    after_incl { @$_ }
    reverse
    after_incl { @$_ }
    map {
      [ 
        reverse
        after_incl { defined }
        reverse
        after_incl { defined }
        @$_
      ]
    } @{$self->$orig()};

  my $missing_lines = $self->rows - scalar(@lines);
  my $before_lines = ($missing_lines / 2);

  [ 
    (map { [] } (1..$before_lines)),
    (map {
      my $missing = $self->cols - scalar(@$_);
      my $prefix = int($missing / 2);
      [((undef) x $prefix), @$_];
    } @lines),
  ]
};

no Moose;

1;
