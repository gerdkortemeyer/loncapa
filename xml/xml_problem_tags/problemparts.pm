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
use Apache::lc_entity_sessions();
use Apache::lc_entity_users();
use Apache::lc_asset_xml();
use Apache::lc_json_utils();
use Apache::lc_entity_assessments();
use Apache::lc_xml_forms();
use Apache::lc_xml_standard();
use Apache::lc_logs;
use Apache::lc_problem_const;
use Apache::lc_ui_localize;

use Data::Dumper;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_problem_html end_problem_html
                 start_problem_grade end_problem_grade
                 start_part_html    end_part_html
                 start_part_grade   end_part_grade);

sub start_problem_html {
   my ($p,$safe,$stack,$token)=@_;
   &init_problem($token->[2]->{'id'},$stack);
   return &Apache::lc_xml_standard::begin_html(@_).
          &Apache::lc_xml_standard::begin_head(@_).
          &Apache::lc_xml_standard::end_head(@_).
          &Apache::lc_xml_standard::begin_body(@_).
          '<div class="lcproblemdiv" id="'.$token->[2]->{'id'}.'">';
}

sub end_problem_html {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_random::popseed();
   return '</div>';
}

sub start_problem_grade {
   my ($p,$safe,$stack,$token)=@_;
   &init_problem($token->[2]->{'id'},$stack);
}

sub end_problem_grade {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_random::popseed();
}

sub start_part_html {
   my ($p,$safe,$stack,$token)=@_;
# Remember what part we are
   $stack->{'context'}->{'asset'}->{'partid'}=$token->[2]->{'id'};
# Load the data for the part
   &load_part_data($stack);
# Figure out if we are correct for the inputs
   $stack->{'context'}->{'part_status'}={};
   if (ref($stack->{'scoredata'}) eq 'ARRAY') {
      foreach my $partdata (@{$stack->{'scoredata'}}) {
         if ($partdata->[0] eq $token->[2]->{'id'}) {
            $stack->{'context'}->{'part_status'}->{'outcome'}=$partdata->[5];
            $stack->{'context'}->{'part_status'}->{'countedtries'}=$partdata->[4];
            $stack->{'context'}->{'part_status'}->{'totaltries'}=$partdata->[3];

         }
      }
   }
# Set the random see for the part
   &Apache::lc_random::set_context_random_seed(&Apache::lc_random::contextseed($stack->{'context'},
                                                                               $token->[2]->{'id'}));
# Produce the output
   return '<div class="lcpartdiv" id="'.$token->[2]->{'id'}.'">'.
          '<form id="'.$token->[2]->{'id'}.'_form" name="'.$token->[2]->{'id'}.'_form" class="lcpartform">'.
          &Apache::lc_xml_forms::hidden_field('assetid',$stack->{'context'}->{'asset'}->{'assetid'}).
          &Apache::lc_xml_forms::hidden_field('partid',$token->[2]->{'id'}).
          &Apache::lc_xml_forms::hidden_field('newsubmission',1);
}

sub end_part_html {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_random::popseed();
   my $problemid=&Apache::lc_asset_xml::tag_attribute('problem','id',$stack);
   my $partid=&Apache::lc_asset_xml::open_tag_attribute('id',$stack);
   my $output='';
#FIXME: out of tries, etc, if(1) - debug
   if (($stack->{'context'}->{'state'} eq &answerable()) &&
       ($stack->{'context'}->{'part_status'}->{'outcome'} ne &correct())) {
      $output.='<p>'.&Apache::lc_xml_forms::triggerbutton($partid.'_submit_button','Submit').'</p>';
   }
#FIXME: if feedback is off, don't say anything
   if (1) {
#FIXME: more statusses possible
      $output.="\n<div class='lcpartfeedback'>\n";
      if ($stack->{'context'}->{'part_status'}->{'outcome'}  eq 'correct') {
         $output.="<div class='lccorrectpart'><span class='lcpartfeedbackmessage'>".&mt("Correct.");
      } elsif ($stack->{'context'}->{'part_status'}->{'outcome'} eq 'incorrect') {
         $output.="<div class='lcincorrectpart'><span class='lcpartfeedbackmessage'>".&mt("Incorrect.");
      } else {
         $output.="<div class='lcinvalidpart'><span class='lcpartfeedbackmessage'>".&mt("Ungraded.");
      }
      $output.='</span><br />'.&mt("Total tries: [_1]",$stack->{'context'}->{'part_status'}->{'totaltries'});
      $output.='<br />'.&mt("Counted tries: [_1]",$stack->{'context'}->{'part_status'}->{'countedtries'});
      $output.="\n</div></div>\n";
   }
   $output.='</form><script>attach_submit_button("'.$problemid.'","'.$partid.'")</script></div>';
   return $output;
}

sub start_part_grade {
   my ($p,$safe,$stack,$token)=@_;
   $stack->{'context'}->{'asset'}->{'partid'}=$token->[2]->{'id'};
   $stack->{'response_grades'}->{$token->[2]->{'id'}}={};
   $stack->{'response_hints'}={};
   &load_part_data($stack);
   &Apache::lc_random::set_context_random_seed(&Apache::lc_random::contextseed($stack->{'context'},
                                                                               $token->[2]->{'id'}));
}

