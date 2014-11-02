# The LearningOnline Network with CAPA - LON-CAPA
# Problem and part tags 
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
package Apache::xml_problem_tags::problemparts;

use strict;
use Apache::lc_ui_localize;
use Apache::lc_ui_utils;
use Apache::lc_date_utils;
use Apache::lc_ui_localize();
use Apache::lc_xml_utils();
use Apache::lc_entity_sessions();
use Apache::lc_entity_users();
use Apache::lc_xml_forms();
use Apache::lc_asset_xml();

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_problem_html end_problem_html
                 start_part_html    end_part_html);

sub start_problem_html {
   my ($p,$safe,$stack,$token)=@_;
   return '<div class="lcproblemdiv">';
}

sub end_problem_html {
   my ($p,$safe,$stack,$token)=@_;
   return '</div>';
}

sub start_part_html {
   my ($p,$safe,$stack,$token)=@_;
   return '<div class="lcpartdiv">'.
          '<form id="'.$token->[2]->{'id'}.'" name="'.$token->[2]->{'id'}.'" class="lcpartform">';
}

sub end_part_html {
   my ($p,$safe,$stack,$token)=@_;
   return '<input type="submit" /></form></div>';
}


1;
__END__
