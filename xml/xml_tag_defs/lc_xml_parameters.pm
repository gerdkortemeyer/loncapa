# The LearningOnline Network with CAPA - LON-CAPA
# Implements conditional blocks
#
# Copyright (C) 2014 Michigan State University Board of Trustees
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
package Apache::lc_xml_parameters;

use strict;
use Apache::lc_asset_safeeval;
use Apache::lc_authorize;
use Apache::lc_entity_sessions();

use Apache::lc_logs;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_parameter_analysis);

sub start_parameter_analysis {
   my ($p,$safe,$stack,$token)=@_;
   &logdebug("I am running!");
   $stack->{'i_was'}='here';
}

1;
__END__
