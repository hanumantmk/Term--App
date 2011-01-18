#!/usr/bin/perl -w

use strict;

use Term::ReadKey;

ReadMode 3;

while (my $key = ReadKey 0) {
  print ord($key) . "\n";
}

END { ReadMode 0 }
