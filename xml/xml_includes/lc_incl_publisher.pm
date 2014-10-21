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
   my ($oldmeta,$newmeta,$add)=@_;
   my $output='';
   my $max=0;
   if ($oldmeta->{'languages'}) {
      for (my $i=0; $i<=$#{$oldmeta->{'languages'}}; $i++) {
         $output.=&Apache::lc_xml_forms::inputfield('contentlanguage','language'.$i,'language'.$i,undef,${$oldmeta->{'languages'}}[$i]); 
      }
      $max=$#{$oldmeta->{'languages'}};
   } elsif ($newmeta->{'suggested'}->{'languages'}) {
      for (my $i=0; $i<=$#{$newmeta->{'suggested'}->{'languages'}}; $i++) { 
         $output.=&Apache::lc_xml_forms::inputfield('contentlanguage','language'.$i,'language'.$i,undef,${$newmeta->{'suggested'}->{'languages'}}[$i]);
      }
      $max=$#{$newmeta->{'suggested'}->{'languages'}};
   } else {
      $output.=&Apache::lc_xml_forms::inputfield('contentlanguage','language0','language0',undef,'-');
   }
   if ($add) {
      $max++;
      $output.=&Apache::lc_xml_forms::inputfield('contentlanguage','language'.$max,'language'.$max,undef,'-');
   }
   return $output;
}

#
# Taxonomy input
#
sub taxonomyinput {
   my ($oldmeta,$newmeta,$add)=@_;
   my $output='';
   my $max=0;
   if ($oldmeta->{'taxonomy'}) {
      for (my $i=0; $i<=$#{$oldmeta->{'taxonomy'}}; $i++) {
         $output.=&Apache::lc_xml_forms::taxonomyfield('taxonomy'.$i,'taxonomy'.$i,${$oldmeta->{'taxonomy'}}[$i]);
      }
      $max=$#{$oldmeta->{'taxonomy'}};
   } elsif ($newmeta->{'suggested'}->{'taxonomy'}) {
      for (my $i=0; $i<=$#{$newmeta->{'suggested'}->{'taxonomy'}}; $i++) {
         $output.=&Apache::lc_xml_forms::taxonomyfield('taxonomy'.$i,'taxonomy'.$i,${$newmeta->{'suggested'}->{'taxonomy'}}[$i]);
      }
      $max=$#{$newmeta->{'suggested'}->{'taxonomy'}};
   } else {
      $output.=&Apache::lc_xml_forms::taxonomyfield('taxonomy0','taxonomy0');
   }
   if ($add) {
      $max++;
      $output.=&Apache::lc_xml_forms::taxonomyfield('taxonomy'.$max,'taxonomy'.$max);
   }
   return $output;
}

#
# Keyboard input
#
sub keywordinput {
   my ($oldmeta,$newmeta)=@_;
   my $output='';
   my $n=0;
   if ($oldmeta->{'keywords'}) {
      foreach my $key (@{$oldmeta->{'keywords'}}) {
         $n++;
         $output.=&Apache::lc_xml_forms::wordbubble('key'.$n,'key'.$n,$key,1).' ';
      }
   } elsif ($newmeta->{'suggested'}->{'keywords'}) {
      my %taxokeywords=&Apache::lc_taxonomy::prokeywords($oldmeta->{'taxonomy'});
      foreach my $key (@{$newmeta->{'suggested'}->{'keywords'}}) {
         $n++;
         $output.=&Apache::lc_xml_forms::wordbubble('key'.$n,'key'.$n,$key,$taxokeywords{$key}).' ';
      }
   }
   $output.=&Apache::lc_xml_forms::hidden_field('maxkey',$n);
   return $output;
}

