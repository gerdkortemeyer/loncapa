# The LearningOnline Network with CAPA - LON-CAPA
# Parser
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
# Equation parser
##
package Apache::math::math_parser::Parser;

use strict;
use warnings;
use utf8;

use File::Util;

use aliased 'Apache::math::math_parser::Definitions';
use aliased 'Apache::math::math_parser::ENode';
use aliased 'Apache::math::math_parser::Operator';
use aliased 'Apache::math::math_parser::ParseException';
use aliased 'Apache::math::math_parser::Token';
use aliased 'Apache::math::math_parser::Tokenizer';

##
# Constructor
# @optional {boolean} implicit_operators - assume hidden multiplication and unit operators in some cases (unlike maxima)
# @optional {boolean} unit_mode - handle only numerical expressions with units (no variable)
##
sub new {
    my $class = shift;
    my $self = {
        _implicit_operators => shift // 0,
        _unit_mode => shift // 0,
        _defs => Definitions->new(),
    };
    $self->{_defs}->define();
    bless $self, $class;
    return $self;
}

# Attribute helpers

##
# Implicit operators ?
# @returns {boolean}
##
sub implicit_operators {
    my $self = shift;
    return $self->{_implicit_operators};
}

##
# Unit mode ?
# @returns {boolean}
##
sub unit_mode {
    my $self = shift;
    return $self->{_unit_mode};
}

##
# Definitions
# @returns {Definitions}
##
sub defs {
    my $self = shift;
    return $self->{_defs};
}

##
# Tokens
# @returns {Token[]}
##
sub tokens {
    my $self = shift;
    return $self->{_tokens};
}

##
# Current token
# @returns {Token}
##
sub current_token {
    my $self = shift;
    return $self->{_current_token};
}

##
# Current token number
# @returns {int}
##
sub token_nr {
    my $self = shift;
    return $self->{_token_nr};
}


##
# Returns the right node at the current token, based on top-down operator precedence.
# @param {integer} rbp - Right binding power
# @returns {ENode}
##
sub expression {
    my( $self, $rbp ) = @_;
    my $left; # ENode
    my $t = $self->current_token;
    if (! defined $t) {
        die ParseException->new("Expected something at the end",
            $self->tokens->[scalar(@{$self->tokens}) - 1]->to + 1);
    }
    $self->advance();
    if (! defined $t->op) {
        $left = ENode->new($t->type, undef, $t->value, undef);
    } elsif (! defined $t->op->nud) {
        die ParseException->new("Unexpected operator '[_1]'", $t->from, $t->from, $t->op->id);
    } else {
        $left = $t->op->nud->($t->op, $self);
    }
    while (defined $self->current_token && defined $self->current_token->op &&
            $rbp < $self->current_token->op->lbp) {
        $t = $self->current_token;
        $self->advance();
        $left = $t->op->led->($t->op, $self, $left);
    }
    return $left;
}

##
# Advance to the next token,
# expecting the given operator id if it is provided.
# Throws a ParseException if a given operator id is not found.
# @optional {string} id - Operator id
##
sub advance {
    my ( $self, $id ) = @_;
    if (defined $id && (!defined $self->current_token || !defined $self->current_token->op ||
            $self->current_token->op->id ne $id)) {
        if (!defined $self->current_token) {
            die ParseException->new("Expected '[_1]' at the end",
                $self->tokens->[scalar(@{$self->tokens}) - 1]->to + 1, undef, $id);
        } else {
            die ParseException->new("Expected '[_1]'", $self->current_token->from, undef, $id);
        }
    }
    if ($self->token_nr >= scalar(@{$self->tokens})) {
        $self->{_current_token} = undef;
        return;
    }
    $self->{_current_token} = $self->tokens->[$self->token_nr];
    $self->{_token_nr} += 1;
}


