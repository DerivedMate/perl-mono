#!/usr/bin/perl
use warnings;
use strict;
use Text::Trim qw(trim);

# remove toe old version
my $rm = "/opt/droidcam-uninstall";
if (-e $rm) {
    my $err = system "sudo $rm";
    die $! if $err;
}

# Get a new one
my $dir = "/tmp";
my $get = "
    cd $dir;
    wget https://files.dev47apps.net/linux/droidcam_latest.zip;
    echo \"fb7d7fa80a8e47a98868941939104636 droidcam_latest.zip\" | md5sum -c --";
my $inst = "
    cd $dir; 
    unzip droidcam_latest.zip -d droidcam && cd droidcam;
    sudo ./install;
";

my $err = system trim($get);
die $! if $err;

my $err = system trim($inst);
die $! if $err;
