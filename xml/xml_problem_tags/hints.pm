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
   return '';
}

#
# At the end of a hintgroup the redirection stack is examined
# and the relevant elements out
# Redirection was needed because of "default"
#
sub end_hintgroup_html {
   my ($p,$safe,$stack,$token)=@_;
   my $output='';
   my $problemid=&Apache::lc_asset_xml::tag_attribute('problem','id',$stack);
# First see if we need default
   my $found=0;
   foreach my $hint (@{$stack->{'hintgroup'}}) {
      if ($hint->{'on'}=~/\S/s) {
         if ($stack->{'hint_conditions'}->{$problemid}->{$hint->{'on'}}) {
            $found=1;
            last;
         }
      }
   }
# Now for real
   foreach my $hint (@{$stack->{'hintgroup'}}) {
      if ($found) {
         if ($stack->{'hint_conditions'}->{$problemid}->{$hint->{'on'}}) {
            $output.=&Apache::lc_asset_xml::get_redirected_output($hint->{'id'},$stack);
         }
      } else {
# We are displaying the default hint(s)
         if ($hint->{'default'}) {
            $output.=&Apache::lc_asset_xml::get_redirected_output($hint->{'id'},$stack);
         }
      }
   }
# Just clean up
   $stack->{'hintgroup'}=[];
   return $output;
}

#
# A particular hint
# Just remember
#
sub start_hint_html {
   my ($p,$safe,$stack,$token)=@_;
# Remember this for </hintgroup>
   push(@{$stack->{'hintgroup'}},{
                                   'id' => $token->[2]->{'id'}, 
                                   'on' => $token->[2]->{'on'},
                                   'default' => &Apache::lc_asset_xml::open_tag_switch('default',$stack)
                                 });
# Redirect, since we don't know yet if we need this
   &Apache::lc_asset_xml::set_redirect($token->[2]->{'id'},$stack);
# Nothing to say
   return '';
}

sub end_hint_html {
   my ($p,$safe,$stack,$token)=@_;
# Done redirecting
   &Apache::lc_asset_xml::clear_redirect($stack);
   return '';
}

#
# Set the flag if a hint is true
# Name of hint, value of answer, stack
#
sub set_hints {
   my ($name,$value,$stack)=@_;
   if ($value) {
      $stack->{'hint_conditions'}->{&Apache::lc_asset_xml::tag_attribute('problem','id',$stack)}->{$name}=1;
   }
}

1;
__END__
