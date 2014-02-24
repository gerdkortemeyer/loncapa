# The LearningOnline Network with CAPA - LON-CAPA
# Generate notifications
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
package Apache::lc_ui_notifications;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);


# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
   my $output='{';
   for (my $i=0; $i<=1+int(rand(10)); $i++) {
      $output.='"i'.$i.'" : "'.
      ('An apple a day keeps the doctor away',
       'Face the music',
       'Keep the ball rolling',
       'No such thing as a free lunch',
       'What you see is what you get')[int(rand(5))].
      '", ';
   }
   $output=~s/\,\s*$//;
   $output.='}';
   $r->print($output);
   return OK;
}
1;
__END__
