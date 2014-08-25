# The LearningOnline Network with CAPA - LON-CAPA
# Serves up various elements of the portfolio page
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
package Apache::lc_ui_portfolio;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);
use Apache::lc_entity_sessions();
use Apache::lc_entity_courses();
use Apache::lc_entity_users();
use Apache::lc_ui_utils;
use Apache::lc_json_utils();
use Apache::lc_logs;
use Apache::lc_ui_localize;
use Apache::lc_authorize;
use Apache::lc_xml_forms();

sub determine_path {
   my ($path)=@_;
   unless ($path) {
# If we don't have a path, look in the defaults
      $path=&Apache::lc_xml_forms::get_screendefaults('path');
   }
   unless ($path) {
# If we still don't have a path, use the user's home directory
      my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();
      $path=$domain.'/'.$entity.'/';
   }
# Path should end with a slash
   unless ($path=~/\/$/) { $path.='/'; }
# ... but not start with one
   $path=~s/^\/+//;
# No cheating by going up
   $path=~s/\.\.//gs;
   return $path;
}

sub listdirectory {
   my ($path)=@_;
   my ($udomain,$uentity)=($path=~/([^\/]+)\/([^\/]+)\//);
   unless (&allowed_user('view_portfolio',undef,$uentity,$udomain)) {
# Nope, good bye
      return '{ "aaData": [] }';
   }
# Okay, we are allowed
   my $output;
   $output->{'aaData'}=[];
   push(@{$output->{'aaData'}},
            ['&nbsp;',
             &Apache::lc_xml_utils::file_icon('special','dir_up'),
             '..',
             'Title',
             'State',
             undef,
             '',
             -2,
             '',
             -2
            ]
   );

   my $dir_list=&Apache::lc_entity_urls::full_dir_list($path);
   foreach my $file (@{$dir_list}) {
       my $version='-';
       my $display_first_date=&mt('Never');
       my $sort_first_date=0;
       my $display_last_date=&mt('Never');
       my $sort_last_date=0;
       my $filename='';
       if ($file->{'type'} eq 'file') {
# It's a file, so we have dates, etc
          if ($file->{'metadata'}->{'current_version'}) {
             $version=$file->{'metadata'}->{'current_version'};
             ($display_first_date,$sort_first_date)=&Apache::lc_ui_localize::locallocaltime(
                                           &Apache::lc_date_utils::str2num($file->{'metadata'}->{'versions'}->{1}));
             ($display_last_date,$sort_last_date)=&Apache::lc_ui_localize::locallocaltime(
                                           &Apache::lc_date_utils::str2num($file->{'metadata'}->{'versions'}->{$version}));
          }
          $filename=$file->{'filename'};
       } else {
# It's a directory
          $display_first_date='';
          $display_last_date='';
          $sort_first_date=-1;
          $sort_last_date=-1;
          my $fullpath=$path.$file->{'filename'}.'/';
          $filename='<a href="#" onClick="set_path(\''.$fullpath.'\')">'.$file->{'filename'}."</a>";
       }
# Add the output line
       push(@{$output->{'aaData'}},
            ['&nbsp;',
             &Apache::lc_xml_utils::file_icon($file->{'type'},$file->{'filename'}),
             $filename,
             'Title',
             'State',
             $version,
             ($sort_first_date>0?'<time datetime="'.$sort_first_date.'">':'').$display_first_date.($sort_first_date>0?'</time>':''),
             $sort_first_date,
             ($sort_last_date>0?'<time datetime="'.$sort_last_date.'">':'').$display_last_date.($sort_last_date>0?'</time>':''),
             $sort_last_date
            ]
           );
   }
   return &Apache::lc_json_utils::perl_to_json($output);
}

sub listpath {
   my ($path)=@_;
   $path=~s/^\/+//;
   $path=~s/\/+$//;
   my @path=split(/\//,$path);
   my @splitpath;
   foreach my $dir (@path) {
      push(@splitpath,{ $dir => $dir });
   }
   $splitpath[0]->{$path[0]}=&Apache::lc_ui_utils::get_domain_name($path[0]);
   my ($firstname,$middlename,$lastname,$suffix)=&Apache::lc_entity_users::full_name($path[1],$path[0]);
   if ($lastname) {
      $splitpath[1]->{$path[1]}=$lastname.', '.$firstname.' '.$middlename;
   }
   return &Apache::lc_json_utils::perl_to_json(\@splitpath); 
}

sub handler {
   my $r = shift;
   $r->content_type('application/json; charset=utf-8');
   my %content=&Apache::lc_entity_sessions::posted_content();
   my $path=&determine_path($content{'pathrow_path'});
   if ($content{'command'} eq 'listdirectory') {
# Do a directory listing
      $r->print(&listdirectory($path));
   } elsif ($content{'command'} eq 'listpath') {
# List the path
      $r->print(&listpath($path));
   }
   return OK;
}
1;
__END__

