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
