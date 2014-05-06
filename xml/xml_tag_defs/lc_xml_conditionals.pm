# The LearningOnline Network with CAPA - LON-CAPA
# Implements conditional blocks
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
package Apache::lc_xml_conditionals;

use strict;
use Apache::lc_asset_safeeval;
use Apache::lc_authorize;
use Apache::lc_entity_sessions();

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_allowed_html start_allowed_tex end_allowed_html end_allowed_tex);

sub start_allowed_html {
   return &allowed_eval(@_);
}

sub start_allowed_tex {
   return &allowed_eval(@_);
}

sub end_allowed_html {
   return '';
}

sub end_allowed_tex {
   return '';
}

sub allowed_eval {
   my ($p,$safe,$stack,$token)=@_;
   my $realm=$token->[2]->{'realm'};
   my $action=$token->[2]->{'action'};
   my $item=$token->[2]->{'item'};
   my $allowed=0;
#FIXME: currently only implements "course"
   if ($realm eq 'course') {
      $allowed=&allowed_course($action,$item,&Apache::lc_entity_sessions::course_entity_domain());
   }
   unless ($allowed) {
# skip all the stuff in-between
#FIXME: does not allow nested allows
      $p->get_text('/allowed');
      $p->get_token;
      pop(@{$stack->{'tags'}});
   }
   return '';
}

1;
__END__
