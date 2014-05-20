# The LearningOnline Network with CAPA - LON-CAPA
# Store screen form defaults
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
package Apache::lc_ui_screendefaults;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common :http);
use Apache::lc_ui_utils;
use Apache::lc_entity_sessions();

use Apache::lc_logs;
use Apache::lc_json_utils();

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
   my $uri=$r->uri;
   my ($namespace)=($uri=~/\/(\w+)$/);
# Extract posted content from AJAX
   my %content=&Apache::lc_entity_sessions::posted_content();
# Store
   if (&Apache::lc_entity_users::set_screen_form_defaults(&Apache::lc_entity_sessions::user_entity_domain(),$namespace,\%content)) {
      $r->print('ok');
   } else {
      &logwarning("Failed to store screen defaults for ($namespace) of (".join(',',&Apache::lc_entity_sessions::user_entity_domain()).")");
      $r->print('error');
   }
   return OK;
}
1;
__END__
