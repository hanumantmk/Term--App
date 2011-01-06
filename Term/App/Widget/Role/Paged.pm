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

sub render {
  my ($self, $text) = @_;

  $rows = $self->rows;
  $cols = $self->cols;

  my @lines = split /\n/, $text, -1;

  splice(@lines, 0, $self->{row});

  if (scalar(@lines) > $rows) {
    splice(@lines, $rows - 1);
  }

  @lines = map {
    substr($_, 0, $self->{col}) = '';

    if (length($_) > $cols) {
      substr($_, $cols - 1) = '';
    }

    $_;
  } @lines;

  return join('', map { "$_\n" } @lines);
}
