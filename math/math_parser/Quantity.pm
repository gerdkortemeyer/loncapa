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

use Math::Complex;

use aliased 'Apache::math::math_parser::Quantity';
use aliased 'Apache::math::math_parser::QVector';

use overload
    '""' => \&toString,
    '+' => \&add,
    '-' => \&sub,
    '*' => \&mult,
    '/' => \&div,
    '^' => \&pow;


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
# Addition
# @param {Quantity}
# @returns {Quantity}
##
sub add {
    my ( $self, $q ) = @_;
    my $v = $self->value + $q->value;
    my %units = %{$self->units};
    foreach my $unit (keys %units) {
        if ($units{$unit} != $q->units->{$unit}) {
            die "addition: units don't match";
        }
    }
    return Quantity->new($v, $self->units);
}

##
# Substraction
# @param {Quantity}
# @returns {Quantity}
##
sub sub {
    my ( $self, $q ) = @_;
    my $v = $self->value - $q->value;
    my %units = %{$self->units};
    foreach my $unit (keys %units) {
        if ($units{$unit} != $q->units->{$unit}) {
            die "substraction: units don't match";
        }
    }
    return Quantity->new($v, $self->units);
}

##
# Negation
# @returns {Quantity}
##
sub neg {
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
sub mult {
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
            $t[$i] = $v->quantities->[$i]->mult($self);
        }
        return QVector->new(\@t);
    }
}

##
# Division
# @returns {Quantity}
##
sub div {
    my ( $self, $q ) = @_;
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
sub pow {
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
    # should check if integer
    my $v = $self->value;
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
    return Quantity->new(log($self->value), $self->units);
}

##
# Decimal logarithm
# @returns {Quantity}
##
sub qlog10 {
    my ( $self ) = @_;
    $self->noUnits("log10");
    return Quantity->new(log10($self->value), $self->units);
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
# Dies if there are any unit.
##
sub noUnits {
    my ( $self, $fct_name ) = @_;
    my %units = %{$self->units};
    foreach my $unit (keys %units) {
        if ($units{$unit} != 0) {
            die "$fct_name of something with units ???";
        }
    }
}

1;
__END__
