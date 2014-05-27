# The LearningOnline Network with CAPA - LON-CAPA
# Operator definitions
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
# Operator definitions (see function define() at the end).
##
package Apache::math::math_parser::Definitions;

use strict;
use warnings;

use Apache::math::math_parser::ENode;
use Apache::math::math_parser::Operator;
use Apache::math::math_parser::ParseException;
use Apache::math::math_parser::Parser;
use Apache::math::math_parser::Token;

use constant ARG_SEPARATOR => ";";
use constant DECIMAL_SIGN_1 => ".";
use constant DECIMAL_SIGN_2 => ",";

##
# Constructor
##
sub new {
    my $class = shift;
    my $self = {
        _operators => [], # Array of Operator
    };
    my $constants_txt = Apache::lc_file_utils::readfile(Apache::lc_parameters::lc_conf_dir()."constants.json");
    $self->{_constants} = Apache::lc_json_utils::json_to_perl($constants_txt);
    bless $self, $class;
    return $self;
}

# Attribute helpers
sub operators {
    my $self = shift;
    return $self->{_operators};
}
sub constants {
    my $self = shift;
    return $self->{_constants};
}

##
# Creates a new operator.
# @param {string} id - Operator id (text used to recognize it)
# @param {integer} arity - Operator::UNARY, BINARY or TERNARY
# @param {integer} lbp - Left binding power
# @param {integer} rbp - Right binding power
# @param {function} nud - Null denotation function
# @param {function} led - Left denotation function
##
sub operator {
    my( $self, $id, $arity, $lbp, $rbp, $nud, $led ) = @_;
    push(@{$self->{_operators}}, new Operator($id, $arity, $lbp, $rbp, $nud, $led));
}

##
# Creates a new separator operator.
# @param {string} id - Operator id (text used to recognize it)
##
sub separator {
    my( $self, $id ) = @_;
    $self->operator($id, Operator::BINARY, 0, 0);
}

##
# Default led function for infix.
# @param {Operator} op
# @param {Parser} p
# @param {ENode} left
# @returns {ENode}
##
sub infixDefaultLed {
    my( $op, $p, $left ) = @_;
    my @children = ($left, $p->expression($op->rbp));
    return new ENode(ENode::OPERATOR, $op, $op->id, \@children);
}

##
# Creates a new infix operator.
# @param {string} id - Operator id (text used to recognize it)
# @param {integer} lbp - Left binding power
# @param {integer} rbp - Right binding power
# @optional {function} led - Left denotation function
##
sub infix {
    my( $self, $id, $lbp, $rbp, $led ) = @_;
    my $arity = Operator::BINARY;
    my $nud = undef;
    if (!defined $led) {
        $led = \&infixDefaultLed;
    }
    $self->operator($id, $arity, $lbp, $rbp, $nud, $led);
}

##
# Default nud function for prefix.
# @param {Operator} op
# @param {Parser} p
# @returns {ENode}
##
sub prefixDefaultNud {
    my( $op, $p ) = @_;
    my @children = ($p->expression($op->rbp));
    return new ENode(ENode::OPERATOR, $op, $op->id, \@children);
}

##
# Creates a new prefix operator.
# @param {string} id - Operator id (text used to recognize it)
# @param {integer} rbp - Right binding power
# @optional {function} nud - Null denotation function
##
sub prefix {
    my( $self, $id, $rbp, $nud ) = @_;
    my $arity = Operator::UNARY;
    my $lbp = 0;
    if (!defined $nud) {
        $nud = \&prefixDefaultNud;
    }
    my $led = undef;
    $self->operator($id, $arity, $lbp, $rbp, $nud, $led);
}

##
# Default led function for suffix.
# @param {Operator} op
# @param {Parser} p
# @param {ENode} left
# @returns {ENode}
##
sub suffixDefaultLed {
    my( $op, $p, $left ) = @_;
    my @children = ($left);
    return new ENode(ENode::OPERATOR, $op, $op->id, \@children);
}

##
# Creates a new suffix operator.
# @param {string} id - Operator id (text used to recognize it)
# @param {integer} lbp - Left binding power
# @optional {function} led - Left denotation function
##
sub suffix {
    my( $self, $id, $lbp, $led ) = @_;
    my $arity = Operator::UNARY;
    my $rbp = 0;
    my $nud = undef;
    if (!defined $led) {
        $led = \&suffixDefaultLed;
    }
    $self->operator($id, $arity, $lbp, $rbp, $nud, $led);
}

##
# Returns the defined operator with the given id
# @param {string} id - Operator id (text used to recognize it)
# @returns {Operator}
##
sub findOperator {
    my( $self, $id ) = @_;
    for (my $i=0; $i<scalar(@{$self->operators}); $i++) {
        if (@{$self->operators}[$i]->id eq $id) {
            return(@{$self->operators}[$i]);
        }
    }
    return undef;
}

