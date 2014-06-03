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
use utf8;

use feature "switch"; # Perl 5.10.1

use Apache::lc_ui_localize;

use aliased 'Apache::math::math_parser::CalcException';
use aliased 'Apache::math::math_parser::Operator';
use aliased 'Apache::math::math_parser::ParseException';
use aliased 'Apache::math::math_parser::QMatrix';
use aliased 'Apache::math::math_parser::Quantity';
use aliased 'Apache::math::math_parser::QVector';
use aliased 'Apache::math::math_parser::Units';

use enum qw(UNKNOWN NAME NUMBER OPERATOR FUNCTION VECTOR SUBSCRIPT);

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
# @param {CalcEnv} env - Calculation environment.
# @returns {Quantity|QVector|QMatrix}
##
sub calc {
    my ( $self, $env ) = @_;
    
    given ($self->type) {
        when (UNKNOWN) {
            die CalcException->new("Unknown node type: [_1]", $self->value);
        }
        when (NAME) {
            if ($env->unit_mode) {
                return $env->convertToSI($self->value);
            } else {
                my $name = $self->value;
                my $value = $env->getVariable($name);
                if (!defined $value) {
                    die CalcException->new("Variable has undefined value: [_1]", $name);
                }
                return Quantity->new($value);
            }
        }
        when (NUMBER) {
            return Quantity->new($self->value);
        }
        when (OPERATOR) {
            my @children = @{$self->children};
            given ($self->value) {
                when ("+") {
                    return($children[0]->calc($env) + $children[1]->calc($env));
                }
                when ("-") {
                    if (!defined $children[1]) {
                        return($children[0]->calc($env)->qneg());
                    } else {
                        return($children[0]->calc($env) - $children[1]->calc($env));
                    }
                }
                when ("*") {
                    return($children[0]->calc($env) * $children[1]->calc($env));
                }
                when ("/") {
                    return($children[0]->calc($env) / $children[1]->calc($env));
                }
                when ("^") {
                    return($children[0]->calc($env) ^ $children[1]->calc($env));
                }
                when ("!") {
                    return $children[0]->calc($env)->qfact();
                }
                when ("%") {
                    return(($children[0]->calc($env) / Quantity->new(100)) * $children[1]->calc($env));
                }
                when (".") {
                    # scalar product for vectors, multiplication for matrices
                    return($children[0]->calc($env)->qdot($children[1]->calc($env)));
                }
                when ("`") {
                    return($children[0]->calc($env) * $children[1]->calc($env));
                }
                default {
                    die CalcException->new("Unknown operator: [_1]", $self->value);
                }
            }
        }
        when (FUNCTION) {
            my @children = @{$self->children};
            my $fname = $children[0]->value;
            
            if (!defined $children[1]) {
                die CalcException->new("Missing parameter for function [_1]", $fname);
            }
            given ($fname) {
                when ("matrix") {    return $self->createVectorOrMatrix($env); }
                when ("pow") {
                    if (!defined $children[2]) {
                        die CalcException->new("Missing parameter for function [_1]", $fname);
                    }
                    return $children[1]->calc($env)->qpow($children[2]->calc($env));
                }
                when ("sqrt") {      return $children[1]->calc($env)->qsqrt(); }
                when ("abs") {       return $children[1]->calc($env)->qabs(); }
                when ("exp") {       return $children[1]->calc($env)->qexp(); }
                when ("ln") {        return $children[1]->calc($env)->qln(); }
                when ("log") {       return $children[1]->calc($env)->qln(); }
                when ("log10") {     return $children[1]->calc($env)->qlog10(); }
                when ("factorial") { return $children[1]->calc($env)->qfact(); }
                when ("mod") {
                    if (!defined $children[2]) {
                        die CalcException->new("Missing parameter for function [_1]", $fname);
                    }
                    return $children[1]->calc($env)->qmod($children[2]->calc($env));
                }
                when ("sgn") {       return $children[1]->calc($env)->qsgn(); }
                when ("ceil") {      return $children[1]->calc($env)->qceil(); }
                when ("floor") {     return $children[1]->calc($env)->qfloor(); }
                when ("sin") {       return $children[1]->calc($env)->qsin(); }
                when ("cos") {       return $children[1]->calc($env)->qcos(); }
                when ("tan") {       return $children[1]->calc($env)->qtan(); }
                when ("asin") {      return $children[1]->calc($env)->qasin(); }
                when ("acos") {      return $children[1]->calc($env)->qacos(); }
                when ("atan") {      return $children[1]->calc($env)->qatan(); }
                when ("atan2") {
                    if (!defined $children[2]) {
                        die CalcException->new("Missing parameter for function [_1]", $fname);
                    }
                    return $children[1]->calc($env)->qatan2($children[2]->calc($env));
                }
                when ("sinh") {      return $children[1]->calc($env)->qsinh(); }
                when ("cosh") {      return $children[1]->calc($env)->qcosh(); }
                when ("tanh") {      return $children[1]->calc($env)->qtanh(); }
                when ("asinh") {     return $children[1]->calc($env)->qasinh(); }
                when ("acosh") {     return $children[1]->calc($env)->qacosh(); }
                when ("atanh") {     return $children[1]->calc($env)->qatanh(); }
                when (["sum","product"]) {
                    if ($env->unit_mode) {
                        die CalcException->new("[_1] cannot work in unit mode.", $fname);
                    }
                    if (scalar(@children) != 5) {
                        die CalcException->new("[_1]: should have 4 parameters.", $fname);
                    }
                    my $var = "".$children[2]->value;
                    if ($var eq "i") {
                        die CalcException->new("[_1]: please use another variable name, i is the imaginary number", $fname);
                    }
                    my $initial = $env->getVariable($var);
                    my $var_value_1 = $children[3]->value;
                    my $var_value_2 = $children[4]->value;
                    if ($var_value_1 > $var_value_2) {
                        die CalcException->new("[_1]: are you trying to make me loop forever ???", $fname);
                    }
                    my $sum = Quantity->new($fname eq "sum" ? 0 : 1);
                    for (my $var_value=$var_value_1; $var_value <= $var_value_2; $var_value++) {
                        $env->setVariable($var, $var_value);
                        if ($fname eq "sum") {
                            $sum += $children[1]->calc($env);
                        } else {
                            $sum *= $children[1]->calc($env);
                        }
                    }
                    $env->setVariable($var, $initial);
                    return $sum;
                }
                when ("binomial") {
                    if (scalar(@children) != 3) {
                        die CalcException->new("[_1]: should have 2 parameters.", $fname);
                    }
                    my $n = $children[1]->calc($env);
                    my $p = $children[2]->calc($env);
                    return $n->qfact() / ($p->qfact() * ($n - $p)->qfact());
                }
                default {            die CalcException->new("Unknown function: [_1]",$fname); }
            }
        }
        when (VECTOR) {
            return $self->createVectorOrMatrix($env);
        }
        when (SUBSCRIPT) {
            die CalcException->new("Subscript cannot be evaluated: [_1]", $self->value);
        }
    }
}

