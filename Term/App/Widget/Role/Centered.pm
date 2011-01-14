package Term::App::Widget::Role::Centered;

use strict;

use List::MoreUtils qw( apply after_incl );

use Moose::Role;

around _render => sub {
  my ($orig, $self) = @_;

  my @lines =
    reverse
    after_incl { ! /^$/ }
    reverse
    after_incl { ! /^$/ }
    apply { 
      s/^\s*//;
      s/\s*$//;
    } @{$self->$orig()};

  my $missing_lines = $self->rows - scalar(@lines);
  my $before_lines = ($missing_lines / 2);

  [
    ('') x $before_lines,
    map {
      my $missing = $self->cols - length($_);
      my $prefix = int($missing / 2);
      (' ' x $prefix) . $_;
    } @lines
  ]
};

no Moose;

1;
