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
package Quantity;

use strict;
use warnings;

use Math::Complex;

use QVector;

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
    my $s = $self->value;
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
            die "add: units don't match";
        }
    }
    return new Quantity($v, $self->units);
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
            die "sub: units don't match";
        }
    }
    return new Quantity($v, $self->units);
}

##
# Negation
# @returns {Quantity}
##
sub neg {
    my ( $self ) = @_;
    my $v = - $self->value;
    my %units = %{$self->units};
    return new Quantity($v, \%units);
}

##
# Multiplication
# @param {Quantity|QVector}
# @returns {Quantity|QVector}
##
sub mult {
    my ( $self, $qv ) = @_;
    if ($qv->isa("Quantity")) {
        my $q = $qv;
        my $v = $self->value * $q->value;
        my %units = %{$self->units};
        foreach my $unit (keys %units) {
            $units{$unit} = $units{$unit} + $q->units->{$unit};
        }
        return new Quantity($v, \%units);
    } else { # QVector
        my $v = $qv;
        my @t = (); # array of Quantity
        for (my $i=0; $i < scalar(@{$v->quantities}); $i++) {
            $t[$i] = $v->quantities->[$i]->mult($self);
        }
        return new QVector(\@t);
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
    return new Quantity($v, \%units);
}

##
# Power
# @returns {Quantity}
##
sub pow {
    my ( $self, $q ) = @_;
    my $v = $self->value ** $q->value;
    my %units = %{$self->units};
    foreach my $unit (keys %{$q->units}) {
        if ($q->units->{$unit} != 0) {
            die "Power of something with units ???";
        }
        $units{$unit} = $units{$unit} * $q->value;
    }
    return new Quantity($v, \%units);
}

##
# Factorial
# @returns {Quantity}
##
sub fact {
    my ( $self ) = @_;
    # should check if integer
    my $v = $self->value;
    my $n = $v;
    for (my $i=$n - 1; $i > 1; $i--) {
        $v *= $i;
    }
    return new Quantity($v, $self->units);
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
    return new Quantity($v, \%units);
}

##
# Absolute value
# @returns {Quantity}
##
sub abs {
    my ( $self ) = @_;
    my $v = abs($self->value);
    my %units = %{$self->units};
    return new Quantity($v, \%units);
}

##
# Exponential
# @returns {Quantity}
##
sub exp {
    my ( $self ) = @_;
    my $v = exp($self->value);
    my %units = %{$self->units}; # TODO: check ?
    return new Quantity($v, \%units);
}

##
# Natural logarithm
# @returns {Quantity}
##
sub qln {
    my ( $self ) = @_;
    my $v = log($self->value);
    my %units = %{$self->units}; # TODO: check ?
    return new Quantity($v, \%units);
}

1;
__END__
