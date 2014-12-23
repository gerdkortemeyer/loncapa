# The LearningOnline Network with CAPA - LON-CAPA
# QInterval
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
# An interval of quantities
##
package Apache::math::math_parser::QInterval;

use strict;
use warnings;
use utf8;

use aliased 'Apache::math::math_parser::CalcException';
use aliased 'Apache::math::math_parser::Quantity';
use aliased 'Apache::math::math_parser::QInterval';
use aliased 'Apache::math::math_parser::QIntervalUnion';

use overload
    '""' => \&toString,
    '+' => \&union,
    '*' => \&qmult;


##
# Constructor
# @param {Quantity} qmin - quantity min
# @param {Quantity} qmax - quantity max
# @param {boolean} qminopen - qmin open ?
# @param {boolean} qmaxopen - qmax open ?
##
sub new {
    my $class = shift;
    my $self = {
        _qmin => shift,
        _qmax => shift,
        _qminopen => shift,
        _qmaxopen => shift,
    };
    bless $self, $class;
    my %units = %{$self->qmin->units};
    foreach my $unit (keys %units) {
        if ($units{$unit} != $self->qmax->units->{$unit}) {
            die CalcException->new("Interval creation: different units are used for the two endpoints.");
        }
    }
    if ($self->qmin > $self->qmax) {
        die CalcException->new("Interval creation: lower limit greater than upper limit.");
    }
    return $self;
}

# Attribute helpers

##
# Min quantity.
# @returns {Quantity}
##
sub qmin {
    my $self = shift;
    return $self->{_qmin};
}

##
# Max quantity.
# @returns {Quantity}
##
sub qmax {
    my $self = shift;
    return $self->{_qmax};
}

##
# Returns 1 if the interval minimum is open, 0 otherwise.
# @returns {boolean}
##
sub qminopen {
    my $self = shift;
    return $self->{_qminopen};
}

##
# Returns 1 if the interval maximum is open, 0 otherwise.
# @returns {boolean}
##
sub qmaxopen {
    my $self = shift;
    return $self->{_qmaxopen};
}


##
# Returns 1 if the interval is empty
# @returns {boolean}
##
sub is_empty {
    my ( $self ) = @_;
    if ($self->qmin->value == $self->qmax->value && $self->qminopen && $self->qmaxopen) {
        return(1);
    }
    return(0);
}

##
# Returns a readable view of the object
# @returns {string}
##
sub toString {
    my ( $self ) = @_;
    my $s;
    if ($self->qminopen) {
        $s = '(';
    } else {
        $s = '[';
    }
    $s .= $self->qmin->toString();
    $s .= " : ";
    $s .= $self->qmax->toString();
    if ($self->qmaxopen) {
        $s .= ')';
    } else {
        $s .= ']';
    }
    return $s;
}

##
# Equality test
# @param {QInterval} inter
# @optional {string|float} tolerance
# @returns {boolean}
##
sub equals {
    my ( $self, $inter, $tolerance ) = @_;
    if (!$inter->isa(QInterval)) {
        return 0;
    }
    if ($self->is_empty() && $inter->is_empty()) {
        return 1;
    }
    if (!$self->qmin->equals($inter->qmin)) {
        return 0;
    }
    if (!$self->qmax->equals($inter->qmax)) {
        return 0;
    }
    if (!$self->qminopen == $inter->qminopen) {
        return 0;
    }
    if (!$self->qmaxopen == $inter->qmaxopen) {
        return 0;
    }
    return 1;
}

##
# Compare this vector with another one, and returns a code.
# Returns Quantity->WRONG_TYPE if the parameter is not a QInterval.
# @param {QInterval|QSet|Quantity|QVector|QMatrix} inter
# @optional {string|float} tolerance
# @returns {int} Quantity->WRONG_TYPE|WRONG_DIMENSIONS|MISSING_UNITS|ADDED_UNITS|WRONG_UNITS|WRONG_VALUE|WRONG_ENDPOINT|IDENTICAL
##
sub compare {
    my ( $self, $inter, $tolerance ) = @_;
    if (!$inter->isa(QInterval)) {
        return Quantity->WRONG_TYPE;
    }
    my @codes = ();
    push(@codes, $self->qmin->compare($inter->qmin, $tolerance));
    push(@codes, $self->qmax->compare($inter->qmax, $tolerance));
    my @test_order = (Quantity->WRONG_TYPE, Quantity->WRONG_DIMENSIONS, Quantity->MISSING_UNITS, Quantity->ADDED_UNITS,
        Quantity->WRONG_UNITS, Quantity->WRONG_VALUE);
    foreach my $test (@test_order) {
        foreach my $code (@codes) {
            if ($code == $test) {
                return $test;
            }
        }
    }
    if ($self->qminopen != $inter->qminopen) {
        return Quantity->WRONG_ENDPOINT;
    }
    if ($self->qmaxopen != $inter->qmaxopen) {
        return Quantity->WRONG_ENDPOINT;
    }
    return Quantity->IDENTICAL;
}

##
# Clone this object.
# @returns {QInterval}
##
sub clone {
    my ( $self ) = @_;
    return QInterval->new($self->qmin->clone(), $self->qmax->clone(), $self->qminopen, $self->qmaxopen);
}

##
# Tests if this interval contains a quantity.
# @param {Quantity} q
# @returns {boolean}
##
sub contains {
    my ( $self, $q ) = @_;
    if (!$q->isa(Quantity)) {
        die CalcException->new("Interval contains: second member is not a quantity.");
    }
    if (!$self->qminopen && $self->qmin->equals($q)) {
        return 1;
    }
    if (!$self->qmaxopen && $self->qmax->equals($q)) {
        return 1;
    }
    if ($self->qmin < $q && $self->qmax > $q) {
        return 1;
    }
    return 0;
}

