# The LearningOnline Network with CAPA - LON-CAPA
# Dealing with publication and rights functions
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
package Apache::lc_ui_publisher;

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
use Apache::lc_file_utils();
use Apache::lc_xml_utils();
use HTML::Entities;

sub listtitle {
   my ($entity,$domain,$url)=@_;
   my $metadata=&Apache::lc_entity_urls::dump_metadata($entity,$domain);
   my ($filename)=($url=~/\/([^\/]+)$/);
   return $filename.($metadata->{'title'}?' ('.$metadata->{'title'}.')':'');
}

sub add_right {
   my ($output,$type,$domain,$entity,$section)=@_;
   my $typedisplay;
   if ($type eq 'view') {
      $typedisplay=&mt('View');
   } elsif ($type eq 'grade') {
      $typedisplay=&mt('Grade by instructor');
   } elsif ($type eq 'clone') {
      $typedisplay=&mt('Clone (make derivatives)');
   } elsif ($type eq 'use') {
      $typedisplay=&mt('Use/assign in courses/communities');
   } elsif ($type eq 'edit') {
      $typedisplay=&mt('Edit');
   }
   my $domaindisplay;
   if ($domain) {
      $domaindisplay=&Apache::lc_ui_utils::get_domain_name($domain);
   }
   my $entitydisplay;
   my $userflag=0;
   if (($entity) && ($domain)) {
      my $profile=&Apache::lc_entity_profile::dump_profile($entity,$domain);
      if ($profile->{'title'}) {
         $entitydisplay=$profile->{'title'};
      } else {
         $userflag=1;
         $entitydisplay=$profile->{'lastname'}.', '.$profile->{'firstname'}.' '.$profile->{'middlename'};
      }
   }
   push(@{$output->{'aaData'}},
        [ undef,
          'Activity',
          $typedisplay,
          ($domain?$domaindisplay:'<i>'.&mt('any').'</i>'),
          ($entity?$entitydisplay:'<i>'.&mt('any').'</i>'),
          ($section?$section:($userflag?'-':'<i>'.&mt('any').'</i>')) ]);
}

sub listrights {
   my ($entity,$domain)=@_;
   my $output;
   $output->{'aaData'}=[];
   my $rights=&Apache::lc_entity_urls::get_rights($entity,$domain);
   foreach my $type (sort(keys(%{$rights}))) {
      foreach my $domain_type (sort(keys(%{$rights->{$type}}))) {
         if ($domain_type eq 'any') {
            if ($rights->{$type}->{$domain_type}) {
               &add_right($output,$type);
            }
         } else {
            foreach my $domain (sort(keys(%{$rights->{$type}->{$domain_type}}))) {
               foreach my $entity_type (sort(keys(%{$rights->{$type}->{$domain_type}->{$domain}}))) {
                  if ($entity_type eq 'any') {
                     if ($rights->{$type}->{$domain_type}->{$domain}->{$entity_type}) {
                        &add_right($output,$type,$domain);
                     }
                  } else {
                     foreach my $entity (sort(keys(%{$rights->{$type}->{$domain_type}->{$domain}->{$entity_type}}))) {
                        foreach my $section_type (sort(keys(%{$rights->{$type}->{$domain_type}->{$domain}->{$entity_type}->{$entity}}))) {
                           if ($section_type eq 'any') {
                              if ($rights->{$type}->{$domain_type}->{$domain}->{$entity_type}->{$entity}->{$section_type}) {
                                 &add_right($output,$type,$domain,$entity);
                              }
                           } else {
                              foreach my $section (sort(keys(%{$rights->{$type}->{$domain_type}->{$domain}->{$entity_type}->{$entity}->{$section_type}}))) {
                                 if ($rights->{$type}->{$domain_type}->{$domain}->{$entity_type}->{$entity}->{$section_type}->{$section}) {
                                    &add_right($output,$type,$domain,$entity,$section);
                                 }
                              }
                           }
                        }
                     }  
                  }
               }
            }
         }
      }
   }
   return &Apache::lc_json_utils::perl_to_json($output);
}

sub handler {
   my $r = shift;
   my %content=&Apache::lc_entity_sessions::posted_content();
   if ($content{'command'} eq 'listtitle') {
      $r->print(&listtitle($content{'entity'},$content{'domain'},$content{'url'}));
   } elsif ($content{'command'} eq 'listrights') {
      $r->content_type('application/json; charset=utf-8');
      $r->print(&listrights($content{'entity'},$content{'domain'}));
   }
   return OK;
}
1;
__END__

