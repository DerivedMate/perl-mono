#!/usr/bin/perl
use warnings;
use strict;
use Text::Trim qw(trim);
use Benchmark;

my $t0 = Benchmark->new();

if ($#ARGV < 3) {
    die "Usage: insert-csv <field-term> <file> <db-name>";
}
my ($term, $fname, $db_name) = @ARGV;

open(DATA, "<$fname");
my $label_line = <DATA>;
my @labels = map {lcfirst $_} (split($term, $label_line));
my @r = (0..$#labels);

use constant {
    INT => 'int',
    VCHAR => 'varchar(255)',
    DATE => 'date',
    TIME => 'time',
    DATETIME => 'datetime',
    BLOB => 'blob',
    TEXT => 'text',
    NONE => 'NONE',
};

sub estab_type {
    my ($old_t, $field) = (shift, shift);

    if ($field =~ /^\d+$/) { # INT
        if ($old_t eq NONE or $old_t eq INT) {
            INT
        } elsif ($old_t eq VCHAR) {
            VCHAR
        }
    } elsif (my ($pre_dot, $post_dot) = ($field =~ /^(\d+)\.(\d+)$/)) { # Decimal
        my ($pre_len, $post_len) = map {length $_} ($pre_dot, $post_dot);
        if ($old_t =~ /decimal/) {
            my ($pre_old, $post_old) = ($old_t =~ /decimal\((\d+),(\d+)\)/);
            my $pre_new = $pre_old > $pre_len ? $pre_old : $pre_len;
            my $post_new = $post_old > $post_len ? $post_old : $post_len;

            "decimal($pre_new,$post_new)"
        } else {
            "decimal($pre_len,$post_len)"
        }
    } elsif ($field =~ /^\d{4}\-\d{2}\-\d{2}$/) {# DATE
        DATE
    } elsif ($field =~ /^\-?\d{3}\:\d{2}\:\d{2}$/) {# TIME
        TIME
    } elsif ($field =~ /^\d{4}\-\d{2}\-\d{2} \-?\d{3}\:\d{2}\:\d{2}$/) { # DATETIME
        DATETIME
    } elsif ($field =~ /^[A-z0-9]$/) { # Blob
        BLOB
    } elsif ($field =~ /[\p{L}\w\d\s]*/) { # Text
        if (length $field > 255) {
            TEXT
        } else {
            VCHAR
        }
    } else {
        $old_t
    }
}

# Establish data types
my @prev = map {NONE} @r;
while (my $l = <DATA>) {
    my @data = map {trim $_} (split($term, $l));
    
    if (scalar @data != scalar @prev and (scalar @data) != 0) {
        die "Inconsistent entry length";
    }
    
    my @r = (0..($#data));
    my @next;
    foreach my $i (@r) {
        push (@next, (estab_type ($prev[$i], $data[$i])));
    }

    @prev = @next;
}

# get the primary key
my $found_id = 0;
foreach my $i (@r) {
    if (not $found_id) {
        my $l = $labels[$i];

        if ($l =~ /(^id|id$)/) {
            my $old = $prev[$i];
            $prev[$i] = "$old primary key";
            $found_id = 1;
        }
    }
}

# get the table name
my ($table_name) = ($fname =~ m/^(.+)\..+$/);

# Create the output script
my $cmd = "
create database if not exists $db_name;
use $db_name;
create table $table_name (
";

foreach my $i (@r) {
    my ($lbl, $type) = map {trim  $_} ($labels[$i], $prev[$i]);
    $cmd .= "\t$lbl $type" . ($i == $#r ? "\n);\n" : ",\n");
}

$cmd .= "set global local_infile = True;\nload data local infile '$fname' into table $table_name fields terminated by '$term' ignore 1 lines;\n";
print $cmd;
my $t1 = Benchmark->new();
my $td = timestr timediff($t1, $t0);
print STDERR "[insert-csv] took $td\n";

close DATA;