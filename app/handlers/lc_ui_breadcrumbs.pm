# The LearningOnline Network with CAPA - LON-CAPA
# Generate the breadcrumbs
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
#
package Apache::lc_ui_breadcrumbs;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);
use Apache::lc_entity_sessions();
use Apache::lc_ui_utils();
use Apache::lc_ui_localize;

sub breadcrumb_item {
   my ($title,$text,$function)=@_;
   return '"br_'.$title.'" : "'.&mt($text).'&'.$function.'"';
}

sub add_breadcrumb {
   my ($title,$text,$function)=@_;
   &Apache::lc_entity_sessions::update_session($ENV{'lc_session'}->{'id'},
          &Apache::lc_json_utils::json_to_perl("{ breadcrumbs : [{title:'$title',text:'$text',function:'$function'}]}"));
}

sub fresh_breadcrumbs {
   my ($title,$text,$function)=@_;
   &Apache::lc_entity_sessions::replace_session_key($ENV{'lc_session'}->{'id'},'breadcrumbs',
          &Apache::lc_json_utils::json_to_perl("[{title:'$title',text:'$text',function:'$function'}]"));
}


# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
   my %content=&Apache::lc_ui_utils::get_content($r);
   if ($content{'mode'} eq 'fresh') {
# Set fresh breadcrumbs ... mmm!
      &fresh_breadcrumbs($content{'title'},$content{'text'},$content{'function'});
   } elsif ($content{'mode'} eq 'add') {
      &add_breadcrumb($content{'title'},$content{'text'},$content{'function'});
   } elsif ($ENV{'lc_session'}->{'data'}->{'breadcrumbs'}) {
      my $output='{';
      foreach my $item (@{$ENV{'lc_session'}->{'data'}->{'breadcrumbs'}}) {
         $output.=&breadcrumb_item($item->{'title'},$item->{'text'},$item->{'function'}).',';
      }
      $output=~s/\,$/\}/;
      $r->print($output);
   } else {
      $r->print('{'.&breadcrumb_item('welcome','Welcome','#').'}');
   }
   return OK;
}

1;
__END__
