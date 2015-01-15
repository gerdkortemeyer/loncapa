# The LearningOnline Network with CAPA - LON-CAPA
# Things having to do with hints
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
package Apache::xml_problem_tags::hints;

use strict;
use Apache::lc_asset_xml();
use Apache::lc_problem_const;

use Apache::lc_logs;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_hintgroup_html end_hintgroup_html start_hint_html end_hint_html);

sub start_hintgroup_html {
   my ($p,$safe,$stack,$token)=@_;
# Starting a new hintgroup, clear all previous stuff
   $stack->{'hintgroup'}=[];
   $stack->{'active_hintgroup'}=1;
   return '';
}

#
# At the end of a hintgroup the redirection stack is examined
# and the relevant elements out
# Redirection within the hintgroup was needed because of "hintgroupdefault"
#
sub end_hintgroup_html {
   my ($p,$safe,$stack,$token)=@_;
   my $output='';
   my $problemid=&Apache::lc_asset_xml::tag_attribute('problem','id',$stack);
# First see if we need default
   my $found=0;
   foreach my $hint (@{$stack->{'hintgroup'}}) {
      if ($hint->{'on'}=~/\S/s) {
         if (&on_applies($stack,$problemid,$hint->{'on'})) {
            $found=1;
            last;
         }
      }
   }
# Now for real
   foreach my $hint (@{$stack->{'hintgroup'}}) {
use Data::Dumper;
&logdebug(Dumper($hint));
      if ($found) {
         if (&on_applies($stack,$problemid,$hint->{'on'})) {
            if (($hint->{'showoncorrect'}) || (&not_correct($stack,$problemid,$hint->{'on'}))) {
               $output.=&Apache::lc_asset_xml::get_redirected_output($hint->{'id'},$stack);
            }
         }
      } else {
# We are displaying the default hint(s) within this hintgroup
         if ($hint->{'hintgroupdefault'}) {
            if (($hint->{'showoncorrect'}) || (&not_correct($stack,undef,undef))) {
               $output.=&Apache::lc_asset_xml::get_redirected_output($hint->{'id'},$stack);
            }
         }
      }
   }
# Just clean up
   $stack->{'hintgroup'}=[];
   $stack->{'active_hintgroup'}=0;
   return $output;
}

#
# A particular hint
# If we are in a hintgroup, just remember, otherwise skip to end hint if not applicable
#
sub start_hint_html {
   my ($p,$safe,$stack,$token)=@_;
   if ($stack->{'active_hintgroup'}) {
# We are in a hint group
# Remember this for </hintgroup>
      push(@{$stack->{'hintgroup'}},{
                                   'id' => $token->[2]->{'id'}, 
                                   'on' => $token->[2]->{'on'},
                                   'hintgroupdefault' => &Apache::lc_asset_xml::open_tag_switch('hintgroupdefault',$stack),
                                   'showoncorrect' => &Apache::lc_asset_xml::cascade_switch('showoncorrect',$stack) 
                                 });
# Redirect, since we don't know yet if we need this
      &Apache::lc_asset_xml::set_redirect($token->[2]->{'id'},$stack);
   } else {
# We are not in a hintgroup, nothing to worry about.
      my $problemid=&Apache::lc_asset_xml::tag_attribute('problem','id',$stack);
      my $showhint=0;
      if (&on_applies($stack,$problemid,$token->[2]->{'on'})) {
         if ((&Apache::lc_asset_xml::cascade_switch('showoncorrect',$stack)) || (&not_correct($stack,$problemid,$token->[2]->{'on'}))) {
            $showhint=1;
         }
      }
# If the hint should not be shown, skip all the way to the end of it
      unless ($showhint) {
         $p->get_text('/hint');
         $p->get_token;
         pop(@{$stack->{'tags'}});
      }
   }
# Nothing to say
   return '';
}

sub on_applies {
   my ($stack,$problemid,$on)=@_;
   if ($on!~/\S/s) { return 1; }
   return $stack->{'hint_conditions'}->{$problemid}->{$on}->{'hintapplies'};
}

sub not_correct {
   my ($stack,$problemid,$on)=@_;
   if ($on=~/\S/s) {
# We have a condition, check if the corresponding response is correct
      return !($stack->{'hint_conditions'}->{$problemid}->{$on}->{'responsecorrect'});
   } else {
# There is no condition, and thus we can only look at the whole part
      return ($stack->{'context'}->{'part_status'}->{'outcome'} ne &correct());
   }
}

sub end_hint_html {
   my ($p,$safe,$stack,$token)=@_;
   if ($stack->{'active_hintgroup'}) {
# Done redirecting
      &Apache::lc_asset_xml::clear_redirect($stack);
   }
   return '';
}

#
# Set the flag if a hint is true
# Name of hint, value of answer, stack
#
sub set_hints {
   my ($name,$value,$outcome,$stack)=@_;
   if ($value) { $value=1; } else { $value=0; }
   if ($outcome) { $outcome=1; } else { $outcome=0; } 
   $stack->{'hint_conditions'}->{&Apache::lc_asset_xml::tag_attribute('problem','id',$stack)}->{$name}=
      { 'hintapplies' => $value, 'responsecorrect' => $outcome };
}

1;
__END__
