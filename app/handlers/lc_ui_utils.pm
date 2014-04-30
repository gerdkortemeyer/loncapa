# The LearningOnline Network with CAPA - LON-CAPA
# UI Utilities
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
package Apache::lc_ui_utils;

use strict;
use Apache::lc_init_cluster_table();
use Apache::lc_ui_localize;
use Apache::lc_entity_sessions();

require Exporter;

our @ISA = qw (Exporter);
our @EXPORT = qw(clean_username clean_domain domain_choices domain_name language_choices timezone_choices);

# ==== Clean up usernames and domains
#
sub clean_username {
   my ($username)=@_;
   $username=~s/\s//gs;
   $username=~s/\///gs;
   return $username;
}

sub clean_domain {
   my ($domain)=@_;
   $domain=~s/\s//gs;
   $domain=~s/\///gs;
   return $domain;
}

# ==== The domain choices
#
sub domain_choices {
   my ($type)=@_;
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   my @shorts;
   my %names;
   foreach my $key (keys(%{$connection_table->{'cluster_table'}->{'hosts'}->{$connection_table->{'self'}}->{'domains'}})) {
      push(@shorts,$key);
      $names{$key}=$connection_table->{'cluster_table'}->{'domains'}->{$key}->{'name'};
   }
   my $domain_short;
   my $domain_name;
   @shorts=sort(@shorts);
   foreach my $key (@shorts) {
       push(@{$domain_short},$key);
       push(@{$domain_name},$names{$key});
   }
   return ($connection_table->{'cluster_table'}->{'hosts'}->{$connection_table->{'self'}}->{'default'},
           $domain_short,$domain_name);
}

sub domain_name {
   my ($domain)=@_;
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   return $connection_table->{'cluster_table'}->{'domains'}->{$domain}->{'name'};
}


# ==== Language choices
#
sub language_choices {
   my ($type)=@_;
   my %language_choices=&Apache::lc_ui_localize::all_languages();
   my $language_short;
   my $language_name;
   foreach my $key (sort(keys(%language_choices))) {
       push(@{$language_short},$key);
       push(@{$language_name},&mt($language_choices{$key}));
   }
   my $default;
   if ($type eq 'user') {
      $default=&Apache::lc_ui_localize::context_language();
   }
   unless ($default) { $default='en'; }
   return ($default,$language_short,$language_name);
}

# ==== Timezone choices
#
sub timezone_choices {
   my ($type)=@_;
   my @timezones=&Apache::lc_ui_localize::all_timezones();
   my $default;
   if ($type eq 'user') {
      $default=&Apache::lc_ui_localize::context_timezone();
   }
   unless ($default) { $default='UTC'; }
   return ($default,\@timezones);
}

1;
__END__
