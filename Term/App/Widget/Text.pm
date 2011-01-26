package Term::App::Widget::Text;

use strict;

use Moose;

extends 'Term::App::Widget';

has 'text' => (is => 'rw', isa => 'Str', default => '');

sub _render {
  my $self = shift;

  [map { [split //] } split /\n/, $self->text];
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
