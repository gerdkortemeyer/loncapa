# The LearningOnline Network with CAPA - LON-CAPA
# Authenticates an entity
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
package Apache::lc_entity_authentication;

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
# We want an explicit "ok" here
         return 'ok';
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
   my ($host,$entity,$domain,$password)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'check_authentication',
                           &Apache::lc_json_utils::perl_to_json({ entity => $entity, domain => $domain, password => $password }));
   if ($code eq HTTP_OK) {
      return $response;
   } else {
      return undef;
   }
}

#
# Check the authentication - this is the one to be called
#
sub check_authentication {
   my ($entity,$domain,$password)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_check_authentication($entity,$domain,$password);
   } else {
      return &remote_check_authentication(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain,$password);
   }
}

#
# Set user credentials
#

sub local_set_authentication {
   my ($entity,$domain,$authdata)=@_;
# Better make sure before we make a mess
   unless (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      &logwarning("Cannot set authdata for ($entity) ($domain), not homeserver");
      return undef;
   }
# Stuff that should be encrypted
   if ($authdata->{'password'}) {
      $authdata->{'password'}=&Apache::lc_entity_utils::oneway($authdata->{'password'});
   }
# Okay, store
   return &Apache::lc_mongodb::update_auth($entity,$domain,$authdata)->{'ok'};
}


sub remote_set_authentication {
   my ($host,$entity,$domain,$authdata)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'set_authentication',
                           &Apache::lc_json_utils::perl_to_json({ entity => $entity, domain => $domain, authdata => $authdata }));
   if ($code eq HTTP_OK) {
      return 1;
   } else {
      return undef;
   }
}


#
# Set authentication - this is the one to be called
#
sub set_authentication {
   my ($entity,$domain,$authdata)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_set_authentication($entity,$domain,$authdata);
   } else {
      return &remote_set_authentication(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain,$authdata);
   }
}



BEGIN {
#FIXME: these want to test credentials
    &Apache::lc_connection_handle::register('check_authentication',undef,undef,undef,\&local_check_authentication,
                                            'entity','domain','password');
    &Apache::lc_connection_handle::register('set_authentication',undef,undef,undef,\&local_set_authentication,
                                            'entity','domain','authdata');
}

1;
__END__
