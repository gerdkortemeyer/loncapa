# The LearningOnline Network with CAPA - LON-CAPA
# Utilities for entities
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
package Apache::lc_entity_utils;

use strict;
use DBI;
use Data::Uniqid qw(luniqid);
use Digest::MD5 qw(md5_hex);

use Apache::lc_logs;


# ================================================================
# IDs
# ================================================================
# ==== Generate a unique ID
sub make_unique_id {
   return &luniqid();
}

# === Oneway encryption of entities
# Takes domain,entity
# or any other array of strings
sub oneway {
   return md5_hex(@_);
}

# ================================================================
# Convert stuff to entities
# ================================================================
# ==== Usernames to entities
#
sub username_to_entity {
   my ($username,$domain)=@_;
}

# ==== PIDs to entities
#
sub pid_to_entity {
   my ($pid,$domain)=@_;
}

# ==== CourseIDs to entities
#
sub courseid_to_entity {
   my ($courseid,$domain)=@_;
}


1;
__END__
