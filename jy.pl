#!/usr/bin/perl

use strict;
use warnings;

use Carp;

my $USAGE_MSG = "Usage: $0 <paragraf length> <paragraf shift> <input filie>";
my $PLMIN = 20;
my $PLMAX = 120;


if ($#ARGV < 2) {
    print "Error: not enaugh arguments\n";
    print $USAGE_MSG;
    exit 1;
}

if ($ARGV[0] < $PLMIN || $ARGV[0] > $PLMAX) {
    print "Error: <paragraf length> mast be between $PLMIN and $PLMAX\n";
    exit 1;
}

my $PL  = $ARGV[0];
my $PL2 = $PL / 2;
my $PS  = $ARGV[1];

# Check for end of paragraf.
sub eop {
    my $tokens = shift;

    return 1 if $$tokens[-1][0] =~ /[\.\?\!]$/;
    return 0;
}

sub form_line 
{
    my $tokens = shift;
    my $offset = shift;
    my $needed_len = shift;

    my $tokens_added = 0;
    my $line_len = 0;
    my @line;

    for my $el (@{$tokens}[$offset..$#{$tokens}]) {
        my $word = $$el[0];
        my $word_len = $$el[1];
        if ($#line >= 0) {
            $word_len += 1;
            $word = ' ' . $word;
        }

        if ($line_len + $word_len < $needed_len) {
            $line_len += $word_len;
            push @line, $word;

            $tokens_added += 1;
        }
        else {
            last;
        }
    }

    if ($#line > 0) {
        while ($line_len < $needed_len) {
            for my $word (reverse @line[1..$#line]) {
                if ($line_len < $needed_len) {
                    $word = ' ' . $word;
                    $line_len += 1;
                }
                else {
                    last;
                }
            }
        }
    }

    +{ 
        'tokens_added' => $tokens_added, 
        'line' => \@line 
    };
}

sub form_paragraf 
{
    my $data = shift;
    my $tokens = $data->{'tokens'};
    my $tokens_count = $#{$tokens};
    my $tokens_added = 0;

    substr($$tokens[0][0], 0, 0) .= ' ' x $PS;
    $$tokens[0][1] += $PS;

    if ($data->{'total_len'} <= $PL2) {
        my $p = $$tokens[0][0]; 
        $p .= ' ' . $$_[0] for @{$tokens}[1..$tokens_count];
        print "$p\n\n"; # Eats one \n. 
        return;
    }
    
    do {
        my $tuple = form_line($tokens, $tokens_added, $PL);
        $tokens_added += $tuple->{'tokens_added'};
        print @{$tuple->{'line'}}, "\n";
    } while ($tokens_added <= $tokens_count);
    print "\n";
}

open my $input, '<', $ARGV[2] or confess "cannot open $ARGV[2]: $!\n";

my $data = {};

while (<$input>) {
    chomp;
    my @tokens = split /\s+/;

    if ($#tokens >= 0 ) {
        for (@tokens) {
            my $len = length;
            push @{$data->{'tokens'}}, [$_, $len];
            $data->{'total_len'} += $len;
        }
        if (eof || eop($data->{'tokens'})) {
            form_paragraf($data);
            $data = {};
        }
    }
} 
