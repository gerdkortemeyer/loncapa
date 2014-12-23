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

'unexpected_ending: [_1] [_2]' => '&lt;[_1]&gt; was found instead of the ending of &lt;/[_2]&gt;.',

'missing_ending: [_1] [_2]' => 'The end of &lt;[_1]&gt; was not found.',

'superuser' => 'Superuser',
'domain_coordinator' => 'Domain Coordinator',
'course_coordinator' => 'Course Coordinator',
'instructor' => 'Instructor',
'teaching_assistant' => 'Teaching Assistant',
'student' => 'Student',
'community_organizer' => 'Community Organizer',
'member' => 'Member',
'author' => 'Author',
'co_author' => 'Co-Author',

'correct' => 'Correct',
'incorrect' => 'Incorrect',
'previously_submitted' => 'Previously submitted',
'numerical_error' => 'Numerical error',
'bad_formula' => 'Bad formula',
'wrong_dimension' => 'Wrong dimension',
'wrong_type' => 'Wrong type',
'no_unit_required' => 'No unit required',
'unit_missing' => 'Unit missing',
'wrong_unit_dimension' => 'Wrong unit dimension',
'wrong_endpoint' => 'Wrong endpoint',
'no_valid_answer' => 'No valid answer',
'no_valid_response' => 'No valid response',
'answer_scalar_required' => 'Scalar answer required',
'response_scalar_required' => 'Scalar response required',
'answer_array_required' => 'Array answer required',
'response_array_required' => 'Array response required',
'internal_error' => 'Internal error'

);

1;

__END__

