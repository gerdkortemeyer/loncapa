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
use Apache::lc_dispatcher();
use Apache::lc_connection_utils();
use Apache::lc_logs;
use CGI::Cookie ();

#
# Makes a course transfer token, including authentication, etc.
# Returns ID
#
sub make_course_transfer_token {
   my ($course_entity,$course_domain,$course_asset)=@_;
   my $token;
   ($token->{'user_entity'},$token->{'user_domain'})=&Apache::lc_entity_sessions::user_entity_domain();
   $token->{'course_entity'}=$course_entity;
   $token->{'course_domain'}=$course_domain;
   $token->{'course_asset_id'}=$course_asset;
   $token->{'authenticated'}=1;
   return &Apache::lc_entity_utils::set_token_data($token);
}
#
# Makes a course transfer link
# Return the jump-off URI
#
sub make_course_transfer_link {
   my ($target_host,$course_entity,$course_domain,$course_asset)=@_;
   return 'https://'.&Apache::lc_dispatcher::host_address($target_host).
          '/direct?referrer='.&Apache::lc_connection_utils::host_name().
          '&token='.&make_course_transfer_token($course_entity,$course_domain,$course_asset);
}

# ==== Main handler
#
sub handler {
# Get request object and posted content
   my $r = shift;
   my %content=&Apache::lc_entity_sessions::posted_content();
# Can come in for many reasons. Where do we go?
   my $location;
# Maybe we get token data - do we have a referrer?
   my $tokendata;
   if (($content{'referrer'}) && ($content{'token'})) {
      $tokendata=&Apache::lc_entity_utils::get_remote_token($content{'referrer'},$content{'token'});
      &lognotice("Attempting to retrieve session token from $content{'referrer'}");
      unless ($tokendata) {
         &logwarning("Unable to retrieve token data from ($content{'referrer'})($content{'token'})");
      }
   }
# Should this user be logged in? Look for flag
   my $sessionid;
   if ($tokendata->{'authenticated'}) {
      &lognotice("Attempting to authenticate ($tokendata->{'user_entity'})($tokendata->{'user_domain'})");
      my ($current_entity,$current_domain)=&Apache::lc_entity_sessions::user_entity_domain();
# If that does not agree with the with token data, or does not exist, open a new session
      unless (($tokendata->{'user_entity'} eq $current_entity)
           && ($tokendata->{'user_domain'} eq $current_domain)) {
         $sessionid=&Apache::lc_entity_sessions::open_session_entity_domain($tokendata->{'user_entity'},$tokendata->{'user_domain'});
         if ($sessionid) {
            &Apache::lc_entity_sessions::grab_session($sessionid);
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
      &lognotice("Attempting to enter course ($tokendata->{'course_entity'})($tokendata->{'course_domain'}) for ($tokendata->{'user_entity'})($tokendata->{'user_domain'})");
      unless (&Apache::lc_entity_sessions::enter_course($tokendata->{'course_entity'},$tokendata->{'course_domain'})) {
         &logwarning("Unable to enter course ($tokendata->{'course_entity'})($tokendata->{'course_domain'}) for ($tokendata->{'user_entity'})($tokendata->{'user_domain'})");
      }
   }
# Are we in a course (now)?
   my ($course_entity,$course_domain)=&Apache::lc_entity_sessions::course_entity_domain();
   if (($course_entity) && ($course_domain)) {
# Are we going anywhere in particular in this course?
      if ($tokendata->{'course_asset_id'}) {
# Okay, guess that's where we are going
         $location='course_asset/'.$tokendata->{'course_asset_id'};
      }
   }
   my $location_cookie=CGI::Cookie->new(-name=>'lcredirect',-value=>$location);
   if ($sessionid) {
      my $session_cookie=CGI::Cookie->new(-name=>'lcsession',-value=>$sessionid);
      $r->err_headers_out->add('Set-Cookie' => [$location_cookie,$session_cookie]);
   } else {
      $r->err_headers_out->add('Set-Cookie' => $location_cookie);
   }
   $r->headers_out->set('Location' => '/?direct='.$location);
   return REDIRECT;
}
1;
__END__
