# The LearningOnline Network with CAPA - LON-CAPA
# String tokenizer
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
# String tokenizer. Recognizes only names, numbers, and parser operators.
##
package Apache::math::math_parser::Tokenizer;

use strict;
use warnings;
use utf8;

use aliased 'Apache::math::math_parser::Definitions';
use aliased 'Apache::math::math_parser::ParseException';
use aliased 'Apache::math::math_parser::Token';

##
# @constructor
# @param {Definitions} defs - Operator definitions
# @param {string} text - The text to tokenize
##
sub new {
    my $class = shift;
    my $self = {
        _defs => shift,
        _text => shift,
    };
    bless $self, $class;
    return $self;
}

# Attribute helpers

##
# Operator definitions
# @returns {Definitions}
##
sub defs {
    my $self = shift;
    return $self->{_defs};
}

##
# The text to tokenize
# @returns {string}
##
sub text {
    my $self = shift;
    return $self->{_text};
}


##
# Tokenizes the text.
# Can throw a ParseException.
# @returns {Token[]}
##
sub tokenize {
    my( $self ) = @_;
    my( $text, $c, $i, $from, @tokens, $value );
    my @operators = @{$self->defs->operators};
    my $dec1 = Definitions->DECIMAL_SIGN_1;
    my $dec2 = Definitions->DECIMAL_SIGN_2;
    
    $text = $self->text;
    if (!defined $text) {
        die "Math Tokenizer: undefined text";
    }
    $i = 0;
    $c = $i < length($text) ? substr($text, $i, 1) : '';
    @tokens = ();
    
main:
    while ($c ne '') {
        $from = $i;
        
        # ignore whitespace
        if ($c le ' ') {
            $i++;
            $c = $i < length($text) ? substr($text, $i, 1) : '';
            next;
        }
        
        # check for numbers before operators
        # (numbers starting with . will not be confused with the . operator)
        if (($c ge '0' && $c le '9') ||
                (($c eq $dec1 || $c eq $dec2) &&
                (substr($text, $i+1, 1) ge '0' && substr($text, $i+1, 1) le '9'))) {
            $value = '';
            
            if ($c ne $dec1 && $c ne $dec2) {
                $i++;
                $value .= $c;
                # Look for more digits.
                for (;;) {
                    $c = $i < length($text) ? substr($text, $i, 1) : '';
                    if ($c lt '0' || $c gt '9') {
                        last;
                    }
                    $i++;
                    $value .= $c;
                }
            }
            
            # Look for a decimal fraction part.
            if ($c eq $dec1 || $c eq $dec2) {
                $i++;
                $value .= $c;
                for (;;) {
                    $c = $i < length($text) ? substr($text, $i, 1) : '';
                    if ($c lt '0' || $c gt '9') {
                        last;
                    }
                    $i++;
                    $value .= $c;
                }
            }
            
            # Look for an exponent part.
            if ($c eq 'e' || $c eq 'E') {
                $i++;
                $value .= $c;
                $c = $i < length($text) ? substr($text, $i, 1) : '';
                if ($c eq '-' || $c eq '+') {
                    $i++;
                    $value .= $c;
                    $c = $i < length($text) ? substr($text, $i, 1) : '';
                }
                if ($c lt '0' || $c gt '9') {
                    # syntax error in number exponent
                    die ParseException->new("Syntax error in number exponent.", $from, $i);
                }
                do {
                    $i++;
                    $value .= $c;
                    $c = $i < length($text) ? substr($text, $i, 1) : '';
                } while ($c ge '0' && $c le '9');
            }
            
            # Convert the string value to a number. If it is finite, then it is a good token.
            my $n = eval "\$value =~ tr/".$dec1.$dec2."/../";
            if (!($n == 9**9**9 || $n == -9**9**9 || ! defined( $n <=> 9**9**9 ))) {
                push(@tokens, Token->new(Token->NUMBER, $from, $i - 1, $value));
                next;
            } else {
                # syntax error in number
                die ParseException->new("Syntax error in number.", $from, $i);
            }
        }
        
        # check for operators before names (they could be confused with
        # variables if they don't use special characters)
        for (my $iop = 0; $iop < scalar(@operators); $iop++) {
            my $op = $operators[$iop];
            my $opid = $op->id;
            if (substr($text, $i, length($opid)) eq $opid) {
                $i += length($op->id);
                $c = $i < length($text) ? substr($text, $i, 1) : '';
                push(@tokens, Token->new(Token->OPERATOR, $from, $i - 1, $op->id, $op));
                next main;
            }
        }
        
        # names
        if (($c ge 'a' && $c le 'z') || ($c ge 'A' && $c le 'Z')) {
            $value = $c;
            $i++;
            for (;;) {
                $c = $i < length($text) ? substr($text, $i, 1) : '';
                if (($c ge 'a' && $c le 'z') || ($c ge 'A' && $c le 'Z') ||
                        ($c ge '0' && $c le '9') || $c eq '_') {
                    $value .= $c;
                    $i++;
                } else {
                    last;
                }
            }
            # "i" is turned into a NUMBER token
            if ($value eq "i") {
                push(@tokens, Token->new(Token->NUMBER, $from, $i - 1, $value));
                next;
            }
            # if it is a constant, replace it by its value instead of adding a NAME token
            foreach my $cst_name (keys %{$self->defs->constants}) {
                if ($value eq $cst_name) {
                    my %cst = %{$self->defs->constants->{$cst_name}};
                    my $cst_value = $cst{"value"};
                    my $cst_units = $cst{"units"};
                    $i = $i - length($value);
                    my $s;
                    if ($cst_units) {
                        $s = "(".$cst_value."`(".$cst_units."))";
                    } else {
                        $s = "(".$cst_value.")";
                    }
                    substr($text, $i, length($value), $s);
                    $c = $i < length($text) ? substr($text, $i, 1) : '';
                    next main;
                }
            }
            push(@tokens, Token->new(Token->NAME, $from, $i - 1, $value));
            next;
        }
        
        # unrecognized operator
        die ParseException->new("Unrecognized operator.", $from, $i);
    }
    return @tokens;
}

1;
__END__
