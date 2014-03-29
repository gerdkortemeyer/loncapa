# The LearningOnline Network with CAPA - LON-CAPA
# Localization Module
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
package Apache::lc_ui_localize;

use strict;
use Apache::lc_localize;
use Apache::lc_entity_sessions();
use DateTime;
use DateTime::TimeZone;

require Exporter;

our @ISA = qw (Exporter);
our @EXPORT = qw(mt);

# ========================================================= The language handle

use vars qw($lh $current_language $mtcache %known_languages);

sub all_languages {
   return %known_languages;
}

sub all_timezones {
   return DateTime::TimeZone->all_names;
}
 
sub mt {
   if ($lh) {
      if ($#_>0) { return $lh->maketext(@_); }
      if ($mtcache->{$current_language}->{$_[0]}) {
         return $mtcache->{$current_language}->{$_[0]};
      }
      my $translation=$lh->maketext(@_);
      $mtcache->{$current_language}->{$_[0]}=$translation;
      return $translation;
   } else {
      return $_[0];
   }
}

sub determine_language {
#FIXME: needs cascading set
   &set_language(&Apache::lc_entity_sessions::userlanguage());
}

sub set_language {
   my ($lang)=@_;
   unless ($known_languages{$lang}) { return undef; }
   undef $lh;
   $lh=Apache::lc_localize->get_handle($lang);
   $current_language=$lang;
}

sub reset_language {
   undef $lh;
   $lh=Apache::lc_localize->get_handle();
   $current_language=&mt('language_code',1);
}

BEGIN {
   %known_languages=(
       'de' => 'German',
       'en' => 'English',
       'x-bork' => 'Swedish Chef',
       'x-pig' => 'Pig Latin'
                    );
}
1;
__END__
