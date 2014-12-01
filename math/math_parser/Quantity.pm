# The LearningOnline Network with CAPA - LON-CAPA
# Quantity
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

##
# A quantity (value and units)
##
package Apache::math::math_parser::Quantity;

use strict;
use warnings;
use utf8;

use POSIX;
use Math::Complex; # must be after POSIX for redefinition of log10

use aliased 'Apache::math::math_parser::CalcException';
use aliased 'Apache::math::math_parser::Quantity';
use aliased 'Apache::math::math_parser::QVector';

use overload
    '""' => \&toString,
    '+' => \&qadd,
    '-' => \&qsub,
    '*' => \&qmult,
    '/' => \&qdiv,
    '^' => \&qpow,
    '<' => \&qlt,
    '<=' => \&qle,
    '>' => \&qgt,
    '>=' => \&qge,
    '<=>' => \&perl_compare;

# compare() return codes:
use enum qw(IDENTICAL WRONG_TYPE WRONG_DIMENSIONS MISSING_UNITS ADDED_UNITS WRONG_UNITS WRONG_VALUE WRONG_ENDPOINT);


##
# Constructor
# @param {complex} value
# @optional {Object.<string, integer>} units - hash: unit name -> exponent for each SI unit
##
sub new {
    my $class = shift;
    my $self = {
        _value => shift,
        _units => shift,
    };
    if ("".$self->{_value} eq "i") {
        $self->{_value} = i;
    } elsif ("".$self->{_value} eq "inf") {
        $self->{_value} = 9**9**9;
    }
    if (!defined $self->{_units}) {
        $self->{_units} = {
            s => 0,
            m => 0,
            kg => 0,
            K => 0,
            A => 0,
            mol => 0,
            cd => 0
        };
    }
    bless $self, $class;
    return $self;
}

# Attribute helpers

sub value {
    my $self = shift;
    return $self->{_value};
}
sub units {
    my $self = shift;
    return $self->{_units};
}

