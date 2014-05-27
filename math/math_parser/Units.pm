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
package Units;

use strict;
use warnings;

use Parser;
use Quantity;

##
# Constructor
##
sub new {
    my $class = shift;
    my $self = {
        _base => [], # array with the names
        _prefix => {}, # hash symbol -> factor
        _derived => {}, # hash symbol -> convert
        _parser => new Parser(1, 1),
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
    #TODO: this might have to be changed to use lc_file_utils's readfile instead of File::Util
    my $f = File::Util->new();
    my $units_txt = $f->load_file("../../conf/units.json");
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
# Converts a unit name into a Quantity
# @param {string} name - the unit name
# @returns {Quantity}
##
sub convertToSI {
    my ( $self, $name ) = @_;
    # check derived units first
    my $convert = $self->derived->{$name};
    if (defined $convert) {
        my $root = $self->parser->parse($convert);
        return $root->calc();
    }
    # then check base units
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
                    return $self->baseQuantity($base)->mult(new Quantity($v));
                }
            }
        }
    }
    die "Unit not found: $name";
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
    return new Quantity(1, \%h);
}

1;
__END__