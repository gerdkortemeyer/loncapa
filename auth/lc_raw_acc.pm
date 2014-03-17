# The LearningOnline Network with CAPA - LON-CAPA
# Full authentication
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
package Apache::lc_raw_acc;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common :http);

# ==== Main handler
# 
sub handler {
# Get request object
   my $r = shift;
#FIXME - there should probably be more here, just creating the hook
   return OK;
}

1;
__END__
