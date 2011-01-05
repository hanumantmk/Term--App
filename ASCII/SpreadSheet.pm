package ASCII::SpreadSheet;

use strict;

use List::Util qw( max );

use constant FORMAT => {
  f => sub { sprintf("%.2f", $_[0]) },
  d => sub { sprintf("%d",   $_[0]) },
};

sub new {
  my ($class, $opts) = @_;

  $opts ||= {};

  bless $opts, $class;
}

sub render {
  my ($self, $input) = @_;

  my @data;

  if (my $data_types = $self->{data_types}) {
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

  my @headers = $self->{headers}
    ? @{$self->{headers}}
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

  return join('', map { "$_\n" } (
    sprintf($format_string, @headers),
    $break_string,
    (map {
      ref $_ eq 'ARRAY'
	? sprintf($format_string, @$_)
	: $break_string
    } @data),
  ));
}

1;
