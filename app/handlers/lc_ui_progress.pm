# The LearningOnline Network with CAPA - LON-CAPA
# Get progress bar data
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
package Apache::lc_ui_progress;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common :http);
use Apache::lc_entity_sessions();

# ==== Main handler
#
sub handler {
   my $r = shift;
   my $uri=$r->uri;
   my ($namespace)=($uri=~/\/(\w+)$/);
   $r->content_type('application/json; charset=utf-8');
   $r-print(&Apache::lc_entity_sessions::get_progress($namespace));
   return OK;
}

1;
__END__
