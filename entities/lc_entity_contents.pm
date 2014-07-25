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

sub toc_to_display {
   my ($toc)=@_;
   my $display;
   
   return $display;
}

sub toc_to_serilize {
   my ($toc)=@_;
   my $series;

   return $series;
}

sub folder_serilize_eval {
   my ($series,$folder)=@_;
   foreach my $element (@{$folder}) {
      if ($element->{'type'} eq 'asset') {
      } elsif ($element->{'type'} eq 'folder') {
      }
   }
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