##
# Returns a readable view of the object
# @returns {string}
##
sub toString {
    my ( $self ) = @_;
    my $s;
    # complex display in polar notation can be confused with vectors
    # normally we should just have to call 	Math::Complex::display_format('cartesian');
    # actually, it's supposed to be the default...
    # but this is not working, so...
    if ($self->value =~ /\[/) {
        my $v = $self->value;
        $v->display_format('cartesian');
        $s = "".$v;
    } else {
        $s = $self->value;
    }
    foreach my $unit (keys %{$self->units}) {
        my $e = $self->units->{$unit};
        if ($e != 0) {
            $s .= " ".$unit;
            if ($e != 1) {
                $s .= "^".$e;
            }
        }
    }
    return $s;
}

##
# Equality test
# @param {Quantity}
# @optional {string|float} tolerance
# @returns {boolean}
##
sub equals {
    my ( $self, $q, $tolerance ) = @_;
    if (!$q->isa(Quantity)) {
        return 0;
    }
    if (!defined $tolerance) {
        $tolerance = 0;
    }
    if ($tolerance =~ /%/) {
        my $perc = $tolerance;
        $perc =~ s/%//;
        $perc /= 100;
        if (abs($self->value - $q->value) > abs($self->value * $perc)) {
            return 0;
        }
    } else {
        if (abs($self->value - $q->value) > $tolerance) {
            return 0;
        }
    }
    my %units = %{$self->units};
    foreach my $unit (keys %units) {
        if ($units{$unit} != $q->units->{$unit}) {
            return 0;
        }
    }
    return 1;
}

##
# Compare this quantity with another one, and returns a code.
# @param {Quantity|QVector|QMatrix}
# @optional {string|float} tolerance
# @returns {int}
##
sub compare {
    my ( $self, $q, $tolerance ) = @_;
    if (!$q->isa(Quantity)) {
        return WRONG_TYPE;
    }
    if (!defined $tolerance) {
        $tolerance = 0;
    }
    my %units = %{$self->units};
    my $this_has_units = 0;
    my $other_has_units = 0;
    my $wrong_units = 0;
    foreach my $unit (keys %units) {
        if ($units{$unit} != 0) {
            $this_has_units = 1;
        }
        if ($q->units->{$unit} != 0) {
            $other_has_units = 1;
        }
        if ($units{$unit} != $q->units->{$unit}) {
            $wrong_units = 1;
        }
    }
    if ($this_has_units && !$other_has_units) {
        return MISSING_UNITS;
    } elsif (!$this_has_units && $other_has_units) {
        return ADDED_UNITS;
    }
    if ($wrong_units) {
        return WRONG_UNITS;
    }
    if ($tolerance =~ /%/) {
        my $perc = $tolerance;
        $perc =~ s/%//;
        $perc /= 100;
        if (abs($self->value - $q->value) > abs($self->value * $perc)) {
            return WRONG_VALUE;
        }
    } else {
        if (abs($self->value - $q->value) > $tolerance) {
            return WRONG_VALUE;
        }
    }
    return IDENTICAL;
}

##
# <=> operator.
# Compare this quantity with another one, and returns -1, 0 or 1.
# @param {Quantity}
# @returns {int}
##
sub perl_compare {
    my ( $self, $q ) = @_;
    if (!$q->isa(Quantity)) {
        die CalcException->new("Quantity perl_compare: second member is not a Quantity.");
    }
    $self->unitsMatch($q, 'perl_compare');
    return($self->value <=> $q->value);
}

##
# Not equal
# @param {Quantity}
# @optional {string|float} tolerance
# @returns {boolean}
##
sub ne {
    my ( $self, $q, $tolerance ) = @_;
    if ($self->equals($q, $tolerance)) {
        return(0);
    } else {
        return(1);
    }
}

##
# Less than
# @param {Quantity}
# @returns {boolean}
##
sub lt {
    my ( $self, $q ) = @_;
    if (!$q->isa(Quantity)) {
        die CalcException->new("Quantity lt: second member is not a Quantity.");
    }
    $self->unitsMatch($q, 'lt');
    if ($self->value < $q->value) {
        return(1);
    } else {
        return(0);
    }
}

##
# Less than or equal
# @param {Quantity}
# @returns {boolean}
##
sub le {
    my ( $self, $q ) = @_;
    if (!$q->isa(Quantity)) {
        die CalcException->new("Quantity le: second member is not a Quantity.");
    }
    $self->unitsMatch($q, 'le');
    if ($self->value <= $q->value) {
        return(1);
    } else {
        return(0);
    }
}

##
# Greater than
# @param {Quantity}
# @returns {boolean}
##
sub gt {
    my ( $self, $q ) = @_;
    if (!$q->isa(Quantity)) {
        die CalcException->new("Quantity gt: second member is not a Quantity.");
    }
    $self->unitsMatch($q, 'gt');
    if ($self->value > $q->value) {
        return(1);
    } else {
        return(0);
    }
}

##
# Greater than or equal
# @param {Quantity}
# @returns {boolean}
##
sub ge {
    my ( $self, $q ) = @_;
    if (!$q->isa(Quantity)) {
        die CalcException->new("Quantity ge: second member is not a Quantity.");
    }
    $self->unitsMatch($q, 'ge');
    if ($self->value >= $q->value) {
        return(1);
    } else {
        return(0);
    }
}

##
# Clone this object
##
sub clone {
    my ( $self ) = @_;
    my %units = %{$self->units};
    return Quantity->new($self->value, \%units);
}

##
# Addition
# @param {Quantity}
# @returns {Quantity}
##
sub qadd {
    my ( $self, $q ) = @_;
    if (!$q->isa(Quantity)) {
        die CalcException->new("Quantity addition: second member is not a Quantity.");
    }
    my $v = $self->value + $q->value;
    $self->unitsMatch($q, 'addition');
    return Quantity->new($v, $self->units);
}

##
# Substraction
# @param {Quantity}
# @returns {Quantity}
##
sub qsub {
    my ( $self, $q ) = @_;
    if (!$q->isa(Quantity)) {
        die CalcException->new("Quantity substraction: second member is not a Quantity.");
    }
    my $v = $self->value - $q->value;
    $self->unitsMatch($q, 'substraction');
    return Quantity->new($v, $self->units);
}

##
# Negation
# @returns {Quantity}
##
sub qneg {
    my ( $self ) = @_;
    my $v = - $self->value;
    my %units = %{$self->units};
    return Quantity->new($v, \%units);
}

##
# Multiplication
# @param {Quantity|QVector}
# @returns {Quantity|QVector}
##
sub qmult {
    my ( $self, $qv ) = @_;
    if ($qv->isa(Quantity)) {
        my $q = $qv;
        my $v = $self->value * $q->value;
        my %units = %{$self->units};
        foreach my $unit (keys %units) {
            $units{$unit} = $units{$unit} + $q->units->{$unit};
        }
        return Quantity->new($v, \%units);
    } else { # QVector
        my $v = $qv;
        my @t = (); # array of Quantity
        for (my $i=0; $i < scalar(@{$v->quantities}); $i++) {
            $t[$i] = $v->quantities->[$i]->qmult($self);
        }
        return QVector->new(\@t);
    }
}

##
# Division
# @param {Quantity}
# @returns {Quantity}
##
sub qdiv {
    my ( $self, $q ) = @_;
    if ($q->value == 0) {
        die CalcException->new("Division by 0");
    }
    my $v = $self->value / $q->value;
    my %units = %{$self->units};
    foreach my $unit (keys %units) {
        $units{$unit} = $units{$unit} - $q->units->{$unit};
    }
    return Quantity->new($v, \%units);
}

##
# Power
# @returns {Quantity}
##
sub qpow {
    my ( $self, $q ) = @_;
    my $v = $self->value ** $q->value;
    $q->noUnits("Power");
    my %units = %{$self->units};
    foreach my $unit (keys %{$q->units}) {
        $units{$unit} = $units{$unit} * $q->value;
    }
    return Quantity->new($v, \%units);
}

##
# Factorial
# @returns {Quantity}
##
sub qfact {
    my ( $self ) = @_;
    my $v = $self->value;
    if ($v < 0) {
        die CalcException->new("Factorial of number < 0");
    }
    # should check if integer
    my $n = $v;
    for (my $i=$n - 1; $i > 1; $i--) {
        $v *= $i;
    }
    return Quantity->new($v, $self->units);
}

##
# Square root
# @returns {Quantity}
##
sub qsqrt {
    my ( $self ) = @_;
    my $v = sqrt($self->value);
    my %units = %{$self->units};
    foreach my $unit (keys %units) {
        $units{$unit} = $units{$unit} / 2;
    }
    return Quantity->new($v, \%units);
}

##
# Absolute value
# @returns {Quantity}
##
sub qabs {
    my ( $self ) = @_;
    my $v = abs($self->value);
    my %units = %{$self->units};
    return Quantity->new($v, \%units);
}

##
# Exponential
# @returns {Quantity}
##
sub qexp {
    my ( $self ) = @_;
    $self->noUnits("exp");
    return Quantity->new(exp($self->value), $self->units);
}

##
# Natural logarithm
# @returns {Quantity}
##
sub qln {
    my ( $self ) = @_;
    $self->noUnits("ln");
    # this will return a complex if the value is < 0
    #if ($self->value < 0) {
    #    die CalcException->new("Ln of number < 0");
    #}
    if ($self->value == 0) {
        die CalcException->new("log(0)");
    }
    return Quantity->new(log($self->value), $self->units);
}

##
# Decimal logarithm
# @returns {Quantity}
##
sub qlog10 {
    my ( $self ) = @_;
    $self->noUnits("log10");
    # this will return a complex if the value is < 0
    #if ($self->value < 0) {
    #    die CalcException->new("Log10 of number < 0");
    #}
    if ($self->value == 0) {
        die CalcException->new("log10(0)");
    }
    return Quantity->new(log10($self->value), $self->units);
}

##
# Modulo
# @param {Quantity}
# @returns {Quantity}
##
sub qmod {
    my ( $self, $q ) = @_;
    my $v = $self->value % $q->value;
    return Quantity->new($v, $self->units);
}

##
# Returns -1, 0 or 1 depending on the sign of the value
# @returns {Quantity}
##
sub qsgn {
    my ( $self ) = @_;
    my $v;
    if ($self->value < 0) {
        $v = -1;
    } elsif ($self->value > 0) {
        $v = 1;
    } else {
        $v = 0;
    }
    return Quantity->new($v, $self->units);
}

##
# Returns the least integer that is greater than or equal to the value.
# @returns {Quantity}
##
sub qceil {
    my ( $self ) = @_;
    my $v = ceil($self->value);
    return Quantity->new($v, $self->units);
}

##
# Returns the largest integer that is less than or equal to the value.
# @returns {Quantity}
##
sub qfloor {
    my ( $self ) = @_;
    my $v = floor($self->value);
    return Quantity->new($v, $self->units);
}

##
# Sinus
# @returns {Quantity}
##
sub qsin {
    my ( $self ) = @_;
    $self->noUnits("sin");
    return Quantity->new(sin($self->value), $self->units);
}

##
# Cosinus
# @returns {Quantity}
##
sub qcos {
    my ( $self ) = @_;
    $self->noUnits("cos");
    return Quantity->new(cos($self->value), $self->units);
}

##
# Tangent
# @returns {Quantity}
##
sub qtan {
    my ( $self ) = @_;
    $self->noUnits("tan");
    return Quantity->new(tan($self->value), $self->units);
}

##
# Arcsinus
# @returns {Quantity}
##
sub qasin {
    my ( $self ) = @_;
    $self->noUnits("asin");
    return Quantity->new(asin($self->value), $self->units);
}

##
# Arccosinus
# @returns {Quantity}
##
sub qacos {
    my ( $self ) = @_;
    $self->noUnits("acos");
    return Quantity->new(acos($self->value), $self->units);
}

##
# Arctangent
# @returns {Quantity}
##
sub qatan {
    my ( $self ) = @_;
    $self->noUnits("atan");
    return Quantity->new(atan($self->value), $self->units);
}

##
# Arctangent of self/x in the range -pi to pi
# @param {Quantity} x
# @returns {Quantity}
##
sub qatan2 {
    my ( $self, $q ) = @_;
    $self->noUnits("atan2");
    my $v = atan2($self->value, $q->value);
    return Quantity->new($v, $self->units);
}

##
# Hyperbolic sinus
# @returns {Quantity}
##
sub qsinh {
    my ( $self ) = @_;
    $self->noUnits("sinh");
    return Quantity->new(sinh($self->value), $self->units);
}

##
# Hyperbolic cosinus
# @returns {Quantity}
##
sub qcosh {
    my ( $self ) = @_;
    $self->noUnits("cosh");
    return Quantity->new(cosh($self->value), $self->units);
}

##
# Hyperbolic tangent
# @returns {Quantity}
##
sub qtanh {
    my ( $self ) = @_;
    $self->noUnits("tanh");
    return Quantity->new(tanh($self->value), $self->units);
}

##
# Hyperbolic arcsinus
# @returns {Quantity}
##
sub qasinh {
    my ( $self ) = @_;
    $self->noUnits("asinh");
    return Quantity->new(asinh($self->value), $self->units);
}

##
# Hyperbolic arccosinus
# @returns {Quantity}
##
sub qacosh {
    my ( $self ) = @_;
    $self->noUnits("acosh");
    return Quantity->new(acosh($self->value), $self->units);
}

##
# Hyperbolic arctangent
# @returns {Quantity}
##
sub qatanh {
    my ( $self ) = @_;
    $self->noUnits("atanh");
    return Quantity->new(atanh($self->value), $self->units);
}

##
# Less than
# @param {Quantity}
# @returns {Quantity}
##
sub qlt {
    my ( $self, $q ) = @_;
    my $v = $self->lt($q);
    return Quantity->new($v);
}

##
# Less than or equal
# @param {Quantity}
# @returns {Quantity}
##
sub qle {
    my ( $self, $q ) = @_;
    my $v = $self->le($q);
    return Quantity->new($v);
}

##
# Greater than
# @param {Quantity}
# @returns {Quantity}
##
sub qgt {
    my ( $self, $q ) = @_;
    my $v = $self->gt($q);
    return Quantity->new($v);
}

##
# Greater than or equal
# @param {Quantity}
# @returns {Quantity}
##
sub qge {
    my ( $self, $q ) = @_;
    my $v = $self->ge($q);
    return Quantity->new($v);
}

##
# Dies if units do not match.
##
sub unitsMatch {
    my ( $self, $q, $fct_name ) = @_;
    my %units = %{$self->units};
    foreach my $unit (keys %units) {
        if ($units{$unit} != $q->units->{$unit}) {
            die CalcException->new("[_1]: units do not match", $fct_name);
        }
    }
}

##
# Dies if there are any unit.
##
sub noUnits {
    my ( $self, $fct_name ) = @_;
    my %units = %{$self->units};
    foreach my $unit (keys %units) {
        if ($units{$unit} != 0) {
            die CalcException->new("[_1] of something with units ???", $fct_name);
        }
    }
}

1;
__END__
