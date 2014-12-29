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

use aliased 'Apache::math::math_parser::CalcException';
use aliased 'Apache::math::math_parser::Operator';
use aliased 'Apache::math::math_parser::ParseException';
use aliased 'Apache::math::math_parser::QMatrix';
use aliased 'Apache::math::math_parser::Quantity';
use aliased 'Apache::math::math_parser::QVector';
use aliased 'Apache::math::math_parser::QInterval';
use aliased 'Apache::math::math_parser::QIntervalUnion';
use aliased 'Apache::math::math_parser::QSet';
use aliased 'Apache::math::math_parser::Units';

use enum qw(UNKNOWN NAME NUMBER OPERATOR FUNCTION VECTOR INTERVAL SET SUBSCRIPT);
use enum qw(NOT_AN_INTERVAL OPEN_OPEN OPEN_CLOSED CLOSED_OPEN CLOSED_CLOSED);

##
# @param {integer} type - UNKNOWN | NAME | NUMBER | OPERATOR | FUNCTION | VECTOR | INTERVAL | SET | SUBSCRIPT
# @param {Operator} op - The operator
# @param {string} value - Node value as a string, undef for type VECTOR
# @param {ENode[]} children - The children nodes, only for types OPERATOR, FUNCTION, VECTOR, INTERVAL, SET, SUBSCRIPT
# @param {interval_type} - The interval type, NOT_AN_INTERVAL | OPEN_OPEN | OPEN_CLOSED | CLOSED_OPEN | CLOSED_CLOSED
##
sub new {
    my $class = shift;
    my $self = {
        _type => shift,
        _op => shift,
        _value => shift,
        _children => shift,
        _interval_type => shift // NOT_AN_INTERVAL,
    };
    bless $self, $class;
    return $self;
}

# Attribute helpers

##
# Node type
# @returns {int} UNKNOWN | NAME | NUMBER | OPERATOR | FUNCTION | VECTOR | INTERVAL | SET | SUBSCRIPT
##
sub type {
    my $self = shift;
    return $self->{_type};
}

##
# Operator
# @returns {Operator}
##
sub op {
    my $self = shift;
    return $self->{_op};
}

##
# Node value as a string, undef for type VECTOR.
# @returns {string}
##
sub value {
    my $self = shift;
    return $self->{_value};
}

##
# The children nodes, only for types OPERATOR, FUNCTION, VECTOR, INTERVAL, SET, SUBSCRIPT
# @returns {ENode[]}
##
sub children {
    my $self = shift;
    return $self->{_children};
}

##
# The interval type, NOT_AN_INTERVAL | OPEN_OPEN | OPEN_CLOSED | CLOSED_OPEN | CLOSED_CLOSED
# @returns {int}
##
sub interval_type {
    my $self = shift;
    return $self->{_interval_type};
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
        when (INTERVAL) { $s .= "INTERVAL"; }
        when (SET) { $s .= "SET"; }
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
    if (defined $self->interval_type) {
        $s .= " " . $self->interval_type;
    }
    $s.= ')';
    return $s;
}

