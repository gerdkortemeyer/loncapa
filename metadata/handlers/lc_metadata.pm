# The LearningOnline Network with CAPA - LON-CAPA
#
# Gathers metadata from an XML/HTML file
# Deals with metadata processing
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
package Apache::lc_metadata;

use strict;

use Apache::lc_parameters;
use Apache::lc_logs;
use Apache::lc_json_utils();
use Apache::lc_file_utils();
use Apache::lc_taxonomy();
use Apache::lc_asset_xml();
use locale;

my $nonwords;

sub split_words {
   my ($text)=@_;
   my @words;
   my @rawwords=split(/\s+/s,$text);
   foreach my $word (@rawwords) {
      unless ($word) { next; }
      if ($word=~/\&.+\;/) { next; }
      if ($word=~/\d/) { next; }
      $word=~s/[\.\;\"\:\'\,]+$//s;
      $word=~s/^[\.\;\"\:\'\,]+//s;
      push(@words,lc($word));
   }
   return \@words;
}


sub detect_languages {
   my ($words)=@_;
   unless ($nonwords) { &load_nonwords(); }
   my $total=0;
   my %languagewords=();
   foreach my $word (@{$words}) {
      $total++;
      foreach my $language (&lc_meta_detect_langs()) {
         if ($nonwords->{$language}->{$word}) {
            $languagewords{$language}++;
         }
      }
   }
   unless ($total) { return []; }
   my $languagesfound;
   foreach my $language (&lc_meta_detect_langs()) {
      if ($languagewords{$language}/$total>0.1) {
         push(@{$languagesfound},$language);
      }
   }
   return $languagesfound;
}

sub detect_keywords {
   my ($words,$languages)=@_;
   my %keywords=();
   foreach my $word (@{$words}) {
# no nonwords
       my $is=1;
       foreach my $language (&lc_meta_detect_langs()) {
          if ($nonwords->{$language}->{$word}) {
             $is=0;
             last;
          }
       }
       if ($is) {
          $keywords{$word}++;
       }
   }
   my @keywordarray=keys(%keywords);
   return \@keywordarray;
}

sub gather_metadata {
   my ($fn)=@_;
   my ($output,$stack)=&Apache::lc_asset_xml::target_render($fn,'meta');
   my $metadata=$stack->{'metadata'};
   if ($stack->{'errors'}) {
      $metadata->{'errors'}=$stack->{'errors'};
   }
   my $words=&split_words($output);
   $metadata->{'suggested'}->{'languages'}=&detect_languages($words);
   $metadata->{'suggested'}->{'taxonomy'}=&Apache::lc_taxonomy::detect_taxonomy($words);
   $metadata->{'suggested'}->{'keywords'}=&detect_keywords($words,$metadata->{'suggested'}->{'languages'});
   return $metadata;
}

sub load_nonwords {
   foreach my $language (&lc_meta_detect_langs()) {
       my $content=&Apache::lc_file_utils::readfile(&lc_conf_dir().'/non_keyword/non_keyword_'.$language.'.txt');
       foreach my $word (split(/\s+/s,$content)) {
          $nonwords->{$language}->{$word}=1;
       }
   }
}

1;
__END__
