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
use Apache::lc_date_utils();

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
   my $last_accessed=&Apache::lc_entity_users::last_accessed(&Apache::lc_entity_sessions::user_entity_domain());
   my $output='<thead><tr><th>&nbsp;</th><th>'.&mt('Title').'</th><th>'.&mt('Domain').'</th><th>'.&mt('Last Access').'</th><th>&nbsp;</th></tr></thead><tbody>';
   foreach my $profile (&Apache::lc_entity_courses::active_session_courses()) {
      if ($type eq $profile->{'type'}) {
         my $display_date;
         my $sort_date;
         if ($last_accessed->{$profile->{'domain'}}->{$profile->{'entity'}}) {
             ($display_date,$sort_date)=&Apache::lc_ui_localize::locallocaltime(
                                           &Apache::lc_date_utils::str2num($last_accessed->{$profile->{'domain'}}->{$profile->{'entity'}}));
         } else {
             $display_date=&mt('Never');
             $sort_date=0;
         }
         $output.="\n".'<tr><td><span class="lcformtrigger"><a href="#" id="select_'.$profile->{'entity'}.'_'.$profile->{'domain'}.
                  '" onClick="select_course('."'".$profile->{'entity'}."','".$profile->{'domain'}."')".'">'.&mt('Select').
                  '</a></span></td><td>'.$profile->{'title'}.'</td><td>'.&domain_name($profile->{'domain'}).'</td><td>'.
                  ($sort_date?'<time datetime="'.$sort_date.'">':'').
                  $display_date.($sort_date?'</time>':'').'</td><td>'.$sort_date.'</td></tr>';
      }
   }
   $output.="</tbody>";
   return $output;
}

1;
__END__
