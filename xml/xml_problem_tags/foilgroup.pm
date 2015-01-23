# The LearningOnline Network with CAPA - LON-CAPA
# Foilgroup and everything inside
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
package Apache::xml_problem_tags::foilgroup;

use strict;

use Apache::lc_math_parser();
use Apache::lc_problem_const;
use Apache::xml_problem_tags::hints();
use Apache::lc_logs;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_foilgroup_html  end_foilgroup_html
                 start_foilgroup_grade end_foilgroup_grade
                 start_conceptgroup_html  end_conceptgroup_html
                 start_conceptgroup_grade end_conceptgroup_grade
                 start_foil_html  end_foil_html
                 start_foil_grade end_foil_grade);

#
# To be called by all responses that need foilgroups
#
sub init_foils {
   my ($stack)=@_;
   $stack->{'foils'}={};
}

# ============================================================
# Foilgroup
# ============================================================

sub start_foilgroup_html {
   my ($p,$safe,$stack,$token)=@_;
   return '';
}

sub start_foilgroup_grade {
   my ($p,$safe,$stack,$token)=@_;
   $stack->{'conceptgroup'}=undef;
   $stack->{'foilgroup'}=$token->[2]->{'id'};
}

sub end_foilgroup_html {
   my ($p,$safe,$stack,$token)=@_;
   return '';
}

sub end_foilgroup_grade {
   my ($p,$safe,$stack,$token)=@_;
}

# ============================================================
# Conceptgroup
# ============================================================

sub start_conceptgroup_html {
   my ($p,$safe,$stack,$token)=@_;
   return '';
}

sub start_conceptgroup_grade {
   my ($p,$safe,$stack,$token)=@_;
   $stack->{'conceptgroup'}=$token->[2]->{'id'};
}

sub end_conceptgroup_html {
   my ($p,$safe,$stack,$token)=@_;
   return '';
}

sub end_conceptgroup_grade {
   my ($p,$safe,$stack,$token)=@_;
   $stack->{'conceptgroup'}=undef;
}

# ============================================================
# Foils
# ============================================================

sub start_foil_html {
   my ($p,$safe,$stack,$token)=@_;
# Definitely don't render in place, just store
   &Apache::lc_asset_xml::set_redirect($token->[2]->{'id'},$stack);
   return '';
}

sub start_foil_grade {
   my ($p,$safe,$stack,$token)=@_;
# Remember this foil
}

sub end_foil_html {
   my ($p,$safe,$stack,$token)=@_;
# Done redirecting
   &Apache::lc_asset_xml::clear_redirect($stack);
   return '';
}

sub end_foil_grade {
   my ($p,$safe,$stack,$token)=@_;
}

1;
__END__
