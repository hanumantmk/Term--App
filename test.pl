#!/usr/bin/perl -w

use strict;

use Log::Watcher;

my @lines;

my $watcher = Log::Watcher->new({
  file     => $ARGV[0],
  callback => sub {
    my $input = shift;
    chomp($input);

    push @lines, $input;

    return join("\n", @lines);
  },
});

$watcher->loop;
