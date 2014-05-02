# The LearningOnline Network with CAPA - LON-CAPA
# German Localization Module
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
#
package Apache::lc_localize::de;
use base qw(Apache::lc_localize);
use utf8;

%Lexicon=('_AUTO' => 1,
'language_code'      => 'de',
'language_direction' => 'ltr',
'language_description' => 'Deutsch',
'date_locale'  => '$weekday, $day. $month $year, $twentyfour:$minutes:$seconds Uhr',
'date_short_locale' => '$day.$month.$year',
'date_months'  => 'Jan.,Feb.,März,April,Mai,Juni,Juli,Aug.,Sep.,Okt.,Nov.,Dez.',
'date_days'    => 'So.,Mo.,Di.,Mi.,Do.,Fr.,Sa.',
'date_am' => 'vormittags',
'date_pm' => 'nachmittags',
'date_format' => '24',

'superuser' => 'Superuser',
'domain_coordinator' => 'Domänenkoordinator',
'course_coordinator' => 'Kurskoordinator',
'instructor' => 'Dozent',
'teaching_assistant' => 'Tutor',
'student' => 'Studierender',
'community_organizer' => 'Gemeinschaftsorganisator',
'member' => 'Mitglied',
'author' => 'Autor',
'co_author' => 'Co-Autor',

'Modify Selected Entries' => 'Ausgewählte Einträge ändern',

'Add New Entry' => 'Neuen Eintrag hinzufügen',

'Manually Enroll User' => 'Manuell Teilnehmer hinzufügen',

'Manually Enroll' => 'Manuell einschreiben',

'Upload List' => 'Liste hochladen',

'Upload User List' => 'Teilnehmerliste hochladen',

'Select All' => 'Alle auswählen',

'Select Filtered' => 'Gefilterte auswählen',

'Deselect All' => 'Alle Auswahlen zurücksetzen',

'Enrollment Mode' => 'Einschreibungsmodus',

'Enrolling User' => 'Einschreibender Nutzer',

'Manual' => 'Manuell',

'Automatic' => 'Automatisch',

'Modify Enrollment List' => 'Teilnehmerliste ändern',

'Please upload a spreadsheet with enrollment information.' => 'Bitte laden Sie in Spreadsheet mit Teilnehmerinformation hoch.',

'Future' => 'Zukünftig',

'Past' => 'Vergangen',

'Welcome!' => 'Willkommen!',

'Welcome' => 'Willkommen',

'Username' => 'Benutzerkennung',

'Password' => 'Passwort',

'Domain' => 'Domäne',

'Login' => 'Anmelden',

'Logout' => 'Abmelden',

'Places' => 'Plätze',

'Courses' => 'Kurse',

'Communities' => 'Gemeinschaften',

'User' => 'Nutzer',

'Messages' => 'Nachrichten',

'Calendar' => 'Kalender',

'Bookmarks' => 'Lesezeichen',

'Title' => 'Titel',

'Show' => 'Anzeigen',

'Set' => 'Setzen',

'Submit' => 'Einreichen',

'Help' => 'Hilfe',

'Preferences' => 'Einstellungen',

'Store' => 'Speichern',

'Language' => 'Sprache',

'German' => 'Deutsch',

'English' => 'Englisch',

'Swedish Chef' => 'Dänischer Koch',

'Pig Latin' => 'Schweine-Latein',

'Timezone' => 'Zeitzone',

'Date format month/day/year' => 'Datum Format Tag.Monat.Jahr',

'Hour' => 'Stunde',

'Minute' => 'Minute',

'Second' => 'Sekunde',

'Before/after midday' => 'vor-/nachmittags',

'Upload file' => 'Datei hochladen',

'Cancel' => 'Abbrechen',

'Do you really want to logout?' => 'Wollen Sie sich wirklich abmelden?',

'Please enter your user information.' => 'Bitte geben Sie Ihre Benutzerinformation ein.',

'A problem occured, please try again later.' => 'Ein Problem ist eingetreten, bitte versuchen Sie es später noch einmal.',

'Your username or password were not recognized.' => 'Ihre Benutzerkennnung oder Ihr Passwort wurden nicht erkannt.',

'You can modify your user preferences below.' => 'Sie können die untenstehenden Einstellungen verändern.',

'A problem occurred while saving your preferences.' => 'Während der Speicherung Ihrer Einstellungen trat ein Problem ein.',

'Your preferences were saved.' => 'Ihre Einstellungen wurden gespeichert.',

'Add this page to your bookmark collection.' => 'Fügen Sie diese Seite Ihrer Lesezeichensammlung hinzu.',

'Dashboard' => 'Übersicht',

'Portfolio' => 'Portfolio',

'Select' => 'Auswählen',

'Never' => 'Niemals',

'Select a course to enter' => 'Wählen Sie einen Kurs aus',

'Select a community to enter' => 'Wählen Sie eine Gemeinschaft aus',

'A problem occurred while entering the course.' => 'Bei der Auswahl des Kurses trat ein Problem auf.',

'A problem occurred while entering the community.' => 'Bei der Auswahl der Gemeinschaft trat ein Problem auf.',

'Course entered.' => 'Kurs ausgewählt.',

'Community entered.' => 'Gemeinschaft ausgewählt.',

'Content' => 'Inhalt',

'Grades' => 'Noten',

'Grading' => 'Benotung',

'My Grades' => 'Meine Noten',

'Administration' => 'Verwaltung',

'Enrollment' => 'Teilnehmer',

'Enrollment List' => 'Teilnehmerliste',

'List' => 'Liste',

'First Name' => 'Vorname',

'Middle Name' => 'Weitere Vornamen',

'Last Name' => 'Nachname',

'Suffix' => 'Namenssuffix',

'ID Number' => 'Matrikelnummer',

'Column Visibility:' => 'Spalteneinblendung:',

'Role' => 'Rolle',

'Section/Group' => 'Sektion/Gruppe',

'Start Date' => 'Anfangsdatum',

'End Date' => 'Enddatum',

'Active' => 'Aktiv',

'Last Access' => 'Letzter Zugriff',

"No data available in table" => "Keine Daten in der Tabelle",

"Showing [_1] to [_2] of [_3] entries" => "Einträge [_1] bis [_2] von [_3] insgesamt",

"Showing 0 to 0 of 0 entries" => "Einträge 0 bis 0 von 0 insgesamt",

"(filtered from [_1] total entries)" => "(gefiltert aus [_1] Gesamteinträgen)",

"," => ".",

"Show [_1] entries" => "Zeige [_1] Einträge",

"Loading..." => "Laden ...",

"Processing..." => "Verarbeiten ...",

"Search:" => "Suche:",

"No matching records found" => "Keine entsprechenden Einträge gefunden",

"First" => "Erste",

"Last" => "Letzte",

"Next" => "Nächste",

"Previous" => "Vorhergehende",

": activate to sort column ascending" => ": aktiviere um Spalte aufsteigend zu ordnen",

": activate to sort column descending" => ": aktiviere um Spalte absteigend zu ordnen"

);

1;
__END__
