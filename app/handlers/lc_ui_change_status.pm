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
package Apache::lc_ui_change_status;

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

#
# Produces an action link to a function
#
sub action_jump {
   my ($which,$entity,$domain,$rule)=@_;
   return $which."('".$entity."','".$domain."','".$rule."')";
}

#
# Make the edit line for a new rule
#
sub new_right {
   my ($output,$rentity,$rdomain)=@_;
   push(@{$output->{'aaData'}},
        [ undef,
# Type
          &Apache::lc_ui_utils::delete_link("discardrule()"),
          &Apache::lc_xml_forms::hidden_label('newtype','Allowed Activity').
          &Apache::lc_xml_forms::selectfield('newtype','newtype',
             ['view','grade','clone','use','edit'],
             [&mt('View'),&mt('Grade by instructor'),&mt('Clone (make derivatives)'),&mt('Use/assign in courses/communities'),&mt('Edit')],
             'view',0,'type_update()'),
# Domain
          &Apache::lc_xml_forms::hidden_label('newdomain','Domain').
          &Apache::lc_xml_forms::inputfield('rolemodifiabledomains','newdomain','newdomain',undef,undef,undef,'type_update()'),
# Entity
          &Apache::lc_xml_forms::selectfield('newentitytype','newentitytype',
             ['user','course'],[&mt('User'),&mt('Course/Community')],
             'user',0,'entitysearch()').'<br />'.
          &Apache::lc_xml_forms::hidden_label('newentity','Entity').
          '<input type="text" id="newentity" size="40" autocomplete="off" onkeyup="entitysearch()" />'.
          '<br /><div id="entityresults" class="lcautocompleteresults"></div>',
          'newsection' ]);
}

#
# Produces an output line in the rights table
# rentity and rdomain are the asset's
# the remainder are of the rule
#
sub add_right {
   my ($output,$rentity,$rdomain,$type,$domain,$entity,$section)=@_;
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
          &Apache::lc_ui_utils::delete_link(&action_jump("deleterule",$rentity,$rdomain,
               &Apache::lc_ui_utils::query_encode(&encode_entities(
                  &Apache::lc_json_utils::perl_to_json({'type' => $type, 'entity' => $entity, 'domain' => $domain, 'section' => $section}),
                         '\W')))),
          $typedisplay,
          ($domain?$domaindisplay:'<i>'.&mt('any').'</i>'),
          ($entity?$entitydisplay:'<i>'.&mt('any').'</i>'),
          ($section?$section:($userflag?'-':'<i>'.&mt('any').'</i>')) ]);
}

#
# List all the rights in JSON
#
sub listrights {
   my ($rentity,$rdomain,$newrule)=@_;
   my $output;
   $output->{'aaData'}=[];
# Do we add an edit line?
   if ($newrule) {
      &new_right($output,$rentity,$rdomain);
   }
# Retrieve rights
   my $rights=&Apache::lc_entity_urls::get_rights($rentity,$rdomain);
# List all active ones
   foreach my $type (sort(keys(%{$rights}))) {
      foreach my $domain_type (sort(keys(%{$rights->{$type}}))) {
         if ($domain_type eq 'any') {
            if ($rights->{$type}->{$domain_type}) {
               &add_right($output,$rentity,$rdomain,$type);
            }
         } else {
            foreach my $domain (sort(keys(%{$rights->{$type}->{$domain_type}}))) {
               foreach my $entity_type (sort(keys(%{$rights->{$type}->{$domain_type}->{$domain}}))) {
                  if ($entity_type eq 'any') {
                     if ($rights->{$type}->{$domain_type}->{$domain}->{$entity_type}) {
                        &add_right($output,$rentity,$rdomain,$type,$domain);
                     }
                  } else {
                     foreach my $entity (sort(keys(%{$rights->{$type}->{$domain_type}->{$domain}->{$entity_type}}))) {
                        foreach my $section_type (sort(keys(%{$rights->{$type}->{$domain_type}->{$domain}->{$entity_type}->{$entity}}))) {
                           if ($section_type eq 'any') {
                              if ($rights->{$type}->{$domain_type}->{$domain}->{$entity_type}->{$entity}->{$section_type}) {
                                 &add_right($output,$rentity,$rdomain,$type,$domain,$entity);
                              }
                           } else {
                              foreach my $section (sort(keys(%{$rights->{$type}->{$domain_type}->{$domain}->{$entity_type}->{$entity}->{$section_type}}))) {
                                 if ($rights->{$type}->{$domain_type}->{$domain}->{$entity_type}->{$entity}->{$section_type}->{$section}) {
                                    &add_right($output,$type,$rentity,$rdomain,$domain,$entity,$section);
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
      $r->print(&listrights($content{'entity'},$content{'domain'},$content{'newrule'}));
   }
   return OK;
}
1;
__END__

