package Term::App::Util::Tokenize;

use strict;

use List::Util qw( max );

use base 'Exporter';

use constant SYMBOLS => {
  left_arrow  => join('',map{ chr($_) } (27, 91, 68)),
  right_arrow => join('',map{ chr($_) } (27, 91, 67)),
  up_arrow    => join('',map{ chr($_) } (27, 91, 65)),
  down_arrow  => join('',map{ chr($_) } (27, 91, 66)),

  page_up     => join('',map{ chr($_) } (27, 91, 53, 126)),
  page_down   => join('',map{ chr($_) } (27, 91, 54, 126)),
  
  tab         => "\t",
  newline     => "\n",

  (map { $_, $_ } ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 )),
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
