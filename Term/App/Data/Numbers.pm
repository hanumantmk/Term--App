package Term::App::Data::Numbers;

use strict;

use Moose;

use PDL::Lite;
$PDL::SHARE=$PDL::SHARE;

has _data => (is => 'rw', default => sub { PDL::Core::pdl([]) });
has low   => (is => 'rw');
has high  => (is => 'rw');

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

  my $new_data = $self->_scrub_data(\@new_data);

  $self->_data($self->_data->append($new_data));
}

sub _scrub_data {
  my ($self, $new_data) = @_;

  my $d = PDL::Core::pdl($new_data);

  $d->inplace->clip($self->low, $self->high) if (defined $self->low or defined $self->high);

  return $d;
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
