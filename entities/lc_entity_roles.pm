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
use Apache::lc_dispatcher();
use Apache::lc_postgresql();
use Apache::lc_memcached();
use Apache::lc_entity_utils();
use Apache::lc_date_utils();
use Apache::lc_init_cluster_table();
use Apache2::Const qw(:common :http);

#
# We are the homeserver of the user that gets the role
# This would also be the routine that's called remotely
#
sub local_modify_rolerecord {
   my ($entity,$domain,$rolerecord)=@_;
# Better make sure before we make a mess
   unless (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      &logwarning("Cannot store rolerecord for ($entity) ($domain), not homeserver");
      return undef;
   }
# Okay, store
   return &Apache::lc_mongodb::update_roles($entity,$domain,$rolerecord)->{'ok'};
}

#
# We are not the homeserver of this entity
# Send to a *** particular *** other server
#
sub remote_modify_rolerecord {
   my ($host,$entity,$domain,$rolerecord)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'modify_rolerecord',
                           &Apache::lc_json_utils::perl_to_json({ entity => $entity, domain => $domain, rolerecord => $rolerecord }));
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
# First make sure this is really for us
  if ($roleentity) {
# This is a regular role, make sure that we are homeserver
      unless (&Apache::lc_entity_utils::we_are_homeserver($roleentity,$roledomain)) {
         &logwarning("Cannot store rolelist for ($roleentity) ($roledomain), not homeserver");
         return undef;
      }
   } else {
# This is a domain or system role. We better be cluster manager!
      unless (&Apache::lc_init_cluster_table::we_are_manager()) {
         &logwarning("Cannot store rolelist, not cluster_manager");
         return undef;
      }
   }
# Okay, we are in charge here
   if (&Apache::lc_postgresql::role_exists_rolelist($roleentity,$roledomain,$rolesection,
                                           $userentity,$userdomain,
                                           $role)) {
      &lognotice("Modifying existing role for ($userentity) ($userdomain)");
      if (&Apache::lc_postgresql::modify_rolelist($roleentity,$roledomain,$rolesection,
                                           $userentity,$userdomain, 
                                           $role, 
                                           $startdate,$enddate,
                                           $manualenrollentity,$manualenrolldomain)<0) {
         &logerror("Error modifying rolelist");
         return 0;
      } else {
         return 1;
      }
   } else {
      &lognotice("Inserting role for ($userentity) ($userdomain)");
      if (&Apache::lc_postgresql::insert_into_rolelist($roleentity,$roledomain,$rolesection,
                                           $userentity,$userdomain, 
                                           $role, 
                                           $startdate,$enddate,
                                           $manualenrollentity,$manualenrolldomain)<0) {
         &logerror("Error inserting into rolelist");
         return 0;
      } else {
         return 1;
      }
   }
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
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'modify_rolelist',
"{  roleentity:'$roleentity',roledomain:'$roledomain',rolesection:'$rolesection',
   userentity:'$userentity',userdomain:'$userdomain',
   role:'$role',
   startdate:'$startdate',enddate:'$enddate',
   manualenrollentity:'$manualenrollentity',manualenrolldomain:'$manualenrolldomain' 
}");
   if ($code eq HTTP_OK) {
      return 1;
   } else {
      return undef;
   }
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
       $type, # system, domain, course, user
       $roleentity,$roledomain,$rolesection, # what's the realm?
       $role, # what role is this?
       $startdate,$enddate, # duration
       $manualenrollentity,$manualenrolldomain # if done manually, who did this?
      )=@_;
