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

use vars qw($roles);
require Exporter;
our @ISA = qw (Exporter);
our @EXPORT = qw(allowed_system allowed_course allowed_section allowed_user);

sub allowed_system {
   my ($action)=@_;
}

sub allowed_domain {
   my ($action,$domain)=@_;
}

sub allowed_course {
   my ($action,$entity,$domain)=@_;
}

sub allowed_section {
   my ($action,$entity,$domain,$section)=@_;
   if (&allowed_course($action,$entity,$domain)) { return 1; }
}

sub allowed_user {
   my ($action,$entity,$domain)=@_;
}


BEGIN {
   unless ($roles) {
      $roles=&Apache::lc_json_utils::json_to_perl(&Apache::lc_file_utils::readfile(&lc_roles_defs()));
      if ($roles) {
         &lognotice("Loaded roles definitions");
      } else {
         &logerror("Could not load roles definitions");
      } 
   }
}

1;
__END__
