# The LearningOnline Network with CAPA - LON-CAPA
# Deal with everything having to do with sessions
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
package Apache::lc_entity_sessions;

use strict;

use Apache::lc_logs;
use Apache::lc_connection_handle();
use Apache::lc_json_utils();
use Apache::lc_memcached();
use Apache::lc_mongodb();
use Apache::lc_entity_utils();
use Apache::lc_init_cluster_table();
use Apache::lc_date_utils();
use Apache::lc_parameters;
use Apache::lc_entity_authentication();
use Apache::lc_entity_users();
use Apache::lc_entity_courses();
use Apache2::Const qw(:common :http);
use CGI;
use vars qw($lc_session);

#
# Sessions are always on the local machine
# This is the normal routine, which takes username and password
# Returns session ID
#
sub open_session {
   my ($username,$domain,$password)=@_;
# Get the entity behind the username
   my $entity=&Apache::lc_entity_users::username_to_entity($username,$domain);
   unless ($entity) {
      &lognotice("Could not open session for username ($username) domain ($domain), no entity");
      return undef;
   }
# Unless the password is correct, we don't do anything
   unless (&Apache::lc_entity_authentication::check_authentication($entity,$domain,$password) eq 'ok') {
      &lognotice("Failed attempt to login by entity ($entity) domain ($domain)");
      return undef;
   }
   return &open_session_entity_domain($entity,$domain);
}

#
# This routine opens a session for entity, domain
# No questions asked, used for example when transfering sessions
# Returns session ID
#
sub open_session_entity_domain {
   my ($entity,$domain)=@_;
# Get profile and roles
   my $data=&load_session_data($entity,$domain);
# Okay, looks like we are in business
   my $sessionid=&Apache::lc_entity_utils::make_unique_id();
   if (&Apache::lc_mongodb::open_session($entity,$domain,$sessionid,$data)) {
      &lognotice("Opened session ($sessionid) for entity ($entity) domain ($domain)"); 
      return $sessionid;
   } else {
      &logerror("Failed to open session ($sessionid) for entity ($entity) domain ($domain)");
      return undef;
   }
}

#
# Fetches the user's profile and roles data
#
sub load_session_data {
   my ($entity,$domain)=@_;
   my $data->{'profile'}=&Apache::lc_entity_profile::dump_profile($entity,$domain);
   $data->{'roles'}=&Apache::lc_entity_roles::active_roles($entity,$domain);
#FIXME: y2038?
   $data->{'last_loaded'}=time;
   return $data;
}


# Clear any session data
#
sub clear_session {
   $lc_session=undef;
}

# Load POSTed parameters into session
#
sub get_posted_content {
   my ($r)=@_;
   my $query = new CGI($r);
   my %content=$query->Vars;
   if ($query->param('uploads')) {
# Wow, uploaded a file. Do not put that into memory, just store it
# uploads contains the filename
# optional uploads_path contains the URL full path
       $content{'remote_filename'}=$query->param('uploads');
       $content{'local_filename'}=$query->tmpFileName($query->param('uploads'));
# Full path under which should be stored in wrk-space - use path if present
       my $path=$query->param('uploads_path');
# Remove domain/entity
       $path=~s/^\/*\w+\/\w+//;
       $path=~s/^\/*//;
       unless ($path=~/\/$/) { $path.='/'; }
       $content{'wrk_filename'}=($path?$path.$query->param('uploads'):$query->param('uploads'));
   }
# Load the normal stuff into memory
   $lc_session->{'content'}=\%content;
}

# Transfers the session to the environment,
# returns 1 on sucess
#
sub grab_session {
   my ($sessionid)=@_;
   unless ($sessionid) { return undef; }
   my $sessiondata=&Apache::lc_mongodb::dump_session($sessionid);
   if ($sessiondata) {
      $lc_session->{'id'}=$sessionid;
      if ((time-$sessiondata->{'sessiondata'}->{'last_loaded'})>&lc_short_expire()) {
# Time to refresh the session
         &update_session(&load_session_data($sessiondata->{'entity'},$sessiondata->{'domain'}));
         $sessiondata=&Apache::lc_mongodb::dump_session($sessionid);
      }
      $lc_session->{'entity'}=$sessiondata->{'entity'};
      $lc_session->{'domain'}=$sessiondata->{'domain'};
      $lc_session->{'data'}=$sessiondata->{'sessiondata'};
      return 1;
   } else {
      return undef;
   }
}

# Returns the session ID
# - good quick check if the user is logged in
#
sub session_id {
   return $lc_session->{'id'};
}

# Returns the session user's entity and domain
# in the order that most subroutines expect
#
sub user_entity_domain {
   return ($lc_session->{'entity'},$lc_session->{'domain'});
}

