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
# Get request object and posted content
   my $r = shift;
   my %content=&Apache::lc_entity_sessions::posted_content();
# Can come in for many reasons.
# Maybe we get token data - do we have a referrer?
   my $tokendata;
   if (($content{'referrer'}) && ($content{'token'})) {
      $tokendata=&Apache::lc_entity_utils::get_remote_token($content{'referrer'},$content{'token'});
      unless ($tokendata) {
         &logwarning("Unable to retrieve token data from ($content{'referrer'})($content{'token'})");
      }
   }
# Should this user be logged in? Look for flag
   my $sessionid;
   if ($tokendata->{'authenticated'}) {
      my ($current_entity,$current_domain)=&Apache::lc_entity_sessions::user_entity_domain();
# If that does not agree with the with token data, or does not exist, open a new session
      unless (($tokendata->{'user_entity'} eq $current_entity)
           && ($tokendata->{'user_domain'} eq $current_domain)) {
         $sessionid=&Apache::lc_entity_sessions::open_session_entity_domain($tokendata->{'user_entity'},$tokendata->{'user_domain'});
         if ($sessionid) {
# Was able to open a new session
         } else {
# Oops! Why not?
            &logwarning("Unable to open transferred session for ($tokendata->{'user_entity'})($tokendata->{'user_domain'})");
         }
      }
   }
# Is this user logged in?
   my ($user_entity,$user_domain)=&Apache::lc_entity_sessions::user_entity_domain();
# If the user is logged in and a certain course/community is desired, enter it
   if (($user_entity) && ($user_domain) && 
       ($tokendata->{'course_entity'}) && ($tokendata->{'course_domain'})) {
   }
# Are we in a course?
   my ($course_entity,$course_domain)=&Apache::lc_entity_sessions::course_entity_domain();


# Attempt to open a session
#    my $sessionid=&Apache::lc_entity_sessions::open_session($username,$domain,$content{'password'});
#       if ($sessionid) {
#       # Successfully opened a session, set the cookie
#
#FIXME: debug only
   my $location=$content{'path'};
#

   my $cookie = CGI::Cookie->new(-name=>'lcredirect',-value=>$location);
   $r->err_headers_out->add('Set-Cookie' => $cookie);
   $r->headers_out->set('Location' => '/?direct='.$location);
   return REDIRECT;
}
1;
__END__
