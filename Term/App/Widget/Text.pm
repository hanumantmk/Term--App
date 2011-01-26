package Term::App::Widget::Text;

use strict;

use Moose;

extends 'Term::App::Widget';

has 'text' => (is => 'rw', isa => 'Str', default => '');
has 'color' => (is => 'rw', isa => 'Str');

sub _render {
  my $self = shift;

  [map {
    $self->color
      ? [map { [$_, {color =>$self->color}] } split //]
      : [split //]
  } split /\n/, $self->text];
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
