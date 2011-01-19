package Term::App::Util::Tokenize;

use strict;

use List::Util qw( max );

use base 'Exporter';

sub ord_to_string {
  join('', map { chr($_) } @_);
}

use constant SYMBOLS => {
  left_arrow  => ord_to_string(27, 91, 68),
  right_arrow => ord_to_string(27, 91, 67),
  up_arrow    => ord_to_string(27, 91, 65),
  down_arrow  => ord_to_string(27, 91, 66),

  page_up     => ord_to_string(27, 91, 53, 126),
  page_down   => ord_to_string(27, 91, 54, 126),

  home        => ord_to_string(27, 91, 49, 126),
  end         => ord_to_string(27, 91, 52, 126),

  backspace   => ord_to_string(127),
  delete      => ord_to_string(27, 91, 51, 126),
  
  tab         => "\t",
  newline     => "\n",
  space       => ' ',

  (map { chr($_), chr($_) } ( 33 .. 126 )),
};

use constant SIZES => do {
  my %sizes;

  while (my ($key, $value) = each %{+SYMBOLS}) {
    $sizes{length($value)}{$value} = $key;
  }

  \%sizes;
};

our @EXPORT_OK = qw( tokenize_ansi );

sub tokenize_ansi {
  my $string = shift;

  my @tokens;

  my $found_token;

  while ($string) {
    $found_token = 0;

    foreach my $size (grep { $_ <= length($string) } keys %{+SIZES}) {
      my $substr = substr($string, 0, $size);
      if (my $token = SIZES->{$size}->{$substr}) {
	substr($string, 0, $size) = '';
	push @tokens, $token;
	$found_token = 1;
      }
    }

    if (! $found_token) {
      substr($string, 0, 1) = '';
    }
  }

  return \@tokens;
}
