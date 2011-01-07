package Term::App::Widget::Container::LeftToRight;

use strict;

use Moose;

use List::Util qw( reduce max );

extends 'Term::App::Widget';

has children => (is => 'ro', isa => 'ArrayRef[Term::App]', default => sub { [] });
has focused => (is => 'ro', isa => 'Term::App');

sub receive_key_events {
  my ($self, $tokens) = @_;

  $self->focused->receive_key_events($tokens);
}

augment render => sub {
  my $self = shift;

  reduce {
    [map {
      ($a->[$_] || '') . ($b->[$_] || '')
    } (0..max(scalar(@$a), scalar(@$b)))];
  } map { $_->render } @{$self->children};
};

no Moose;

1;
