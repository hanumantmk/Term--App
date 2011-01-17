package Term::App::Event::WatchFile;

use Moose;

use AnyEvent;

use Scalar::Util qw( weaken );

extends 'Term::App::Event';

has 'filename' => (is => 'ro', required => 1);
has 'seconds' => (is => 'ro', required => 1);

sub _build_event {
  my $self = shift;

  weaken($self);

  my $mtime = 0;

  AnyEvent->timer(
    after    => $self->seconds,
    interval => $self->seconds,
    cb       => sub {
      my $new_mtime = [stat($self->filename)]->[9];

      if ($new_mtime > $mtime) {
	local $/;
	open FILE, $self->filename or $self->log("Couldn't open file " . $self->filename . ": $!") and return;
	my $content = <FILE>;
	close FILE or $self->log("Couldn't close file " . $self->filename . ": $!") and return;

	$self->callback->($content);
      }
    },
  );
}

no Moose;

1;
