#!/usr/bin/perl
use warnings;
use strict;
use Text::Trim qw(trim);
use List::Util qw[min max];
use Benchmark;

use constant {
    INT => 'int',
    DATE => 'date',
    TIME => 'time',
    DATETIME => 'datetime',
    BLOB => 'blob',
    TEXT => 'text',
    NONE => 'NONE',
};

my $t0 = Benchmark->new();

if ($#ARGV < 2) {
    die "Usage: insert-csv <field-term> <file> <db-name>";
}

sub extract_char {
    my $t = shift;
    my ($n) = ($t =~ /(?:var)?char\((\d+)\)/);
    $n
}
sub resolve_char {
    my ($old, $new) = (shift, shift);
    my $a = extract_char $old;
    my $b = extract_char $new;

    if ($a != $b) {
        my $c = max ($a, $b);
        "varchar($c)"
    } elsif ($old =~ /var/) {
        "varchar($b)"
    } else {
        "char($b)"
    }
}

sub extract_dec {
    my $t = shift;
    my ($n, $m) = ($t =~ /decimal\((\d+),(\d+)\)/);
    ($n, $m)
}
sub resolve_decimal {
    my ($old, $new) = (shift, shift);
    my ($old_a, $old_b) = extract_dec $old;
    my ($new_a, $new_b) = extract_dec $new;

    my $a = max ($old_a, $new_a);
    my $b = max ($old_b, $new_b);

    "decimal($a,$b)"
}

sub estab_type {
    my $field = shift;

    if ($field =~ /^\d+$/) { # INT
        INT
    } elsif (my ($pre_dot, $post_dot) = ($field =~ /^(\d+)\.(\d+)$/)) { # Decimal
        my ($pre_len, $post_len) = map {length $_} ($pre_dot.$post_dot, $post_dot);
        "decimal($pre_len,$post_len)"
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
            my $l = length $field;
            "char($l)"
        }
    } else {
        NONE
    }
}

sub merge_types {
    my ($old, $new) = (shift, shift);

    if ($old eq NONE) {
        $new
    } elsif ($new eq TEXT) {
        TEXT
    } elsif ($old =~ /char/ and $new =~/char/) {
        resolve_char $old, $new
    } elsif ($old =~ /decimal/ and $new eq INT) {
        $old
    } elsif ($new =~ /decimal/ and $old eq INT) {
        $new
    } else {
        $old
    }
}

sub file_cmd {
    my ($fname, $term, $db_name) = (shift, shift, shift);

    open(my $fh, "<$fname");
    my $label_line = <$fh>;
    my @labels = map {lcfirst $_} (split($term, $label_line));
    my @r = (0..$#labels);

    # Establish data types
    my @prev = map {NONE} @r;
    while (my $l = <$fh>) {
        my @data = map {trim $_} (split($term, $l));

        if (scalar @data != scalar @prev and (scalar @data) != 0) {
            die "Inconsistent entry length";
        }

        my @next;
        foreach my $i (@r) {
            my $new = estab_type $data[$i];
            push (@next, merge_types ($prev[$i], $new));
        }

        @prev = @next;
    }

    # get the primary key
    my $found_id = 0;
    foreach my $i (@r) {
        my $l = $labels[$i];
            if ($l =~ /(^id|id$)/) {
                my $old = $prev[$i];
                if ($found_id == 0) {
                    $prev[$i] = "$old primary key";
                    $found_id = 1;
                } else {
                    $prev[$i] = "$old not null";
                }
            }
    }

    # get the table name
    my ($table_name) = ($fname =~ m/([\w_\d]+)\.\w+$/);

    # Create the output script
    my $cmd = "create table $table_name (\n";

    # Insert field types
    foreach my $i (@r) {
        my ($lbl, $type) = map {trim  $_} ($labels[$i], $prev[$i]);
        $cmd .= "\t$lbl $type" . ($i == $#r ? "\n);\n" : ",\n");
    }

    # Add an insertion command
    $cmd .= "load data local infile '$fname' into table $table_name fields terminated by '$term' ignore 1 lines;\n\n";
    print $cmd;

    close $fh;
}

my ($source, $del, $db_name) = (shift, shift, shift);
print "create database if not exists $db_name;use $db_name;\nset global local_infile = True;\n";

open (my $srch, "<$source") or die $!;

foreach my $f (<$srch>) {
    $f = trim $f;
    file_cmd $f, $del, $db_name
}

close $srch;
my $t1 = Benchmark->new();
my $td = timestr timediff($t1, $t0);
print STDERR "[insert-csv] took $td\n";
