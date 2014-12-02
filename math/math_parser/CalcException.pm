# The LearningOnline Network with CAPA - LON-CAPA
# Calculation exception
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
# Calculation exception
##
package Apache::math::math_parser::CalcException;

use strict;
use warnings;
use utf8;

use Apache::lc_ui_localize;

use overload '""' => \&toString;

##
# Constructor
# @param {string} msg - error message, using [_1] for the first parameter
# @param {...string} param - parameters for the message
##
sub new {
    my $class = shift;
    my $self = {
        _msg => shift,
        _params => [],
    };
    while (@_) {
        push(@{$self->{_params}}, shift);
    }
    bless $self, $class;
    return $self;
}

# Attribute helpers

##
# Error message, using [_1] for the first parameter.
# @returns {string}
##
sub msg {
    my $self = shift;
    return $self->{_msg};
}

##
# Parameters for the message.
# @returns {string[]}
##
sub params {
    my $self = shift;
    return $self->{_params};
}


##
# Returns the exception as a string, for debug only.
# @returns {string}
##
sub toString {
    my $self = shift;
    my $s = "Calculation error: ".$self->msg;
    if (scalar(@{$self->params}) > 0) {
        $s .= ", ".join(", ", @{$self->params});
    }
    return $s;
}

##
# Returns the error message localized for the user interface.
# @returns {string}
##
sub getLocalizedMessage {
    my $self = shift;
    return mt("Calculation error: [_1]", mt($self->msg, @{$self->params}));
}

1;
__END__
