# The LearningOnline Network with CAPA - LON-CAPA
# QIntervalUnion
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
# A union of possibly disjoint intervals
##
package Apache::math::math_parser::QIntervalUnion;

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
# @param {QInterval[]} intervals
##
sub new {
    my $class = shift;
    # we use an array to preserve order (of course purely for cosmetic reasons)
    my $self = {
        _intervals => shift,
    };
    bless $self, $class;
    
    # sanity checks
    foreach my $inter (@{$self->intervals}) {
        if (!$inter->isa(QInterval)) {
            die CalcException->new("QIntervalUnion constructor: a member is not an interval.");
        }
    }
    if (scalar(@{$self->intervals}) > 0) {
        my %units = %{$self->intervals->[0]->qmin->units};
        for (my $i=1; $i < scalar(@{$self->intervals}); $i++) {
            my $inter = $self->intervals->[$i];
            foreach my $unit (keys %units) {
                if ($units{$unit} != $inter->qmin->units->{$unit}) {
                    die CalcException->new("QIntervalUnion constructor: different units are used in the intervals.");
                }
            }
        }
    }
    
    # clone the intervals so that they can be modified independantly
    for (my $i=0; $i < scalar(@{$self->intervals}); $i++) {
        $self->intervals->[$i] = $self->intervals->[$i]->clone();
    }
    
    # reduction to make comparisons easier
    $self->reduce();
    
    return $self;
}

# Attribute helpers

##
# The intervals in the interval union, in canonical form (sorted disjoint intervals)
# @returns {QInterval[]}
##
sub intervals {
    my $self = shift;
    return $self->{_intervals};
}


##
# Returns a readable view of the object
# @returns {string}
##
sub toString {
    my ( $self ) = @_;
    my $s = '(';
    for (my $i=0; $i < scalar(@{$self->intervals}); $i++) {
        $s .= $self->intervals->[$i]->toString();
        if ($i != scalar(@{$self->intervals}) - 1) {
            $s .= "+";
        }
    }
    $s .= ')';
    return $s;
}

##
# Equality test
# @param {QIntervalUnion|QInterval|QSet|Quantity|QVector|QMatrix}
# @optional {string|float} tolerance
# @returns {boolean}
##
sub equals {
    my ( $self, $qiu, $tolerance ) = @_;
    if (!$qiu->isa(QIntervalUnion)) {
        return 0;
    }
    if (scalar(@{$self->intervals}) != scalar(@{$qiu->intervals})) {
        return 0;
    }
    foreach my $inter1 (@{$self->intervals}) {
        my $found = 0;
        foreach my $inter2 (@{$qiu->intervals}) {
            if ($inter1->equals($inter2, $tolerance)) {
                $found = 1;
                last;
            }
        }
        if (!$found) {
            return 0;
        }
    }
    return 1;
}

##
# Compare this interval union with another one, and returns a code.
# Returns Quantity->WRONG_TYPE if the parameter is not a QIntervalUnion
# (this might happen if a union of disjoint intervals is compared with a simple interval).
# @param {QIntervalUnion|QInterval|QSet|Quantity|QVector|QMatrix}
# @optional {string|float} tolerance
# @returns {int} Quantity->WRONG_TYPE|WRONG_DIMENSIONS|MISSING_UNITS|ADDED_UNITS|WRONG_UNITS|WRONG_VALUE|WRONG_ENDPOINT|IDENTICAL
##
sub compare {
    my ( $self, $qiu, $tolerance ) = @_;
    if (!$qiu->isa(QIntervalUnion)) {
        return Quantity->WRONG_TYPE;
    }
    if (scalar(@{$self->intervals}) != scalar(@{$qiu->intervals})) {
        return Quantity->WRONG_DIMENSIONS;
    }
    my @codes = ();
    foreach my $inter1 (@{$self->intervals}) {
        my $best_code = Quantity->WRONG_TYPE;
        foreach my $inter2 (@{$qiu->intervals}) {
            my $code = $inter1->compare($inter2, $tolerance);
            if ($code == Quantity->IDENTICAL) {
                $best_code = $code;
                last;
            } elsif ($code > $best_code) {
                $best_code = $code;
            }
        }
        if ($best_code != Quantity->IDENTICAL) {
            return $best_code;
        }
    }
    return Quantity->IDENTICAL;
}