##
# Adds hidden multiplication and unit operators to the token stream
##
sub addHiddenOperators {
    my ( $self ) = @_;
    my $multiplication = $self->defs->findOperator("*");
    my $unit_operator = $self->defs->findOperator("`");
    my $in_units = 0; # we check if we are already in the units to avoid adding two ` operators inside
    my $in_exp = 0;
    for (my $i=0; $i<scalar(@{$self->tokens}) - 1; $i++) {
        my $token = $self->tokens->[$i];
        my $next_token = $self->tokens->[$i + 1];
        if ($self->unit_mode) {
            if ($token->value eq "`") {
                $in_units = 1;
            } elsif ($in_units) {
                if ($token->value eq "^") {
                    $in_exp = 1;
                } elsif ($in_exp && $token->type == Token->NUMBER) {
                    $in_exp = 0;
                } elsif (!$in_exp && $token->type == Token->NUMBER) {
                    $in_units = 0;
                } elsif ($token->type == Token->OPERATOR && index("*/^()", $token->value) == -1) {
                    $in_units = 0;
                } elsif ($token->type == Token->NAME && $next_token->value eq "(") {
                    $in_units = 0;
                }
            }
        }
        my $token_type = $token->type;
        my $next_token_type = $next_token->type;
        my $token_value = $token->value;
        my $next_token_value = $next_token->value;
        if (
                ($token_type == Token->NAME && $next_token_type == Token->NAME) ||
                ($token_type == Token->NUMBER && $next_token_type == Token->NAME) ||
                ($token_type == Token->NUMBER && $next_token_type == Token->NUMBER) ||
                ($token_type == Token->NUMBER && $next_token_value ~~ ["(","[","{"]) ||
                # ($token_type == Token->NAME && $next_token_value eq "(") ||
                # name ( could be a function call
                ($token_value ~~ [")","]","}"] && $next_token_type == Token->NAME) ||
                ($token_value ~~ [")","]","}"] && $next_token_type == Token->NUMBER) ||
                ($token_value ~~ [")","]","}"] && $next_token_value eq "(")
           ) {
            # support for things like "(1/2) (m/s)" is complex...
            my $units = ($self->unit_mode && !$in_units &&
                ($token_type == Token->NUMBER || $token_value ~~ [")","]","}"]) &&
                ($next_token_type == Token->NAME ||
                    ($next_token_value ~~ ["(","[","{"] && scalar(@{$self->tokens}) > $i + 2 &&
                    $self->tokens->[$i + 2]->type == Token->NAME)));
            if ($units) {
                my( $test_token, $index_test);
                if ($next_token_type == Token->NAME) {
                    $test_token = $next_token;
                    $index_test = $i + 1;
                } else {
                    # for instance for "2 (m/s)"
                    $index_test = $i + 2;
                    $test_token = $self->tokens->[$index_test];
                }
                if (scalar(@{$self->tokens}) > $index_test + 1 && $self->tokens->[$index_test + 1]->value eq "(") {
                    my @known_functions = ("pow", "sqrt", "abs", "exp", "factorial", "diff",
                        "integrate", "sum", "product", "limit", "binomial", "matrix",
                        "ln", "log", "log10", "mod", "sgn", "ceil", "floor",
                        "sin", "cos", "tan", "asin", "acos", "atan", "atan2",
                        "sinh", "cosh", "tanh", "asinh", "acosh", "atanh");
                    for (my $j=0; $j<scalar(@known_functions); $j++) {
                        if ($test_token->value eq $known_functions[$j]) {
                            $units = 0;
                            last;
                        }
                    }
                }
            }
            my $new_token;
            if ($units) {
                $new_token = Token->new(Token->OPERATOR, $next_token->from,
                    $next_token->from, $unit_operator->id, $unit_operator);
            } else {
                $new_token = Token->new(Token->OPERATOR, $next_token->from,
                    $next_token->from, $multiplication->id, $multiplication);
            }
            splice(@{$self->{_tokens}}, $i+1, 0, $new_token);
        }
    }
}

##
# Parse the string, returning an ENode tree.
# @param {string} text - The text to parse.
# @returns {ENode}
##
sub parse {
    my ( $self, $text ) = @_;
    
    my $tokenizer = Tokenizer->new($self->defs, $text);
    @{$self->{_tokens}} = $tokenizer->tokenize();
    if (scalar(@{$self->tokens}) == 0) {
        die ParseException->new("No token found");
    }
    if ($self->implicit_operators) {
        $self->addHiddenOperators();
    }
    $self->{_token_nr} = 0;
    $self->{_current_token} = $self->tokens->[$self->token_nr];
    $self->advance();
    my $root = $self->expression(0);
    if (defined $self->current_token) {
        die ParseException->new("Expected the end", $self->current_token->from);
    }
    return $root;
}

1;
__END__
