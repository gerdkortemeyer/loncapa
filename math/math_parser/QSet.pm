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
    '+' => \&union;

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
# @param {QSet}
# @optional {string|float} tolerance
# @returns {boolean}
##
sub equals {
    my ( $self, $v, $tolerance ) = @_;
    if (!$v->isa(QSet)) {
        return 0;
    }
    if (scalar(@{$self->quantities}) != scalar(@{$v->quantities})) {
        return 0;
    }
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        if (!$self->quantities->[$i]->equals($v->quantities->[$i], $tolerance)) {
            return 0;
        }
    }
    return 1;
}

##
# Compare this set with another one, and returns a code.
# @param {QSet|QInterval|Quantity|QVector|QMatrix}
# @optional {string|float} tolerance
# @returns {int}
##
sub compare {
    my ( $self, $v, $tolerance ) = @_;
    if (!$v->isa(QSet)) {
        return Quantity->WRONG_TYPE;
    }
    if (scalar(@{$self->quantities}) != scalar(@{$v->quantities})) {
        return Quantity->WRONG_DIMENSIONS;
    }
    my @codes = ();
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        push(@codes, $self->quantities->[$i]->compare($v->quantities->[$i], $tolerance));
    }
    my @test_order = (Quantity->WRONG_TYPE, Quantity->WRONG_DIMENSIONS, Quantity->MISSING_UNITS, Quantity->ADDED_UNITS,
        Quantity->WRONG_UNITS, Quantity->WRONG_VALUE);
    foreach my $test (@test_order) {
        foreach my $code (@codes) {
            if ($code == $test) {
                return $test;
            }
        }
    }
    return Quantity->IDENTICAL;
}

##
# Union
# @param {QSet}
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
# @param {QSet}
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
