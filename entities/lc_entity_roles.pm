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
use DBI;
use Apache::lc_logs;

#
# Modify a role
# This needs to update two data-source:
# * The user's record of roles (authoritative)
# * The entity's record (domain or system)

sub modify_role {
   my ($entity,$domain, # who gets the role?
       $roleentity,$roledomain,$rolesection, # what's the realm?
       $role, # what role is this?
       $startdate,$enddate, # duration
       $manualenrollentity,$manualenrolldomain # if done manually, who did this?
      )=@_;
}

BEGIN {
}
1;
__END__
