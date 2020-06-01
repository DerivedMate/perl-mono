#!/usr/bin/perl
use warnings;
use strict;

system("sudo apt-get update");

my $pkgs = join ' ', @ARGV;
my $err = system("sudo apt-get install $pkgs");

die "No pude instalar los paquetes [$pkgs]:\n$!" if $err;
