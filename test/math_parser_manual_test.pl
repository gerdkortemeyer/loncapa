#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Try::Tiny;

use lib '/home/httpd/lib/perl';
use Apache::lc_connection_utils(); # to avoid a circular reference problem
use Apache::lc_ui_localize;

use aliased 'Apache::math::math_parser::CalcException';
use aliased 'Apache::math::math_parser::ParseException';
use aliased 'Apache::math::math_parser::Parser';
use aliased 'Apache::math::math_parser::ENode';
use aliased 'Apache::math::math_parser::CalcEnv';


Apache::lc_ui_localize::set_language('en');
my $accept_bad_syntax = 1;
my $unit_mode = 1;
print "Expression: ";
$_ = <STDIN>;
chomp;
my $eqtxt = $_;
try {
    my $p = Parser->new($accept_bad_syntax, $unit_mode);
    my $root = $p->parse($eqtxt);
    print "Parsing: ".$root->toString()."\n\n";
    my $env = CalcEnv->new($unit_mode);
    print "Maxima syntax: ".$root->toMaxima()."\n";
    print "Value: ".$root->calc($env)->toString()."\n";
} catch {
    if (UNIVERSAL::isa($_,CalcException) || UNIVERSAL::isa($_,ParseException)) {
        die $_->getLocalizedMessage()."\n";
    } else {
        die "Internal error: $_\n";
    }
}
