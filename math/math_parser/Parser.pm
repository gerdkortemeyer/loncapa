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
package Parser;

use strict;
use warnings;

use File::Util;
use lc_json_utils;

use Definitions;
use ENode;
use Operator;
use ParseException;
use Token;
use Tokenizer;

##
# Constructor
# @optional {boolean} accept_bad_syntax - assume hidden multiplication operators in some cases (unlike maxima)
# @optional {boolean} unit_mode - handle only numerical expressions with units (no variable)
##
sub new {
    my $class = shift;
    my $self = {
        _accept_bad_syntax => shift // 0,
        _unit_mode => shift // 0,
        _defs => new Definitions(),
        _operators => undef, # operator hash table
        _oph => {},
    };
    $self->{_defs}->define();
    $self->{_operators} = $self->{_defs}->operators;
    foreach my $op (@{$self->{_operators}}) {
        $self->{_oph}{$op->{_id}} = $op;
    }
    bless $self, $class;
    return $self;
}

# Attribute helpers
sub accept_bad_syntax {
    my $self = shift;
    return $self->{_accept_bad_syntax};
}
sub unit_mode {
    my $self = shift;
    return $self->{_unit_mode};
}
sub defs {
    my $self = shift;
    return $self->{_defs};
}
sub operators {
    my $self = shift;
    return $self->{_operators};
}
sub oph {
    my $self = shift;
    return $self->{_oph};
}
sub tokens {
    my $self = shift;
    return $self->{_tokens};
}
sub current_token {
    my $self = shift;
    return $self->{_current_token};
}
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
        die new ParseException("Expected something at the end",
            $self->tokens->[scalar(@{$self->tokens}) - 1]->to + 1);
    }
    $self->advance();
    if (! defined $t->op) {
        $left = new ENode($t->type, undef, $t->value, undef);
    } elsif (! defined $t->op->nud) {
        die new ParseException("Unexpected operator '" + $t->op->id + "'", $t->from);
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
            die new ParseException("Expected '" . $id . "' at the end",
                $self->tokens->[scalar(@{$self->tokens}) - 1]->to + 1);
        } else {
            die new ParseException("Expected '" . $id . "'", $self->current_token->from);
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
# Adds hidden multiplication operators to the token stream
##
sub addHiddenOperators {
    my ( $self ) = @_;
    my $multiplication = $self->defs->findOperator("*");
    my $unit_operator = $self->defs->findOperator("`");
    for (my $i=0; $i<scalar(@{$self->tokens}) - 1; $i++) {
        my $token = $self->tokens->[$i];
        my $next_token = $self->tokens->[$i + 1];
        if (
                ($token->type == Token::NAME && $next_token->type == Token::NAME) ||
                ($token->type == Token::NUMBER && $next_token->type == Token::NAME) ||
                ($token->type == Token::NUMBER && $next_token->type == Token::NUMBER) ||
                ($token->type == Token::NUMBER && $next_token->value eq "(") ||
                # ($token->type == Token::NAME && $next_token->value eq "(") ||
                # name ( could be a function call
                ($token->value eq ")" && $next_token->type == Token::NAME) ||
                ($token->value eq ")" && $next_token->type == Token::NUMBER) ||
                ($token->value eq ")" && $next_token->value eq "(")
           ) {
            my $units = ($self->unit_mode && $token->type == Token::NUMBER && $next_token->type == Token::NAME);
            if ($units) {
                if (scalar(@{$self->tokens}) > $i + 2 && $self->tokens->[$i + 2]->value eq "(") {
                    my @known_functions = ("sqrt", "abs", "exp", "factorial", "diff",
                        "integrate", "sum", "product", "limit", "binomial", "matrix");
                    for (my $j=0; $j<=scalar(@known_functions); $j++) {
                        if ($next_token->value eq $known_functions[$j]) {
                            $units = 0;
                            last;
                        }
                    }
                }
            }
            my $new_token;
            if ($units) {
                $new_token = new Token(Token::OPERATOR, $next_token->from,
                    $next_token->from, $unit_operator->id, $unit_operator);
            } else {
                $new_token = new Token(Token::OPERATOR, $next_token->from,
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
    
    my $tokenizer = new Tokenizer($self->defs, $text);
    @{$self->{_tokens}} = $tokenizer->tokenize();
    if (scalar(@{$self->tokens}) == 0) {
        die "No token found";
    }
    if ($self->accept_bad_syntax) {
        $self->addHiddenOperators();
    }
    $self->{_token_nr} = 0;
    $self->{_current_token} = $self->tokens->[$self->token_nr];
    $self->advance();
    my $root = $self->expression(0);
    if (defined $self->current_token) {
        die new ParseException("Expected the end", $self->current_token->from);
    }
    return $root;
}

1;
__END__
