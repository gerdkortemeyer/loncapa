# The LearningOnline Network with CAPA - LON-CAPA
# UI Menu
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
package Apache::lc_ui_menu;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);

use Apache::lc_ui_localize;


sub menu_item {
   my ($title,$text,$function)=@_;
   return '"'.$title.'" : "'.&mt($text).'&'.$function.'"';
}


# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
   my $menu='{';
   if ($ENV{'lc_session'}->{'id'}) {
      $menu.=&menu_item('dashboard','Dashboard','dashboard()').',';
      $menu.=&menu_item('portfolio','Portfolio','portfolio()').',';
   }
# Always second to last item
   $menu.=&menu_item('help','Help','help()').',';
# Always the last item
   if ($ENV{'lc_session'}->{'id'}) {
      $menu.=&menu_item('logout','Logout','logout()');
   } else {
      $menu.=&menu_item('login','Login','login()');
   }
   $menu.='}';
# Send it out!
   $r->print($menu);
   return OK;
}
1;
__END__
