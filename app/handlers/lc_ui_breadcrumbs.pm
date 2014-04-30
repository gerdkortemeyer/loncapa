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
use Apache::lc_ui_localize;

sub breadcrumb_item {
   my ($title,$text,$function)=@_;
   return '"br_'.$title.'" : "'.&mt($text).'&'.$function.'"';
}

sub add_breadcrumb {
   my ($title,$text,$function)=@_;
   my @breadcrumbs=&Apache::lc_entity_sessions::breadcrumbs();
   push(@breadcrumbs,{title => $title, text => $text, function => $function});
   &Apache::lc_entity_sessions::replace_session_key ('breadcrumbs',\@breadcrumbs);
}

sub fresh_breadcrumbs {
   my ($title,$text,$function)=@_;
   &Apache::lc_entity_sessions::replace_session_key('breadcrumbs',
          &Apache::lc_json_utils::json_to_perl("[{title:'$title',text:'$text',function:'$function'}]"));
}


# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
   $r->content_type('application/json; charset=utf-8');
   my %content=&Apache::lc_entity_sessions::posted_content();
   if ($content{'mode'} eq 'fresh') {
# Set fresh breadcrumbs ... mmm!
      &fresh_breadcrumbs($content{'title'},$content{'text'},$content{'function'});
   } elsif ($content{'mode'} eq 'add') {
      &add_breadcrumb($content{'title'},$content{'text'},$content{'function'});
   } elsif (&Apache::lc_entity_sessions::breadcrumbs()) {
      my $output='{';
      foreach my $item (&Apache::lc_entity_sessions::breadcrumbs()) {
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
