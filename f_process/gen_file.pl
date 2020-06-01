#!/usr/bin/perl
use warnings;
use strict;

my $fname = shift;
open my $fh, '>', "$fname" or die "Cannot create $fname: $!";

foreach my $l (<>) {
  for (0..100000) {
    print $fh "$l\n";
  }
}