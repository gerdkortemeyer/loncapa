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
# @param {string} msg - Error message
##
sub new {
    my $class = shift;
    my $self = {
        _msg => shift,
    };
    bless $self, $class;
    return $self;
}

##
# Returns the exception as a string, for debug
# @returns {string}
##
sub toString {
    my $self = shift;
    return mt("Calculation error: ").$self->{_msg};
}

1;
__END__
