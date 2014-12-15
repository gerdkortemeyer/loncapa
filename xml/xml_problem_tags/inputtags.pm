# The LearningOnline Network with CAPA - LON-CAPA
# Problem input tags 
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
package Apache::xml_problem_tags::inputtags;

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

use Apache::lc_logs;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_textline_html start_textline_grade);

sub start_textline_html {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::add_response_input($stack);
   my $size=&Apache::lc_asset_xml::open_tag_attribute('size',$stack);
   unless ($size) { $size=20; }
   my $hidden=&Apache::lc_asset_xml::open_tag_switch('hidden',$stack);
   my $responsedetails=&Apache::lc_asset_xml::get_response_details($token->[2]->{'id'},$stack);
   if (&Apache::lc_asset_xml::enclosed_in('numericalresponse',$stack)) {
      my $data_constants=&Apache::lc_asset_xml::open_tag_attribute('constants',$stack);
      unless ($data_constants) {
         $data_constants='c, pi, e, hbar, amu, G';
      }
      my $value='';
      if (ref($responsedetails) eq 'ARRAY') {
#FIXME: more than one input field
         $value=$responsedetails->[-1]->{'value'};
      } else {
         $value=&Apache::lc_asset_xml::open_tag_attribute('value',$stack);
      }
      my $status='';
      my $message='';
      return
 '<input class="math" data-implicit_operators="true" data-unit_mode="true" data-constants="'.$data_constants.
 '" spellcheck="off" autocomplete="off" name="'.$token->[2]->{'id'}.
 '" size="'.$size.'"'.($hidden?' hidden="hidden"':'').' value="'.$value.'" />'.
#FIXME: not for all
     '['.$status.']['.$message.']';
   }
   return '';
}

sub start_textline_grade {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::add_response_input($stack);
#FIXME: need to adapt to type of response
   my $id=&Apache::lc_asset_xml::open_tag_attribute('id',$stack);


&logdebug("ID: $id ".$stack->{'content'}->{$id});

   &Apache::lc_asset_xml::add_response_details($id,
                                               { 'value' => $stack->{'content'}->{$id} },
                                               $stack);
}
1;
__END__
