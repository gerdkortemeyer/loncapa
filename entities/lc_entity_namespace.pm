# The LearningOnline Network with CAPA - LON-CAPA
# Deal with everything having to do with namespaces
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
package Apache::lc_entity_namespace;

use strict;

use Apache::lc_logs;
use Apache::lc_connection_handle();
use Apache::lc_json_utils();
use Apache::lc_dispatcher();
use Apache::lc_entity_utils();
use Apache::lc_init_cluster_table();
use Apache2::Const qw(:common :http);

use Data::Dumper;

#
# We are the homeserver of the user/course
# This would also be the routine that's called remotely
#
sub local_modify_namespace {
   my ($entity,$domain,$name,$data)=@_;
# Better make sure before we make a mess
   unless (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      &logwarning("Cannot store namespace ($name) for ($entity) ($domain), not homeserver");
      return undef;
   }
# Okay, store
   my $result=&Apache::lc_mongodb::update_namespace($entity,$domain,$name,$data);
   if (ref($result) eq 'HASH') {
      return $result->{'ok'};
   } elsif ($result) {
      return 1;
   }
   return 0;
}

#
# We are not the homeserver of this entity
# Send to a *** particular *** other server
#
sub remote_modify_namespace {
   my ($host,$entity,$domain,$name,$data)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'modify_namespace',
                           &Apache::lc_json_utils::perl_to_json({ entity => $entity, domain => $domain, name => $name, data => $data }));
   if ($code eq HTTP_OK) {
      return 1;
   } else {
      return undef;
   }
}


#
# Modify a namespace - this is the one to be called
# Call with new namespace data
#
sub modify_namespace {
   my ($entity,$domain,$name,$data)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_modify_namespace($entity,$domain,$name,$data);
   } else {
      return &remote_modify_namespace(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain,$name,$data);
   }
}

#
# Dump namespace from local data source
#
sub local_dump_namespace {
   return &Apache::lc_mongodb::dump_namespace(@_);
}

sub local_json_dump_namespace {
   return &Apache::lc_json_utils::perl_to_json(&local_dump_namespace(@_));
}

#
# Get the namespace from elsewhere
#
sub remote_dump_namespace {
   my ($host,$entity,$domain,$name)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'dump_namespace',
                                               "{ entity : '$entity', domain : '$domain', name : '$name' }");
   if ($code eq HTTP_OK) {
      return &Apache::lc_json_utils::json_to_perl($response);
   } else {
      return undef;
   }
}


# Dump current namespace for an entity
# Call this one
#
sub dump_namespace {
   my ($entity,$domain,$name)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_dump_namespace($entity,$domain,$name);
   } else {
      return &remote_dump_namespace(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain,$name);
   }
}

BEGIN {
    &Apache::lc_connection_handle::register('modify_namespace',undef,undef,undef,\&local_modify_namespace,'entity','domain','name','data');
    &Apache::lc_connection_handle::register('dump_namespace',undef,undef,undef,\&local_json_dump_namespace,'entity','domain','name');
}

1;
__END__
