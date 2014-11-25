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
$| = 1;
my $implicit_operators = 1;
my $unit_mode = 1;
print "Expression: ";
$_ = <STDIN>;
chomp;
my $eqtxt = $_;
my ($p, $root, $env);
try {
    $p = Parser->new($implicit_operators, $unit_mode);
    $root = $p->parse($eqtxt);
    print "\nParsing: ";
    print $root->toString()."\n";
    $env = CalcEnv->new($unit_mode);
} catch {
    if (UNIVERSAL::isa($_,CalcException)) {
        die "Calculation error: ".$_->getLocalizedMessage()."\n";
    } elsif (UNIVERSAL::isa($_,ParseException)) {
        die "Parsing error: ".$_->getLocalizedMessage()."\n";
    } else {
        die "Internal error: $_\n";
    }
};

try {
    print "\nTeX syntax: ";
    print $root->toTeX()."\n";
} catch {
    if (UNIVERSAL::isa($_,CalcException)) {
        print STDERR "Calculation error: ".$_->getLocalizedMessage()."\n";
    } elsif (UNIVERSAL::isa($_,ParseException)) {
        print STDERR "Parsing error: ".$_->getLocalizedMessage()."\n";
    } else {
        print STDERR "Internal error: $_\n";
    }
};

try {
    print "\nMaxima syntax: ";
    print $root->toMaxima()."\n";
} catch {
    if (UNIVERSAL::isa($_,CalcException)) {
        print STDERR "Calculation error: ".$_->getLocalizedMessage()."\n";
    } elsif (UNIVERSAL::isa($_,ParseException)) {
        print STDERR "Parsing error: ".$_->getLocalizedMessage()."\n";
    } else {
        print STDERR "Internal error: $_\n";
    }
};

try {
    print "\nValue: ";
    print $root->calc($env)->toString()."\n";
} catch {
    if (UNIVERSAL::isa($_,CalcException)) {
        print STDERR "Calculation error: ".$_->getLocalizedMessage()."\n";
    } elsif (UNIVERSAL::isa($_,ParseException)) {
        print STDERR "Parsing error: ".$_->getLocalizedMessage()."\n";
    } else {
        print STDERR "Internal error: $_\n";
    }
};
