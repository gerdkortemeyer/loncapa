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
use Apache::lc_entity_utils();
use Apache::lc_init_cluster_table();
use Apache2::Const qw(:common :http);

use Data::Dumper;

#
# Checking user credentials
#
sub local_check_authentication {
   my ($entity,$domain,$password)=@_;
# Get the authentication record
   my $authrecord=&Apache::lc_mongodb::dump_auth($entity,$domain);
   unless ($authrecord) {
      &logwarning("Contacted for authentication of entity ($entity) domain ($domain), no record.");
      return undef;
   }
# Who takes care of this?
   if ($authrecord->{'mode'} eq 'internal') {
# It's just us - compare one-way encrypted passwords
      if (&Apache::lc_entity_utils::oneway($password) eq $authrecord->{'password'}) {
         &lognotice("Authenticated entity ($entity) domain ($domain)");
         return 1;
      } else {
         &lognotice("Rejected internal authentication for entity ($entity) domain ($domain)");
         return undef;
      }
   } else {
#FIXME: plugable stuff goes here
      return undef;
   }
}

sub remote_check_authentication {
   my ($host,$entity,$domain,$profile)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'modify_profile',
                           &Apache::lc_json_utils::perl_to_json({ entity => $entity, domain => $domain, profile => $profile }));
   if ($code eq HTTP_OK) {
      return 1;
   } else {
      return undef;
   }
}

#
# We are the homeserver of the user/course
# This would also be the routine that's called remotely
#
sub local_modify_profile {
   my ($entity,$domain,$profile)=@_;
# Better make sure before we make a mess
   unless (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      &logwarning("Cannot store profile for ($entity) ($domain), not homeserver");
      return undef;
   }
# Okay, store
   return &Apache::lc_mongodb::update_profile($entity,$domain,$profile)->{'ok'};
}

#
# We are not the homeserver of this entity
# Send to a *** particular *** other server
#
sub remote_modify_profile {
   my ($host,$entity,$domain,$profile)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'modify_profile',
                           &Apache::lc_json_utils::perl_to_json({ entity => $entity, domain => $domain, profile => $profile }));
   if ($code eq HTTP_OK) {
      return 1;
   } else {
      return undef;
   }
}


#
# Modify a profile - this is the one to be called
# Call with new profile data
#
sub modify_profile {
   my ($entity,$domain,$profile)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_modify_profile($entity,$domain,$profile);
   } else {
      return &remote_modify_profile(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain,$profile);
   }
}

#
# Dump profile from local data source
#
sub local_dump_profile {
   return &Apache::lc_mongodb::dump_profile(@_);
}


#
# Get the profile from elsewhere
#
sub remote_dump_profile {
   my ($host,$entity,$domain)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'dump_profile',
                                               "{ entity : '$entity', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return &Apache::lc_json_utils::json_to_perl($response);
   } else {
      return undef;
   }
}


BEGIN {
    &Apache::lc_connection_handle::register('modify_profile',undef,undef,undef,\&local_modify_profile,'entity','domain','profile');
    &Apache::lc_connection_handle::register('dump_profile',undef,undef,undef,\&local_json_dump_profile,'entity','domain');
}

1;
__END__