##
# Led function for the ` (units) operator
# @param {Operator} op
# @param {Parser} p
# @param {ENode} left
# @returns {ENode}
##
sub unitsLed {
    my( $op, $p, $left ) = @_;
    # this led for units gathers all the units in an ENode
    my $right = $p->expression(125);
    while (defined $p->current_token && index("*/", $p->current_token->value) != -1) {
        my $token2 = $p->tokens->[$p->token_nr];
        if (!defined $token2) {
            last;
        }
        if ($token2->type != Token::NAME && $token2->value ne "(") {
            last;
        }
        my $token3 = $p->tokens->[$p->token_nr + 1];
        if (defined $token3 && ($token3->value eq "(" || $token3->type == Token::NUMBER)) {
            last;
        }
        # a check for constant names here is not needed because constant names are replaced in the tokenizer
        my $t = $p->current_token;
        $p->advance();
        $right = $t->op->led->($t->op, $p, $right);
    }
    my @children = ($left, $right);
    return new ENode(ENode::OPERATOR, $op, $op->id, \@children);
}

##
# nud function for the ( operator (used to parse mathematical sub-expressions)
# @param {Operator} op
# @param {Parser} p
# @returns {ENode}
##
sub parenthesisNud {
    my( $op, $p ) = @_;
    my $e = $p->expression(0);
    $p->advance(")");
    return $e;
}

##
# Led function for the ( operator (used to parse function calls)
# @param {Operator} op
# @param {Parser} p
# @param {ENode} left
# @returns {ENode}
##
sub parenthesisLed {
    my( $op, $p, $left ) = @_;
    if ($left->type != ENode::NAME && $left->type != ENode::SUBSCRIPT) {
        die new ParseException("Function name expected before a parenthesis.", $p->tokens->[$p->token_nr - 1]->from);
    }
    my @children = ($left);
    if ((!defined $p->current_token) || (!defined $p->current_token->op) || ($p->current_token->op->id ne ")")) {
        while (1) {
            push(@children, $p->expression(0));
            if (!defined $p->current_token || !defined $p->current_token->op || $p->current_token->op->id ne Definitions::ARG_SEPARATOR) {
                last;
            }
            $p->advance(Definitions::ARG_SEPARATOR);
        }
    }
    $p->advance(")");
    return new ENode(ENode::FUNCTION, $op, $op->id, \@children);
}

##
# nud function for the [ operator (used to parse vectors)
# @param {Operator} op
# @param {Parser} p
# @returns {ENode}
##
sub vectorNud {
    my( $op, $p ) = @_;
    my @children = ();
    if (!defined $p->current_token || !defined $p->current_token->op || $p->current_token->op->id ne "]") {
        while (1) {
            push(@children, $p->expression(0));
            if (!defined $p->current_token || !defined $p->current_token->op || $p->current_token->op->id ne Definitions::ARG_SEPARATOR) {
                last;
            }
            $p->advance(Definitions::ARG_SEPARATOR);
        }
    }
    $p->advance("]");
    return new ENode(ENode::VECTOR, $op, undef, \@children);
}

##
# Led function for the [ operator (used to parse subscript)
# @param {Operator} op
# @param {Parser} p
# @param {ENode} left
# @returns {ENode}
##
sub subscriptLed {
    my( $op, $p, $left ) = @_;
    if ($left->type != ENode::NAME && $left->type != ENode::SUBSCRIPT) {
        die new ParseException("Name expected before a square bracket.", $p->tokens->[$p->token_nr - 1]->from);
    }
    my @children = ($left);
    if (!defined $p->current_token || !defined $p->current_token->op || $p->current_token->op->id != "]") {
        while (1) {
            push(@children, $p->expression(0));
            if (!defined $p->current_token || !defined $p->current_token->op || $p->current_token->op->id ne Definitions::ARG_SEPARATOR) {
                last;
            }
            $p->advance(Definitions::ARG_SEPARATOR);
        }
    }
    $p->advance("]");
    return new ENode(ENode::SUBSCRIPT, $op, "[", \@children);
}

##
# Defines all the operators.
##
sub define {
    my( $self ) = @_;
    $self->suffix("!", 160);
    $self->infix("^", 140, 139);
    $self->infix(".", 130, 129);
    $self->infix("`", 125, 125, \&unitsLed);
    $self->infix("*", 120, 120);
    $self->infix("/", 120, 120);
    $self->infix("%", 120, 120);
    $self->infix("+", 100, 100);
    $self->operator("-", Operator::BINARY, 100, 134, \&prefixDefaultNud, sub {
        my( $op, $p, $left ) = @_;
        my @children = ($left, $p->expression(100));
        return new ENode(ENode::OPERATOR, $op, $op->id, \@children);
    });
    $self->infix("=", 80, 80);
    $self->infix("#", 80, 80);
    $self->infix("<=", 80, 80);
    $self->infix(">=", 80, 80);
    $self->infix("<", 80, 80);
    $self->infix(">", 80, 80);
    
    $self->separator(")");
    $self->separator(Definitions::ARG_SEPARATOR);
    $self->operator("(", Operator::BINARY, 200, 200, \&parenthesisNud, \&parenthesisLed);
    
    $self->separator("]");
    $self->operator("[", Operator::BINARY, 200, 70, \&vectorNud, \&subscriptLed);
}


1;
__END__