# === This is a big deal, so do sanity testing
unless ($entity) {
   &logerror("Modify role must provide entity");
   return undef;
}
unless ($domain) {
   &logerror("Modify role must provide domain");
   return undef;
}
unless (($type eq 'system') || ($type eq 'domain') || ($type eq 'course') || ($type eq 'user')) {
   &logerror("Type ($type) not supported for modifying roles of entity ($entity) domain ($domain)");
   return undef;
}
unless ($roledomain) { $roledomain=''; }
unless ($roleentity) { $roleentity=''; }
unless ($rolesection) { $rolesection=''; }
unless ($manualenrollentity) { $manualenrollentity=''; }
unless ($manualenrolldomain) { $manualenrolldomain=''; }
# === Deal with the user's record
# Role itself
   my $thisrole;
   $thisrole->{'startdate'}=$startdate;
   $thisrole->{'enddate'}=$enddate;
   $thisrole->{'manualenrollentity'}=$manualenrollentity;
   $thisrole->{'manualenrolldomain'}=$manualenrolldomain;
# Assemble the role record
   my $rolerecord;
# Different types of roles have different structures
   if ($type eq 'system') {
# System-level role
      $rolerecord->{'system'}->{$role}=$thisrole;
   } elsif ($type eq 'domain') {
# Domain-level role
      $rolerecord->{'domain'}->{$roledomain}->{$role}=$thisrole;
   } elsif ($type eq 'course') {
# Course-level role
# Do we have a section?
      if ($rolesection) {
         $rolerecord->{'course'}->{$roledomain}->{$roleentity}->{'section'}->{$rolesection}->{$role}=$thisrole;
      } else {
         $rolerecord->{'course'}->{$roledomain}->{$roleentity}->{'any'}->{$role}=$thisrole;
      }
   } elsif ($type eq 'user') {
# Role for another user
      $rolerecord->{'user'}->{$roledomain}->{$roleentity}->{$role}=$thisrole;
   }
# Have the complete rolerecord now, which goes to the user
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      &local_modify_rolerecord($entity,$domain,$rolerecord);
   } else {
      &remote_modify_rolerecord(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain,$rolerecord);
   }
# === Deal with the rolelist lookup table according to type
   if (($type eq 'system') || ($type eq 'domain')) {
# This needs to go to the cluster manager
# Maybe that's us?
      if (&Apache::lc_init_cluster_table::we_are_manager()) {
         &local_modify_rolelist($roleentity,$roledomain,$rolesection,
                                $entity,$domain,
                                $role,
                                $startdate,$enddate,
                                $manualenrollentity,$manualenrolldomain);
      } else {
# No, we are not the cluster manager
         &remote_modify_rolelist(&Apache::lc_connection_utils::cluster_manager_host(),
                                $roleentity,$roledomain,$rolesection,
                                $entity,$domain,
                                $role,
                                $startdate,$enddate,
                                $manualenrollentity,$manualenrolldomain);
      }
   } else {
# Goes on the homeserver of the roleentity
# Maybe that's us?
      if (&Apache::lc_entity_utils::we_are_homeserver($roleentity,$roledomain)) {
         &local_modify_rolelist($roleentity,$roledomain,$rolesection,
                                $entity,$domain,
                                $role,
                                $startdate,$enddate,
                                $manualenrollentity,$manualenrolldomain);
      } else {
# Nope, not us
         &remote_modify_rolelist(&Apache::lc_entity_utils::homeserver($roleentity,$roledomain),
                                $roleentity,$roledomain,$rolesection,
                                $entity,$domain,
                                $role,
                                $startdate,$enddate,
                                $manualenrollentity,$manualenrolldomain);
      }
   }
   return 1;
}

#
# Get a rolelist for an entity, for example a list of all users in a course
#

sub local_lookup_entity_rolelist {
   return &Apache::lc_postgresql::lookup_entity_rolelist(@_);
}

sub local_json_lookup_entity_rolelist {
   return &Apache::lc_json_utils::perl_to_json(&local_lookup_entity_rolelist(@_));
}

sub remote_lookup_entity_rolelist {
   my ($host,$entity,$domain)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'lookup_entity_rolelist',"{entity:'$entity',domain:'$domain'}");
   if ($code eq HTTP_OK) {
      return &Apache::lc_json_utils::json_to_perl($response);
   } else {
      return undef;
   }
}

#
# This is the routine to call
#
sub lookup_entity_rolelist {
   my ($entity,$domain)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_lookup_entity_rolelist($entity,$domain);
   } else {
      return &remote_lookup_entity_rolelist(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain);
   }

}



