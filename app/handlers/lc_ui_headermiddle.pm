# The LearningOnline Network with CAPA - LON-CAPA
# Middle part of the header 
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
package Apache::lc_ui_headermiddle;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);
use Apache::lc_entity_sessions();
use Apache::lc_entity_courses();
use Apache::lc_ui_utils;
use Apache::lc_logs;

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
   $r->content_type('application/json; charset=utf-8');
   my $title='';
   my ($course_entity,$course_domain)=&Apache::lc_entity_sessions::course_entity_domain();
   if ($course_entity) {
      $title=&Apache::lc_entity_courses::course_title($course_entity,$course_domain);
   }
   unless ($title) { $title=''; }
   $r->print(&Apache::lc_json_utils::perl_to_json({'title' => $title}));
   return OK;
}
1;
__END__
