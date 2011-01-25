#!/usr/bin/perl -w

use strict;

use Term::ReadKey;

ReadMode 3;

print "\033[?9h";

while (my $key = ReadKey 0) {
  print ord($key) . "\n";
}

END { ReadMode 0; print "\033[?9l" }
