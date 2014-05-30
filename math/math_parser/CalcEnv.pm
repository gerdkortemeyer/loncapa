# The LearningOnline Network with CAPA - LON-CAPA
# QVector
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
# Calculation environment, using either units or variables.
##
package Apache::math::math_parser::CalcEnv;

use strict;
use warnings;

use aliased 'Apache::math::math_parser::Units';

##
# Constructor
# @param {boolean} unit_mode
##
sub new {
    my $class = shift;
    my $self = {
        _unit_mode => shift // 0,
    };
    if ($self->{_unit_mode}) {
        $self->{_units} = Units->new();
    } else {
        $self->{_variables} = { }; # hash variable name -> value
    }
    bless $self, $class;
    return $self;
}

# Attribute helpers
sub unit_mode {
    my $self = shift;
    return $self->{_unit_mode};
}
sub units {
    my $self = shift;
    return $self->{_units};
}
sub variables {
    my $self = shift;
    return $self->{_variables};
}

##
# Changes an existing unit or defines a new one.
# @param {string} symbol - name used in math expressions
# @param {string} convert - SI equivalent or using other units to help converting to SI
##
sub setUnit {
    my( $self, $symbol, $convert ) = @_;
    $self->units->{_derived}->{$symbol} = $convert;
}

##
# Changes an existing variable value or defines a new one.
# @param {string} symbol - name used in math expressions
# @param {float} value - number value (not unit !)
##
sub setVariable {
    my( $self, $symbol, $value ) = @_;
    $self->variables->{$symbol} = $value;
}

##
# Returns a variable value or undef.
# @param {string} symbol - name used in math expressions
##
sub getVariable {
    my( $self, $symbol ) = @_;
    return $self->variables->{$symbol};
}

##
# Converts a unit name into a Quantity. Throws an exception if the unit is not known.
# @param {string} name - the unit name
# @returns {Quantity}
##
sub convertToSI {
    my ( $self, $name ) = @_;
    return $self->units->convertToSI($self, $name);
}


1;
__END__
