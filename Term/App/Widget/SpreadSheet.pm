package Term::App::Widget::SpreadSheet;

use strict;

use Moose;

extends 'Term::App::Widget';

use List::MoreUtils qw( firstidx pairwise );
use List::Util qw( max );

use Scalar::Util qw( weaken );

use constant FORMAT => {
  f => sub { sprintf("%.2f", $_[0]) },
  d => sub { sprintf("%d",   $_[0]) },
  s => sub { sprintf("%s",   $_[0]) },
};

has headers => (is => 'rw', isa => 'ArrayRef[Str]');
has data_types => (is => 'rw', isa => 'ArrayRef[Str]');
has sort_column => (is => 'rw', isa => 'Int');
has reversed => (is => 'rw');

has input => (is => 'rw', isa => 'ArrayRef[ArrayRef[Str]]', default => sub {[]});

sub sort {
  my $self = shift;

  $self->ask("By which column?", sub {
    my $column = shift;

    if ($column =~ /^r (.+)$/) {
      $column = $1;
      $self->reserved(1);
    } else {
      $self->reserved(0);
    }

    my $idx = firstidx { /$column/ } @{$self->headers};
    if ($idx < 0) {
      return;
    }

    $self->sort_column($idx);
    $self->app->draw;
  });
}

sub _render {
  my $self = shift;

  weaken($self);

  my $input = $self->input;

  @$input or return [];

  if (defined(my $idx = $self->sort_column)) {
    $input = [sort {
      ! $self->data_types || $self->data_types->[$idx] eq 's'
	? $b->[$idx] cmp $a->[$idx]
	: $b->[$idx] <=> $a->[$idx];
    } @$input];

    if ($self->reversed) {
      $input = [reverse @$input];
    }
  }

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

  my $header = do {
    my $i = 0;
    my @points = map {
      my $size = $_;
      my $j = $i++;

      my $callback = sub {
	if (defined $self->sort_column && $self->sort_column eq $j) {
	  $self->reversed(! $self->reversed);
	} else {
	  $self->sort_column($j);
	}
	$self->app->draw;
      };

      ((($callback) x $size), '', '', '');
    } @max_sizes;

    splice(@points,-3);

    my @headers = split //, sprintf($format_string, @headers);

    my @header = pairwise {
      $b
	? [$a, {callback => $b}]
	: $a
    } @headers, @points;

    \@header;
  };

  [
    $header,
    map { [split //] }
    (
      $break_string,
      (map {
	my $d = $_;

	my $i = 0;

	if (ref $d eq 'ARRAY') {
	  for (my $i = scalar(@$d); $i < scalar(@max_sizes); $i++) {
	    $d->[$i] = '';
	  }
	  sprintf($format_string, @$d);
	} else {
	  $break_string
	}
      } @data),
    ),
  ];
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
