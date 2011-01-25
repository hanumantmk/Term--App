package Term::App::Widget;

use strict;

use Moose;

use List::MoreUtils qw( firstidx );

use Scalar::Util qw( weaken );

has rows => (is => 'rw', isa => 'Int');
has cols => (is => 'rw', isa => 'Int');

has preferred_rows => (is => 'rw', isa => 'Int');
has preferred_cols => (is => 'rw', isa => 'Int');

has bindings => (is => 'ro', isa => 'HashRef', default => sub { {} } );
has plugins => (is => 'ro', isa => 'ArrayRef', default => sub { [] } );
has events => (is => 'ro', isa => 'ArrayRef', default => sub { [] } );

has has_focus => (is => 'rw', isa => 'Int');
has weight => (is => 'rw', isa => 'Int', default => 1);

has parent => (is => 'rw', weak_ref => 1);
has app => (is => 'rw', weak_ref => 1, handles => { log => 'log' });

sub render {
  my $self = shift;

  return [] if ($self->rows < 1);
  return [map { [] } 1..$self->rows] if ($self->cols < 1);

  my @lines = @{$self->_render};

  if (scalar(@lines) > $self->rows) {
    splice(@lines, $self->rows);
  } elsif (scalar(@lines) < $self->rows) {
    push @lines, map { [] } 1..($self->rows - scalar(@lines));
  }

  foreach my $line (@lines) {
    if (scalar(@$line) > $self->cols) {
      splice(@$line, $self->cols);
    } else {
      @$line = @{$self->make_cells($line, $self->make_empty_cells($self->cols - scalar(@$line)))};
    }
  }

  \@lines;
}

sub toggle_focus {
  my ($self, @children) = @_;

  my $idx = firstidx { $_->has_focus } @children;

  $children[$idx]->has_focus(0);

  $idx = ($idx == $#children)
    ? 0
    : $idx + 1;

  $children[$idx]->has_focus(1);

  return;
}

sub receive_key_events {
  my ($self, $tokens) = @_;

  foreach my $token (@$tokens) {
    if (my $sub = $self->bindings->{''} || $self->bindings->{ref $token ? $token->[0] : $token}) {
      if (ref $sub eq 'CODE') {
	$sub->($self, $token);
      } else {
	$self->$sub($token);
      }
    }
  }
}

sub new {
  my ($class, $args) = @_;

  ($args->{plugins}
    ? Moose::Meta::Class->create_anon_class(superclasses => [$class], roles => [map { "Term::App::Widget::Role::$_" } @{$args->{plugins}}], cache => 1)->name
    : $class)->SUPER::new($args);
}

sub BUILD {
  my $self = shift;

  weaken($self);

  foreach my $event (@{$self->events}) {
    my $cb = $event->callback;
    $event->callback(sub {
      $cb->($self,@_);
    });
    $event->register;
  }
}

sub assign_app {
  my ($self, $app) = @_;

  $self->app($app);
}

sub ask {
  my ($self, $string, $callback) = @_;

  require Term::App::Widget::Question;

  weaken($self);

  my $current_top_level_child = $self->app->child;

  my $question_modal = Term::App::Widget::Question->new({
    plugins    => ["Border", "Modal"],
    question   => $string,
    background => $current_top_level_child,
    callback   => sub {
      my $answer = shift;

      $self->app->child($current_top_level_child);

      $callback->($answer);
    },
  });

  $self->app->child($question_modal);
}

sub make_cells {
  my ($self, @args) = @_;

  [ map {
    if (ref $_) {
      @$_;
    } else {
#      map { [$_, [$self]] } split //, $_;
      map { [$_] } split //, $_;
    }
  } @args ];
}

sub make_empty_cells {
  my ($self, $num) = @_;

  [map { [undef] } (1..$num)];
}

no Moose;

1;
