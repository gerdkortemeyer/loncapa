# The LearningOnline Network with CAPA - LON-CAPA
# Catch-all tag for including raw handler output into pages
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
package Apache::lc_xml_include;

use strict;

use Apache::lc_incl_userroles;
use Apache::lc_logs;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_lcinclude_html);

sub start_lcinclude_html {
   my ($p,$safe,$stack,$token)=@_;
   my $id=$token->[2]->{'id'};
   my $name=$token->[2]->{'name'};
   unless ($id) { return ''; }
   unless ($name) { $name=$id; }
   my $output="<div id='$id' name='$name'>";
   my $subroutine='incl_'.$id;
   $subroutine=~s/\W//g;
   no strict 'refs';
   if (defined(&$subroutine)) {
      $output.=&{$subroutine}($p,$safe,$stack,$token);
   }
   use strict 'refs';
   $output.='</div>';
   return $output;
}

1;
__END__
