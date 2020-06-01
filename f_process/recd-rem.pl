#!/usr/bin/perl
use warnings;
use strict;

sub run {
  my ($del, $mdir) = (shift, shift);

  opendir (my $dh, $mdir) or die "Failed to open dir \"$mdir\": $!";
  my @dirst = grep { not /^\./} readdir $dh;

  foreach my $d (@dirst) {
    my $dir_full = $mdir =~ /\/$/ ? $mdir.$d : "$mdir/$d";

    if ( $d eq $del ) {
      print "=> Deleting $dir_full\n";

      my $err = system "rm -rf $dir_full";
      print "Couldn't delete dir \"$dir_full\" : $!\n" if $err;
    } else {
      run($del, $dir_full);
    }
  }
} 

run @ARGV; 