package Term::App;

use Moose;

use AnyEvent;
use AnyEvent::Handle;
use Term::ReadKey;
use Term::App::Util::Tokenize qw( tokenize_ansi );

use IO::Handle;

use Scalar::Util qw( weaken );

use strict;

has 'child' => (is => 'ro', isa => 'Term::App::Widget');

has 'screen' => (is => 'rw', isa => 'ArrayRef[Str]', default => sub { [] });

has 'events' => (is => 'rw', isa => 'ArrayRef[Term::App::Event]', default => sub { [] });

has 'keyboard_handler' => (is => 'ro', isa => 'AnyEvent::Handle', builder => '_build_keyboard_handler', lazy => 1);

has 'quit_condvar' => (is => 'ro', default => sub { AnyEvent->condvar });

has 'stdout' => (is => 'ro', default => sub { AnyEvent::Handle->new(fh => \*STDOUT) });

sub _build_keyboard_handler {
  my $self = shift;

  weaken($self);

  ReadMode 3;

  AnyEvent::Handle->new(
    fh   => \*STDIN,
    on_read => sub {
      my $hdl = shift;

      $hdl->{rbuf} or return;

      my $tokens = tokenize_ansi($hdl->{rbuf});

      $hdl->{rbuf} = '';

      if (grep { $_ eq 'q' } @$tokens) {
	$self->quit_condvar->send;
	return;
      }

      $self->child->receive_key_events($tokens);
      $self->draw;
    },
  );
}

sub draw {
  my $self = shift;

  my ($cols, $rows) = GetTerminalSize;

  $self->child->rows($rows);
  $self->child->cols($cols);

  my $to_draw = $self->child->render;
  
#TODO use ANSI sequences to avoid having to clear and redraw

  return if (join('', @$to_draw) eq join('', @{$self->screen}));

  $self->stdout->push_write("\033[H" . join("\n", @$to_draw));

  $self->screen($to_draw);

  return;
}

sub loop {
  my $self = shift;

  $self->draw;

  $self->keyboard_handler;

  $self->quit_condvar->recv;

  $self->stdout->push_write("\033[?25h");

  ReadMode 0;

  return;
}

sub BUILD {
  my $self = shift;

  weaken($self);

  $self->stdout->push_write("\033[?25l");

  $self->child->app($self);

  foreach my $event (@{$self->events}) {
    my $cb = $event->callback;
    $event->callback(sub {
      $cb->($self,@_);
    });
    $event->register;
  }
}

no Moose;

1;
