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
package Apache::lc_incl_publisher;

use strict;
use Apache::lc_json_utils();
use Apache::lc_file_utils();
use Apache::lc_xml_utils();
use Apache::lc_authorize;
use Apache::lc_ui_localize;
use Apache::lc_xml_forms();
use Apache::lc_xml_gadgets();
use Apache::lc_entity_users();
use Apache::lc_entity_roles();
use Apache::lc_entity_profile();
use Apache::lc_logs;
use Apache2::Const qw(:common);


use Data::Dumper;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(incl_publisher_screens);

sub incl_publisher_screens {
# Get posted content
   my %content=&Apache::lc_entity_sessions::posted_content();
   my $metadata=&Apache::lc_entity_urls::dump_metadata($content{'entity'},$content{'domain'});
   my $output='';
   $output.=&Apache::lc_xml_forms::hidden_field('entity',$content{'entity'}).
            &Apache::lc_xml_forms::hidden_field('domain',$content{'domain'}).
            &Apache::lc_xml_forms::hidden_field('url',$content{'url'});
   if ($content{'stage_two'}) {
   } else {
      $output.='<h1>'.&mt('Title').'</h1>';
      $output.=&Apache::lc_xml_forms::inputfield('text','title','title',40,$metadata->{'title'});
   }
   return $output;
}

sub handler {
   my $r=shift;
   $r->print(&incl_publisher_screens());
   return OK;
}

1;
__END__
