# The LearningOnline Network with CAPA - LON-CAPA
#
# Deal with the taxonomy table
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
package Apache::lc_taxonomy;

use strict;

use Apache::lc_parameters;
use Apache::lc_logs;
use Apache::lc_json_utils();
use Apache::lc_file_utils();

my $taxonomy;

#
# Return hashes of first, second, and third level
# taxonomy options
#
sub first_level {
   my ($lang)=@_;
   unless ($lang) { $lang='en'; }
   my %terms;
   unless ($taxonomy) { &load_taxonomy() }
   foreach my $key (keys(%{$taxonomy})) {
      $terms{$key}=$taxonomy->{$key}->{'lang'}->{$lang};
      unless ($terms{$key}) {
         $terms{$key}=$taxonomy->{$key}->{'lang'}->{'en'};
      }
   }
   return %terms;
}

sub second_level {
   my ($lang,$first)=@_;
   unless ($first) { return (); }
   if ($first eq '-') { return (); }
   unless ($lang) { $lang='en'; }
   my %terms;
   unless ($taxonomy) { &load_taxonomy() }
   foreach my $key (keys(%{$taxonomy->{$first}->{'sub'}})) {
      $terms{$key}=$taxonomy->{$first}->{'sub'}->{$key}->{'lang'}->{$lang};
      unless ($terms{$key}) {
         $terms{$key}=$taxonomy->{$first}->{'sub'}->{$key}->{'lang'}->{'en'};
      }
   }
   return %terms;
}

sub third_level {
   my ($lang,$first,$second)=@_;
   unless ($first) { return (); }
   if ($first eq '-') { return (); }
   unless ($second) { return (); }
   if ($second eq '-') { return (); }
   unless ($lang) { $lang='en'; }
   my %terms;
   unless ($taxonomy) { &load_taxonomy() }
   foreach my $key (keys(%{$taxonomy->{$first}->{'sub'}->{$second}->{'sub'}})) {
      $terms{$key}=$taxonomy->{$first}->{'sub'}->{$second}->{'sub'}->{$key}->{'lang'}->{$lang};
      unless ($terms{$key}) {
         $terms{$key}=$taxonomy->{$first}->{'sub'}->{$second}->{'sub'}->{$key}->{'lang'}->{'en'};
      }
   }
   return %terms;
}


#
# Give the full names for a taxonomy
#
sub full_name {
   my ($lang,$first,$second,$third)=@_;
   unless ($lang) { $lang='en'; }
   unless ($taxonomy) { &load_taxonomy(); }
   my $firstfull='';
   my $secondfull='';
   my $thirdfull='';
   if ($first) {
      $firstfull=$taxonomy->{$first}->{'lang'}->{$lang};
   }
   if ($second) {
      $secondfull=$taxonomy->{$first}->{'sub'}->{$second}->{'lang'}->{$lang};
   }
   if ($third) {
      $thirdfull=$taxonomy->{$first}->{'sub'}->{$second}->{'sub'}->{$third}->{'lang'}->{$lang};
   }
   return ($firstfull,$secondfull,$thirdfull);
}

#
# Try to automatically assign some taxonomies
# based on indicative and counter-indicative
# keywords
#

sub found_a_term {
   my ($words,$wordlist)=@_;
   foreach my $term (@{$wordlist}) {
      foreach my $word (@{$words}) {
         if ($word eq $term) { 
            return 1; 
         }
      }
   }
   return 0;
}

sub check_procon {
   my ($procon,$words,$term,%foundtaxonomies)=@_;
   if ($procon->{'pro'}) {
      if (&found_a_term($words,$procon->{'pro'})) {
         $foundtaxonomies{$term}++;
      }
   }
   if ($procon->{'con'}) {
      if (&found_a_term($words,$procon->{'con'})) {
         delete($foundtaxonomies{$term});
      }
   }
   return %foundtaxonomies;
}

sub detect_taxonomy {
   my ($words)=@_;
   my %foundtaxonomies=();
   unless ($taxonomy) { &load_taxonomy() }
# First level
   foreach my $firstkey (keys(%{$taxonomy})) {
      %foundtaxonomies=&check_procon($taxonomy->{$firstkey},$words,$firstkey,%foundtaxonomies);
# Second level
      foreach my $secondkey (keys(%{$taxonomy->{$firstkey}->{'sub'}})) {
         %foundtaxonomies=&check_procon($taxonomy->{$firstkey}->{'sub'}->{$secondkey},$words,"$firstkey:$secondkey",%foundtaxonomies);
# Third level
         foreach my $thirdkey (keys(%{$taxonomy->{$firstkey}->{'sub'}->{$secondkey}->{'sub'}})) {
            %foundtaxonomies=&check_procon($taxonomy->{$firstkey}->{'sub'}->{$secondkey}->{'sub'}->{$thirdkey},$words,"$firstkey:$secondkey:$thirdkey",%foundtaxonomies);
         }
      }
   }
# Filter out less specific
   my @taxonomyterms=();
   foreach my $taxo (sort(keys(%foundtaxonomies))) {
      if ($#taxonomyterms>=0) {
         if ($taxo=~/^\Q$taxonomyterms[-1]\E/) {
            $taxonomyterms[-1]=$taxo;
         } else {
            push(@taxonomyterms,$taxo);
         }
      } else {
         push(@taxonomyterms,$taxo);
      }
   }
   return \@taxonomyterms; 
}

sub load_taxonomy {
   $taxonomy=&Apache::lc_json_utils::json_to_perl(
                        &Apache::lc_file_utils::readfile(&lc_conf_dir().'taxonomy.json')
                                                 );
   unless ($taxonomy) {
      &logerror("Could not read taxonomy file");
      return 0;
   }
   &lognotice("Read taxonomy");
   return 1;
}


1;
__END__
