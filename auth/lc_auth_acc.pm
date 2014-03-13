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
package Apache::lc_auth_acc;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common :http);
use CGI::Cookie ();
use Apache::lc_ui_utils;
use Apache::lc_entity_sessions();
use Apache::lc_ui_localize;


# ==== Initialize session environment
#
sub get_session {
   my $r = shift;
   delete($ENV{'lc_session'});
   my %cookie=CGI::Cookie->parse($r->headers_in->{'Cookie'});
# Clean up the session token
   my ($token)=($cookie{'lcsession'}=~/\s*lcsession\s*\=\s*(\w+)\s*\;/);
   unless ($token=~/\w/) {
      &Apache::lc_ui_localize::reset_language();
      return HTTP_UNAUTHORIZED;
   }
# Attempt to retrieve the session
   my $sessiondata=&Apache::lc_entity_sessions::dump_session($token);
   if ($sessiondata) {
# Remember session data
      $ENV{'lc_session'}->{'id'}=$token;
      $ENV{'lc_session'}->{'data'}=$sessiondata;
#FIXME: use actual language
      &Apache::lc_ui_localize::set_language('de');
      return OK;
   } else {
      &Apache::lc_ui_localize::reset_language();
      return HTTP_UNAUTHORIZED;
   }
}

# ==== Main handler
# 
sub handler {
# Get request object
   my $r = shift;
   return &get_session($r);
}

1;
__END__