#
# Dump roles from local data source
#
sub local_dump_roles {
   return &Apache::lc_mongodb::dump_roles(@_);
}

sub local_json_dump_roles {
   return &Apache::lc_json_utils::perl_to_json(&local_dump_roles(@_));
}

#
# Get the roles from elsewhere
#
sub remote_dump_roles {
   my ($host,$entity,$domain)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'dump_roles',
                                               "{ entity : '$entity', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return &Apache::lc_json_utils::json_to_perl($response);
   } else {
      return undef;
   }
}


# Dump current roles for an entity
# Call this one
#
sub dump_roles {
   my ($entity,$domain)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_dump_roles($entity,$domain);
   } else {
      return &remote_dump_roles(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain);
   }
}

# Get all active roles
#
sub active_roles {
   my ($entity,$domain)=@_;
   my $roles=&dump_roles($entity,$domain);
# Check on start and end dates, eliminate non-active roles
# System level
   foreach my $role (keys(%{$roles->{'system'}})) {
      unless (&Apache::lc_date_utils::in_date_range(
                 $roles->{'system'}->{$role}->{'startdate'},
                 $roles->{'system'}->{$role}->{'enddate'})) {
         delete($roles->{'system'}->{$role});
      }
   }
# Domain level
   foreach my $domain (keys(%{$roles->{'domain'}})) {
      foreach my $role (keys(%{$roles->{'domain'}->{$domain}})) {
         unless (&Apache::lc_date_utils::in_date_range(
                    $roles->{'domain'}->{$domain}->{$role}->{'startdate'},
                    $roles->{'domain'}->{$domain}->{$role}->{'enddate'})) {
            delete($roles->{'domain'}->{$domain}->{$role});
         }
      }
   }
# Course level
   foreach my $domain (keys(%{$roles->{'course'}})) {
      foreach my $course (keys(%{$roles->{'course'}->{$domain}})) {
# Across all sections
         foreach my $role (keys(%{$roles->{'course'}->{$domain}->{$course}->{'any'}})) {
            unless (&Apache::lc_date_utils::in_date_range(
                       $roles->{'course'}->{$domain}->{$course}->{'any'}->{$role}->{'startdate'},
                       $roles->{'course'}->{$domain}->{$course}->{'any'}->{$role}->{'enddate'})) {
               delete($roles->{'course'}->{$domain}->{$course}->{'any'}->{$role});
            }
         }
# Within specific sections
         foreach my $section (keys(%{$roles->{'course'}->{$domain}->{$course}->{'section'}})) {
            foreach my $role (keys(%{$roles->{'course'}->{$domain}->{$course}->{'section'}->{$section}})) {
               unless (&Apache::lc_date_utils::in_date_range(
                          $roles->{'course'}->{$domain}->{$course}->{'section'}->{$section}->{$role}->{'startdate'},
                          $roles->{'course'}->{$domain}->{$course}->{'section'}->{$section}->{$role}->{'enddate'})) {
                  delete($roles->{'course'}->{$domain}->{$course}->{'section'}->{$section}->{$role});
               }
            }
         }
      }
   }
   return $roles;
}

BEGIN {
    &Apache::lc_connection_handle::register('modify_rolelist',undef,undef,undef,\&local_modify_rolelist,
                  'roleentity','roledomain','rolesection',
                  'userentity','userdomain',
                  'role',
                  'startdate','enddate',
                  'manualenrollentity','manualenrolldomain');
    &Apache::lc_connection_handle::register('modify_rolerecord',undef,undef,undef,\&local_modify_rolerecord,'entity','domain','rolerecord');
    &Apache::lc_connection_handle::register('dump_roles',undef,undef,undef,\&local_json_dump_roles,'entity','domain');
    &Apache::lc_connection_handle::register('lookup_entity_rolelist',undef,undef,undef,\&local_json_lookup_entity_rolelist,'entity','domain');
}

1;
__END__
