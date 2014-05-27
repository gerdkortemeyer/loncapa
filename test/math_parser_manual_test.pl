#!/usr/bin/perl

use strict;
use warnings;

# note: we could use Try::Tiny to catch errors if we wanted

use Apache::math::math_parser::Parser;
use Apache::math::math_parser::ENode;


my $accept_bad_syntax = 1;
my $unit_mode = 1;
print "Expression: ";
$_ = <STDIN>;
chomp;
my $eqtxt = $_;
my $p = new Parser($accept_bad_syntax, $unit_mode);
my $root = $p->parse($eqtxt);
print "Parsing: ".$root->toString()."\n\n";
print "Value: ".$root->calc()->toString()."\n";
