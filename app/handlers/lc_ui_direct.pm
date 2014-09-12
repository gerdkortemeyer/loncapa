# The LearningOnline Network with CAPA - LON-CAPA
# Direct jump to a resource
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
package Apache::lc_ui_direct;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common :http);
use Apache::lc_entity_sessions();
use Apache::lc_entity_utils();
use CGI::Cookie ();

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
   my %content=&Apache::lc_entity_sessions::posted_content();
# Can come in for many reasons.
# Do we have a referrer?
   if (($content{'origin'}) && ($content{'token'})) {
      my $tokendata=&Apache::lc_entity_utils::get_remote_token($content{'origin'},$content{'token'});
   }


# Attempt to open a session
#    my $sessionid=&Apache::lc_entity_sessions::open_session($username,$domain,$content{'password'});
#       if ($sessionid) {
#       # Successfully opened a session, set the cookie
#             my $cookie = CGI::Cookie->new(-name=>'lcsession',-value=>$sessionid);
#                   $r->headers_out->add('Set-Cookie' => $cookie);
#                         $r->err_headers_out->add('Set-Cookie' => $cookie);
   $r->headers_out->set('Location' => '/?direct='.$content{path});
   return REDIRECT;
}
1;
__END__
