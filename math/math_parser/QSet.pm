# The LearningOnline Network with CAPA - LON-CAPA
# QSet
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
# A set of quantities
##
package Apache::math::math_parser::QSet;

use strict;
use warnings;
use utf8;

use aliased 'Apache::math::math_parser::CalcException';
use aliased 'Apache::math::math_parser::Quantity';
use aliased 'Apache::math::math_parser::QSet';

use overload
    '""' => \&toString,
    '+' => \&union,
    '*' => \&qmult;

##
# Constructor
# @param {Quantity[]} quantities
##
sub new {
    my $class = shift;
    # we use an array to preserve order (of course purely for cosmetic reasons)
    my $self = {
        _quantities => shift,
    };
    bless $self, $class;
    # remove duplicates
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        my $qi = $self->quantities->[$i];
        for (my $j=0; $j < $i; $j++) {
            my $qj = $self->quantities->[$j];
            if ($qi->equals($qj)) {
                splice(@{$self->quantities}, $i, 1);
                $i--;
                last;
            }
        }
    }
    return $self;
}

# Attribute helpers

##
# The components of the set.
# @returns {Quantity[]}
##
sub quantities {
    my $self = shift;
    return $self->{_quantities};
}


##
# Returns a readable view of the object
# @returns {string}
##
sub toString {
    my ( $self ) = @_;
    my $s = "{";
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $s .= $self->quantities->[$i]->toString();
        if ($i != scalar(@{$self->quantities}) - 1) {
            $s .= "; ";
        }
    }
    $s .= "}";
    return $s;
}

##
# Equality test
# @param {QSet} set
# @optional {string|float} tolerance
# @returns {boolean}
##
sub equals {
    my ( $self, $set, $tolerance ) = @_;
    if (!$set->isa(QSet)) {
        return 0;
    }
    if (scalar(@{$self->quantities}) != scalar(@{$set->quantities})) {
        return 0;
    }
    foreach my $q1 (@{$self->quantities}) {
        my $found = 0;
        foreach my $q2 (@{$set->quantities}) {
            if ($q1->equals($q2, $tolerance)) {
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
# Compare this set with another one, and returns a code.
# Returns Quantity->WRONG_TYPE if the parameter is not a QSet.
# @param {QSet|QInterval|Quantity|QVector|QMatrix} set
# @optional {string|float} tolerance
# @returns {int} Quantity->WRONG_TYPE|WRONG_DIMENSIONS|MISSING_UNITS|ADDED_UNITS|WRONG_UNITS|WRONG_VALUE|IDENTICAL
##
sub compare {
    my ( $self, $set, $tolerance ) = @_;
    if (!$set->isa(QSet)) {
        return Quantity->WRONG_TYPE;
    }
    if (scalar(@{$self->quantities}) != scalar(@{$set->quantities})) {
        return Quantity->WRONG_DIMENSIONS;
    }
    my @codes = ();
    foreach my $q1 (@{$self->quantities}) {
        my $best_code = Quantity->WRONG_TYPE;
        foreach my $q2 (@{$set->quantities}) {
            my $code = $q1->compare($q2, $tolerance);
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
# Multiplication by a Quantity
# @param {Quantity} q
# @returns {QSet}
##
sub qmult {
    my ( $self, $q ) = @_;
    if (!$q->isa(Quantity)) {
        die CalcException->new("Set multiplication: second member is not a quantity.");
    }
    my @t = ();
    foreach my $sq (@{$self->quantities}) {
        push(@t, $sq * $q);
    }
    return QSet->new(\@t);
}

##
# Union
# @param {QSet} set
# @returns {QSet}
##
sub union {
    my ( $self, $set ) = @_;
    if (!$set->isa(QSet)) {
        die CalcException->new("Set union: second member is not a set.");
    }
    my @t = @{$self->quantities};
    foreach my $q (@{$set->quantities}) {
        my $found = 0;
        foreach my $q2 (@t) {
            if ($q->equals($q2)) {
                $found = 1;
                last;
            }
        }
        if (!$found) {
            push(@t, $q);
        }
    }
    return QSet->new(\@t);
}

##
# Intersection
# @param {QSet} set
# @returns {QSet}
##
sub intersection {
    my ( $self, $set ) = @_;
    if (!$set->isa(QSet)) {
        die CalcException->new("Set intersection: second member is not a set.");
    }
    my @t = ();
    foreach my $q (@{$self->quantities}) {
        my $found = 0;
        foreach my $q2 (@{$set->quantities}) {
            if ($q->equals($q2)) {
                $found = 1;
                last;
            }
        }
        if ($found) {
            push(@t, $q);
        }
    }
    return QSet->new(\@t);
}


1;
__END__
