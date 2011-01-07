package Term::App;

use Moose;

use AnyEvent;
use Term::ReadKey;
use Term::App::Util::Tokenize qw( tokenize_ansi );

use strict;

has 'child' => (is => 'ro', isa => 'Term::App::Widget');

has 'screen' => (is => 'rw', isa => 'ArrayRef[Str]', default => sub { [] });

sub draw {
  my ($self, $to_draw) = @_;

#TODO use ANSI sequences to avoid having to clear and redraw
  
  print `clear`;
  print join('', map { "$_\n" } @$to_draw);

  $self->screen($to_draw);

  return;
}

sub loop {
  my $self = shift;

  ReadMode 4;

  my $user = AnyEvent->io(
    fh   => \*STDIN,
    poll => 'r',
    cb   => sub {
      my $input;
      if (sysread(\*STDIN, $input, 4096)) {
	my $tokens = tokenize_ansi($input);

	if (grep { $_ eq 'q' } @$tokens) {
	  ReadMode 0;
	  exit 0;
	}

	$self->child->receive_key_events(tokenize_ansi($input));
	$self->draw($self->child->render);
      }
    },
  );

  AnyEvent->condvar->recv;
}

no Moose;

1;
