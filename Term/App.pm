package Term::App;

use Moose;

use AnyEvent;
use Term::ReadKey;
use Term::App::Util::Tokenize qw( tokenize_ansi );

use strict;

has 'child' => (is => 'ro', isa => 'Term::App::Widget');

has 'screen' => (is => 'rw', isa => 'ArrayRef[Str]', default => sub { [] });

sub draw {
  my $self = shift;

  my ($cols, $rows) = GetTerminalSize;

  $self->child->rows($rows);
  $self->child->cols($cols);

  my $to_draw = $self->child->render;
  
#TODO use ANSI sequences to avoid having to clear and redraw

  print `clear`;
  print join('', map { "$_\n" } @$to_draw);

  $self->screen($to_draw);

  return;
}

sub loop {
  my $self = shift;

  $self->draw;

  ReadMode 3;

  my $user = AnyEvent->io(
    fh   => \*STDIN,
    poll => 'r',
    cb   => sub {
      my $input;
      if (sysread(\*STDIN, $input, 4096)) {
	my $tokens = tokenize_ansi($input);

	if (grep { $_ eq 'q' } @$tokens) {
	  exit 0;
	}

	$self->child->receive_key_events($tokens);
	$self->draw;
      }
    },
  );

  AnyEvent->condvar->recv;
}

END {
  ReadMode 0;
}

no Moose;

1;
