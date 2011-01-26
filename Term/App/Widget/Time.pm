package Term::App::Widget::Time;

use strict;

use Moose;

extends 'Term::App::Widget';

sub _render {
  my $self = shift;

  [[split //, scalar(localtime(time))]];
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
