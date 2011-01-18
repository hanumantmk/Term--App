package Term::App::Event::WatchFile;

use Moose;

use EV;
use IO::AIO;
use AnyEvent::AIO;

use Scalar::Util qw( weaken );

extends 'Term::App::Event';

has 'filename'     => (is => 'ro', required => 1);
has 'seconds'      => (is => 'ro', default => 5);
has 'initial_read' => (is => 'ro', default => 0);

sub _build_event {
  my $self = shift;

  weaken($self);

  if ($self->initial_read) {
    $self->_aio_slurp_file;
  }

  EV::stat($self->filename, $self->seconds, sub { $self->_aio_slurp_file });
}

sub _aio_slurp_file {
  my $self = shift;

  weaken($self);

  aio_open $self->filename, IO::AIO::O_RDONLY, 0, sub {
    my $fh = shift or $self->app->log("couldn't open file " . $self->filename . ": $!") and return;

    my $size = -s $fh;

    my $contents = '';
    aio_read $fh, 0, $size, $contents, 0, sub {
      my $read = shift;

      $read == $size or $self->app->log("short read: $!") and return;

      close $fh;

      $self->callback->($contents);
    };
  };
}

no Moose;

1;
