package Term::Pager;

use strict;

use Term::ReadKey;

my $clear_string = `clear`;

sub new {
  my ($class, $opts) = @_;

  $opts ||= {};

  my $self = {
    row => 0,
    col => 0,
    %$opts,
  };

  bless $self, $class;
}

sub left {
  my $self = shift;

  $self->{col} and $self->{col}--;
}

sub right {
  my $self = shift;

  $self->{col}++;
}

sub up {
  my $self = shift;

  $self->{row} and $self->{row}--;
}

sub down {
  my $self = shift;

  $self->{row}++;
}

sub get_term_size {
  my ($cols, $rows) = GetTerminalSize();

  return ($rows, $cols);
}

sub print {
  my ($self, $text) = @_;

  print $clear_string;

  print($self->render($text, get_term_size()));
}

sub render {
  my ($self, $text, $rows, $cols) = @_;

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
