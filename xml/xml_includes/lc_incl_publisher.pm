# The LearningOnline Network with CAPA - LON-CAPA
# Include handler modifying course users
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
package Apache::lc_incl_publisher;

use strict;
use Apache::lc_json_utils();
use Apache::lc_file_utils();
use Apache::lc_xml_utils();
use Apache::lc_authorize;
use Apache::lc_ui_localize;
use Apache::lc_xml_forms();
use Apache::lc_xml_gadgets();
use Apache::lc_entity_users();
use Apache::lc_entity_roles();
use Apache::lc_entity_profile();
use Apache::lc_metadata();
use Apache::lc_logs;
use Apache::lc_parameters;
use Apache2::Const qw(:common);


use Data::Dumper;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(incl_publisher_screens);

sub taxonomyinput {
   my ($oldmeta,$newmeta)=@_;
   return &Apache::lc_xml_forms::inputfield('taxonomy','newtaxo','newtaxo',undef,'physics:mechanics:linearkinematics');
}

sub languageinput {
   my ($oldmeta,$newmeta)=@_;
   if ($oldmeta->{'languages'}) {
      my $output='';
      for (my $i=0; $i<=$#{$oldmeta->{'languages'}}; $i++) {
         $output.=&Apache::lc_xml_forms::table_input_field('language'.$i,'language'.$i,'Language','contentlanguage',undef,${$oldmeta->{'languages'}}[$i]); 
      }
      return $output;
   } elsif ($newmeta->{'suggested'}->{'languages'}) {
      my $output='';
      for (my $i=0; $i<=$#{$newmeta->{'suggested'}->{'languages'}}; $i++) { 
         $output.=&Apache::lc_xml_forms::table_input_field('language'.$i,'language'.$i,'Language','contentlanguage',undef,${$newmeta->{'suggested'}->{'languages'}}[$i]);
      }
      return $output;
   } else {
      return &Apache::lc_xml_forms::table_input_field('language0','language0','Language','contentlanguage');
   }
}

sub incl_publisher_screens {
# Get posted content
   my %content=&Apache::lc_entity_sessions::posted_content();
   my $metadata=&Apache::lc_entity_urls::dump_metadata($content{'entity'},$content{'domain'});
   my $output='';
   $output.=&Apache::lc_xml_forms::hidden_field('entity',$content{'entity'}).
            &Apache::lc_xml_forms::hidden_field('domain',$content{'domain'}).
            &Apache::lc_xml_forms::hidden_field('url',$content{'url'});
   if ($content{'stage_two'}) {
   } else {
# First screen
      my $parserextensions=&lc_match_parser();
      my $newmetadata;
      if ($content{'url'}=~/\.$parserextensions$/i) {
         $newmetadata=&Apache::lc_metadata::gather_metadata(&Apache::lc_entity_urls::asset_resource_filename($content{'entity'},$content{'domain'},'wrk','-'));
         unless ($newmetadata) {
            &logerror('Attempt to publish ['.$content{'entity'}.'] ['.$content{'domain'}.'] failed');
            return &Apache::lc_xml_utils::error_message('A problem occured, please try again later.').'<script>$(".lcerror").show()</script>';
         }
         if ($newmetadata->{'errors'}) {
            $output.=&Apache::lc_xml_utils::problem_message('The document has errors and cannot be published.').'<script>$(".lcproblem").show()</script>';
            $output.='<ul class="lcstandard">';
            foreach my $error (@{$newmetadata->{'errors'}}) {
               $output.='<li>'.&mt($error->{'type'}.': [_1] [_2]',$error->{'expected'},$error->{'found'}).'</li>';
            }
            $output.='</ul>';
            return $output;
         }
      }
# We can go ahead with the publication, figure out what we take
      $output.=&Apache::lc_xml_forms::form_table_start().
               &Apache::lc_xml_forms::table_input_field('title','title','Title','text',40,($metadata->{'title'}?$metadata->{'title'}:$newmetadata->{'title'})).
               &languageinput($metadata,$newmetadata).
               &Apache::lc_xml_forms::form_table_end().
               &Apache::lc_xml_forms::triggerbutton('addlanguage','Add Language');
$output.='<pre>'.Dumper($metadata).Dumper($newmetadata).'</pre>';
   }
   return $output;
}

sub handler {
   my $r=shift;
   $r->print(&incl_publisher_screens());
   return OK;
}

1;
__END__
