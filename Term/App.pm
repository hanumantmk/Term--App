package Term::App;

use Moose;

use EV;
use AnyEvent;
use AnyEvent::Handle;
use Term::ReadKey;
use Term::App::Util::Tokenize qw( tokenize_ansi );

use Term::ANSIColor qw( color );

use IO::Handle;

use Scalar::Util qw( weaken );

use strict;

has 'child' => (is => 'rw', isa => 'Term::App::Widget', trigger => sub {
  my ($self, $child) = @_;

  $child->app($self);
  $child->parent($self);
});

has 'screen' => (is => 'rw', isa => 'Str', default => '');
has '_last_render' => (is => 'rw', default => sub { [[]] });

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

      if (grep { (ref $_ ? $_->[0] : $_) eq 'q' } @$tokens) {
	$self->quit_condvar->send;
	return;
      }

      foreach my $token (@$tokens) {
	if (ref $token ? $token->[0] : $token =~ 'click' ) {
	  my ($click, $col, $row) = @$token;
	  $row-=33;
	  $col-=33;

	  my $cell = $self->_last_render->[$row][$col];

	  if (defined $cell && ref $cell && $cell->[1]{callback}) {
	    $cell->[1]{callback}->($click);
	  }
	} else {
	  $self->child->receive_key_events([$token]);
        }
      }
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
  
  my $string = join("\n", map {
    my $color = '';

    join('', map {
      my $new_color = '';

      if (defined $_ && ref $_ && $_->[1]{color}) {
	$new_color = $_->[1]{color}
      }

      my $val = '';

      if ($color && ! $new_color) {
	$val = color("reset");
      } elsif ((! $color && $new_color) || ($color ne $new_color)) {
	$val = color($new_color);
      }

      $color = $new_color;

      if (defined $_) {
	if (ref $_) {
	  $val .= $_->[0]
	} else {
	  $val .= $_;
	}
      } else {
	$val .= ' ';
      }

      $val
    } @$_) . ($color ? color('reset') : '');
  } @$to_draw);
  $string =~ s/\t/ /g;

  $self->_last_render($to_draw);

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

  $self->stdout->push_write("\033[?25l"); # turn off cursor
  $self->stdout->push_write("\033[?9h"); # turn on mouse events

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
  print "\033[?25h"; # turn on cursor
  print "\033[?9l"; # turn off mouse events
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
