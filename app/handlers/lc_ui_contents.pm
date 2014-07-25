# The LearningOnline Network with CAPA - LON-CAPA
# Serves up the table of contents in JSON
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
package Apache::lc_ui_contents;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);
use Apache::lc_entity_sessions();
use Apache::lc_entity_users();
use Apache::lc_ui_utils;
use Apache::lc_json_utils();
use Apache::lc_logs;

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
   $r->content_type('application/json; charset=utf-8');
   $r->print(<<ENDCONTENTS);
     [
       { "id" : "ajson1", "parent" : "#", "text" :  "Simple root node" },
       { "id" : "ajson2", "parent" : "#", "text" : "Root folder node 2" },
       { "id" : "ajson3", "parent" : "ajson2", "text" : "Child 1" },
       { "id" : "ajson4", "parent" : "ajson2", "text" : "Child 2" }
     ]
ENDCONTENTS
   return OK;
}
1;
__END__
