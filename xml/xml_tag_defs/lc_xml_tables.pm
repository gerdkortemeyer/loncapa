# The LearningOnline Network with CAPA - LON-CAPA
# Implements elements for tables
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
package Apache::lc_xml_tables;

use strict;
use Apache::lc_entity_courses();
use Apache::lc_ui_localize;
use Apache::lc_ui_utils;

use Data::Dumper;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_lcdatatable_html);

sub start_lcdatatable_html {
   my ($p,$safe,$stack,$token)=@_;
   my $class=$token->[2]->{'class'};
   my $type=$token->[2]->{'type'};
   my $id=$token->[2]->{'id'};
   my $name=$token->[2]->{'name'};
   unless ($name) { $name=$id; }
   my $output='<table id="'.$id.'" name="'.$name.'" class="dataTable">';
   if ($class eq "courseselect") {
      $output.=&courseselect($type);
   }
   $output.='</table>';
   return $output;
}

sub courseselect {
   my ($type)=@_;
   my $output='<thead><tr><th>'.&mt('Domain').'</th><th>'.&mt('Title').'</th></tr></thead><tbody>';
   foreach my $profile (&Apache::lc_entity_courses::active_session_courses()) {
      if ($type eq $profile->{'type'}) {
         $output.='<tr><td>'.&domain_name($profile->{'domain'}).'</td><td>'.$profile->{'title'}.'</td></tr>';
      }
   }
   $output.="</tbody>";
   return $output;
}

1;
__END__
