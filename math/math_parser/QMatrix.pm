# The LearningOnline Network with CAPA - LON-CAPA
# QVector
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

use aliased 'Apache::math::math_parser::Quantity';
use aliased 'Apache::math::math_parser::QVector';
use aliased 'Apache::math::math_parser::QMatrix';

use overload
    '""' => \&toString,
    '+' => \&add,
    '-' => \&sub,
    '*' => \&mult,
    '^' => \&pow;

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
# @param {QMatrix}
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
# Addition
# @param {QMatrix}
# @returns {QMatrix}
##
sub add {
    my ( $self, $m ) = @_;
    if (!$m->isa(QMatrix)) {
        die "Matrix addition: second member is not a matrix.";
    }
    if (scalar(@{$self->quantities}) != scalar(@{$m->quantities}) || 
            scalar(@{$self->quantities->[0]}) != scalar(@{$m->quantities->[0]})) {
        die "Matrix addition: the matrices have different sizes.";
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
# @param {QMatrix}
# @returns {QMatrix}
##
sub sub {
    my ( $self, $m ) = @_;
    if (!$m->isa(QMatrix)) {
        die "Matrix substraction: second member is not a matrix.";
    }
    if (scalar(@{$self->quantities}) != scalar(@{$m->quantities}) || 
            scalar(@{$self->quantities->[0]}) != scalar(@{$m->quantities->[0]})) {
        die "Matrix substraction: the matrices have different sizes.";
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
sub neg {
    my ( $self ) = @_;
    my @t = (); # 2d array of Quantity
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $t[$i] = [];
        for (my $j=0; $j < scalar(@{$self->quantities->[$i]}); $j++) {
            $t[$i][$j] = $self->quantities->[$i][$j]->neg();
        }
    }
    return QMatrix->new(\@t);
}

##
# Element-by-element multiplication by a quantity, vector or matrix (like Maxima)
# @param {Quantity|QVector|QMatrix}
# @returns {QMatrix}
##
sub mult {
    my ( $self, $m ) = @_;
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
            die "Matrix-Vector element-by-element multiplication: the sizes do not match (use the dot product for matrix product).";
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
        die "Matrix element-by-element multiplication: the matrices have different sizes (use the dot product for matrix product).";
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
# @param {QVector|QMatrix}
# @returns {QVector|QMatrix}
##
sub dot {
    my ( $self, $m ) = @_;
    if ($m->isa(Quantity)) {
        die "Dot product Matrix: Quantity is not defined.";
    }
    if (scalar(@{$self->quantities->[0]}) != scalar(@{$m->quantities})) {
        die "Matrix product: the matrices sizes do not match.";
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
# @param {Quantity}
# @returns {QMatrix}
##
sub pow {
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
