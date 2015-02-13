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
use Apache::lc_entity_urls();
use Apache::lc_ui_utils;
use Apache::lc_json_utils();
use Apache::lc_logs;
use Apache::lc_ui_localize;
use Apache::lc_authorize;
use Apache::lc_xml_forms();
use Apache::lc_file_utils();
use Apache::lc_xml_utils();
use HTML::Entities;

use Data::Dumper;

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

# =====================================================
# Permissions checking
# =====================================================
#
sub edit_permission {
   my ($rurl)=@_;
# Extract author domain and entity from URL
   my ($adomain,$aentity)=($rurl=~/^([^\/]+)\/([^\/]+)\//);
   return &allowed_user('edit_portfolio',undef,$aentity,$adomain);
}

sub view_permission {
   my ($rurl)=@_;
# Extract author domain and entity from URL
   my ($adomain,$aentity)=($rurl=~/^([^\/]+)\/([^\/]+)\//);
   return &allowed_user('view_portfolio',undef,$aentity,$adomain);
}

sub verify_url {
   my ($entity,$url)=@_;
   return (&Apache::lc_entity_urls::url_to_entity('/asset/-/-/'.$url) eq $entity);
}

# =====================================================
# Publication status
# =====================================================
#
sub publication_status_link {
   my ($entity,$domain,$url,$obsolete,$modified,$published)=@_;
   my $led='red';
   my $publishedflag=0;
   my $status=&mt('Unpublished');
   if ($obsolete) {
      $led='black';
      $status=&mt('Obsolete');
   } elsif ($published) {
      if ($modified) {
         $led='orange';
         $status=&mt('Modified');
      } else {
         $led='green';
         $status=&mt('Published');
         $publishedflag=1;
      }
   }
   my $inner=&Apache::lc_xml_utils::file_icon('special','led_'.$led).'&nbsp'.$status;
   if (&edit_permission($url)) {
      if ($publishedflag) {
         return $inner;
      } else {
         return '<a href="#" onClick="'.&action_jump('publisher',$entity,$domain,$url).'" class="lcdirlink">'.
                  $inner.'</a>';
      }
   } else {
      return $inner;
   }
}


# =====================================================
# Changing titles
# =====================================================
#
# Produce a link to the modal window to change titles
#
sub change_title_link {
   my ($entity,$domain,$url,$title)=@_;
   my $inner=($title=~/\S/?$title:'-');
   if (&edit_permission($url)) {
      return '<a href="#" onClick="change_title(\''.$entity.'\',\''.$domain.
          '\',\''.&Apache::lc_ui_utils::query_encode($url).
          '\',\''.&Apache::lc_ui_utils::query_encode($title).'\')" class="lcdirlink">'.
                  $inner.'</a>',
   } else {
      return $inner;
   }
}
#
# Actually change the title
#
sub change_title {
   my ($entity,$domain,$url,$title)=@_;
   unless (&edit_permission($url)) { 
      &logwarning("No edit portfolio permission ($url)");
      return 'error'; 
   }
   unless (&verify_url($entity,$url)) {
      &logwarning("Mismatch ($entity) ($domain) ($url)");
      return 'error';
   }
   if (&Apache::lc_entity_urls::store_new_title($entity,$domain,$title)) {
      return 'ok';
   } else {
       &logerror("Storing new title failed for ($entity) ($domain)");
       return 'error';
   }
}

#
# Rightslink
#
sub rights_link {
   my ($entity,$domain,$url,$obsolete,$modified,$published)=@_;
   my $inner='';
   if ($published) {
      my ($overall,$std)=&Apache::lc_entity_urls::standard_rights($entity,$domain,$url);
      $inner.='<ul class="lcsmallwordlist">';
      foreach my $type ('grade','use','view','edit','clone') {
         if ($std->{$type} eq 'none') { next; }
         my $description;
         if ($type eq 'grade') {
            $description=&mt('Grade: [_1]',&mt($std->{$type}));
         } elsif ($type eq 'use') { 
            $description=&mt('Use: [_1]',&mt($std->{$type}));
         } elsif ($type eq 'view') {  
            $description=&mt('View: [_1]',&mt($std->{$type}));
         } elsif ($type eq 'edit') {  
            $description=&mt('Edit: [_1]',&mt($std->{$type}));
         } elsif ($type eq 'clone') {  
            $description=&mt('Clone: [_1]',&mt($std->{$type}));
         }
         $inner.='<li class="lcsmallwordbubble">'.$description.'</li> ';         
      } 
      $inner.='</ul>';
   }
   if (&edit_permission($url)) {
      if ($published) {
         return '<a href="#" onClick="'.&action_jump('change_status',$entity,$domain,$url).'" class="lcdirlink">'.
                  $inner.'</a>';
      } else {
         return $inner;
      }
   } else {
      return $inner;
   }
}

#
# Generate a function call
#
sub action_jump {
   my ($which,$entity,$domain,$url)=@_;
   return $which."('".$entity."','".$domain."','".&Apache::lc_ui_utils::query_encode($url)."')";
}

# ======================================================================
# List directory
# ======================================================================
#
# Return the directory listing as JSON
# Input: path to list and whether or not to show hidden (obsolete) files
#
sub listdirectory {
   my ($path,$showhidden)=@_;
   my ($udomain,$uentity)=($path=~/([^\/]+)\/([^\/]+)\//);
   unless (&allowed_user('view_portfolio',undef,$uentity,$udomain)) {
# Nope, good bye
      return '{ "aaData": [] }';
   }
# Okay, we are allowed
   my $output;
   $output->{'aaData'}=[];
# Generate the level up link, if allowed
   my $uppath=$path;
   $uppath=~s/[^\/]+\/$//;
   if ($uppath=~/^[^\/]+\//) {
      push(@{$output->{'aaData'}},
            ['',
             '&nbsp;',
             &Apache::lc_xml_utils::file_icon('special','dir_up'),
             '0',
             '<i><a href="#" onClick="set_path(\''.$uppath.'\')" class="lcdirlink">'.&mt('Parent directory').'</a></i>',
             '',
             '',
             '',
             '',
             -2,
             '',
             '',
             -2,
             '',
             -2,
             '',
             -2
            ]
      );
   }
   my $dir_list=&Apache::lc_entity_urls::full_dir_list($path);
   foreach my $file (@{$dir_list}) {
# Is the file/directory obsolete?
       my $obsolete=0;
       my $deleted=0;
       if (ref($file->{'metadata'}->{'urldata'}) eq 'HASH') {
          $obsolete=$file->{'metadata'}->{'urldata'}->{&Apache::lc_entity_urls::url_encode($file->{'url'})}->{'obsolete'};
          $deleted=$file->{'metadata'}->{'urldata'}->{&Apache::lc_entity_urls::url_encode($file->{'url'})}->{'deleted'};
       }
# Deleted? Move on!
       if ($deleted) { next; }
# Published?
       my $published=0;
# Modified?
       my $modified=0;
# Don't show it unless asked for
       unless ($showhidden) {
          if ($obsolete) { next; }
       }
       my $version='-';
       my $display_first_date=&mt('Never');
       my $sort_first_date=0;
       my $display_last_date=&mt('Never');
       my $sort_last_date=0;
       my $filename='';
       my $size='';
       my $sort_size=-1;
       my $status='';
       my $rights='';
       my $display_last_modified=&mt('Never');
       my $sort_last_modified=0;
       my $sort_type='1';
       my $actionicons='';
       if ($file->{'type'} eq 'file') {
# It's a file, so we have dates, etc
          my $last_published=0;
          if ($file->{'metadata'}->{'current_version'}) {
# If there is a current version, it's published
# Get date of first publication and date of most recent publication
             $published=1;
             $version=$file->{'metadata'}->{'current_version'};
             ($display_first_date,$sort_first_date)=&Apache::lc_ui_localize::locallocaltime(
                                           &Apache::lc_date_utils::str2num($file->{'metadata'}->{'versions'}->{1}));
             $last_published=&Apache::lc_date_utils::str2num($file->{'metadata'}->{'versions'}->{$version});
             ($display_last_date,$sort_last_date)=&Apache::lc_ui_localize::locallocaltime($last_published);
          }
# Figure out when wrk-file was last modified
          my $last_modified=&Apache::lc_date_utils::str2num($file->{'metadata'}->{'filedata'}->{'wrk'}->{'modified'});
          ($display_last_modified,$sort_last_modified)=&Apache::lc_ui_localize::locallocaltime($last_modified);
# If the last modification is after the most recent publication, it's modified
          if ($last_published) {
             if ($last_modified>$last_published) {
                $modified=1;
             }
          }
          $status=&publication_status_link($file->{'entity'},$file->{'domain'},$file->{'url'},$obsolete,$modified,$published);
          $rights=&rights_link($file->{'entity'},$file->{'domain'},$file->{'url'},$obsolete,$modified,$published);
# Action links
          $actionicons.=&Apache::lc_ui_utils::download_link(&action_jump("downloadfile",$file->{'entity'},$file->{'domain'},$file->{'url'}));
          unless ($published) {
             $actionicons.=&Apache::lc_ui_utils::delete_link(&action_jump("deletefile",$file->{'entity'},$file->{'domain'},$file->{'url'}));
             if ($file->{'filename'} =~ /\.xml$/) { # FIXME
               $actionicons.=&Apache::lc_ui_utils::edit_link(&action_jump("editfile",$file->{'entity'},$file->{'domain'},$file->{'url'}));
             }
          } else {
             unless ($obsolete) {
                $actionicons.=&Apache::lc_ui_utils::remove_link(&action_jump("removefile",$file->{'entity'},$file->{'domain'},$file->{'url'}));
             } else {
                $actionicons.=&Apache::lc_ui_utils::recover_link(&action_jump("recover",$file->{'entity'},$file->{'domain'},$file->{'url'}));
             }
          }
          unless ($obsolete) {
             if (($modified) || (!$published)) { 
                $actionicons.=&Apache::lc_ui_utils::publish_link(&action_jump("publisher",$file->{'entity'},$file->{'domain'},$file->{'url'}));
             }
          }
          $sort_size=$file->{'metadata'}->{'filedata'}->{'wrk'}->{'size'};
          $size=&Apache::lc_ui_localize::human_readable_size($sort_size);
          $filename='<a href="#" onClick="parent.display_asset(\'/asset/wrk/-/'.$file->{'url'}.'\')" class="lcdirlink">'.
                    $file->{'filename'}.'</a>';
          $sort_type=&Apache::lc_file_utils::file_icon($file->{'type'},$file->{'filename'});
       } else {
# It's a directory
          $display_first_date='';
          $display_last_date='';
          $display_last_modified='';
          $sort_first_date=-1;
          $sort_last_date=-1;
          $sort_last_modified=-1;
          my $fullpath=$path.$file->{'filename'}.'/';
          $filename='<a href="#" onClick="set_path(\''.$fullpath.'\')" class="lcdirlink">'.$file->{'filename'}."</a>";
       }
# Add the output line
       push(@{$output->{'aaData'}},
            [&encode_entities(
               &Apache::lc_json_utils::perl_to_json({'entity' => $file->{'entity'}, 'domain' => $file->{'domain'}, 'url' => $file->{'url'}}),
                         '\W'),
             $actionicons,
             &Apache::lc_xml_utils::file_icon($file->{'type'},$file->{'filename'}),
             $sort_type,
             $filename,
             &change_title_link($file->{'entity'},$file->{'domain'},$file->{'url'},$file->{'metadata'}->{'title'}),
             $status,
             $rights,
             $size,
             $sort_size,
             $version,
             ($sort_first_date>0?'<time datetime="'.$sort_first_date.'">':'').$display_first_date.($sort_first_date>0?'</time>':''),
             $sort_first_date,
             ($sort_last_date>0?'<time datetime="'.$sort_last_date.'">':'').$display_last_date.($sort_last_date>0?'</time>':''),
             $sort_last_date,
             ($sort_last_modified>0?'<time datetime="'.$sort_last_modified.'">':'').$display_last_modified.($sort_last_modified>0?'</time>':''),
             $sort_last_modified
            ]
           );
   }
   return &Apache::lc_json_utils::perl_to_json($output);
}

# ========================================================
# List path
# ========================================================
#
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

# ========================================================
# Obsoleting
# ========================================================
#
sub remove {
   my ($entity,$domain,$url)=@_;
   unless (&edit_permission($url)) {
      &logwarning("No edit portfolio permission ($url)");
      return 'error';
   }
   unless (&verify_url($entity,$url)) {
      &logwarning("Mismatch ($entity) ($domain) ($url)");
      return 'error';
   }
   if (&Apache::lc_entity_urls::make_obsolete('/asset/-/-/'.$url)) {
      return 'ok';
   } else {
       &logerror("Making obsolete failed for ($entity) ($domain)");
       return 'error';
   }
}

sub deletefile {
   my ($entity,$domain,$url)=@_;
   unless (&edit_permission($url)) {
      &logwarning("No edit portfolio permission ($url)");
      return 'error';
   }
   unless (&verify_url($entity,$url)) {
      &logwarning("Mismatch ($entity) ($domain) ($url)");
      return 'error';
   }
   if (&Apache::lc_entity_urls::make_delete('/asset/-/-/'.$url)) {
      return 'ok';
   } else {
       &logerror("Deleting failed for ($entity) ($domain)");
       return 'error';
   }
}

sub recover {
   my ($entity,$domain,$url)=@_;
   unless (&edit_permission($url)) {
      &logwarning("No edit portfolio permission ($url)");
      return 'error';
   }
   unless (&verify_url($entity,$url)) {
      &logwarning("Mismatch ($entity) ($domain) ($url)");
      return 'error';
   }
   if (&Apache::lc_entity_urls::un_obsolete('/asset/-/-/'.$url)) {
      return 'ok';
   } else {
       &logerror("Unobsoleting failed for ($entity) ($domain)");
       return 'error';
   }
   return 'ok';
}

sub downloadfile {
  my ($entity,$domain,$url,$r)=@_;
  unless (&view_permission($url)) {
    &logwarning("No view portfolio permission ($url)");
    $r->print('error');
    return;
  }
  unless (&verify_url($entity,$url)) {
    &logwarning("Mismatch ($entity) ($domain) ($url)");
    $r->print('error');
    return;
  }
  my $filepath = &Apache::lc_entity_urls::url_to_filepath('/asset/wrk/-/'.$url);
  my $filename = $url;
  $filename =~ s/^.*\/([^\/]*)$/$1/;
  if (open(my $fh, '<', $filepath)) {
    $r->headers_out->set('Content-Disposition' => "attachment; filename=$filename");
    if (-B $fh) {
      binmode($fh);
      local $/ = \10240;
      while (<$fh>) {
        print $_;
      }
    } else {
      binmode($fh, ":encoding(utf-8)");
      if ($filename =~ /\.xml$/) { # FIXME
        $r->content_type('text/xml; charset=utf-8');
      } else {
        $r->content_type('text/plain; charset=utf-8');
      }
      while (my $line = <$fh>) {
        chomp $line;
        $r->print("$line\n");
      }
    }
    close FILE;
  } else {
    &logerror("Downloading failed for ($entity) ($domain)");
    $r->print('error');
  }
}



sub handler {
   my $r = shift;
   my %content=&Apache::lc_entity_sessions::posted_content();
   my $path=&determine_path($content{'pathrow_path'});
   if ($content{'command'} eq 'listdirectory') {
# Do a directory listing
      $r->content_type('application/json; charset=utf-8');
      $r->print(&listdirectory($path,$content{'showhidden'}));
   } elsif ($content{'command'} eq 'listpath') {
# List the path
      $r->content_type('application/json; charset=utf-8');
      $r->print(&listpath($path));
   } elsif ($content{'command'} eq 'changetitle') {
      $r->print(&change_title($content{'entity'},$content{'domain'},$content{'url'},$content{'title'}));
   } elsif ($content{'command'} eq 'remove') {
      $r->print(&remove($content{'entity'},$content{'domain'},$content{'url'}));
   } elsif ($content{'command'} eq 'delete') {
      $r->print(&deletefile($content{'entity'},$content{'domain'},$content{'url'}));
   } elsif ($content{'command'} eq 'recover') {
      $r->print(&recover($content{'entity'},$content{'domain'},$content{'url'}));
   } elsif ($content{'command'} eq 'download') {
      &downloadfile($content{'entity'},$content{'domain'},$content{'url'},$r);
   }
   return OK;
}
1;
__END__