#
# Stage one asks title and language
#
sub stage_one {
   my ($metadata,%content)=@_;
   my $output='';
   my $parserextensions=&lc_match_parser();
   my $newmetadata;
# Can this content be parsed? If yes, get what we can. If it does not parse correctly, give up now
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
# We can go ahead
   $output.=&Apache::lc_xml_forms::form_table_start().
            &Apache::lc_xml_forms::table_input_field('title','title','Title','text',40,($metadata->{'title'}?$metadata->{'title'}:$newmetadata->{'title'})).
            &Apache::lc_xml_forms::form_table_end().'<p>'.
            &Apache::lc_xml_utils::standard_message('Select the languages').'<br />'.
            &languageinput($metadata,$newmetadata,$content{'addlanguage'}).'<br />&nbsp;<br />'.
            &Apache::lc_xml_forms::triggerbutton('addlanguage','Add Language').'<script>attach_language()</script></p>'.
            &Apache::lc_xml_forms::hidden_field('stage',1);
   return $output;
}

#
# Stage two asks for taxonomies
#
sub stage_two {
   my ($metadata,%content)=@_;
   my $output='';
   my $parserextensions=&lc_match_parser();
   my $newmetadata;
   if ($content{'url'}=~/\.$parserextensions$/i) {
      $newmetadata=&Apache::lc_metadata::gather_metadata(&Apache::lc_entity_urls::asset_resource_filename($content{'entity'},$content{'domain'},'wrk','-'));
   }
   $output.='<p>'.&Apache::lc_xml_utils::standard_message('Select the taxonomy categories').'<br />'.
            &taxonomyinput($metadata,$newmetadata,$content{'addtaxonomy'}).'<br />&nbsp;<br />'.
            &Apache::lc_xml_forms::triggerbutton('addtaxonomy','Add Taxonomy').'<script>attach_taxonomy()</script></p>'.
            &Apache::lc_xml_forms::hidden_field('stage',2);
   return $output;
}

#
# Stage three asks for keywords
#
sub stage_three {
   my ($metadata,%content)=@_;
   my $output='';
   my $parserextensions=&lc_match_parser();
   my $newmetadata;
   if ($content{'url'}=~/\.$parserextensions$/i) {
      $newmetadata=&Apache::lc_metadata::gather_metadata(&Apache::lc_entity_urls::asset_resource_filename($content{'entity'},$content{'domain'},'wrk','-'));
   }
   $output.='<p>'.&Apache::lc_xml_utils::standard_message('Select the keywords').'<br />'.
            &keywordinput($metadata,$newmetadata).'<br />&nbsp;<br />'.
            &Apache::lc_xml_forms::form_table_start().
            &Apache::lc_xml_forms::table_input_field('addkey','addkey','Additional keywords','text',60).
            &Apache::lc_xml_forms::form_table_end().
            &Apache::lc_xml_forms::triggerbutton('addkeywords','Add Keywords').'<script>attach_keywords()</script></p>'.
            &Apache::lc_xml_forms::hidden_field('stage',3);
   return $output;
}

#
# Stage four asks about rights
#
sub stage_four {
   my ($metadata,%content)=@_;
   my $std_rights=&Apache::lc_entity_urls::standard_rights($content{'entity'},$content{'domain'},$content{'url'});
   my $output;
# Viewing
# Derivative
#
   $output.=
            &Apache::lc_xml_forms::hidden_field('stage',4);


$output.=&Apache::lc_xml_forms::radiobuttons('test','test',['optionA','optionB','optionC'],
                                             ['Option A','Great Option B','My Option C'],
                                             'optionB');
   return $output;
}

#
# Finalize
#
sub stage_five {
   my ($metadata,%content)=@_;
   my $output;
   return $output;
}

