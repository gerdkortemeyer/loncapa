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
use Apache::lc_entity_authentication();
use Apache2::Const qw(:common :http);

#
# Sessions are always on the local machine
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
# Okay, looks like we are in business
   my $sessionid=&Apache::lc_entity_utils::make_unique_id();
   if (&Apache::lc_mongodb::open_session($entity,$domain,$sessionid,{ created => &Apache::lc_date_utils::now2str() })) {
      &lognotice("Opened session ($sessionid) for entity ($entity) domain ($domain)"); 
      return $sessionid;
   } else {
      &logerror("Failed to open session ($sessionid) for entity ($entity) domain ($domain)");
      return undef;
   }
}

sub grab_session {
   my ($sessionid)=@_;
   unless ($sessionid) { return undef; }
   delete($ENV{'lc_session'});
   my $sessiondata=&Apache::lc_mongodb::dump_session($sessionid);
   if ($sessiondata) {
      $ENV{'lc_session'}->{'id'}=$sessionid;
      $ENV{'lc_session'}->{'data'}=$sessiondata->{'sessiondata'};
      return 1;
   } else {
      return undef;
   }
}

sub session_id {
   return $ENV{'lc_session'}->{'id'};
}

sub breadcrumbs {
   if ($ENV{'lc_session'}->{'data'}->{'breadcrumbs'}) {
      return @{$ENV{'lc_session'}->{'data'}->{'breadcrumbs'}};
   } else {
      return undef;
   }
}

sub userlanguage {
   return $ENV{'lc_session'}->{'data'}->{'language'};
}

sub close_session {
   unless (&session_id()) { return undef; }
   return &Apache::lc_mongodb::close_session(&session_id());
}

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
   return &Apache::lc_mongodb::replace_session_key(&session_id(),$key,$data);
}

1;
__END__
