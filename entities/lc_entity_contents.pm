# The LearningOnline Network with CAPA - LON-CAPA
# Utilities for handling tables of contents 
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

package Apache::lc_entity_contents;

use strict;
use Apache::lc_logs;
use Apache::lc_parameters;
use Apache::lc_entity_urls();
use Apache::lc_entity_utils();
use Apache::lc_entity_sessions();
use Apache::lc_memcached();

#
# Returns the displayable version of the table
# of contents for the current session
#
sub toc_display {
   my $display;
   my $digest=&toc_digest();
   foreach my $element (@{$digest->{'series'}}) {
      my $newelement=undef;
      $newelement->{'text'}=$element->{'title'};
      $newelement->{'parent'}=$element->{'parent'}->[-1];
      $newelement->{'id'}=$element->{'id'};
      push(@{$display},$newelement);
   }
   return $display;
}

#
# Returns are data structure for assetid
#
sub toc_asset_data {
   my ($assetid)=@_;
   my $assetdata=();
   my $digest=&toc_digest();
   $assetdata->{'current'}=$digest->{'series'}->[$digest->{'num'}->{$assetid}];
   if ($assetdata->{'current'}->{'prev'}) {
      $assetdata->{'prev'}=$digest->{'series'}->[$digest->{'num'}->{$assetdata->{'current'}->{'prev'}}];
   }
   if ($assetdata->{'current'}->{'next'}) {
      $assetdata->{'next'}=$digest->{'series'}->[$digest->{'num'}->{$assetdata->{'current'}->{'next'}}];
   }
   return $assetdata;
}

#
# Returns the digest of the table of contents for the
# current course and user
#

my $series;
my @stack;

sub toc_digest {
   my $digest=&Apache::lc_memcached::lookup_tocdigest(
                      &Apache::lc_entity_sessions::user_entity_domain(),
                      &Apache::lc_entity_sessions::course_entity_domain());
   if ($digest) { return $digest; }
# Unfortunately not cached, need to construct it
   $series=undef;
   @stack=();
   $digest={};
   $digest->{'series'}=&folder_serialize_eval('#',&Apache::lc_entity_courses::load_contents(&Apache::lc_entity_sessions::course_entity_domain()));
# Store information about accessible assets: predecessors, successors, url
   if ($digest) {
      my $prev=undef;
      my @lastfolders=();
      for (my $i=0; $i<=$#{$digest->{'series'}}; $i++) {
          $digest->{'num'}->{$digest->{'series'}->[$i]->{'id'}}=$i;
# This is not an asset, we will need to remember what is the next real asset
          unless ($digest->{'series'}->[$i]->{'type'} eq 'asset') { 
             push(@lastfolders,$i);
             next; 
          }
          if ($i>0) { $digest->{'series'}->[$i]->{'prev'}=$prev; }
          $digest->{'series'}->[$digest->{'num'}->{$prev}]->{'next'}=$digest->{'series'}->[$i]->{'id'};
# Since we are real, make all enclosing folders know who we are
          if ($#lastfolders>=0) {
             foreach my $previous (@lastfolders) {
                $digest->{'series'}->[$previous]->{'next_asset'}=$digest->{'series'}->[$i]->{'id'};
             }
# Done here, the other stuff is presumably normal
             @lastfolders=();
          }
# And we now turn into history
          $prev=$digest->{'series'}->[$i]->{'id'};
      }
      &Apache::lc_memcached::insert_tocdigest(
                      &Apache::lc_entity_sessions::user_entity_domain(),
                      &Apache::lc_entity_sessions::course_entity_domain(),
                      $digest);
   }
   return $digest;
}

sub folder_serialize_eval {
   my ($name,$folder)=@_;
   push(@stack,$name);
   foreach my $element (@{$folder}) {
#FIXME: do not push any elements that the user is not allowed to see
      my @current_stack=@stack;
      $element->{'parent'}=\@current_stack;
      push(@{$series},$element);
      if ($element->{'type'} eq 'folder') {
         &folder_serialize_eval($element->{'id'},$element->{'content'});
         delete($element->{'content'});
      }
   }
   pop(@stack);
   return $series;
}

sub new_asset {
   my ($resurl,$restitle)=@_;
   return { url => $resurl, 
            title => $restitle, 
            type => 'asset', 
            active => 1, hidden => 0, 
            id => &Apache::lc_entity_utils::long_unique_id() }
}

sub new_folder {
   my ($foldertitle)=@_;
   return { title => $foldertitle, type => 'folder',
            active => 1, hidden => 0, 
            id => &Apache::lc_entity_utils::long_unique_id(), 
            content => [] } 
}

sub setattribute {
   my ($id,$attribute,$value)=@_;

}

sub hide {
   my ($id)=@_;
}

sub unhide {
   my ($id)=@_;
}

sub activate {
   my ($id)=@_;
}

sub deactivate {
   my ($id)=@_;
}

1;
__END__