#
# See if we learned anything that should be stored
# Update metadata if needed
#
sub storedata {
   my ($metadata,%content)=@_;
   my $storemeta;
   my $refreshkeys;
# Title
   $content{'title'}=~s/^\s+//s;
   $content{'title'}=~s/\s+$//s;
   if ($content{'title'}) {
      if ($content{'title'} ne $metadata->{'title'}) {
         $storemeta->{'title'}=$content{'title'};
      }
   }
# Languages
   if ($content{'language0'}) {
      my $n=0;
      my %already=();
      $storemeta->{'languages'}=[];
      push(@{$refreshkeys},'languages');
      while ($content{'language'.$n}) {
         if ($content{'language'.$n} ne '-') {
            unless ($already{$content{'language'.$n}}) {
               push(@{$storemeta->{'languages'}},$content{'language'.$n});
               $already{$content{'language'.$n}}=1;
            }
         }
         $n++;
      }
   }
# Taxonomy categories
   if ($content{'taxonomy0_first'}) {
      my $n=0;
      my %already=();
      $storemeta->{'taxonomy'}=[];
      push(@{$refreshkeys},'taxonomy');
      while ($content{'taxonomy'.$n.'_first'}) {
         if ($content{'taxonomy'.$n.'_first'} ne '-') {
            my $term=$content{'taxonomy'.$n.'_first'};
            if (($content{'taxonomy'.$n.'_second'}) && ($content{'taxonomy'.$n.'_second'} ne '-')) {
               $term.=':'.$content{'taxonomy'.$n.'_second'};
            }
            if (($content{'taxonomy'.$n.'_third'}) && ($content{'taxonomy'.$n.'_third'} ne '-')) {
               $term.=':'.$content{'taxonomy'.$n.'_third'};
            }
            unless ($already{$term}) { 
               push(@{$storemeta->{'taxonomy'}},$term);
               $already{$term}=1;
            }
         }
         $n++;
      }
   }
# Keywords
   my %keywords=();
   if ($content{'maxkey'}) {
      for (my $n=1; $n<=$content{'maxkey'}; $n++) {
          if ($content{'key'.$n}) {
             $keywords{$content{'key'.$n}}++;
          }
      }
   }
   my $words=&Apache::lc_metadata::split_words($content{'addkey'});
   foreach my $word (@{$words}) {
      $keywords{$word}=1;
   }
   my @keywords=keys(%keywords);
   if ($#keywords>=0) {
      push(@{$refreshkeys},'keywords');
      $storemeta->{'keywords'}=\@keywords;
   }
# Actually store this
   if ($storemeta) {
      unless (&Apache::lc_entity_urls::store_metadata($content{'entity'},$content{'domain'},$storemeta,$refreshkeys)) {
         &logerror('Attempt to store metadata for ['.$content{'entity'}.'] ['.$content{'domain'}.'] failed');
         return &Apache::lc_xml_utils::error_message('A problem occured, please try again later.').'<script>$(".lcerror").show()</script>';
      }
   }
   return '';
}

sub incl_publisher_screens {
# Get posted content
   my %content=&Apache::lc_entity_sessions::posted_content();
   my $metadata=&Apache::lc_entity_urls::dump_metadata($content{'entity'},$content{'domain'});
   my $output='';
# Remember what we are talking about
   $output.=&Apache::lc_xml_forms::hidden_field('entity',$content{'entity'}).
            &Apache::lc_xml_forms::hidden_field('domain',$content{'domain'}).
            &Apache::lc_xml_forms::hidden_field('url',$content{'url'});
# Figure out the stage (which screen in the sequence)
# Override can be used to direct back to a previous screen if needed
   my $stage=$content{'stage'};
   if ($content{'returnstage'}) {
      $stage=$content{'returnstage'}-1;
   }
# Anything to store?
   $output.=&storedata($metadata,%content);
# Reload to make sure we have the latest data
   $metadata=&Apache::lc_entity_urls::dump_metadata($content{'entity'},$content{'domain'});
   if ($stage==1) {
       $output.=&stage_two($metadata,%content);
   } elsif ($stage==2) {
       $output.=&stage_three($metadata,%content);
   } elsif ($stage==3) {
       $output.=&stage_four($metadata,%content);
   } elsif ($stage==4) {
       $output.=&stage_five($metadata,%content);
   } else {
       $output.=&stage_one($metadata,%content);
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
