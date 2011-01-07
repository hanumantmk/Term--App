package Term::App::Widget::SpreadSheet;

use strict;

extends 'Term::App::Widget';

use List::Util qw( max );

use constant FORMAT => {
  f => sub { sprintf("%.2f", $_[0]) },
  d => sub { sprintf("%d",   $_[0]) },
};

has headers => (is => 'rw', isa => 'ArrayRef[Str]');
has data_types => (is => 'rw', isa => 'ArrayRef[Str]');

has input => (is => 'rw', isa => 'ArrayRef[ArrayRef[Str]]');

sub render {
  my $self = shift;

  my $input = $self->input;

  my @data;

  if (my $data_types = $self->data_types) {
    @data = map {
      if (ref $_ eq 'ARRAY') {
	my $i = 0;
	[ map {
	  my $r = $data_types->[$i]
	    ? FORMAT->{$data_types->[$i]}->($_)
	    : $_;
	  
	  $i++;

	  $r;
	} @$_ ]
      } else {
	$_
      }
    } @$input;
  } else {
    @data = @$input;
  }

  my @headers = $self->headers
    ? @{$self->headers}
    : ();

  my @max_sizes;

  foreach my $row (grep { ref $_ eq 'ARRAY' } @data) {
    for (my $i = 0; $i < scalar(@$row); $i++) {
      my $len = length($row->[$i]);

      if (! defined($max_sizes[$i]) || $max_sizes[$i] < $len) {
	$max_sizes[$i] = $len;
      }
    }
  }

  if (scalar(@headers) < scalar(@max_sizes)) {
    for (my $i = @headers; $i < scalar(@max_sizes); $i++) {
      $headers[$i] = $i + 1;
    }
  }

  for (my $i = 0; $i < scalar(@headers); $i++) {
    my $len = length($headers[$i]);

    if (! defined($max_sizes[$i]) || $max_sizes[$i] < $len) {
      $max_sizes[$i] = $len;
    }
  }

  my $format_string = join(" | ", map { "%${_}s" } @max_sizes);
  my $break_string  = join("-+-", map { "-" x $_ } @max_sizes);

  [
    sprintf($format_string, @headers),
    $break_string,
    (map {
      ref $_ eq 'ARRAY'
	? sprintf($format_string, @$_)
	: $break_string
    } @data),
  ];
}

no Moose;

1;
