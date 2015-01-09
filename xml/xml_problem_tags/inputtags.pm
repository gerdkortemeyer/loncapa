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
use Apache::lc_problem_const;

use Apache::lc_logs;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_textline_html start_textline_grade);

sub textboxmessaging {
   my ($id,$status,$message)=@_;
   if (($status ne 'no_valid_response') &&
       ($status ne 'correct') &&
       ($status ne 'incorrect')) {
      return '<span class="lcresponseerror" id="'.$id.'_message">'.&mt($status).($message=~/\S/s?': '.$message:'').'</span><script>attach_textfield_message("'.$id.'");</script>';
   } else {
      return '';
   }
}

sub show_entered_text {
   my ($id,$value)=@_;
   if ($value=~/\S/s) {
      return '<span class="lcshowenteredtext">'.$value.'</span>'.
             &Apache::lc_xml_forms::hidden_field($id,$value);
   } else {
      return '<span class="lcshowenteredtext">&nbsp;&nbsp;</span>';
   }
}

sub show_answer_text {
   my ($value)=@_;
   if ($value=~/\S/s) {
      return '<span class="lcshowanswertext">'.$value.'</span>';
   } else {
      return '<span class="lcshowanswertext">&nbsp;&nbsp;</span>';
   }
}

sub start_textline_html {
   my ($p,$safe,$stack,$token)=@_;
# Another one!
   $stack->{'response_input_count'}++;
# Pick up some parameters that are the same for all flavors of textline
   my $size=&Apache::lc_asset_xml::open_tag_attribute('size',$stack);
   unless ($size) { $size=20; }
   my $hidden=&Apache::lc_asset_xml::open_tag_switch('hidden',$stack);
# Get previously entered answers
   my $responsedetails=&Apache::lc_asset_xml::get_response_details($token->[2]->{'id'},$stack);
   my $value='';
   if (ref($responsedetails) eq 'ARRAY') {
      $value=$responsedetails->[-1]->{'value'};
   } else {
      $value=&Apache::lc_asset_xml::open_tag_attribute('value',$stack);
   }
# Closed? Then just show what was entered before
   if ($stack->{'context'}->{'state'} eq &closed()) {
      return &show_entered_text($token->[2]->{'id'},$value);
   }
# Get response status
   my $correct=($stack->{'context'}->{'part_status'}->{'outcome'} eq &correct());
   my $showanswer=($stack->{'context'}->{'state'} eq &show_answer());
# Now deal with the different flavors for different responses
   if (&Apache::lc_asset_xml::enclosed_in('numericalresponse',$stack)) {
# Deal with show_answer. Challenge: multiple fields
      if (($showanswer) || ($correct)) {
         my $output=&show_entered_text($token->[2]->{'id'},$value);
         if ($showanswer) {
            my $ans='';
# How many input fields are there?
            my $num_inputs=$#{$stack->{'response_inputs'}->{$stack->{'response_id'}}};
            if ($num_inputs>0) {
# There are several input fields
               my $answer=&Apache::lc_asset_xml::cascade_attribute('answer',$stack);
               unless ($answer=~/\S/) { $answer=0; }
               my $unit=&Apache::lc_asset_xml::cascade_attribute('unit',$stack);
               unless ($unit) { $unit=''; }
               if (ref($answer) eq 'ARRAY') {
# Multidimensional answer given as an array
                  my $num_answers=$#{$answer};
                  if ($stack->{'response_input_count'}-1<=$num_answers) {
                     $ans=$answer->[$stack->{'response_input_count'}-1].($unit?' '.$unit:'');
                  }
               } else {
# Multidimensional answer given as a string
                  $answer=~s/[\[\{\}\]]//gs;
                  $ans=(split(/\s*\;\s*/,$answer))[$stack->{'response_input_count'}-1].($unit?' '.$unit:'');
               }
            } else {
# Only one input field, just concatinate
               my $mode=&Apache::lc_asset_xml::cascade_attribute('mode',$stack);
               $ans=&Apache::xml_problem_tags::numericalresponse::evaluate_show_answer($stack,$mode);
# Eliminate possible spurious parantheses around numerical value
               $ans=~s/^\s*\((.+)\)\s*([^\)]*)$/$1 $2/;
               if ($mode eq 'lt') { $ans='<'.$ans; }
               if ($mode eq 'le') { $ans='<='.$ans; }
               if ($mode eq 'gt') { $ans='>'.$ans; }
               if ($mode eq 'ge') { $ans='>='.$ans; }
               if ($mode eq 'ne') { $ans='<>'.$ans; }
            }
            $output.=&show_answer_text($ans);
         }
         return $output;
      } 
# We are answerable!
      my $data_constants=&Apache::lc_asset_xml::open_tag_attribute('constants',$stack);
      unless ($data_constants) {
         $data_constants='c, pi, e, hbar, amu, G';
      }
      my $responsegrade=&Apache::lc_asset_xml::get_response_grade('numericalresponse',$stack);
      return
 '<input class="math" data-implicit_operators="true" data-unit_mode="true" data-constants="'.$data_constants.
 '" spellcheck="off" autocomplete="off" name="'.$token->[2]->{'id'}.'" id="'.$token->[2]->{'id'}.
 '" size="'.$size.'"'.($hidden?' hidden="hidden"':'').' value="'.
 &Apache::lc_xml_utils::form_escape($value).'" />'.
 &textboxmessaging($token->[2]->{'id'},$responsegrade->{'status'},$responsegrade->{'message'});
   }
# Unknown flavor
   return '';
}

sub start_textline_grade {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::add_response_input($stack);
#FIXME: need to adapt to type of response
   my $id=&Apache::lc_asset_xml::open_tag_attribute('id',$stack);
   &Apache::lc_asset_xml::add_response_details($id,
                                               { 'value' => $stack->{'content'}->{$id} },
                                               $stack);
}
1;
__END__