##
# Returns the equation as a string with the Maxima syntax.
# @returns {string}
##
sub toMaxima {
    my ( $self ) = @_;
    
    given ($self->type) {
        when (UNKNOWN) {
            die CalcException->new("Unknown node type: [_1]", $self->value);
        }
        when (NAME) {
            # constants have already been transformed, so this should be a variable (no % necessary)
            my $name = $self->value;
            return($name);
        }
        when (NUMBER) {
            if ($self->value eq "i") {
                return "%i";
            } else {
                return $self->value;
            }
        }
        when (OPERATOR) {
            my @children = @{$self->children};
            given ($self->value) {
                when ("+") {
                    return("(".$children[0]->toMaxima()."+".$children[1]->toMaxima().")");
                }
                when ("-") {
                    if (!defined $children[1]) {
                        return("(-".$children[0]->toMaxima().")");
                    } else {
                        return("(".$children[0]->toMaxima()."-".$children[1]->toMaxima().")");
                    }
                }
                when ("*") {
                    return("(".$children[0]->toMaxima()."*".$children[1]->toMaxima().")");
                }
                when ("/") {
                    return("(".$children[0]->toMaxima()."/".$children[1]->toMaxima().")");
                }
                when ("^") {
                    return("(".$children[0]->toMaxima()."^".$children[1]->toMaxima().")");
                }
                when ("!") {
                    return("factorial(".$children[0]->toMaxima().")");
                }
                when ("%") {
                    return("((".$children[0]->toMaxima()."/100)*".$children[1]->toMaxima().")");
                }
                when (".") {
                    # scalar product for vectors, multiplication for matrices
                    return("(".$children[0]->toMaxima().".".$children[1]->toMaxima().")");
                }
                when ("`") {
                    return("(".$children[0]->toMaxima()."`".$children[1]->toMaxima().")");
                }
                default {
                    die CalcException->new("Unknown operator: [_1]", $self->value);
                }
            }
        }
        when (FUNCTION) {
            my @children = @{$self->children};
            my $fname = $children[0]->value;
            
            given ($fname) {
                when ("log10") {  return "log(".$children[1]->toMaxima().")/log(10)"; }
                when ("sgn") {    return "signum(".$children[1]->toMaxima().")"; }
                when ("ceil") {   return "ceiling(".$children[1]->toMaxima().")"; }
                default {
                    my $s = $fname."(";
                    for (my $i=1; $i<scalar(@children); $i++) {
                        if ($i != 1) {
                            $s .= ", ";
                        }
                        $s .= $children[$i]->toMaxima();
                    }
                    $s .= ")";
                    return($s);
                }
            }
        }
        when (VECTOR) {
            my @children = @{$self->children};
            my $s;
            if ($children[0]->type == VECTOR) {
                $s = "matrix(";
            } else {
                $s = "[";
            }
            for (my $i=0; $i<scalar(@children); $i++) {
                if ($i != 0) {
                    $s .= ", ";
                }
                $s .= $children[$i]->toMaxima();
            }
            if ($children[0]->type == VECTOR) {
                $s .= ")";
            } else {
                $s .= "]";
            }
            return($s);
        }
        when (SUBSCRIPT) {
            my @children = @{$self->children};
            return("(".$children[0]->toMaxima()."_".$children[1]->toMaxima().")");
        }
    }
}