sub end_part_grade {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_random::popseed();
# Collect all of the response status
   my $allcorrect=1;
   my $allprevious=1;
   my $allinvalid=1;
   my $allvalid=1;

   foreach my $responseid (keys(%{$stack->{'response_grades'}->{$stack->{'context'}->{'asset'}->{'partid'}}})) {
       my $responsestatus=$stack->{'response_grades'}->{$stack->{'context'}->{'asset'}->{'partid'}}->{$responseid};
       unless ($responsestatus->{'previously_submitted'}) { $allprevious=0; }
       if ($responsestatus->{'status'} ne &correct()) { $allcorrect=0; }
       if ($responsestatus->{'status'} ne &no_valid_response()) { $allinvalid=0; }
       if (($responsestatus->{'status'} ne &correct()) &&
           ($responsestatus->{'status'} ne &incorrect())) { $allvalid=0; } 
   }
   if ($allinvalid) {
# Nothing to grade, good bye
      return;
   } else {
# One more try
      $stack->{'scores'}->{'totaltries'}++;
   }
   $stack->{'scores'}->{'status'}=&incorrect();
#FIXME: absolute possible
   $stack->{'scores'}->{'scoretype'}='relative';
   $stack->{'scores'}->{'score'}=0;
   if ($allcorrect) {
      $stack->{'scores'}->{'status'}=&correct();
#FIXME: absolute and partial credit
      $stack->{'scores'}->{'score'}=1;
   }
   if (($allvalid) && (!$allprevious)) { 
      $stack->{'scores'}->{'countedtries'}++; 
   }
# Save the information
   unless (&save_part_data($stack)) {
      &logerror("Could not save part infomation");
#FIXME: don't leave the user in the dark
   }
}

# =============================================
# Initialize problem
# =============================================

sub init_problem {
   my ($id,$stack)=@_;
   $stack->{'scoredata'}=&Apache::lc_entity_assessments::get_one_user_assessment(
              $stack->{'context'}->{'course'}->{'entity'},
              $stack->{'context'}->{'course'}->{'domain'},
              $stack->{'context'}->{'user'}->{'entity'},
              $stack->{'context'}->{'user'}->{'domain'},
              $stack->{'context'}->{'asset'}->{'assetid'});
#FIXME: actually determine
   $stack->{'context'}->{'randversion'}=0;
   &Apache::lc_random::set_context_random_seed(&Apache::lc_random::contextseed($stack->{'context'},$id));
}

# =============================================
# Generate seed for problem/part
# =============================================

# =============================================
# Loading and saving part data
# =============================================

#
# Get the stored data for a problem part
#
sub load_part_data {
   my ($stack)=@_;
   if (ref($stack->{'scoredata'}) eq 'ARRAY') {
# Let's see if we find existing data for this part
      foreach my $partdata (@{$stack->{'scoredata'}}) {
         if ($partdata->[0] eq $stack->{'context'}->{'asset'}->{'partid'}) {
            ($stack->{'scores'}->{'partid'},
             $stack->{'scores'}->{'scoretype'},
             $stack->{'scores'}->{'score'},
             $stack->{'scores'}->{'totaltries'},
             $stack->{'scores'}->{'countedtries'},
             $stack->{'scores'}->{'status'},
             my $responsedetailsjson)=@{$partdata};
            if ($responsedetailsjson) {
               $stack->{'response_details'}=&Apache::lc_json_utils::json_to_perl($responsedetailsjson);
            }
            return;
         }
      }
   }
# Nope, none found, start with clean slate
   delete($stack->{'scores'});
   $stack->{'scores'}->{'partid'}=$stack->{'context'}->{'asset'}->{'partid'};
   $stack->{'scores'}->{'totaltries'}=0;
   $stack->{'scores'}->{'countedtries'}=0;
}

#
# Save the data from a problem part
#
sub save_part_data {
   my ($stack)=@_;
   if ($stack->{'context'}->{'asset'}->{'partid'} ne
       $stack->{'scores'}->{'partid'}) {
      &logerror("Partid mismatch, scores for [".$stack->{'scores'}->{'partid'}."], but record for [".
                                                $stack->{'context'}->{'asset'}->{'partid'}."]");
      return 0;
   }
   return &Apache::lc_entity_assessments::store_assessment(
                                     $stack->{'context'}->{'course'}->{'entity'},
                                     $stack->{'context'}->{'course'}->{'domain'},
                                     $stack->{'context'}->{'user'}->{'entity'},
                                     $stack->{'context'}->{'user'}->{'domain'},
                                     $stack->{'context'}->{'asset'}->{'assetid'},
                                     $stack->{'context'}->{'asset'}->{'partid'},
                                     $stack->{'scores'}->{'scoretype'},
                                     $stack->{'scores'}->{'score'},
                                     $stack->{'scores'}->{'totaltries'},
                                     $stack->{'scores'}->{'countedtries'},
                                     $stack->{'scores'}->{'status'},
                                     &Apache::lc_json_utils::perl_to_json($stack->{'response_details'}));
}

1;
__END__
