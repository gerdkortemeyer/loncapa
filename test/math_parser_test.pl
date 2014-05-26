#!/usr/bin/perl

use strict;
use warnings;

use File::Util;
use Try::Tiny;

use lc_json_utils;
use Parser;
use ENode;
use ParseException;


my $accept_bad_syntax = 1;
my $unit_mode = 1;
print "Expression: ";
$_ = <STDIN>;
chomp;
my $eqtxt = $_;
my $p = new Parser($accept_bad_syntax, $unit_mode);
try {
    my $root = $p->parse($eqtxt);
    print "Parsing: ".$root->toString()."\n";
    print "Value:".$root->calc()->toString()."\n";
} catch {
    my $ex = shift;
    if (ref $ex eq 'ParseException') {
        print "Parsing error: ".$ex->toString();
    } else {
        print "Error: ".$ex;
    }
}
