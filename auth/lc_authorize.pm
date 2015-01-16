# The LearningOnline Network with CAPA - LON-CAPA
# Deal with authorization
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
package Apache::lc_authorize;

use strict;
use Apache::lc_file_utils();
use Apache::lc_json_utils();
use Apache::lc_parameters;
use Apache::lc_logs;
use Apache::lc_entity_sessions();
use Apache::lc_entity_courses();

use vars qw($privileges);
require Exporter;
our @ISA = qw (Exporter);
our @EXPORT = qw(allowed_system allowed_domain allowed_course allowed_section allowed_user allowed_any_section);

# Check privileges on system-level, going through all system roles
# $action is the action (e.g., "view_user")
# $item is any sub-action
#
sub allowed_system {
   my ($action,$item)=@_;
   my $roles=&Apache::lc_entity_sessions::roles();
   foreach my $role (keys(%{$roles->{'system'}})) {
      if ($privileges->{$role}->{'system'}->{$action} eq '1') { return 1; }
      if ($item) {
         if ($privileges->{$role}->{'system'}->{$action}->{$item} eq '1') { return 1; }
      }
   }
   return 0;
}

# Check privileges on domain-level and above
# $action is the action (e.g., "view_user")
# $item is any sub-action
# $domain is the domain that will be affected
#
sub allowed_domain {
   my ($action,$item,$domain)=@_;
   if (&allowed_system($action,$item)) { return 1; }
   my $roles=&Apache::lc_entity_sessions::roles();
   foreach my $role (keys(%{$roles->{'domain'}->{$domain}})) {
      if ($privileges->{$role}->{'domain'}->{$action} eq '1') { return 1; }
      if ($item) {
         if ($privileges->{$role}->{'domain'}->{$action}->{$item} eq '1') { return 1; }
      }
   }
   return 0;
}

# Check privileges on course-level and above
# $action is the action (e.g., "view_user")
# $item is any sub-action
# $entity, $domain are the course that will be affected
#
sub allowed_course {
   my ($action,$item,$entity,$domain)=@_;
   if (&allowed_domain($action,$item,$domain)) { return 1; }
   my $roles=&Apache::lc_entity_sessions::roles();
   foreach my $role (keys(%{$roles->{'course'}->{$domain}->{$entity}->{'any'}})) {
      if ($privileges->{$role}->{'course'}->{$action} eq '1') { return 1; }
      if ($item) {
         if ($privileges->{$role}->{'course'}->{$action}->{$item} eq '1') { return 1; }
      }
   }
   return 0;
}

# Check privileges on section-level and above
# $action is the action (e.g., "view_user")
# $item is any sub-action
# $entity, $domain are the course that will be affected
# $section should be the section that will be affected, for
# example the section that a student is in who will be graded
#
sub allowed_section {
   my ($action,$item,$entity,$domain,$section)=@_;
   if (&allowed_course($action,$item,$entity,$domain)) { return 1; }
   my $roles=&Apache::lc_entity_sessions::roles();
   foreach my $role (keys(%{$roles->{'course'}->{$domain}->{$entity}->{'section'}->{$section}})) {
      if ($privileges->{$role}->{'section'}->{$action} eq '1') { return 1; }
      if ($item) {
         if ($privileges->{$role}->{'section'}->{$action}->{$item} eq '1') { return 1; }
      }
   }
   return 0;
}

# Check privileges on user-level and above
# $action is the action (e.g., "view_user")
# $item is any sub-action
# $entity, $domain is the user that will be affected
#
sub allowed_user {
   my ($action,$item,$entity,$domain)=@_;
   if (&allowed_domain($action,$item,$domain)) { return 1; }
   my $roles=&Apache::lc_entity_sessions::roles();
   foreach my $role (keys(%{$roles->{'user'}->{$domain}->{$entity}})) {
      if ($privileges->{$role}->{'user'}->{$action} eq '1') { return 1; }
      if ($item) {
         if ($privileges->{$role}->{'user'}->{$action}->{$item} eq '1') { return 1; }
      }
   }
   return 0;
}

#
# Allowed in any section of the course?
# Will return true if the action is allowed for any section
# - just see if some functionality should be pulled up in the first
# place, but before actually doing anything, the particular section
# needs to be checked.
# $action is the action (e.g., "view_user")
# $item is any sub-action
# $entity, $domain are the course that will be affected
#
sub allowed_any_section {
   my ($action,$item,$entity,$domain)=@_;
   if (&allowed_course($action,$item,$entity,$domain)) { return 1; }
   my $roles=&Apache::lc_entity_sessions::roles();
   foreach my $section (keys(%{$roles->{'course'}->{$domain}->{$entity}->{'section'}})) {
      foreach my $role (keys(%{$roles->{'course'}->{$domain}->{$entity}->{'section'}->{$section}})) {
         if ($privileges->{$role}->{'section'}->{$action} eq '1') { return 1; }
         if ($item) {
            if ($privileges->{$role}->{'section'}->{$action}->{$item} eq '1') { return 1; }
         }
      }
   }
   return 0;
}

#
# Roles available in the system
#
sub all_roles {
   my ($realm)=@_;
   my @all_roles=();
   foreach my $thisrole (keys(%{$privileges})) {
      if ($realm) {
         if ($privileges->{$thisrole}->{'realm'} eq $realm) {
            push(@all_roles,$thisrole);
         }
      } else {
         push(@all_roles,$thisrole);
      }
   }
   return @all_roles;
}

#
# Should this role have a portfolio space?
#
sub should_have_portfolio {
   my ($role)=@_;
   if (($privileges->{$role}->{'realm'} eq 'regular') ||
       ($privileges->{$role}->{'realm'} eq 'community')) {
      return 1;
   }
   return 0;
}
#
# Course roles that this user can modify 
# Returns a hash with "1" for allowed roles
#
sub modifiable_course_roles {
   my %roles=();
   foreach my $thisrole (sort(&all_roles(&Apache::lc_entity_courses::course_type(&Apache::lc_entity_sessions::course_entity_domain())))) {
      if (&allowed_any_section('modify_role',$thisrole,&Apache::lc_entity_sessions::course_entity_domain())) {
         $roles{$thisrole}=1;
      }
   }
   return %roles;
}


#
# This loads the role definitions into a global variable $permission
# for quick lookup. The role definitions specify what roles can do on
# which levels
#
BEGIN {
   unless ($privileges) {
      $privileges=&Apache::lc_json_utils::json_to_perl(&Apache::lc_file_utils::readfile(&lc_roles_defs()));
      if ($privileges) {
         &lognotice("Loaded roles definitions");
      } else {
         &logerror("Could not load roles definitions");
      } 
   }
}

1;
__END__
