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

my $series;

sub toc_to_display {
   my ($toc)=@_;
   my $display;
   my $series=&toc_to_serialize($toc);
   foreach my $element (@{$series}) {
      my $newelement=undef;
      $newelement->{'text'}=$element->{'title'};
      $newelement->{'parent'}=$element->{'parent'};
      $newelement->{'id'}=$element->{'id'};
      push(@{$display},$newelement);
   } 
   return $display;
}

sub toc_to_serialize {
   my ($toc)=@_;
   $series=undef;
   return &folder_serialize_eval('#',$toc);
}

sub folder_serialize_eval {
   my ($name,$folder)=@_;
   foreach my $element (@{$folder}) {
      $element->{'parent'}=$name;
      push(@{$series},$element);
      if ($element->{'type'} eq 'folder') {
         &folder_serialize_eval($element->{'id'},$element->{'content'});
      }
   }
   return $series;
}

sub new_asset {
   my ($resentity,$resdomain,$restitle)=@_;
   return { entity => $resentity, domain => $resdomain, 
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
