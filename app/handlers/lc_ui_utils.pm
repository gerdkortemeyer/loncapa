# The LearningOnline Network with CAPA - LON-CAPA
# UI Utilities
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
package Apache::lc_ui_utils;

use strict;
use Apache::lc_init_cluster_table();
use Apache::lc_ui_localize;
use Apache::lc_entity_sessions();
use Apache::lc_entity_courses();
use Apache::lc_authorize;
use Locale::Language;

use Apache::lc_logs;
use URI::Escape;

use Data::Dumper;

require Exporter;

our @ISA = qw (Exporter);
our @EXPORT = qw(clean_username clean_domain domain_choices domain_name language_choices content_language_choices timezone_choices modifiable_role_choices);

# ==== Clean up usernames and domains
#
sub clean_username {
   my ($username)=@_;
   $username=~s/\s//gs;
   $username=~s/\///gs;
   return $username;
}

sub clean_domain {
   my ($domain)=@_;
   $domain=~s/\s//gs;
   $domain=~s/\///gs;
   return $domain;
}

# ==== Encode variables for query strings
#
sub query_encode {
   return &uri_escape(@_[0]);
}

sub query_unencode {
   return &uri_unescape(@_[0]);
}


# ==== Another domain name
#
sub get_domain_name {
   my ($short)=@_;
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   return $connection_table->{'cluster_table'}->{'domains'}->{$short}->{'name'};
}

# ==== The domain choices
#
sub domain_choices {
   my ($type)=@_;
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   my %names;
   if ($type eq 'hosted') {
# Return all domains that are hosted on this server
      foreach my $key (keys(%{$connection_table->{'cluster_table'}->{'hosts'}->{$connection_table->{'self'}}->{'domains'}})) {
         $names{$key}=$connection_table->{'cluster_table'}->{'domains'}->{$key}->{'name'};
      }
   } elsif ($type eq 'rolemodifiable') {
# Return all domains in which this user can modify any roles
      if (&allowed_system('modify_role')) {
# Systemwide - so all domains!
         foreach my $key (keys(%{$connection_table->{'cluster_table'}->{'domains'}})) {
            $names{$key}=$connection_table->{'cluster_table'}->{'domains'}->{$key}->{'name'};
         }
      } else {
# Not so privileged, go through actual roles
         my $roles=&Apache::lc_entity_sessions::roles();
# Domain-level
         foreach my $key (keys(%{$roles->{'domain'}})) {
            if (&allowed_domain('modify_role'),$key) {
               $names{$key}=$connection_table->{'cluster_table'}->{'domains'}->{$key}->{'name'};
            }
         }
# Course-level
         foreach my $domain_key (keys(%{$roles->{'course'}})) {
            foreach my $course_key (keys(%{$roles->{'course'}->{$domain_key}})) {
               if (&allowed_any_section('modify_role',undef,$course_key,$domain_key)) {
                  $names{$domain_key}=$connection_table->{'cluster_table'}->{'domains'}->{$domain_key}->{'name'};
               }
            }
         }
      }
   }
   my $domain_short;
   my $domain_name;
   foreach my $key (sort(keys(%names))) {
       push(@{$domain_short},$key);
       push(@{$domain_name},$names{$key});
   }
   return ($connection_table->{'cluster_table'}->{'hosts'}->{$connection_table->{'self'}}->{'default'},
           $domain_short,$domain_name);
}

sub domain_name {
   my ($domain)=@_;
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   return $connection_table->{'cluster_table'}->{'domains'}->{$domain}->{'name'};
}

# ==== Modifiable course role choices
#
sub modifiable_role_choices {
   my ($type)=@_;
   my $roles_short;
   my $roles_name;
#FIXME: more than just "course"
   if ($type eq 'course') {
      my %modifiable_roles=&Apache::lc_authorize::modifiable_course_roles();
      foreach my $thisrole (sort(keys(%modifiable_roles))) {
         push(@{$roles_short},$thisrole);
         push(@{$roles_name},&mt($thisrole));
      }
   }
   return ($roles_short,$roles_name);
}

# ==== Language choices
#
sub language_choices {
   my ($type)=@_;
   my %language_choices=&Apache::lc_ui_localize::all_languages();
   my $language_short;
   my $language_name;
   foreach my $key (sort(keys(%language_choices))) {
       push(@{$language_short},$key);
       push(@{$language_name},&mt($language_choices{$key}));
   }
   my $default;
   if ($type eq 'user') {
      $default=&Apache::lc_ui_localize::context_language();
   }
   unless ($default) { $default='en'; }
   return ($default,$language_short,$language_name);
}

sub content_language_choices {
   my ($default)=@_;
# Retrieve names
   my @names=&all_language_names();
   my %codes=();
   for (my $i=0; $i<=$#names; $i++) {
      my $code=&language2code($names[$i]);
# Remove the parenthetical clarifications
      $names[$i]=~s/\s*\(.+$//;
# Translate
      $names[$i]=&mt($names[$i]);
# Assign code
      $codes{$names[$i]}=$code;
   }
# Output arrays
   my $language_short=['-'];
   my $language_name=['-'];
# Sort in order of translated language
   foreach my $key (sort(@names)) {
       push(@{$language_short},$codes{$key});
       push(@{$language_name},$key);
   }
   unless ($default) {
      $default=&Apache::lc_ui_localize::context_language();
   }
   unless ($default) { $default='en'; }
   return ($default,$language_short,$language_name);
}

# ==== Timezone choices
#
sub timezone_choices {
   my ($type)=@_;
   my @timezones=&Apache::lc_ui_localize::all_timezones();
   my $default;
   if ($type eq 'user') {
      $default=&Apache::lc_ui_localize::context_timezone();
   }
   unless ($default) { $default='UTC'; }
   return ($default,\@timezones);
}

# ==== Action icons
#
sub action_icon {
   my ($which,$title)=@_;
   $title=&mt($title);
   return '<img src="/images/actionicons/'.$which.'.png" width="22" height="22" alt="'.$title.'" title="'.$title.'" />';
}

sub action_link {
   my ($which,$title,$onclick)=@_;
   if ($onclick) {
      $onclick=~s/\'/\"/gs;
      return "<a href='#' class='lcdirlink' onclick='$onclick'>".
             &action_icon($which,$title)."</a>";
   } else {
      return &action_icon($which,$title);
   }
}

sub copy_link {
   my ($onclick)=@_;
   return &action_link('edit-copy','Copy',$onclick);
}

sub cut_link {
   my ($onclick)=@_;
   return &action_link('edit-cut','Cut',$onclick);
}

sub delete_link {
   my ($onclick)=@_; 
   return &action_link('user-delete','Delete',$onclick);
}

sub remove_link {
   my ($onclick)=@_;
   return &action_link('user-trash','Remove',$onclick);
}

sub recover_link {
   my ($onclick)=@_;
   return &action_link('user-trash-recover','Recover',$onclick);
}

sub publish_link {
   my ($onclick)=@_;
   return &action_link('publish','Publish',$onclick);
}

sub add_link {
   my ($onclick)=@_;
   return &action_link('list-add','Add',$onclick);
}

sub download_link {
   my ($onclick)=@_;
   return &action_link('download','Download',$onclick);
}

sub edit_link {
   my ($onclick)=@_;
   return &action_link('edit','Edit',$onclick);
}

1;
__END__
