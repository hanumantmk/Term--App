package Term::App::Widget::Text;

use strict;

use Moose;

extends 'Term::App::Widget';

has 'text' => (is => 'rw', isa => 'Str', default => '');

sub _render {
  my $self = shift;

  [split /\n/, $self->text];
}

no Moose;

1;
