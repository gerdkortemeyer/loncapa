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
    '+' => \&union;


##
# Constructor
# @param {Quantity} quantity min
# @param {Quantity} quantity max
# @param {boolean} qmin open ?
# @param {boolean} qmax open ?
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
        die CalcException->new("Interval creation: qmin > qmax");
    }
    return $self;
}

# Attribute helpers

sub qmin {
    my $self = shift;
    return $self->{_qmin};
}
sub qmax {
    my $self = shift;
    return $self->{_qmax};
}
sub qminopen {
    my $self = shift;
    return $self->{_qminopen};
}
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
# @param {QInterval}
# @optional {string|float} tolerance
# @returns {boolean}
##
sub equals {
    my ( $self, $int, $tolerance ) = @_;
    if (!$int->isa(QInterval)) {
        return 0;
    }
    if ($self->is_empty() && $int->is_empty()) {
        return 1;
    }
    if (!$self->qmin->equals($int->qmin)) {
        return 0;
    }
    if (!$self->qmax->equals($int->qmax)) {
        return 0;
    }
    if (!$self->qminopen == $int->qminopen) {
        return 0;
    }
    if (!$self->qmaxopen == $int->qmaxopen) {
        return 0;
    }
    return 1;
}

##
# Compare this vector with another one, and returns a code.
# @param {QInterval|QSset|Quantity|QVector|QMatrix}
# @optional {string|float} tolerance
# @returns {int}
##
sub compare {
    my ( $self, $int, $tolerance ) = @_;
    if (!$int->isa(QInterval)) {
        return Quantity->WRONG_TYPE;
    }
    my @codes = ();
    push(@codes, $self->qmin->compare($int->qmin, $tolerance));
    push(@codes, $self->qmax->compare($int->qmax, $tolerance));
    my @test_order = (Quantity->WRONG_TYPE, Quantity->WRONG_DIMENSIONS, Quantity->MISSING_UNITS, Quantity->ADDED_UNITS,
        Quantity->WRONG_UNITS, Quantity->WRONG_VALUE);
    foreach my $test (@test_order) {
        foreach my $code (@codes) {
            if ($code == $test) {
                return $test;
            }
        }
    }
    if ($self->qminopen != $int->qminopen) {
        return Quantity->WRONG_ENDPOINT;
    }
    if ($self->qmaxopen != $int->qmaxopen) {
        return Quantity->WRONG_ENDPOINT;
    }
    return Quantity->IDENTICAL;
}

##
# Clone this object
##
sub clone {
    my ( $self ) = @_;
    return QInterval->new($self->qmin->clone(), $self->qmax->clone(), $self->qminopen, $self->qmaxopen);
}

##
# Tests if this interval contains a quantity.
# @param {Quantity}
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
# Union
# @param {QInterval|QIntervalUnion}
# @returns {QInterval|QIntervalUnion}
##
sub union {
    my ( $self, $int ) = @_;
    if (!$int->isa(QInterval) && !$int->isa(QIntervalUnion)) {
        die CalcException->new("Interval union: second member is not an interval or an interval union.");
    }
    if ($int->isa(QIntervalUnion)) {
        return($int->union($self));
    }
    my %units = %{$self->qmin->units};
    foreach my $unit (keys %units) {
        if ($units{$unit} != $int->qmin->units->{$unit}) {
            die CalcException->new("Interval union: different units are used in the two intervals.");
        }
    }
    if ($self->qmax->value < $int->qmin->value || $self->qmin->value > $int->qmax->value) {
        return QIntervalUnion->new([$self, $int]);
    }
    if ($self->qmax->equals($int->qmin) && $self->qmaxopen && $int->qminopen) {
        return QIntervalUnion->new([$self, $int]);
    }
    if ($self->qmin->equals($int->qmax) && $self->qmaxopen && $int->qminopen) {
        return QIntervalUnion->new([$self, $int]);
    }
    if ($self->qmin->value == $self->qmax->value && $self->qminopen && $self->qmaxopen) {
        # $self is an empty interval
        return QInterval->new($int->qmin, $int->qmax, $int->qminopen, $int->qmaxopen);
    }
    if ($int->qmin->value == $int->qmax->value && $int->qminopen && $int->qmaxopen) {
        # $int is an empty interval
        return QInterval->new($self->qmin, $self->qmax, $self->qminopen, $self->qmaxopen);
    }
    my ($qmin, $qminopen);
    if ($self->qmin->value == $int->qmin->value) {
        $qmin = $int->qmin->clone();
        $qminopen = $self->qminopen && $int->qminopen;
    } elsif ($self->qmin->value < $int->qmin->value) {
        $qmin = $self->qmin->clone();
        $qminopen = $self->qminopen;
    } else {
        $qmin = $int->qmin->clone();
        $qminopen = $int->qminopen;
    }
    my ($qmax, $qmaxopen);
    if ($self->qmax->value == $int->qmax->value) {
        $qmax = $self->qmax->clone();
        $qmaxopen = $self->qmaxopen && $int->qmaxopen;
    } elsif ($self->qmax->value > $int->qmax->value) {
        $qmax = $self->qmax->clone();
        $qmaxopen = $self->qmaxopen;
    } else {
        $qmax = $int->qmax->clone();
        $qmaxopen = $int->qmaxopen;
    }
    return QInterval->new($qmin, $qmax, $qminopen, $qmaxopen);
}

##
# Intersection
# @param {QInterval|QIntervalUnion}
# @returns {QInterval}
##
sub intersection {
    my ( $self, $int ) = @_;
    if (!$int->isa(QInterval) && !$int->isa(QIntervalUnion)) {
        die CalcException->new("Interval intersection: second member is not an interval or an interval union.");
    }
    if ($int->isa(QIntervalUnion)) {
        return($int->intersection($self));
    }
    my %units = %{$self->qmin->units};
    foreach my $unit (keys %units) {
        if ($units{$unit} != $int->qmin->units->{$unit}) {
            die CalcException->new("Interval intersection: different units are used in the two intervals.");
        }
    }
    if ($self->qmax->value < $int->qmin->value || $self->qmin->value > $int->qmax->value) {
        return QInterval->new($self->qmin, $self->qmin, 1, 1); # empty interval
    }
    if ($self->qmax->equals($int->qmin) && $self->qmaxopen && $int->qminopen) {
        return QInterval->new($self->qmax, $self->qmax, 1, 1); # empty interval
    }
    if ($self->qmin->equals($int->qmax) && $self->qmaxopen && $int->qminopen) {
        return QInterval->new($self->qmin, $self->qmin, 1, 1); # empty interval
    }
    my ($qmin, $qminopen);
    if ($self->qmin->value == $int->qmin->value) {
        $qmin = $self->qmin->clone();
        $qminopen = $self->qminopen || $int->qminopen;
    } elsif ($self->qmin->value < $int->qmin->value) {
        $qmin = $int->qmin->clone();
        $qminopen = $int->qminopen;
    } else {
        $qmin = $self->qmin->clone();
        $qminopen = $self->qminopen;
    }
    my ($qmax, $qmaxopen);
    if ($self->qmax->value == $int->qmax->value) {
        $qmax = $self->qmax->clone();
        $qmaxopen = $self->qmaxopen || $int->qmaxopen;
    } elsif ($self->qmax->value > $int->qmax->value) {
        $qmax = $int->qmax->clone();
        $qmaxopen = $int->qmaxopen;
    } else {
        $qmax = $self->qmax->clone();
        $qmaxopen = $self->qmaxopen;
    }
    return QInterval->new($qmin, $qmax, $qminopen, $qmaxopen);
}

1;
__END__
