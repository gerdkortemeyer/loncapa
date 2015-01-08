# The LearningOnline Network with CAPA - LON-CAPA
# Utilities for handling JSON
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
#
package Apache::lc_json_utils;

use strict;
use JSON::DWIW;

# ==== Parsing JSON to Perl data structure
# Input: JSON text
# Output: data structure
#
sub json_to_perl {
   return (JSON::DWIW->new->from_json(@_[0]))[0];
}

# ==== Translate Perl data structure into JSON
# Input: data structure
# Output: JSON text
#
sub perl_to_json {
   # Called in list context, to_json returns a list, so we need to use scalar context to get a string.
   return (JSON::DWIW->new->to_json(@_[0]))[0];
}

1;
__END__