sub user_domain {
   return $lc_session->{'domain'};
}

# Returns the current session's course entity and domain
# in the order expected by most subroutines
#
sub course_entity_domain {
   return ($lc_session->{'data'}->{'current_course'}->{'entity'},
           $lc_session->{'data'}->{'current_course'}->{'domain'});
}

#
# Enter a course
#
sub enter_course {
   my ($courseid,$domain)=@_;
   &Apache::lc_entity_courses::set_last_accessed($courseid,$domain);
   &Apache::lc_entity_users::set_last_accessed(&user_entity_domain(),$courseid,$domain);
   &update_session({ 'current_course' => { 'entity' => $courseid, 'domain' => $domain }});
}

#
# Return the resourceid
#
sub resource_id {
   return $lc_session->{'data'}->{'current_asset'}->{'resourceid'};
}

sub asset_entity_domain {
   return ($lc_session->{'data'}->{'current_asset'}->{'entity'},
           $lc_session->{'data'}->{'current_asset'}->{'domain'});
}


# Returns the current breadcrumbs
#
sub breadcrumbs {
   if ($lc_session->{'data'}->{'breadcrumbs'}) {
      return $lc_session->{'data'}->{'breadcrumbs'};
   } else {
      return undef;
   }
}

# Returns the language preferred by the user for the session
#
sub userlanguage {
   return $lc_session->{'data'}->{'profile'}->{'language'};
}

# Returns the timezone preferred by the user
#
sub usertimezone {
   return $lc_session->{'data'}->{'profile'}->{'timezone'};
}

# Returns all roles
# 
sub roles {
   return $lc_session->{'data'}->{'roles'};
}

# Returns posted content
#
sub posted_content {
   return %{$lc_session->{'content'}};
}


# Progress indicator
# $which is the name of the progress indicator
#
sub get_progress {
   my ($which)=@_;
   my $data=&Apache::lc_memcached::lookup_progress(
           $lc_session->{'data'}->{'current_course'}->{'entity'},
           $lc_session->{'data'}->{'current_course'}->{'domain'},
           $which);
   unless ($data) {
      $data='{"total":"1","success":"0","skip":"0","fail":"0"}';
   }
   return $data;
}

# Set everything on the progress $which
#
sub put_progress {
   my ($which,$total,$success,$skip,$fail)=@_;
   unless ($total) { $total=1; }
   unless ($success) { $success=0; }
   unless ($skip) { $skip=0; }
   unless ($fail) { $fail=0; }
   if ($success>$total) { $success=$total; }
   if ($success+$skip+$fail>$total) { $fail=0; $skip=0; }
   &Apache::lc_memcached::insert_progress(
           $lc_session->{'data'}->{'current_course'}->{'entity'},
           $lc_session->{'data'}->{'current_course'}->{'domain'},
           $which,'{"total":"'.$total.'","success":"'.$success.'","skip":"'.$skip.'","fail":"'.$fail.'"}');
}

# Set the total (probably the first thing you want to do)
#
sub set_progress_total {
   my ($which,$total)=@_;
   my $progress=&Apache::lc_json_utils::json_to_perl(&get_progress($which));
   $progress->{'total'}=$total;
   &put_progress($which,$progress->{'total'},$progress->{'success'},$progress->{'skip'},$progress->{'fail'});
}


# $which is the name of the progress counter
# $what is success, skip, or fail
sub inc_progress {
   my ($which,$what)=@_;
   my $progress=&Apache::lc_json_utils::json_to_perl(&get_progress($which));
   $progress->{$what}++;
   &put_progress($which,$progress->{'total'},$progress->{'success'},$progress->{'skip'},$progress->{'fail'});
}

sub reset_progress {
   my ($which)=@_;
   &put_progress($which,1,0,0,0);
}

# Get rid of this session
#
sub close_session {
   unless (&session_id()) { return undef; }
   return &Apache::lc_mongodb::close_session(&session_id());
}

# Dumps the session data fresh from the database
# (rather than the environment)
#
sub dump_session {
   unless (&session_id()) { return undef; }
   return &Apache::lc_mongodb::dump_session(&session_id());
}

# Update the session environment
# For arrays, this adds on
sub update_session {
   my ($data)=@_;
   unless (&session_id()) { return undef; }
   return &Apache::lc_mongodb::update_session(&session_id(),$data);
}

# Update the session environment
# For arrays, this replaces
sub replace_session_key {
   my ($key,$data)=@_;
   unless (&session_id()) { return undef; }
# Replace immediately for this request cycle
   $lc_session->{'data'}->{$key}=$data;
# Replace for future cycles
   return &Apache::lc_mongodb::replace_session_key(&session_id(),$key,$data);
}

1;
__END__
