package Term::App;

use Moose;

use strict;

has 'child' => (is => 'ro', isa => 'Term::App::Widget');

has 'screen' => (is => 'rw', isa => 'Str');

sub draw {
  my ($self, $to_draw) = @_;

#TODO use ANSI sequences to avoid having to clear and redraw
  
  print `clear`;
  print $to_draw;

  $self->screen($to_draw);

  return;
}

no Moose;

1;
