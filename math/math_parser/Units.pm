# The LearningOnline Network with CAPA - LON-CAPA
# Units
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
# Loads and converts units
##
package Apache::math::math_parser::Units;

use strict;
use warnings;
use utf8;

use Apache::lc_file_utils;
use Apache::lc_json_utils;
use Apache::lc_parameters;

use aliased 'Apache::math::math_parser::CalcException';
use aliased 'Apache::math::math_parser::Parser';
use aliased 'Apache::math::math_parser::Quantity';

##
# Constructor
##
sub new {
    my $class = shift;
    my $self = {
        _base => [], # array with the names
        _prefix => {}, # hash symbol -> factor
        _derived => {}, # hash symbol -> convert
        _parser => Parser->new(1, 1),
    };
    bless $self, $class;
    $self->loadUnits();
    return $self;
}

# Attribute helpers

sub base {
    my $self = shift;
    return $self->{_base};
}
sub prefix {
    my $self = shift;
    return $self->{_prefix};
}
sub derived {
    my $self = shift;
    return $self->{_derived};
}
sub parser {
    my $self = shift;
    return $self->{_parser};
}

##
# Loads units from units.json
##
sub loadUnits {
    my ( $self ) = @_;
    my $units_txt = Apache::lc_file_utils::readfile(Apache::lc_parameters::lc_conf_dir()."units.json");
    my $jsunits = Apache::lc_json_utils::json_to_perl($units_txt);
    for (my $i=0; $i < scalar(@{$jsunits->{"base"}}); $i++) {
        my $base = $jsunits->{"base"}->[$i];
        push(@{$self->{_base}}, $base->{"symbol"});
    }
    for (my $i=0; $i < scalar(@{$jsunits->{"prefix"}}); $i++) {
        my $prefix = $jsunits->{"prefix"}->[$i];
        $self->{_prefix}->{$prefix->{"symbol"}} = $prefix->{"factor"};
    }
    for (my $i=0; $i < scalar(@{$jsunits->{"derived"}}); $i++) {
        my $derived = $jsunits->{"derived"}->[$i];
        $self->{_derived}->{$derived->{"symbol"}} = $derived->{"convert"};
    }
}

##
# Converts a unit name into a Quantity. Throws an exception if the unit is not known.
# @param {CalcEnv} env - Calculation environment
# @param {string} name - the unit name
# @returns {Quantity}
##
sub convertToSI {
    my ( $self, $env, $name ) = @_;
    
    # possible speed optimization: we could cache the result
    
    # check derived units first
    my $convert = $self->derived->{$name};
    if (defined $convert) {
        my $root = $self->parser->parse($convert);
        return $root->calc($env);
    }
    # then check base units, without or with a prefix
    for (my $i=0; $i < scalar(@{$self->base}); $i++) {
        my $base = $self->base->[$i];
        if ($name eq $base) {
            return $self->baseQuantity($base);
        } else {
            my $base2;
            if ($base eq "kg") {
                $base2 = "g";
            } else {
                $base2 = $base;
            }
            if ($name =~ /$base2$/) {
                # look for a prefix
                my $prefix = $self->prefix->{substr($name, 0, length($name) - length($base2))};
                if (defined $prefix) {
                    my $v = $prefix;
                    $v =~ s/10\^/1E/;
                    if ($base2 eq "g") {
                        $v /= 1000;
                    }
                    return $self->baseQuantity($base) * Quantity->new($v);
                }
            }
        }
    }
    # now check derived units with a prefix
    foreach my $derived_name (keys(%{$self->derived})) {
        if ($name =~ /$derived_name$/) {
            my $prefix_v = $self->prefix->{substr($name, 0, length($name) - length($derived_name))};
            if (defined $prefix_v) {
                $prefix_v =~ s/10\^/1E/;
                my $convert = $self->derived->{$derived_name};
                my $root = $self->parser->parse($convert);
                my $derived_v = $root->calc($env);
                return $derived_v * Quantity->new($prefix_v);
            }
        }
    }
    die CalcException->new("Unit not found: [_1]", $name);
}

##
# Returns the Quantity for a base unit name
# @param {string} name - the unit name
# @returns {Quantity}
##
sub baseQuantity {
    my ( $self, $name ) = @_;
    my %h = (s => 0, m => 0, kg => 0, K => 0, A => 0, mol => 0, cd => 0);
    $h{$name} = 1;
    return Quantity->new(1, \%h);
}

1;
__END__
