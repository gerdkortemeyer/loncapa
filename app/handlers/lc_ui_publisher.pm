# The LearningOnline Network with CAPA - LON-CAPA
# Dealing with publication and rights functions
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
package Apache::lc_ui_publisher;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);
use Apache::lc_entity_sessions();
use Apache::lc_entity_courses();
use Apache::lc_entity_users();
use Apache::lc_ui_utils;
use Apache::lc_json_utils();
use Apache::lc_logs;
use Apache::lc_ui_localize;
use Apache::lc_authorize;
use Apache::lc_xml_forms();
use Apache::lc_file_utils();
use Apache::lc_xml_utils();
use Apache::lc_taxonomy();
use HTML::Entities;

sub taxonomy {
   my ($level,$first,$second)=@_;
   my %taxo;
   if ($level eq 'first') {
      %taxo=&Apache::lc_taxonomy::first_level(&Apache::lc_ui_localize::context_language());
   } elsif ($level eq 'second') {
      %taxo=&Apache::lc_taxonomy::second_level(&Apache::lc_ui_localize::context_language(),$first);
   } else {
      %taxo=&Apache::lc_taxonomy::third_level(&Apache::lc_ui_localize::context_language(),$first,$second);
   }
   return &Apache::lc_json_utils::perl_to_json(\%taxo);
}


sub handler {
   my $r = shift;
   my %content=&Apache::lc_entity_sessions::posted_content();
   if ($content{'command'} eq 'taxonomy') {
      $r->content_type('application/json; charset=utf-8');
      $r->print(&taxonomy($content{'level'},$content{'first'},$content{'second'}));
   }
   return OK;
}
1;
__END__

