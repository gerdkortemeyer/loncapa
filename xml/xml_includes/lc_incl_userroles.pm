# The LearningOnline Network with CAPA - LON-CAPA
# Include handlers for user roles
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
package Apache::lc_incl_userroles;

use strict;
use Apache::lc_json_utils();
use Apache::lc_file_utils();
use Apache::lc_xml_utils();
use Apache::lc_xml_forms();

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(incl_spreadsheet_finalize_items);

sub incl_spreadsheet_finalize_items {
   my %content=&Apache::lc_entity_sessions::posted_content();
   my $output=&Apache::lc_xml_forms::hidden_vars(%content);
   return $output;

   my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();

   my $sheets=&Apache::lc_json_utils::json_to_perl(
                &Apache::lc_file_utils::readfile(
                   &Apache::lc_entity_urls::wrk_to_filepath($domain.'/'.$entity.'/uploaded_spreadsheet.json')));
   unless ($sheets) {
      return &Apache::lc_xml_utils::error_message('Could not interpret spreadsheet data. Please make sure your file has the proper extension (e.g., ".xls") or try another format.');
   }
# We have a valid spreadsheet. Now have to see if we have all the information we need
#   foreach my $col ($sheets->{$worksheet}->{'col_min'} .. $sheets->{$worksheet}->{'col_max'}) {
#      $output.="\n<tr><td><pre>";
#      my $found=0;
#      foreach my $row ($sheets->{$worksheet}->{'row_min'} .. $sheets->{$worksheet}->{'row_max'}) {
#         if ($sheets->{$worksheet}->{'cells'}->{$row}->{$col}->{'value'}) {
#            $output.=$sheets->{$worksheet}->{'cells'}->{$row}->{$col}->{'value'}."\n";
#            $found++;
#         }
#         if ($found>5) { last; }
#      }
#      $output.="</pre></td><td>\n";
#      my $default='nothing';
#      my $id=&Apache::lc_xml_utils::form_escape($worksheet.'c'.$col);
#      if ($screen_form_defaults->{$id}) {
#         $default=$screen_form_defaults->{$id};
#      }
#      $output.=&selectfield($id,$id,$values,$choices,$default,$stack->{'tags'}->[-1]->{'args'}->{'verify'});
#      $output.="</td></tr>";
#   #}
#   $output.='</tbody></table>';
}

sub handler {
   my $r=shift;
   $r->print(&incl_spreadsheet_finalize_items());
}

1;
__END__
