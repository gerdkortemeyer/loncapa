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
package ENode;

use strict;
use warnings;

use feature "switch"; # Perl 5.10.1

use Operator;
use ParseException;
use Quantity;
use QVector;
use Units;

use enum qw(UNKNOWN NAME NUMBER OPERATOR FUNCTION VECTOR SUBSCRIPT);

our $units; # single units object that can be changed to add custom units

##
# @param {integer} type - ENode::UNKNOWN | NAME | NUMBER | OPERATOR | FUNCTION | VECTOR
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
        when (ENode::UNKNOWN) { $s .= "UNKNOWN"; }
        when (ENode::NAME) { $s .= "NAME"; }
        when (ENode::NUMBER) { $s .= "NUMBER"; }
        when (ENode::OPERATOR) { $s .= "OPERATOR"; }
        when (ENode::FUNCTION) { $s .= "FUNCTION"; }
        when (ENode::VECTOR) { $s .= "VECTOR"; }
        when (ENode::SUBSCRIPT) { $s .= "SUBSCRIPT"; }
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
        when (ENode::UNKNOWN) {
            die "Unknown node type: ".$self->value;
        }
        when (ENode::NAME) {
            if (!defined $units) {
                $units = new Units();
            }
            return $units->convertToSI($self->value);
        }
        when (ENode::NUMBER) {
            return new Quantity($self->value);
        }
        when (ENode::OPERATOR) {
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
                    return(($children[0]->calc() / new Quantity(100)) * $children[1]->calc());
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
        when (ENode::FUNCTION) {
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
        when (ENode::VECTOR) {
            my @children = @{$self->children};
            my @t = (); # array of Quantity
            for (my $i=0; $i < scalar(@children); $i++) {
                $t[$i] = $children[$i]->calc();
            }
            return new QVector(\@t);
        }
        when (ENode::SUBSCRIPT) {
            die "Subscript cannot be evaluated: ".$self->value;
        }
    }
}

1;
__END__
