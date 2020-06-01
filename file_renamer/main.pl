#!/usr/bin/perl
use strict;
use warnings;

use Path::Tiny; 

my $dir_p = $ARGV[0] or die "Path not given";
my $rex = '(\w+):(\d+)\.(\d+)\.md';

my $dir = path $dir_p;
my $iter = $dir->iterator();

sub rename_file { 
  my ($file, $rex) = @_;

  my ($sub, $d, $m) = ($file =~ $rex);
  my $new = "$dir/$sub:$m.$d.md";

  print "Renaming '$file' -> '$new'\n";
  rename ($file, $new) or die "failed to rename; $!";
} 

while (my $file = $iter->()) {
  next if $file->is_dir() or not ($file =~ /$rex/);
  
  rename_file $file, $rex;
}

 