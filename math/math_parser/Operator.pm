# The LearningOnline Network with CAPA - LON-CAPA
# Parser operator
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
# Parser operator, like "(".
##
package Apache::math::math_parser::Operator;

use strict;
use warnings;
use utf8;

use enum qw(UNKNOWN UNARY BINARY TERNARY);

##
# Constructor
# @param {string} id - Characters used to recognize the operator
# @param {integer} arity (Operator::UNKNOWN, UNARY, BINARY, TERNARY)
# @param {integer} lbp - left binding power
# @param {integer} rbp - right binding power
# @param {nudFunction} nud - Null denotation function. Parameters: Parser p. Returns: ENode.
# @param {ledFunction} led - Left denotation function Parameters: Parser p, ENode left. Returns: ENode.
##
sub new {
    my $class = shift;
    my $self = {
        _id => shift,
        _arity => shift,
        _lbp => shift,
        _rbp => shift,
        _nud => shift,
        _led => shift,
    };
    bless $self, $class;
    return $self;
}

# Attribute helpers

sub id {
    my $self = shift;
    return $self->{_id};
}
sub arity {
    my $self = shift;
    return $self->{_arity};
}
sub lbp {
    my $self = shift;
    return $self->{_lbp};
}
sub rbp {
    my $self = shift;
    return $self->{_rbp};
}
sub nud {
    my $self = shift;
    return $self->{_nud};
}
sub led {
    my $self = shift;
    return $self->{_led};
}

1;
__END__