##
# Turns the internal structure into canonical form (sorted disjoint intervals)
##
sub reduce {
    my ( $self ) = @_;
    my @intervals = @{$self->intervals}; # shallow copy (just to make the code easier to read)
    
    # remove empty intervals
    for (my $i=0; $i < scalar(@intervals); $i++) {
        my $inter = $intervals[$i];
        if ($inter->qmin->value == $inter->qmax->value && $inter->qminopen && $inter->qmaxopen) {
            splice(@intervals, $i, 1);
            $i--;
        }
    }
    
    # unite intervals that are not disjoint
    # (at this point we already know that units are the same, and there is no empty interval)
    for (my $i=0; $i < scalar(@intervals); $i++) {
        my $inter1 = $intervals[$i];
        for (my $j=$i+1; $j < scalar(@intervals); $j++) {
            my $inter2 = $intervals[$j];
            if ($inter1->qmax->value < $inter2->qmin->value || $inter1->qmin->value > $inter2->qmax->value) {
                next;
            }
            if ($inter1->qmax->equals($inter2->qmin) && $inter1->qmaxopen && $inter2->qminopen) {
                next;
            }
            if ($inter1->qmin->equals($inter2->qmax) && $inter1->qmaxopen && $inter2->qminopen) {
                next;
            }
            $intervals[$i] = $inter1->union($inter2);
            splice(@intervals, $j, 1);
            $j--;
        }
    }
    
    # sort the intervals
    for (my $i=0; $i < scalar(@intervals); $i++) {
        my $inter1 = $intervals[$i];
        for (my $j=$i+1; $j < scalar(@intervals); $j++) {
            my $inter2 = $intervals[$j];
            if ($inter1->qmin > $inter2->qmin) {
                $intervals[$i] = $inter2;
                $intervals[$j] = $inter1;
                $inter1 = $intervals[$i];
                $inter2 = $intervals[$j];
            }
        }
    }
    
    $self->{_intervals} = \@intervals;
}

##
# Tests if this union of intervals contains a quantity.
# @param {Quantity}
# @returns {boolean}
##
sub contains {
    my ( $self, $q ) = @_;
    if (!$q->isa(Quantity)) {
        die CalcException->new("Interval contains: second member is not a quantity.");
    }
    foreach my $inter (@{$self->intervals}) {
        if ($inter->contains($q)) {
            return 1;
        }
    }
    return 0;
}

##
# Union
# @param {QIntervalUnion|QInterval}
# @returns {QIntervalUnion|QInterval}
##
sub union {
    my ( $self, $qiu ) = @_;
    if (!$qiu->isa(QIntervalUnion) && !$qiu->isa(QInterval)) {
        die CalcException->new("QIntervalUnion union: second member is not an interval union or an interval.");
    }
    my @t = ();
    foreach my $inter (@{$self->intervals}) {
        push(@t, $inter->clone());
    }
    if ($qiu->isa(QInterval)) {
        push(@t, $qiu->clone());
    } else {
        foreach my $inter (@{$qiu->intervals}) {
            push(@t, $inter->clone());
        }
    }
    my $new_union = QIntervalUnion->new(\@t); # will be reduced in the constructor
    if (scalar(@{$new_union->intervals}) == 1) {
        return $new_union->intervals->[0];
    }
    return $new_union;
}

##
# Intersection
# @param {QIntervalUnion|QInterval}
# @returns {QIntervalUnion|QInterval}
##
sub intersection {
    my ( $self, $qiu ) = @_;
    if (!$qiu->isa(QIntervalUnion) && !$qiu->isa(QInterval)) {
        die CalcException->new("QIntervalUnion intersection: second member is not an interval union or an interval.");
    }
    my @t = ();
    my $intervals2;
    if ($qiu->isa(QInterval)) {
        $intervals2 = [$qiu];
    } else {
        $intervals2 = $qiu->intervals;
    }
    foreach my $inter1 (@{$self->intervals}) {
        foreach my $inter2 (@{$intervals2}) {
            my $intersection = $inter1->intersection($inter2);
            if (!$intersection->is_empty()) {
                push(@t, $intersection);
            }
        }
    }
    my $new_qiu = QIntervalUnion->new(\@t);
    if (scalar(@{$new_qiu->intervals}) == 1) {
        return $new_qiu->intervals->[0];
    }
    return $new_qiu;
}


1;
__END__
