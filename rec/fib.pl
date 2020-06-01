#!/usr/bin/perl
use warnings;
use strict;

sub fib {
  our $n = shift;

  sub go {
    my ($i, $a, $b) = (shift, shift, shift);
    return $a if $i == $n;
    return go ($i+1, $b, $a+$b);
  };

  return go(0,0,1);
}
my $f = fib shift;
print "$f\n";