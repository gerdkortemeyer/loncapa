#!/usr/bin/perl

use strict;
use warnings;

# note: we could use Try::Tiny to catch errors if we wanted

use lib '/home/httpd/lib/perl';
use Apache::lc_connection_utils(); # to avoid a circular reference problem

use aliased 'Apache::math::math_parser::Parser';
use aliased 'Apache::math::math_parser::ENode';
use aliased 'Apache::math::math_parser::CalcEnv';


my $accept_bad_syntax = 1;
my $unit_mode = 1;
print "Expression: ";
$_ = <STDIN>;
chomp;
my $eqtxt = $_;
my $p = Parser->new($accept_bad_syntax, $unit_mode);
my $root = $p->parse($eqtxt);
print "Parsing: ".$root->toString()."\n\n";
my $env = CalcEnv->new($unit_mode);
print "Value: ".$root->calc($env)->toString()."\n";
