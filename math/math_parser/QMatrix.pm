# The LearningOnline Network with CAPA - LON-CAPA
# QMatrix
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
# A matrix of quantities
##
package Apache::math::math_parser::QMatrix;

use strict;
use warnings;
use utf8;

use aliased 'Apache::math::math_parser::CalcException';
use aliased 'Apache::math::math_parser::Quantity';
use aliased 'Apache::math::math_parser::QVector';
use aliased 'Apache::math::math_parser::QMatrix';

use overload
    '""' => \&toString,
    '+' => \&qadd,
    '-' => \&qsub,
    '*' => \&qmult,
    '^' => \&qpow;

##
# Constructor
# @param {Quantity[][]} quantities
##
sub new {
    my $class = shift;
    my $self = {
        _quantities => shift,
    };
    bless $self, $class;
    return $self;
}

# Attribute helpers

##
# The components of the matrix.
# @returns {Quantity[][]}
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
    my $s = "[";
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $s .= "[";
        for (my $j=0; $j < scalar(@{$self->quantities->[$i]}); $j++) {
            $s .= $self->quantities->[$i][$j]->toString();
            if ($j != scalar(@{$self->quantities->[$i]}) - 1) {
                $s .= "; ";
            }
        }
        $s .= "]";
        if ($i != scalar(@{$self->quantities}) - 1) {
            $s .= "; ";
        }
    }
    $s .= "]";
    return $s;
}

##
# Equality test
# @param {QMatrix} m
# @optional {string|float} tolerance
# @returns {boolean}
##
sub equals {
    my ( $self, $m, $tolerance ) = @_;
    if (!$m->isa(QMatrix)) {
        return 0;
    }
    if (scalar(@{$self->quantities}) != scalar(@{$m->quantities})) {
        return 0;
    }
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        if (scalar(@{$self->quantities->[$i]}) != scalar(@{$m->quantities->[$i]})) {
            return 0;
        }
        for (my $j=0; $j < scalar(@{$self->quantities->[$i]}); $j++) {
            if (!$self->quantities->[$i][$j]->equals($m->quantities->[$i][$j], $tolerance)) {
                return 0;
            }
        }
    }
    return 1;
}

##
# Compare this matrix with another one, and returns a code.
# @param {Quantity|QVector|QMatrix|QSet|QInterval} m
# @optional {string|float} tolerance
# @returns {int} Quantity->WRONG_TYPE|WRONG_DIMENSIONS|MISSING_UNITS|ADDED_UNITS|WRONG_UNITS|WRONG_VALUE|IDENTICAL
##
sub compare {
    my ( $self, $m, $tolerance ) = @_;
    if (!$m->isa(QMatrix)) {
        return Quantity->WRONG_TYPE;
    }
    if (scalar(@{$self->quantities}) != scalar(@{$m->quantities})) {
        return Quantity->WRONG_DIMENSIONS;
    }
    my @codes = ();
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        if (scalar(@{$self->quantities->[$i]}) != scalar(@{$m->quantities->[$i]})) {
            return Quantity->WRONG_DIMENSIONS;
        }
        for (my $j=0; $j < scalar(@{$self->quantities->[$i]}); $j++) {
            push(@codes, $self->quantities->[$i][$j]->compare($m->quantities->[$i][$j], $tolerance));
        }
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
# Addition
# @param {QMatrix} m
# @returns {QMatrix}
##
sub qadd {
    my ( $self, $m ) = @_;
    if (!$m->isa(QMatrix)) {
        die CalcException->new("Matrix addition: second member is not a matrix.");
    }
    if (scalar(@{$self->quantities}) != scalar(@{$m->quantities}) || 
            scalar(@{$self->quantities->[0]}) != scalar(@{$m->quantities->[0]})) {
        die CalcException->new("Matrix addition: the matrices have different sizes.");
    }
    my @t = (); # 2d array of Quantity
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $t[$i] = [];
        for (my $j=0; $j < scalar(@{$self->quantities->[$i]}); $j++) {
            $t[$i][$j] = $self->quantities->[$i][$j] + $m->quantities->[$i][$j];
        }
    }
    return QMatrix->new(\@t);
}

##
# Substraction
# @param {QMatrix} m
# @returns {QMatrix}
##
sub qsub {
    my ( $self, $m ) = @_;
    if (!$m->isa(QMatrix)) {
        die CalcException->new("Matrix substraction: second member is not a matrix.");
    }
    if (scalar(@{$self->quantities}) != scalar(@{$m->quantities}) || 
            scalar(@{$self->quantities->[0]}) != scalar(@{$m->quantities->[0]})) {
        die CalcException->new("Matrix substraction: the matrices have different sizes.");
    }
    my @t = (); # 2d array of Quantity
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $t[$i] = [];
        for (my $j=0; $j < scalar(@{$self->quantities->[$i]}); $j++) {
            $t[$i][$j] = $self->quantities->[$i][$j] - $m->quantities->[$i][$j];
        }
    }
    return QMatrix->new(\@t);
}

