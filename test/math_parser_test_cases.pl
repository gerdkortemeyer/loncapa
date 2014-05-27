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

# note: we could use Try::Tiny to catch errors if we wanted

use aliased 'Apache::math::math_parser::Parser';
use aliased 'Apache::math::math_parser::ENode';

# please add your own !!!
my %cases = (
    "1e-1/2+e-1/2" => "e-0.45",
    "1/2s" => "0.5`(s^-1)",
    "(1/2)s" => "0.5`s",
    "1m/2s" => "0.5`(m*s^-1)",
    "(1+2)(m/s)" => "3`(m*s^-1)",
    "2 m^2 s" => "2`(m^2*s)",
    "2(m/s)kg" => "2`(m*s^-1*kg)",
    "sqrt(2) m" => "sqrt(2)`m",
    "2sqrt(4)" => "4",
    "ln(2)+ln(3)" => "ln(6)",
    "abs(-1)" => "1",
    "log10(10)" => "1",
    "factorial(4)" => "4!",
    "asin(sin(pi/4))" => "pi/4",
    "acos(cos(pi/4))" => "pi/4",
    "atan(tan(pi/4))" => "pi/4",
    "2m/s*3m/s" => "6`(m^2*s^-2)",
    "2m/s*c" => "(2*299792458)`(m^2*s^-2)",
    "1 J" => "1`(kg*m^2*s^-2)",
    "sqrt(34J/(2*45kg))" => "0.614636297`(m*s^-1)",
    "sqrt((2*45 eV)/(345 mg))" => "2.04440481E-7`(m*s^-1)",
    "2 pi hbar c" => "2 pi (1.956E9 J) * (1.616199E-35 m)",
    "sqrt(-1)" => "i",
    "i^2" => "-1",
    "exp(i*pi)+1" => "0",
    "2%c" => "2*c/100",
    "[1m;2m]+[3m;4m]" => "[4m;6m]",
    "[1;2].[3;4]" => "[3;8]",
    "13 + 1 + 20 + 8" => "42", # MATH
    "1/(1/2-1/3-1/7)" => "42",
);

sub test {
    my( $parser, $expression, $expected, $tolerance ) = @_;
    if (!defined $tolerance) {
        $tolerance = 1e-5;
    }
    my $quantity = $parser->parse($expression)->calc();
    my $expected_quantity = $parser->parse($expected)->calc();
    if (!$quantity->equals($expected_quantity, $tolerance)) {
        die "Incorrect result for $expression: ".$quantity." instead of ".$expected_quantity;
    }
}

my $accept_bad_syntax = 1;
my $unit_mode = 1;
my $p = Parser->new($accept_bad_syntax, $unit_mode);
foreach my $s (keys %cases) {
    test($p, $s, $cases{$s});
}

# now let's try to use custom units !
ENode->units->{_derived}->{"peck"} = "2 gallon";
ENode->units->{_derived}->{"bushel"} = "8 gallon";
ENode->units->{_derived}->{"gallon"} = "4.4 L";
test($p, "4 peck + 2 bushel", "106`L", "1%");

print "All tests OK !\n";
