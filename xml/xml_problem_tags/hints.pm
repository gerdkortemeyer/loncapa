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
   return '';
}

sub end_hintgroup_html {
   my ($p,$safe,$stack,$token)=@_;
   return '';
}

sub start_hint_html {
   my ($p,$safe,$stack,$token)=@_;
   return '';
}

sub end_hint_html {
   my ($p,$safe,$stack,$token)=@_;
   return '';
}

#
# Set the flag if a hint is true
# Name of hint, value of answer, stack
#
sub set_hints {
   my ($name,$value,$stack)=@_;
   if ($value eq &correct()) {
      $stack->{'hint_conditions'}->{&Apache::lc_asset_xml::tag_attribute('problem','id',$stack)}->{$name}=1;
   }
}

1;
__END__
