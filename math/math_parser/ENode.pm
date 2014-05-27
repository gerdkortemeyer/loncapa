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

use Switch;

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
    switch ($self->type) {
        case ENode::UNKNOWN { $s .= "UNKNOWN"; }
        case ENode::NAME { $s .= "NAME"; }
        case ENode::NUMBER { $s .= "NUMBER"; }
        case ENode::OPERATOR { $s .= "OPERATOR"; }
        case ENode::FUNCTION { $s .= "FUNCTION"; }
        case ENode::VECTOR { $s .= "VECTOR"; }
        case ENode::SUBSCRIPT { $s .= "SUBSCRIPT"; }
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
    
    switch ($self->type) {
        case ENode::UNKNOWN {
            die "Unknown node type: ".$self->value;
        }
        case ENode::NAME {
            if (!defined $units) {
                $units = new Units();
            }
            return $units->convertToSI($self->value);
        }
        case ENode::NUMBER {
            return new Quantity($self->value);
        }
        case ENode::OPERATOR {
            my @children = @{$self->children};
            switch ($self->value) {
                case "+" {
                    return($children[0]->calc() + $children[1]->calc());
                }
                case "-" {
                    if (!defined $children[1]) {
                        return($children[0]->calc()->neg());
                    } else {
                        return($children[0]->calc() - $children[1]->calc());
                    }
                }
                case "*" {
                    return($children[0]->calc() * $children[1]->calc());
                }
                case "/" {
                    return($children[0]->calc() / $children[1]->calc());
                }
                case "^" {
                    return($children[0]->calc() ^ $children[1]->calc());
                }
                case "!" {
                    return $children[0]->calc()->fact();
                }
                case "%" {
                    return(($children[0]->calc() / new Quantity(100)) * $children[1]->calc());
                }
                case "." {
                    # scalar product for vectors
                    return($children[0]->calc()->dot($children[1]->calc()));
                }
                case "`" {
                    return($children[0]->calc() * $children[1]->calc());
                }
                else {
                    die "Unknown operator: ".$self->value;
                }
            }
        }
        case ENode::FUNCTION {
            my @children = @{$self->children};
            my $fname = $children[0]->value;
            
            if (!defined $children[1]) {
                die "Missing parameter for function $fname";
            }
            if ($fname eq "sqrt") {
                return $children[1]->calc()->qsqrt();
                
            } elsif ($fname eq "abs") {
                return $children[1]->calc()->qabs();
                
            } elsif ($fname eq "exp") {
                return $children[1]->calc()->qexp();
                
            } elsif ($fname eq "ln") {
                return $children[1]->calc()->qln();
                
            } elsif ($fname eq "log10") {
                return $children[1]->calc()->qlog10();
                
            } elsif ($fname eq "factorial") {
                return $children[1]->calc()->qfact();
                
            } elsif ($fname eq "sin") {
                return $children[1]->calc()->qsin();
                
            } elsif ($fname eq "cos") {
                return $children[1]->calc()->qcos();
                
            } elsif ($fname eq "tan") {
                return $children[1]->calc()->qtan();
                
            } elsif ($fname eq "asin") {
                return $children[1]->calc()->qasin();
                
            } elsif ($fname eq "acos") {
                return $children[1]->calc()->qacos();
                
            } elsif ($fname eq "atan") {
                return $children[1]->calc()->qatan();
                
            } else {
                die "Unknown function: ".$fname;
            }
        }
        case ENode::VECTOR {
            my @children = @{$self->children};
            my @t = (); # array of Quantity
            for (my $i=0; $i < scalar(@children); $i++) {
                $t[$i] = $children[$i]->calc();
            }
            return new QVector(\@t);
        }
        case ENode::SUBSCRIPT {
            die "Subscript cannot be evaluated: ".$self->value;
        }
    }
}

1;
__END__