##
# Evaluates the node, returning a quantity or an object from a more complex class using quantities as base components.
# Can throw a CalcException if a result cannot be calculated.
# @param {CalcEnv} env - Calculation environment.
# @returns {Quantity|QVector|QMatrix|QSet|QInterval|QIntervalUnion}
##
sub calc {
    my ( $self, $env ) = @_;
    
    given ($self->type) {
        when (UNKNOWN) {
            die CalcException->new("Unknown node type: [_1].", $self->value);
        }
        when (NAME) {
            if ($self->value =~ /^inf$/i) {
                return Quantity->new(9**9**9);
            } elsif ($self->value =~ /^nan$/i) {
                return Quantity->new(-sin(9**9**9));
            }
            if ($env->unit_mode) {
                return $env->convertToSI($self->value);
            } else {
                my $name = $self->value;
                my $value = $env->getVariable($name);
                if (!defined $value) {
                    die CalcException->new("Variable has undefined value: [_1].", $name);
                }
                return Quantity->new($value);
            }
        }
        when (NUMBER) {
            return Quantity->new($self->value);
        }
        when (OPERATOR) {
            my @children = @{$self->children};
            my ($q1, $q2);
            if (defined $children[0]) {
                $q1 = $children[0]->calc($env);
            }
            if (defined $children[1]) {
                $q2 = $children[1]->calc($env);
            }
            given ($self->value) {
                when ("+") {
                    if (!overload::Method($q1, '+')) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return($q1 + $q2);
                }
                when ("-") {
                    if (!defined $q2) {
                        if (!$q1->can('qneg')) {
                            die CalcException->new("Negation is not implemented for this type.");
                        }
                        return($q1->qneg());
                    } else {
                        if (!overload::Method($q1, '-')) {
                            die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                        }
                        return($q1 - $q2);
                    }
                }
                when ("*") {
                    if (!overload::Method($q1, '*')) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return($q1 * $q2);
                }
                when ("/") {
                    if (!overload::Method($q1, '/')) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return($q1 / $q2);
                }
                when ("^") {
                    if (!overload::Method($q1, '^')) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return($q1 ^ $q2);
                }
                when ("!") {
                    if (!$q1->can('qfact')) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return $q1->qfact();
                }
                when ("%") {
                    if (!$q1->isa(Quantity) || !$q2->isa(Quantity)) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return(($q1 / Quantity->new(100)) * $q2);
                }
                when (".") {
                    # scalar product for vectors, multiplication for matrices
                    if (!$q1->can('qdot')) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return($q1->qdot($children[1]->calc($env)));
                }
                when ("`") {
                    if (!overload::Method($q1, '*')) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return($q1 * $q2);
                }
                when ("=") {
                    if (!$q1->can('qeq')) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return($q1->qeq($q2));
                }
                when ("<") {
                    if (!overload::Method($q1, '<')) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return($q1 < $q2);
                }
                when ("<=") {
                    if (!overload::Method($q1, '<=')) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return($q1 <= $q2);
                }
                when (">") {
                    if (!overload::Method($q1, '>')) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return($q1 > $q2);
                }
                when (">=") {
                    if (!overload::Method($q1, '>=')) {
                        die CalcException->new("The [_1] operator is not implemented for this type.", $self->value);
                    }
                    return($q1 >= $q2);
                }
                default {
                    die CalcException->new("Unknown operator: [_1].", $self->value);
                }
            }
        }
        when (FUNCTION) {
            my @children = @{$self->children};
            my $fname = $children[0]->value;
            
            if (!defined $children[1]) {
                die CalcException->new("Missing parameter for function [_1].", $fname);
            }
            my ($q1, $q2);
            if ($fname ~~ ['pow', 'sqrt', 'abs', 'exp', 'ln', 'log', 'log10', 'factorial',
                    'mod', 'sgn', 'ceil', 'floor', 'sin', 'cos', 'tan', 'asin', 'acos', 'atan',
                    'atan2', 'sinh', 'cosh', 'tanh', 'asinh', 'acosh', 'atanh']) {
                $q1 = $children[1]->calc($env);
                if (!$q1->isa(Quantity)) {
                    die CalcException->new("The [_1] function is not implemented for this type.", $fname);
                }
            }
            if ($fname ~~ ['pow', 'mod', 'atan2']) {
                if (!defined $children[2]) {
                    die CalcException->new("Missing parameter for function [_1].", $fname);
                }
                $q2 = $children[2]->calc($env);
                if (!$q2->isa(Quantity)) {
                    die CalcException->new("The [_1] function is not implemented for this type.", $fname);
                }
            }
            given ($fname) {
                when ("matrix") {    return $self->createVectorOrMatrix($env); }
                when ("pow") {       return $q1->qpow($q2); }
                when ("sqrt") {      return $q1->qsqrt(); }
                when ("abs") {       return $q1->qabs(); }
                when ("exp") {       return $q1->qexp(); }
                when ("ln") {        return $q1->qln(); }
                when ("log") {       return $q1->qln(); }
                when ("log10") {     return $q1->qlog10(); }
                when ("factorial") { return $q1->qfact(); }
                when ("mod") {       return $q1->qmod($q2); }
                when ("sgn") {       return $q1->qsgn(); }
                when ("ceil") {      return $q1->qceil(); }
                when ("floor") {     return $q1->qfloor(); }
                when ("sin") {       return $q1->qsin(); }
                when ("cos") {       return $q1->qcos(); }
                when ("tan") {       return $q1->qtan(); }
                when ("asin") {      return $q1->qasin(); }
                when ("acos") {      return $q1->qacos(); }
                when ("atan") {      return $q1->qatan(); }
                when ("atan2") {     return $q1->qatan2($q2); }
                when ("sinh") {      return $q1->qsinh(); }
                when ("cosh") {      return $q1->qcosh(); }
                when ("tanh") {      return $q1->qtanh(); }
                when ("asinh") {     return $q1->qasinh(); }
                when ("acosh") {     return $q1->qacosh(); }
                when ("atanh") {     return $q1->qatanh(); }
                when (["sum","product"]) {
                    if ($env->unit_mode) {
                        die CalcException->new("[_1] cannot work in unit mode.", $fname);
                    }
                    if (scalar(@children) != 5) {
                        die CalcException->new("[_1] should have four parameters.", $fname);
                    }
                    my $var = "".$children[2]->value;
                    if ($var !~ /^[a-zA-Z_][a-zA-Z_0-9]*$/) {
                        die CalcException->new("[_1]: wrong variable name", $fname);
                    }
                    if ($var eq "i") {
                        die CalcException->new("[_1]: please use another variable name, i is the imaginary number.", $fname);
                    }
                    my $initial = $env->getVariable($var);
                    my $var_value_1 = $children[3]->value;
                    my $var_value_2 = $children[4]->value;
                    if ($var_value_1 !~ /^[0-9]+$/) {
                        die CalcException->new("[_1]: the third parameter should be an integer", $fname);
                    }
                    if ($var_value_2 !~ /^[0-9]+$/) {
                        die CalcException->new("[_1]: the fourth parameter should be an integer", $fname);
                    }
                    if ($var_value_1 > $var_value_2) {
                        die CalcException->new("[_1]: are you trying to make me loop forever?", $fname);
                    }
                    my $result;
                    for (my $var_value=$var_value_1; $var_value <= $var_value_2; $var_value++) {
                        $env->setVariable($var, $var_value);
                        my $nq = $children[1]->calc($env);
                        if (!$nq->isa(Quantity) && !$nq->isa(QVector) && !$nq->isa(QMatrix)) {
                            die CalcException->new("[_1]: wrong type for a calculated value", $fname);
                        }
                        if (!defined $result) {
                            $result = $nq;
                        } elsif ($fname eq "sum") {
                            $result += $nq;
                        } else {
                            $result *= $nq;
                        }
                    }
                    $env->setVariable($var, $initial);
                    return $result;
                }
                when ("binomial") {
                    if (scalar(@children) != 3) {
                        die CalcException->new("[_1] should have two parameters.", $fname);
                    }
                    my $n = $children[1]->calc($env);
                    my $p = $children[2]->calc($env);
                    if (!$n->isa(Quantity) || !$p->isa(Quantity)) {
                        die CalcException->new("Wrong parameter type for function [_1]", $fname);
                    }
                    return $n->qfact() / ($p->qfact() * ($n - $p)->qfact());
                }
                when (["union","intersection"]) {
                    if (!defined $children[2]) {
                        die CalcException->new("Missing parameter for function [_1].", $fname);
                    }
                    my $p1 = $children[1]->calc($env);
                    my $p2 = $children[2]->calc($env);
                    if (!$p1->isa(QSet) && !$p1->isa(QInterval) && !$p1->isa(QIntervalUnion)) {
                        die CalcException->new("Wrong type for function [_1] (should be a set or interval).", $fname);
                    }
                    if ($fname eq "union") {
                        return $p1->union($p2);
                    } else {
                        return $p1->intersection($p2);
                    }
                }
                default {            die CalcException->new("Unknown function: [_1].",$fname); }
            }
        }
        when (VECTOR) {
            return $self->createVectorOrMatrix($env);
        }
        when (INTERVAL) {
            my @children = @{$self->children};
            if (scalar(@children) != 2) {
                die CalcException->new("Interval should have two parameters.");
            }
            my $qmin = $children[0]->calc($env);
            my $qmax = $children[1]->calc($env);
            my ($qminopen, $qmaxopen);
            given ($self->interval_type) {
                when (OPEN_OPEN) { $qminopen = 1; $qmaxopen = 1; }
                when (OPEN_CLOSED) { $qminopen = 1; $qmaxopen = 0; }
                when (CLOSED_OPEN) { $qminopen = 0; $qmaxopen = 1; }
                when (CLOSED_CLOSED) { $qminopen = 0; $qmaxopen = 0; }
            }
            return QInterval->new($qmin, $qmax, $qminopen, $qmaxopen);
        }
        when (SET) {
            my @t = ();
            foreach my $child (@{$self->children}) {
                push(@t, $child->calc($env));
            }
            return QSet->new(\@t);
        }
        when (SUBSCRIPT) {
            die CalcException->new("Subscript cannot be evaluated: [_1].", $self->value);
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
            die CalcException->new("Unknown node type: [_1].", $self->value);
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
                    if ($children[0]->type == SET && $children[1]->type == SET) {
                        return("union(".$children[0]->toMaxima().", ".$children[1]->toMaxima().")");
                    } else {
                        return("(".$children[0]->toMaxima()."+".$children[1]->toMaxima().")");
                    }
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
                when ("=") {
                    # NOTE: should we use is(...) to evaluate the expression ?
                    return("(".$children[0]->toMaxima()."=".$children[1]->toMaxima().")");
                }
                when ("<") {
                    return("(".$children[0]->toMaxima()."<".$children[1]->toMaxima().")");
                }
                when (">") {
                    return("(".$children[0]->toMaxima().">".$children[1]->toMaxima().")");
                }
                when ("<=") {
                    return("(".$children[0]->toMaxima()."<=".$children[1]->toMaxima().")");
                }
                when (">=") {
                    return("(".$children[0]->toMaxima().">=".$children[1]->toMaxima().")");
                }
                default {
                    die CalcException->new("Unknown operator: [_1].", $self->value);
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
        when (INTERVAL) {
            die CalcException->new("Maxima syntax: intervals are not implemented.");
            # see http://ieeexplore.ieee.org/xpls/icp.jsp?arnumber=5959544
            # "New Package in Maxima for Single-Valued Interval Computation on Real Numbers"
        }
        when (SET) {
            my @children = @{$self->children};
            my $s = "{";
            for (my $i=0; $i<scalar(@children); $i++) {
                if ($i != 0) {
                    $s .= ", ";
                }
                $s .= $children[$i]->toMaxima();
            }
            $s .= "}";
            return($s);
        }
        when (SUBSCRIPT) {
            my @children = @{$self->children};
            return("(".$children[0]->toMaxima()."_".$children[1]->toMaxima().")");
        }
    }
}

##
# Returns the equation as a string with the TeX syntax.
# @returns {string}
##
sub toTeX {
    my ( $self ) = @_;
    
    given ($self->type) {
        when (UNKNOWN) {
            die CalcException->new("Unknown node type: [_1].", $self->value);
        }
        when (NAME) {
            my $name = $self->value;
            if ($name =~ /^([a-zA-Z]+)([0-9]+)$/) {
                return($1."_{".$2."}");
            }
            my @greek = (
                "alpha", "beta", "gamma", "delta", "epsilon", "zeta",
                "eta", "theta", "iota", "kappa", "lambda", "mu",
                "nu", "xi", "omicron", "pi", "rho", "sigma",
                "tau", "upsilon", "phi", "chi", "psi", "omega",
                "Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta",
                "Eta", "Theta", "Iota", "Kappa", "Lambda", "Mu",
                "Nu", "Xi", "Omicron", "Pi", "Rho", "Sigma",
                "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega",
            );
            if ($name ~~ @greek) {
                return('\\'.$name);
            } elsif ($name eq "hbar") {
                return("\\hbar");
            } elsif ($name eq "inf") {
                return("\\infty");
            } elsif ($name eq "minf") {
                return("-\\infty");
            } else {
                return($name);
            }
        }
        when (NUMBER) {
            return $self->value;
        }
        when (OPERATOR) {
            my @children = @{$self->children};
            my $c0 = $children[0];
            my $c1 = $children[1];
            given ($self->value) {
                when ("+") {
                    # should we add parenthesis ? We need to check if there is a '-' to the left of c1
                    my $par = 0;
                    my $first = $c1;
                    while ($first->type == OPERATOR) {
                        if ($first->value eq "-" && scalar(@{$first->children}) == 1) {
                            $par = 1;
                            last;
                        } elsif ($first->value eq "+" || $first->value eq "-" || $first->value eq "*") {
                            $first = $first->children->[0];
                        } else {
                            last;
                        }
                    }
                    my $s = $c0->toTeX()." + ".$c1->toTeX();
                    if ($par) {
                        $s = "(".$s.")";
                    }
                    return $s;
                }
                when ("-") {
                    if (!defined $c1) {
                        return("-".$c0->toTeX());
                    } else {
                        my $s = $c0->toTeX()." - ";
                        my $par = ($c1->type == OPERATOR &&
                            ($c1->value eq "+" || $c1->value eq "-"));
                        if ($par) {
                            $s .= "(".$c1->toTeX().")";
                        } else {
                            $s .= $c1->toTeX();
                        }
                        return $s;
                    }
                }
                when ("*") {
                    my $par = ($c0->type == OPERATOR && ($c0->value eq "+" || $c0->value eq "-"));
                    my $s = $c0->toTeX();
                    if ($par) {
                        $s = "(".$s.")";
                    }
                    # should the x operator be visible ? We need to check if there is a number to the left of c1
                    my $firstinc1 = $c1;
                    while ($firstinc1->type == OPERATOR) {
                        $firstinc1 = $firstinc1->children->[0];
                    }
                    # ... and if it's an operation between vectors/matrices, the * operator should be displayed
                    # (it is ambiguous otherwise)
                    # note: this will not work if the matrix is calculated, for instance with 2[1;2]*[3;4]
                    if ($c0->type == VECTOR && $c1->type == VECTOR) {
                        $s .= " * ";
                    } elsif ($firstinc1->type == NUMBER) {
                        $s .= " \\times ";
                    } else {
                        $s .= " ";
                    }
                    $par = ($c1->type == OPERATOR && ($c1->value eq "+" || $c1->value eq "-"));
                    if ($par) {
                        $s .= "(".$c1->toTeX().")";
                    } else {
                        $s .= $c1->toTeX();
                    }
                    return $s;
                }
                when ("/") {
                    return("\\cfrac{".$c0->toTeX()."}{".$c1->toTeX()."}");
                }
                when ("^") {
                    my $par;
                    if ($c0->type == FUNCTION) {
                        if ($c0->value eq "sqrt" || $c0->value eq "abs" || $c0->value eq "matrix" ||
                                $c0->value eq "diff") {
                            $par = 0;
                        } else {
                            $par = 1;
                        }
                    } elsif ($c0->type == OPERATOR) {
                        $par = 1;
                    } else {
                        $par = 0;
                    }
                    if ($par) {
                        return("(".$c0->toTeX().")^{".$c1->toTeX()."}");
                    } else {
                        return($c0->toTeX()."^{".$c1->toTeX()."}");
                    }
                }
                when ("!") {
                    return($c0->toTeX()." !");
                }
                when ("%") {
                    return($c0->toTeX()." \\% ".$c1->toTeX());
                }
                when (".") {
                    # scalar product for vectors, multiplication for matrices
                    my $par = ($c0->type == OPERATOR && ($c0->value eq "+" || $c0->value eq "-"));
                    my $s = $c0->toTeX();
                    if ($par) {
                        $s = "(".$s.")";
                    }
                    $s .= " \\cdot ";
                    $par = ($c1->type == OPERATOR && ($c1->value eq "+" || $c1->value eq "-"));
                    if ($par) {
                        $s .= "(".$c1->toTeX().")";
                    } else {
                        $s .= $c1->toTeX();
                    }
                    return $s;
                }
                when ("`") {
                    return($c0->toTeX()." \\textrm{".$c1->toTeX()."}");
                }
                when ("=") {
                    return($c0->toTeX()." = ".$c1->toTeX());
                }
                when ("#") {
                    return($c0->toTeX()." \\not ".$c1->toTeX());
                }
                when ("<") {
                    return($c0->toTeX()." < ".$c1->toTeX());
                }
                when (">") {
                    return($c0->toTeX()." > ".$c1->toTeX());
                }
                when ("<=") {
                    return($c0->toTeX()." \\leq ".$c1->toTeX());
                }
                when (">=") {
                    return($c0->toTeX()." \\geq ".$c1->toTeX());
                }
                default {
                    die CalcException->new("Unknown operator: [_1].", $self->value);
                }
            }
        }
        when (FUNCTION) {
            my @children = @{$self->children};
            my $fname = $children[0]->value;
            my $c1 = $children[1];
            my $c2 = $children[2];
            my $c3 = $children[3];
            my $c4 = $children[4];
            
            given ($fname) {
                when ("sqrt") {   return "\\sqrt{".$c1->toTeX()."}"; }
                when ("abs") {    return "|".$c1->toTeX()."|"; }
                when ("exp") {    return "\\mathrm{e}^{".$c1->toTeX()."}"; }
                when ("diff") {
                    if (scalar(@children) == 3) {
                        return "\\frac{d}{d".$c2->toTeX()."} ".$c1->toTeX();
                    } else {
                        return "\\frac{d^{".$c3->toTeX()."}}{d ".$c2->toTeX().
                            "^{".$c3->toTeX()."}} ".$c1->toTeX();
                    }
                }
                when ("integrate") {
                    if (scalar(@children) == 3) {
                        return "\\int ".$c1->toTeX()." \\ d ".$c2->toTeX();
                    } else {
                        return "\\int_{".$c3->toTeX()."}^{".$c4->toTeX()."} ".
                            $c1->toTeX()." \\ d ".$c2->toTeX();
                    }
                }
                when ("sum") {
                    return "\\sum_{".$c2->toTeX()."=".$c3->toTeX().
                        "}^{".$c4->toTeX()."} ".$c1->toTeX();
                }
                when ("product") {
                    return "\\prod_{".$c2->toTeX()."=".$c3->toTeX().
                        "}^{".$c4->toTeX()."} ".$c1->toTeX();
                }
                when ("limit") {
                    if (scalar(@children) < 4) {
                        return "\\lim ".$c1->toTeX();
                    } elsif (scalar(@children) == 4) {
                        return "\\lim_{".$c2->toTeX()." \\to ".$c3->toTeX().
                        "}".$c1->toTeX();
                    } else {
                        return "\\lim_{".$c2->toTeX()." \\to ".$c3->toTeX().
                        (($c4->value eq "plus") ? "+" : "-").
                        "}".$c1->toTeX();
                    }
                }
                when ("binomial") {
                    return "\\binom{".$c1->toTeX()."}{".$c2->toTeX()."}";
                }
                when ("sin") {     return "\\sin ".$c1->toTeX(); }
                when ("cos") {     return "\\cos ".$c1->toTeX(); }
                when ("tan") {     return "\\tan ".$c1->toTeX(); }
                when ("asin") {    return "\\arcsin ".$c1->toTeX(); }
                when ("acos") {    return "\\arccos ".$c1->toTeX(); }
                when ("atan") {    return "\\arctan ".$c1->toTeX(); }
                when ("sinh") {    return "\\sinh ".$c1->toTeX(); }
                when ("cosh") {    return "\\cosh ".$c1->toTeX(); }
                when ("tanh") {    return "\\tanh ".$c1->toTeX(); }
                default {
                    my $s = $fname."(";
                    for (my $i=1; $i<scalar(@children); $i++) {
                        if ($i != 1) {
                            $s .= ", ";
                        }
                        $s .= $children[$i]->toTeX();
                    }
                    $s .= ")";
                    return($s);
                }
            }
        }
        when (VECTOR) {
            my @children = @{$self->children};
            my $s = "\\begin{pmatrix}";
            for (my $i=0; $i<scalar(@children); $i++) {
                if ($i != 0) {
                    $s .= " \\\\ ";
                }
                if ($children[0]->type == VECTOR) {
                    # matrix
                    for (my $j=0; $j<scalar(@{$children[$i]->children}); $j++) {
                        if ($j != 0) {
                            $s .= " & ";
                        }
                        $s .= $children[$i]->children->[$j]->toTeX();
                    }
                } else {
                    # vector
                    $s .= $children[$i]->toTeX();
                }
            }
            $s .= "\\end{pmatrix}";
            return($s);
        }
        when (INTERVAL) {
            my @children = @{$self->children};
            if (scalar(@children) != 2) {
                die CalcException->new("Interval should have two parameters.");
            }
            my ($qminopen, $qmaxopen);
            given ($self->interval_type) {
                when (OPEN_OPEN) { $qminopen = 1; $qmaxopen = 1; }
                when (OPEN_CLOSED) { $qminopen = 1; $qmaxopen = 0; }
                when (CLOSED_OPEN) { $qminopen = 0; $qmaxopen = 1; }
                when (CLOSED_CLOSED) { $qminopen = 0; $qmaxopen = 0; }
            }
            my $s = "\\left";
            if ($qminopen) {
                $s .= "(";
            } else {
                $s .= "[";
            }
            $s .= $children[0]->toTeX();
            $s .= ", ";
            $s .= $children[1]->toTeX();
            $s .= "\\right";
            if ($qmaxopen) {
                $s .= ")";
            } else {
                $s .= "]";
            }
            return($s);
        }
        when (SET) {
            my @children = @{$self->children};
            my $s = "\\left\\{ {";
            for (my $i=0; $i<scalar(@children); $i++) {
                if ($i != 0) {
                    $s .= ", ";
                }
                $s .= $children[$i]->toTeX();
            }
            $s .= "}\\right\\}";
            return($s);
        }
        when (SUBSCRIPT) {
            my @children = @{$self->children};
            return($children[0]->toTeX()."_{".$children[1]->toTeX()."}");
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
