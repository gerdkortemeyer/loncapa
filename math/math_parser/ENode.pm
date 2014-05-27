# The LearningOnline Network with CAPA - LON-CAPA
# Parsed tree node
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
# Parsed tree node. ENode.toMathML(hcolors) contains the code for the transformation into MathML.
##
package Apache::math::math_parser::ENode;

use strict;
use warnings;

use feature "switch"; # Perl 5.10.1

use Apache::math::math_parser::Operator;
use Apache::math::math_parser::ParseException;
use Apache::math::math_parser::Quantity;
use Apache::math::math_parser::QVector;
use Apache::math::math_parser::Units;

use enum qw(UNKNOWN NAME NUMBER OPERATOR FUNCTION VECTOR SUBSCRIPT);

our $units; # single units object that can be changed to add custom units

##
# @param {integer} type - UNKNOWN | NAME | NUMBER | OPERATOR | FUNCTION | VECTOR
# @param {Operator} op - The operator
# @param {string} value - Node value as a string, undef for type VECTOR
# @param {ENode[]} children - The children nodes, only for types OPERATOR, FUNCTION, VECTOR, SUBSCRIPT
##
sub new {
    my $class = shift;
    my $self = {
        _type => shift,
        _op => shift,
        _value => shift,
        _children => shift,
    };
    bless $self, $class;
    return $self;
}

# Attribute helpers
sub type {
    my $self = shift;
    return $self->{_type};
}
sub op {
    my $self = shift;
    return $self->{_op};
}
sub value {
    my $self = shift;
    return $self->{_value};
}
sub children {
    my $self = shift;
    return $self->{_children};
}

##
# Returns the node as a string, for debug
# @returns {string}
##
sub toString {
    my ( $self ) = @_;
    my $s = '(';
    given ($self->type) {
        when (UNKNOWN) { $s .= "UNKNOWN"; }
        when (NAME) { $s .= "NAME"; }
        when (NUMBER) { $s .= "NUMBER"; }
        when (OPERATOR) { $s .= "OPERATOR"; }
        when (FUNCTION) { $s .= "FUNCTION"; }
        when (VECTOR) { $s .= "VECTOR"; }
        when (SUBSCRIPT) { $s .= "SUBSCRIPT"; }
    }
    if (defined $self->op) {
        $s .= " '" . $self->op->id . "'";
    }
    if (defined $self->value) {
        $s .= " '" . $self->value . "'";
    }
    if (defined $self->{_children}) {
        $s .= ' [';
        for (my $i = 0; $i < scalar(@{$self->children}); $i++) {
            $s .= $self->children->[$i]->toString();
            if ($i != scalar(@{$self->children}) - 1) {
                $s .= ',';
            }
        }
        $s .= ']';
    }
    $s.= ')';
    return $s;
}

##
# Evaluates the node, returning either a number, a complex or a vector with associated units.
# @returns {Quantity|QVector}
##
sub calc {
    my ( $self ) = @_;
    
    given ($self->type) {
        when (UNKNOWN) {
            die "Unknown node type: ".$self->value;
        }
        when (NAME) {
            if (!defined $units) {
                $units = Units->new();
            }
            return $units->convertToSI($self->value);
        }
        when (NUMBER) {
            return Quantity->new($self->value);
        }
        when (OPERATOR) {
            my @children = @{$self->children};
            given ($self->value) {
                when ("+") {
                    return($children[0]->calc() + $children[1]->calc());
                }
                when ("-") {
                    if (!defined $children[1]) {
                        return($children[0]->calc()->neg());
                    } else {
                        return($children[0]->calc() - $children[1]->calc());
                    }
                }
                when ("*") {
                    return($children[0]->calc() * $children[1]->calc());
                }
                when ("/") {
                    return($children[0]->calc() / $children[1]->calc());
                }
                when ("^") {
                    return($children[0]->calc() ^ $children[1]->calc());
                }
                when ("!") {
                    return $children[0]->calc()->qfact();
                }
                when ("%") {
                    return(($children[0]->calc() / Quantity->new(100)) * $children[1]->calc());
                }
                when (".") {
                    # scalar product for vectors
                    return($children[0]->calc()->dot($children[1]->calc()));
                }
                when ("`") {
                    return($children[0]->calc() * $children[1]->calc());
                }
                default {
                    die "Unknown operator: ".$self->value;
                }
            }
        }
        when (FUNCTION) {
            my @children = @{$self->children};
            my $fname = $children[0]->value;
            
            if (!defined $children[1]) {
                die "Missing parameter for function $fname";
            }
            given ($fname) {
                when ("sqrt") {      return $children[1]->calc()->qsqrt(); }
                when ("abs") {       return $children[1]->calc()->qabs(); }
                when ("exp") {       return $children[1]->calc()->qexp(); }
                when ("ln") {        return $children[1]->calc()->qln(); }
                when ("log10") {     return $children[1]->calc()->qlog10(); }
                when ("factorial") { return $children[1]->calc()->qfact(); }
                when ("sin") {       return $children[1]->calc()->qsin(); }
                when ("cos") {       return $children[1]->calc()->qcos(); }
                when ("tan") {       return $children[1]->calc()->qtan(); }
                when ("asin") {      return $children[1]->calc()->qasin(); }
                when ("acos") {      return $children[1]->calc()->qacos(); }
                when ("atan") {      return $children[1]->calc()->qatan(); }
                default {            die "Unknown function: ".$fname; }
            }
        }
        when (VECTOR) {
            my @children = @{$self->children};
            my @t = (); # array of Quantity
            for (my $i=0; $i < scalar(@children); $i++) {
                $t[$i] = $children[$i]->calc();
            }
            return QVector->new(\@t);
        }
        when (SUBSCRIPT) {
            die "Subscript cannot be evaluated: ".$self->value;
        }
    }
}

1;
__END__
