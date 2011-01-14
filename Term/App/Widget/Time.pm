package Term::App::Widget::Time;

use strict;

use Moose;

extends 'Term::App::Widget';

sub _render {
  my $self = shift;

  [scalar(localtime(time))];
}

no Moose;

1;
