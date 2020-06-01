#!/usr/bin/perl
use warnings;
use strict;

my $content = "#!/usr/bin/perl\nuse warnings;\nuse strict;\n";

my $f_name = shift or die "Filename unspecified";
open my $fh, '>', $f_name or die "Cannot create the file $f_name";
print $fh $content;

system "chmod +x $f_name";
