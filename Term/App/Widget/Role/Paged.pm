package Term::App::Widget::Role::Paged;

use strict;

use Moose::Role;

has row => (is => 'rw', isa => 'Int');
has col => (is => 'rw', isa => 'Int');

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

sub down {
  my $self = shift;

  $self->row($self->row + 1);
}

around render => sub {
  my ($orig, $self) = @_;

  $rows = $self->rows;
  $cols = $self->cols;

  my @lines = @{$self->$orig()};

  splice(@lines, 0, $self->row);

  [ map {
    substr($_, 0, $self->col) = '';

    $_;
  } @lines ];
};
