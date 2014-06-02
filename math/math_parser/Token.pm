# The LearningOnline Network with CAPA - LON-CAPA
# A parser token.
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
# A token from the equation text
##
package Apache::math::math_parser::Token;

use strict;
use warnings;
use utf8;

use enum qw(UNKNOWN NAME NUMBER OPERATOR);

##
# Constructor
# @param {integer} type - Token type: Token::UNKNOWN, NAME, NUMBER, OPERATOR
# @param {integer} from - Index of the token's first character
# @param {integer} to - Index of the token's last character
# @param {string} value - String content of the token
# @optional {Operator} op - The matching operator
##
sub new {
    my $class = shift;
    my $self = {
        _type => shift,
        _from => shift,
        _to => shift,
        _value => shift,
        _op => shift,
    };
    bless $self, $class;
    return $self;
}

# Attribute helpers

sub type {
    my $self = shift;
    return $self->{_type};
}
sub from {
    my $self = shift;
    return $self->{_from};
}
sub to {
    my $self = shift;
    return $self->{_to};
}
sub value {
    my $self = shift;
    return $self->{_value};
}
sub op {
    my $self = shift;
    return $self->{_op};
}

1;
__END__
