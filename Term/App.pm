package Term::App;

use Moose;

use EV;
use AnyEvent;
use AnyEvent::Handle;
use Term::ReadKey;
use Term::App::Util::Tokenize qw( tokenize_ansi );

use IO::Handle;

use Scalar::Util qw( weaken );

use strict;

has 'child' => (is => 'rw', isa => 'Term::App::Widget', trigger => sub {
  my ($self, $child) = @_;

  $child->app($self);
  $child->parent($self);
});

has 'screen' => (is => 'rw', isa => 'Str', default => '');

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

sub log {
  my ($self, $string) = @_;

  warn $string;
}

sub draw {
  my $self = shift;

  my ($cols, $rows) = GetTerminalSize;

  $self->child->rows($rows);
  $self->child->cols($cols);

  my $to_draw = $self->child->render;
  
#TODO use ANSI sequences to avoid having to clear and redraw

  my $string = join("\n", @$to_draw);
  $string =~ s/\t/ /g;

  return if ($string eq $self->screen);

  $self->stdout->push_write("\033[H" . $string);

  $self->screen($string);

  return;
}

sub loop {
  my $self = shift;

  $self->draw;

  $self->keyboard_handler;

  $self->quit_condvar->recv;

  return;
}

sub BUILD {
  my $self = shift;

  weaken($self);

  $self->stdout->push_write("\033[?25l");

  $self->child->parent($self);
  $self->child->assign_app($self);

  foreach my $event (@{$self->events}) {
    my $cb = $event->callback;
    $event->callback(sub {
      $cb->($self,@_);
    });
    $event->register($self);
  }
}

END {
  ReadMode 0;
  print "\033[?25h";
}

no Moose;

1;
