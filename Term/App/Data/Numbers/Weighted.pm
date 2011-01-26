package Term::App::Data::Numbers::Weighted;

use strict;

use Moose;

extends 'Term::App::Data::Numbers';

use PDL::Lite;

has granularity => (is => 'ro', isa => 'Int', default => 100);
has _weights     => (is => 'rw', default => sub { PDL::Core::pdl([]) });

sub histogram {
  my ($self, $num_buckets) = @_;

  my ($xvals, $hist) = $self->_histogram($self->_data, $self->_weights, $num_buckets);

  return map { [PDL::Core::list($_)] } ($xvals, $hist);
}

sub _histogram {
  my ($self, $data, $weights, $num_buckets) = @_;

  my ($mean, $prms, $median, $min, $max, $adev, $rms) = PDL::Primitive::stats($data, $weights);

  if ($max == $min) {
    return (PDL::Core::pdl(($max) x $num_buckets),PDL::Core::pdl((1) x $num_buckets));
  }

  my $step = ($max - $min) / $num_buckets;

  return PDL::Basic::whist($data, $weights, $min, $max, $step);
}

sub integrate {
  my ($self, @new_data) = @_;

  my $n = $self->_scrub_data(\@new_data);

  my ($data, $weights) = $self->_histogram($self->_data->append($n), $self->_weights->append($n->ones), $self->granularity);

  $self->_data($data);
  $self->_weights($weights);

  return;
}

sub stats {
  my $self = shift;

  my ($mean, $prms, $median, $min, $max, $adev, $rms) = PDL::Primitive::stats($self->_data, $self->_weights);

  return ($mean, $prms, $median, $min, $max, $adev, $rms);
}

sub size {
  my $self = shift;

  $self->_weights->sum;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