##
# Creates a vector or a matrix with this node
# @param {CalcEnv} env - Calculation environment.
# @returns {QVector|QMatrix}
##
sub createVectorOrMatrix {
    my ( $self, $env ) = @_;
    my @children = @{$self->children};
    my @t = (); # 1d or 2d array of Quantity
    my $start;
    if ($self->type == FUNCTION) {
        $start = 1;
    } else {
        $start = 0;
    }
    my $nb1;
    for (my $i=0; $i < scalar(@children) - $start; $i++) {
        my $qv = $children[$i+$start]->calc($env);
        my $nb2;
        if ($qv->isa(Quantity)) {
            $nb2 = 1;
        } else {
            $nb2 = scalar(@{$qv->quantities});
        }
        if (!defined $nb1) {
            $nb1 = $nb2;
        } elsif ($nb2 != $nb1) {
            die CalcException->new("Inconsistent number of elements in a matrix.");
        }
        if ($qv->isa(Quantity)) {
            $t[$i] = $qv;
        } else {
            $t[$i] = [];
            for (my $j=0; $j < scalar(@{$qv->quantities}); $j++) {
                $t[$i][$j] = $qv->quantities->[$j];
            }
        }
    }
    if (ref($t[0]) eq 'ARRAY') {
        return QMatrix->new(\@t);
    } else {
        return QVector->new(\@t);
    }
}

1;
__END__
