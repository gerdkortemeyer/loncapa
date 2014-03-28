# The LearningOnline Network with CAPA - LON-CAPA
# Preferences Handler
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
package Apache::lc_ui_preferences;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common :http);
use Apache::lc_ui_utils;
use Apache::lc_entity_sessions();
use Apache::lc_entity_profile();

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
# Extract posted content from AJAX
   my %content=&get_content($r);
# Collect items that changed
   my $newprofile;
   if ($content{'language'} ne &Apache::lc_entity_sessions::userlanguage) {
      &Apache::lc_entity_sessions::update_session({ 'profile' => {'language' => $content{'language'}}});
      $newprofile->{'language'}=$content{'language'};
   }
   if (&Apache::lc_entity_profile::modify_profile(&Apache::lc_entity_sessions::entity_domain(),
                                                  $newprofile)) {
      $r->print('yes');
   } else {
      $r->print('no');
   }
   return OK;
}
1;
__END__
