package Term::App::Data::Numbers;

use strict;

use Moose;

use PDL::Lite;
$PDL::SHARE=$PDL::SHARE;

has _data => (is => 'rw', default => sub { PDL::Core::pdl([]) });

sub histogram {
  my ($self, $num_buckets) = @_;

  my ($mean, $prms, $median, $min, $max, $adev, $rms) = $self->stats;

  if ($max == $min) {
    return ([($max) x $num_buckets],[(1) x $num_buckets]);
  }

  my $step = ($max - $min) / $num_buckets;

  my ($xvals, $hist) = PDL::Basic::hist($self->_data, $min, $max, $step);

  return map { [PDL::Core::list($_)] } ($xvals, $hist);
}

sub integrate {
  my ($self, @new_data) = @_;

  $self->_data($self->_data->append(PDL::Core::pdl(@new_data)));
}

sub stats {
  my $self = shift;

  my ($mean, $prms, $median, $min, $max, $adev, $rms) = PDL::Primitive::stats($self->_data);

  return ($mean, $prms, $median, $min, $max, $adev, $rms);
}

sub size {
  my $self = shift;

  $self->is_empty
    ? 0
    : $self->_data->getdim(1);
}

sub is_empty {
  my $self = shift;

  $self->_data->isempty;
}

no Moose;

1;
