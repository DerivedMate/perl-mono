#!/usr/bin/perl
use warnings;
use strict;
use Text::Trim qw(trim);

my ($term, $fname, $db_name) = @ARGV 
    or die "Usage: insert-csv <field-term> <file> <db-name>";

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
    } elsif ($field =~ /^\d{4}\-\d{2}\-\d{2}$/) {# DATE
        DATE
    } elsif ($field =~ /^\-?\d{3}\:\d{2}\:\d{2}$/) {# TIME
        TIME
    } elsif ($field =~ /^\d{4}\-\d{2}\-\d{2} \-?\d{3}\:\d{2}\:\d{2}$/) { # DATETIME
        DATETIME
    } elsif ($field =~ /^[A-z0-9]$/) {
        BLOB
    } elsif ($field =~ /[\p{L}\w\d\s]*/) {
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
my @prev = map {NONE} (0..($#labels));
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

close DATA;