#!/usr/bin/perl
use strict;
use warnings;

sub fact {
  my $n = shift;

  ($n < 1) 
    ? 1
    : $n * fact ($n-1)
  
}

print (fact shift);