##
# Multiplication by a Quantity
# @param {Quantity} q
# @returns {QInterval}
##
sub qmult {
    my ( $self, $q ) = @_;
    if (!$q->isa(Quantity)) {
        die CalcException->new("Interval multiplication: second member is not a quantity.");
    }
    return QInterval->new($self->qmin * $q, $self->qmax * $q, $self->qminopen, $self->qmaxopen);
}

##
# Union
# @param {QInterval|QIntervalUnion} inter
# @returns {QInterval|QIntervalUnion}
##
sub union {
    my ( $self, $inter ) = @_;
    if (!$inter->isa(QInterval) && !$inter->isa(QIntervalUnion)) {
        die CalcException->new("Interval union: second member is not an interval or an interval union.");
    }
    if ($inter->isa(QIntervalUnion)) {
        return($inter->union($self));
    }
    my %units = %{$self->qmin->units};
    foreach my $unit (keys %units) {
        if ($units{$unit} != $inter->qmin->units->{$unit}) {
            die CalcException->new("Interval union: different units are used in the two intervals.");
        }
    }
    if ($self->qmax->value < $inter->qmin->value || $self->qmin->value > $inter->qmax->value) {
        return QIntervalUnion->new([$self, $inter]);
    }
    if ($self->qmax->equals($inter->qmin) && $self->qmaxopen && $inter->qminopen) {
        return QIntervalUnion->new([$self, $inter]);
    }
    if ($self->qmin->equals($inter->qmax) && $self->qmaxopen && $inter->qminopen) {
        return QIntervalUnion->new([$self, $inter]);
    }
    if ($self->qmin->value == $self->qmax->value && $self->qminopen && $self->qmaxopen) {
        # $self is an empty interval
        return QInterval->new($inter->qmin, $inter->qmax, $inter->qminopen, $inter->qmaxopen);
    }
    if ($inter->qmin->value == $inter->qmax->value && $inter->qminopen && $inter->qmaxopen) {
        # $inter is an empty interval
        return QInterval->new($self->qmin, $self->qmax, $self->qminopen, $self->qmaxopen);
    }
    my ($qmin, $qminopen);
    if ($self->qmin->value == $inter->qmin->value) {
        $qmin = $inter->qmin->clone();
        $qminopen = $self->qminopen && $inter->qminopen;
    } elsif ($self->qmin->value < $inter->qmin->value) {
        $qmin = $self->qmin->clone();
        $qminopen = $self->qminopen;
    } else {
        $qmin = $inter->qmin->clone();
        $qminopen = $inter->qminopen;
    }
    my ($qmax, $qmaxopen);
    if ($self->qmax->value == $inter->qmax->value) {
        $qmax = $self->qmax->clone();
        $qmaxopen = $self->qmaxopen && $inter->qmaxopen;
    } elsif ($self->qmax->value > $inter->qmax->value) {
        $qmax = $self->qmax->clone();
        $qmaxopen = $self->qmaxopen;
    } else {
        $qmax = $inter->qmax->clone();
        $qmaxopen = $inter->qmaxopen;
    }
    return QInterval->new($qmin, $qmax, $qminopen, $qmaxopen);
}

##
# Intersection
# @param {QInterval|QIntervalUnion} inter
# @returns {QInterval}
##
sub intersection {
    my ( $self, $inter ) = @_;
    if (!$inter->isa(QInterval) && !$inter->isa(QIntervalUnion)) {
        die CalcException->new("Interval intersection: second member is not an interval or an interval union.");
    }
    if ($inter->isa(QIntervalUnion)) {
        return($inter->intersection($self));
    }
    my %units = %{$self->qmin->units};
    foreach my $unit (keys %units) {
        if ($units{$unit} != $inter->qmin->units->{$unit}) {
            die CalcException->new("Interval intersection: different units are used in the two intervals.");
        }
    }
    if ($self->qmax->value < $inter->qmin->value || $self->qmin->value > $inter->qmax->value) {
        return QInterval->new($self->qmin, $self->qmin, 1, 1); # empty interval
    }
    if ($self->qmax->equals($inter->qmin) && $self->qmaxopen && $inter->qminopen) {
        return QInterval->new($self->qmax, $self->qmax, 1, 1); # empty interval
    }
    if ($self->qmin->equals($inter->qmax) && $self->qmaxopen && $inter->qminopen) {
        return QInterval->new($self->qmin, $self->qmin, 1, 1); # empty interval
    }
    my ($qmin, $qminopen);
    if ($self->qmin->value == $inter->qmin->value) {
        $qmin = $self->qmin->clone();
        $qminopen = $self->qminopen || $inter->qminopen;
    } elsif ($self->qmin->value < $inter->qmin->value) {
        $qmin = $inter->qmin->clone();
        $qminopen = $inter->qminopen;
    } else {
        $qmin = $self->qmin->clone();
        $qminopen = $self->qminopen;
    }
    my ($qmax, $qmaxopen);
    if ($self->qmax->value == $inter->qmax->value) {
        $qmax = $self->qmax->clone();
        $qmaxopen = $self->qmaxopen || $inter->qmaxopen;
    } elsif ($self->qmax->value > $inter->qmax->value) {
        $qmax = $inter->qmax->clone();
        $qmaxopen = $inter->qmaxopen;
    } else {
        $qmax = $self->qmax->clone();
        $qmaxopen = $self->qmaxopen;
    }
    return QInterval->new($qmin, $qmax, $qminopen, $qmaxopen);
}

1;
__END__