##
# Negation
# @returns {QMatrix}
##
sub qneg {
    my ( $self ) = @_;
    my @t = (); # 2d array of Quantity
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $t[$i] = [];
        for (my $j=0; $j < scalar(@{$self->quantities->[$i]}); $j++) {
            $t[$i][$j] = $self->quantities->[$i][$j]->qneg();
        }
    }
    return QMatrix->new(\@t);
}

##
# Element-by-element multiplication by a quantity, vector or matrix (like Maxima)
# @param {Quantity|QVector|QMatrix} m
# @returns {QMatrix}
##
sub qmult {
    my ( $self, $m ) = @_;
    if (!$m->isa(Quantity) && !$m->isa(QVector) && !$m->isa(QMatrix)) {
        die CalcException->new("Matrix element-by-element multiplication: second member is not a quantity, vector or matrix.");
    }
    if ($m->isa(Quantity)) {
        my @t = (); # 2d array of Quantity
        for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
            $t[$i] = [];
            for (my $j=0; $j < scalar(@{$self->quantities->[$i]}); $j++) {
                $t[$i][$j] = $self->quantities->[$i][$j] * $m;
            }
        }
        return QMatrix->new(\@t);
    }
    if ($m->isa(QVector)) {
        if (scalar(@{$self->quantities}) != scalar(@{$m->quantities})) {
            die CalcException->new(
"Matrix-Vector element-by-element multiplication: the sizes do not match (use the dot product for matrix product).");
        }
        my @t = (); # 2d array of Quantity
        for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
            $t[$i] = [];
            for (my $j=0; $j < scalar(@{$self->quantities->[$i]}); $j++) {
                $t[$i][$j] = $self->quantities->[$i][$j] * $m->quantities->[$i];
            }
        }
        return QMatrix->new(\@t);
    }
    if (scalar(@{$self->quantities}) != scalar(@{$m->quantities}) || 
            scalar(@{$self->quantities->[0]}) != scalar(@{$m->quantities->[0]})) {
        die CalcException->new(
"Matrix element-by-element multiplication: the matrices have different sizes (use the dot product for matrix product).");
    }
    my @t = (); # 2d array of Quantity
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $t[$i] = [];
        for (my $j=0; $j < scalar(@{$self->quantities->[$i]}); $j++) {
            $t[$i][$j] = $self->quantities->[$i][$j] * $m->quantities->[$i][$j];
        }
    }
    return QMatrix->new(\@t);
}

##
# Noncommutative multiplication by a vector or matrix
# @param {QVector|QMatrix} m
# @returns {QVector|QMatrix}
##
sub qdot {
    my ( $self, $m ) = @_;
    if (!$m->isa(QVector) && !$m->isa(QMatrix)) {
        die CalcException->new("Matrix product: second member is not a vector or a matrix.");
    }
    if (scalar(@{$self->quantities->[0]}) != scalar(@{$m->quantities})) {
        die CalcException->new("Matrix product: the matrices sizes do not match.");
    }
    if ($m->isa(QVector)) {
        my @t = (); # array of Quantity
        for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
            $t[$i] = Quantity->new(0);
            for (my $j=0; $j < scalar(@{$m->quantities}); $j++) {
                $t[$i] += $self->quantities->[$i][$j] * $m->quantities->[$j];
            }
        }
        return QVector->new(\@t);
    }
    my @t = (); # array or 2d array of Quantity
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $t[$i] = [];
        for (my $j=0; $j < scalar(@{$m->quantities->[0]}); $j++) {
            $t[$i][$j] = Quantity->new(0);
            for (my $k=0; $k < scalar(@{$m->quantities}); $k++) {
                $t[$i][$j] += $self->quantities->[$i][$k] * $m->quantities->[$k][$j];
            }
        }
    }
    return QMatrix->new(\@t);
}

##
# Power by a scalar
# @param {Quantity} q
# @returns {QMatrix}
##
sub qpow {
    my ( $self, $q ) = @_;
    $q->noUnits("Power");
    # note: this could be optimized, see "exponentiating by squaring"
    my $m = QMatrix->new($self->quantities);
    for (my $i=0; $i < $q->value - 1; $i++) {
        $m = $m * $self;
    }
    return $m;
}

1;
__END__
