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
package Apache::lc_localize;
use base qw(Locale::Maketext);

package Apache::lc_localize::en;
use base qw(Apache::lc_localize);
%Lexicon=('_AUTO' => 1, 
'language_code'      => 'en',
'language_direction' => 'ltr',
'language_description' => 'English',
'date_short_locale' => '$month/$day/$year',
'decimal_divider' => '.',
'power_of_ten_divider' => ',',

'superuser' => 'Superuser',
'domain_coordinator' => 'Domain Coordinator',
'course_coordinator' => 'Course Coordinator',
'instructor' => 'Instructor',
'teaching_assistant' => 'Teaching Assistant',
'student' => 'Student',
'community_organizer' => 'Community Organizer',
'member' => 'Member',
'author' => 'Author',
'co_author' => 'Co-Author'
);

1;

__END__

