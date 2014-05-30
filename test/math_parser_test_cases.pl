#!/usr/bin/perl

# The LearningOnline Network with CAPA - LON-CAPA
# check test cases
#
# Copyright (C) 2014 Michigan State University Board of Trustees
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;

use Try::Tiny;

use lib '/home/httpd/lib/perl';
use Apache::lc_connection_utils(); # to avoid a circular reference problem

use aliased 'Apache::math::math_parser::Parser';
use aliased 'Apache::math::math_parser::ENode';
use aliased 'Apache::math::math_parser::CalcEnv';

# please add your own !!!
my %unit_mode_cases = (
    "1e-1/2+e-1/2" => "e-0.45",
    "1/2s" => "0.5`(s^-1)",
    "(1/2)s" => "0.5`s",
    "1m/2s" => "0.5`(m*s^-1)",
    "(1+2)(m/s)" => "3`(m*s^-1)",
    "2 m^2 s" => "2`(m^2*s)",
    "2(m/s)kg" => "2`(m*s^-1*kg)",
    "sqrt(2) m" => "sqrt(2)`m",
    "2m/s*3m/s" => "6`(m^2*s^-2)",
    "2m/s*c" => "(2*299792458)`(m^2*s^-2)",
    "1 J" => "1`(kg*m^2*s^-2)",
    "sqrt(34J/(2*45kg))" => "0.614636297`(m*s^-1)",
    "sqrt((2*45 eV)/(345 mg))" => "2.04440481E-7`(m*s^-1)",
    "2 pi hbar c" => "2 pi (1.956E9 J) * (1.616199E-35 m)",
    "2%c" => "2*c/100",
    "[1m;2m]+[3m;4m]" => "[4m;6m]",
);

my %symbolic_mode_cases = (
    "1e-1/2+e-1/2" => "e-0.45",
    "x+y" => "42.23",
    "1/2x" => "x/2",
    "2sqrt(4)" => "4",
    "ln(x)+ln(y)" => "ln(x*y)",
    "abs(-1)" => "1",
    "log10(10)" => "1",
    "factorial(4)" => "4!",
    "asin(sin(pi/4))" => "pi/4",
    "acos(cos(pi/4))" => "pi/4",
    "atan(tan(pi/4))" => "pi/4",
    "sqrt(-1)" => "i",
    "i^2" => "-1",
    "exp(i*pi)+1" => "0",
    "13 + 1 + 20 + 8" => "x",
    "1/(1/2-1/3-1/7)" => "x",
    "[1;2].[3;4]" => "[3;8]",
    "matrix([1;2];[3;4]) + matrix([5;6];[7;8])" => "matrix([6;8];[10;12])",
    "[[5;6];[7;8]] - [[1;2];[3;4]]" => "[[4;4];[4;4]]",
    "-[[1;2];[3;4]]" => "[[-1;-2];[-3;-4]]",
    "[[1;2;3];[4;5;6]] . [7;8;9]" => "[50;122]",
    "[[1;2;3];[4;5;6]] * [7;8]" => "[[7;14;21];[32;40;48]]",
    "[[1;2;3];[4;5;6]] . [[7;8];[9;10];[11;12]]" => "[[58;64];[139;154]]",
    "[[1;2];[3;4]]^2" => "[[1;4];[9;16]]",
);

sub test {
    my( $parser, $env, $expression, $expected, $tolerance ) = @_;
    if (!defined $tolerance) {
        $tolerance = 1e-5;
    }
    try {
        my $quantity = $parser->parse($expression)->calc($env);
        my $expected_quantity = $parser->parse($expected)->calc($env);
        if (!$quantity->equals($expected_quantity, $tolerance)) {
            die "Wrong result: ".$quantity." instead of ".$expected_quantity;
        }
    } catch {
        die "Error for $expression: $_\n";
    }
}

# unit mode
my $accept_bad_syntax = 1;
my $unit_mode = 1;
my $p = Parser->new($accept_bad_syntax, $unit_mode);
my $env = CalcEnv->new($unit_mode);
foreach my $s (keys %unit_mode_cases) {
    test($p, $env, $s, $unit_mode_cases{$s});
}

# now let's try to use custom units !
$env->setUnit("peck", "2 gallon");
$env->setUnit("bushel", "8 gallon");
$env->setUnit("gallon", "4.4 L");
test($p, $env, "4 peck + 2 bushel", "106`L", "1%");

# symbolic mode
$unit_mode = 0;
$p = Parser->new($accept_bad_syntax, $unit_mode);
$env = CalcEnv->new($unit_mode);
$env->setVariable("x", "42");
$env->setVariable("y", "2.3e-1");
foreach my $s (keys %symbolic_mode_cases) {
    test($p, $env, $s, $symbolic_mode_cases{$s});
}

print "All tests OK !\n";
