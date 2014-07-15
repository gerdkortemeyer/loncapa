# The LearningOnline Network with CAPA - LON-CAPA
# Include handler modifying course users
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
package Apache::lc_incl_modify_courseusers;

use strict;
use Apache::lc_json_utils();
use Apache::lc_file_utils();
use Apache::lc_xml_utils();
use Apache::lc_authorize;
use Apache::lc_ui_localize;
use Apache::lc_xml_forms();
use Apache::lc_entity_users();
use Apache::lc_entity_roles();
use Apache::lc_entity_profile();
use Apache::lc_logs;
use Apache2::Const qw(:common);


use Data::Dumper;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(incl_modify_courseusers_finalize);

sub incl_modify_courseusers_finalize {
# Get posted content
   my %content=&Apache::lc_entity_sessions::posted_content();
   my $output='';
# Storage or display stage?
   if ($content{'stage_two'}) {
# We actually store things
#FIXME
   } else {
# We are presenting data
      my $modifyusers;
# Is this just one user or possibly multiple?
      if (($content{'user_username'}) && ($content{'user_domain'})) {
# Just one
         $modifyusers->[0]->{'username'}=$content{'user_username'};
         $modifyusers->[0]->{'domain'}=$content{'user_domain'};
      } else {
# Possibly multiple
         $modifyusers=&Apache::lc_json_utils::json_to_perl($content{'postdata'});
      }
#FIXME: debug
      $output.='<pre>'.Dumper($modifyusers).'</pre>';
   }
   $output.=join("\n<br />",map { $_.'='.$content{$_} } keys(%content));
   return $output;
}

sub handler {
   my $r=shift;
   $r->print(&incl_modify_courseusers_finalize());
   return OK;
}

1;
__END__
