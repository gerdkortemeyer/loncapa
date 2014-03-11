# The LearningOnline Network with CAPA - LON-CAPA
# Deal with everything having to do with roles
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
package Apache::lc_entity_roles;

use strict;

use Apache::lc_logs;
use Apache::lc_connection_handle();
use Apache::lc_json_utils();

use Apache::lc_postgresql();
use Apache::lc_memcached();
use Apache::lc_entity_utils();

use Apache2::Const qw(:common :http);

#
# We are the homeserver of the user that gets the role
# This would also be the routine that's called remotely
#
sub local_modify_rolerecord {
   my ($entity,$domain,$role)=@_;
# Better make sure before we make a mess
   unless (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return undef;
   }
# Okay, store
   &Apache::lc_mongodb::update_roles($entity,$domain,$role);
   return 1;
}

#
# We are not the homeserver of this entity
# Send to a *** particular *** other server
#
sub remote_modify_rolerecord {
   my ($host,$entity,$domain,$role)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'modify_rolerecord',
                           &Apache::lc_json_utils::perl_to_json({ entity => $entity, domain => $domain, role => $role }));
   if ($code eq HTTP_OK) {
      return 1;
   } else {
      return undef;
   }

}


#
# We are the server that hosts the entity for which a role is given out
# Modify local rolelist (lookup)
# This would also be the routine that is called remotely
#
sub local_modify_rolelist {
   my ($roleentity,$roledomain,$rolesection,
       $userentity,$userdomain,
       $role,
       $startdate,$enddate,
       $manualenrollentity,$manualenrolldomain)=@_;
}

#
# We are NOT the server that hosts the entity for which the role is given out
# Forward the request to a *** particular *** other machine
# System and domain roles go on cluster manager
# Course and user roles go on home server of that course or user
#
sub remote_modify_rolelist {
   my ($host,
       $roleentity,$roledomain,$rolesection,
       $userentity,$userdomain,
       $role,
       $startdate,$enddate,
       $manualenrollentity,$manualenrolldomain)=@_;
}

#
# Modify a role - this is the one to be called
# This needs to update two data-source:
# * The user's record of roles (authoritative)
# * The entity's rolelist (entity, domain, or system lookup table)
# Both could be on different servers
#
sub modify_role {
   my ($entity,$domain, # who gets the role?
       $roleentity,$roledomain,$rolesection, # what's the realm?
       $role, # what role is this?
       $startdate,$enddate, # duration
       $manualenrollentity,$manualenrolldomain # if done manually, who did this?
      )=@_;
}

BEGIN {
    &Apache::lc_connection_handle::register('modify_rolelist',undef,undef,undef,\&local_modify_rolelist,
                  'roleentity','roledomain','rolesection',
                  'userentity','userdomain',
                  'role',
                  'startdate','enddate',
                  'manualenrollentity','manualenrolldomain');
    &Apache::lc_connection_handle::register('modify_rolerecord',undef,undef,undef,\&local_modify_rolerecord,'entity','domain','role');
}

1;
__END__
