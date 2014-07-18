# The LearningOnline Network with CAPA - LON-CAPA
# All kinds of little gadgets
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
package Apache::lc_xml_gadgets;

use strict;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_lcprogressbar_html);

sub start_lcprogressbar_html {
   my ($p,$safe,$stack,$token)=@_;
   my $id=$token->[2]->{'id'};
   my $process=$token->[2]->{'process'};
   return &progressbar($id,$process);
}

sub progressbar {
   my ($id,$process)=@_;
   return "<div id='lcprogressbar'><div id='lcprogresssuccess'></div><div id='lcprogressskip'></div><div id='lcprogressfail'></div></div>\n".
          "<script>progressbar('$id','$process')</script>";
}


1;
__END__
