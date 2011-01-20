package Term::App::Widget::Histogram;

use strict;

use Moose;
use Moose::Util::TypeConstraints;

use PDL::Lite;
$PDL::SHARE=$PDL::SHARE;

use List::Util qw( max min );
use List::MoreUtils qw( pairwise );

extends 'Term::App::Widget';

has orientation => (is => 'rw', isa => enum([qw( vertical horizontal )]), default => 'horizontal');
has buckets     => (is => 'rw', isa => 'Int');
has max_val     => (is => 'rw', isa => 'Int');
has min_val     => (is => 'rw', isa => 'Int');
has input       => (is => 'rw', isa => 'ArrayRef', default => sub {[]});

sub _render {
  my $self = shift;

  @{$self->input} or return [];

  my $data = PDL::Core::pdl($self->input);

  my ($mean, $prms, $median, $min, $max, $adev, $rms) = PDL::Primitive::stats($data);

  $max = min($self->max_val, $max) if defined $self->max_val;
  $min = max($self->min_val, $min) if defined $self->min_val;

  my $buckets = $self->buckets;
  
  if ($self->orientation eq 'vertical') {
    my $high = int($self->cols / 2 - length($max) + 1);

    if (! $buckets || $buckets > $high) {
      $buckets = $high;
    }
  } else {
    my $high = $self->rows - length(scalar(@{$self->input}));

    if (! $buckets || $buckets > $high) {
      $buckets = $high;
    }
  }

  if ($buckets <= 0) {
    return [];
  }

  my $step = (($max - $min) / $buckets) || 1;

  my ($xvals, $hist) = PDL::Basic::hist($data, $min, $max, $step);
  my @xvals = map { sprintf("%.1f", $_) } PDL::Core::list $xvals;
  my @hist  = PDL::Core::list $hist;

  if ($self->orientation eq 'horizontal') {
    my $x_size = max map { length } @xvals;
    my $y_max  = max @hist;

    my $bar_size = $self->cols - $x_size - 2;

    my $sprintf = "%-" . $x_size . "s " . "%-" . $bar_size . "s";

    my @lines = pairwise { sprintf($sprintf, $a, ('X' x ($bar_size * ($b/$y_max)))) } @xvals, @hist;

    my @y_labels;

    foreach my $h (grep { $_ > 0 } @hist) {
      my @chars = split //, $h;

      for (my $i = 0; $i < @chars; $i++) {
	$y_labels[$i][$bar_size * ($h/$y_max)] = $chars[$i];
      }
    }

    return [
      @lines,
      (map {
	(' ' x $x_size) . join '', map { defined $_ ? $_ : ' ' } @$_;
      } @y_labels),
    ];
  } else {
    my $y_size = max map { length } @hist;
    my $y_max  = max @hist;
    my $x_max  = max map { length } @xvals;

    my $bar_size = $self->rows - $x_max - 2;

    my @l;

    my %bars;

    for (my $i = 0; $i < @hist; $i++) {
      my $bar = int($bar_size * ($hist[$i]/$y_max));
      $bars{$bar} = $hist[$i];

      $l[$_][$i] = 'X' for 0..$bar;
    }

    my @lines;

    for (my $i = 0; $i < @l; $i++) {
      $lines[$bar_size - $i] = sprintf("%-" . $y_size . "s ", $bars{$i} || '') .
        join(' ', map { defined $_ ? $_ : ' ' } @{$l[$i]});
    }

    my @y_labels;

    my $j = 0;
    foreach my $x (@xvals) {
      my @chars = split //, $x;

      for (my $i = 0; $i < @chars; $i++) {
	$y_labels[$i][$j] = $chars[$i];
      }
      $j++;
    }

    return [
      @lines,
      (' ' x ($y_size + 1)) . "=" x (scalar(@{$y_labels[0]} * 2 - 1)),
      (map {
	(' ' x ($y_size + 1)) . join(' ', map { defined $_ ? $_ : ' ' } @$_);
      } @y_labels),
    ];
  }
}

no Moose;

1;
