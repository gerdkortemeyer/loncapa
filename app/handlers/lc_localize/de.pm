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
'decimal_divider' => ',',
'power_of_ten_divider' => '.',

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

"Abkhazian" => "Abkhazian",
"Afar" => "Afar",
"Afrikaans" => "Afrikaans",
"Akan" => "Akan",
"Albanian" => "Albanian",
"Amharic" => "Amharic",
"Arabic" => "Arabisch",
"Aragonese" => "Aragonese",
"Armenian" => "Armenian",
"Assamese" => "Assamese",
"Avaric" => "Avaric",
"Avestan" => "Avestan",
"Aymara" => "Aymara",
"Azerbaijani" => "Azerbaijani",
"Bambara" => "Bambara",
"Bashkir" => "Bashkir",
"Basque" => "Baskisch",
"Belarusian" => "Weißrussisch",
"Bengali" => "Bengali",
"Bihari languages" => "Bihari Sprachen",
"Bislama" => "Bislama",
"Bosnian" => "Bosnisch",
"Breton" => "Bretonisch",
"Bulgarian" => "Bulgarisch",
"Burmese" => "Burmesisch",
"Catalan" => "Katalanisch",
"Central Khmer" => "Zentral Khmer",
"Chamorro" => "Chamorro",
"Chechen" => "Tschetschechenisch",
"Chinese" => "Chinesisch",
"Church Slavic" => "Kirchenslawisch",
"Chuvash" => "Chuvash",
"Cornish" => "Kornisch",
"Corsican" => "Korsisch",
"Cree" => "Cree",
"Croatian" => "Kroatisch",
"Czech" => "Tschechisch",
"Danish" => "Dänisch",
"Dhivehi" => "Dhivehi",
"Dutch" => "Holländisch",
"Dzongkha" => "Dzongkha",
"English" => "Englisch",
"Esperanto" => "Esperanto",
"Estonian" => "Estonisch",
"Ewe" => "Ewe",
"Faroese" => "Färöisch",
"Fijian" => "Fijian",
"Finnish" => "Finnisch",
"French" => "Französisch",
"Fulah" => "Fulah",
"Galician" => "Galician",
"Ganda" => "Ganda",
"Georgian" => "Georgisch",
"German" => "Deutsch",
"Guarani" => "Guarani",
"Gujarati" => "Gujarati",
"Haitian" => "Haitian",
"Hausa" => "Hausa",
"Hebrew" => "Hebräisch",
"Herero" => "Herero",
"Hindi" => "Hindi",
"Hiri Motu" => "Hiri Motu",
"Hungarian" => "Hungarian",
"Icelandic" => "Isländisch",
"Ido" => "Ido",
"Igbo" => "Igbo",
"Indonesian" => "Indonesisch",
"Interlingua" => "Interlingua",
"Interlingue" => "Interlingue",
"Inuktitut" => "Inuktitut",
"Inupiaq" => "Inupiaq",
"Irish" => "Irisch",
"Italian" => "Italienisch",
"Japanese" => "Japanisch",
"Javanese" => "Javanesisch",
"Kalaallisut" => "Kalaallisut",
"Kannada" => "Kannada",
"Kanuri" => "Kanuri",
"Kashmiri" => "Kashmiri",
"Kazakh" => "Kazakh",
"Kikuyu" => "Kikuyu",
"Kinyarwanda" => "Kinyarwanda",
"Kirghiz" => "Kirghiz",
"Komi" => "Komi",
"Kongo" => "Kongo",
"Korean" => "Koreanisch",
"Kuanyama" => "Kuanyama",
"Kurdish" => "Kurdisch",
"Lao" => "Lao",
"Latin" => "Lateinisch",
"Latvian" => "Lettisch",
"Limburgan" => "Limburgan",
"Lingala" => "Lingala",
"Lithuanian" => "Litauisch",
"Luba-Katanga" => "Luba-Katanga",
"Luxembourgish" => "Luxembourgisch",
"Macedonian" => "Mazedonisch",
"Malagasy" => "Malagasy",
"Malay" => "Malaiisch",
"Malayalam" => "Malayalam",
"Maltese" => "Maltesisch",
"Manx" => "Manx",
"Maori" => "Maori",
"Marathi" => "Marathi",
"Marshallese" => "Marshallese",
"Modern Greek" => "Modernes Griechisch",
"Mongolian" => "Mongolian",
"Nauru" => "Nauru",
"Navajo" => "Navajo",
"Ndonga" => "Ndonga",
"Nepali" => "Nepali",
"North Ndebele" => "Nord Ndebele",
"Northern Sami" => "Nord Sami",
"Norwegian" => "Norwegisch",
"Norwegian Bokmal" => "Norwegisch Bokmal",
"Norwegian Nynorsk" => "Norwegisch Nynorsk",
"Nyanja" => "Nyanja",
"Occitan" => "Occitan",
"Ojibwa" => "Ojibwa",
"Oriya" => "Oriya",
"Oromo" => "Oromo",
"Ossetian" => "Ossetian",
"Pali" => "Pali",
"Panjabi" => "Panjabi",
"Persian" => "Persisch",
"Polish" => "Polisch",
"Portuguese" => "Portugisisch",
"Pushto" => "Paschtunisch",
"Quechua" => "Quechua",
"Romanian" => "Rumänisch",
"Romansh" => "Rätoromanisch",
"Rundi" => "Rundi",
"Russian" => "Russisch",
"Samoan" => "Samoan",
"Sango" => "Sango",
"Sanskrit" => "Sanskrit",
"Sardinian" => "Sardinian",
"Scottish Gaelic" => "Schottisch-Gälisch",
"Serbian" => "Serbisch",
"Serbo-Croatian" => "Serbokroatisch",
"Shona" => "Shona",
"Sichuan Yi" => "Sichuan Yi",
"Sindhi" => "Sindhi",
"Sinhala" => "Singhalesisch",
"Slovak" => "Slowakisch",
"Slovenian" => "Slowenisch",
"Somali" => "Somalisch",
"South Ndebele" => "Süd Ndebele",
"Southern Sotho" => "Süd Sotho",
"Spanish" => "Spanisch",
"Sundanese" => "Sundanesisch",
"Swahili" => "Swahili",
"Swati" => "Swati",
"Swedish" => "Schwedisch",
"Tagalog" => "Tagalog",
"Tahitian" => "Tahitian",
"Tajik" => "Tadschikisch",
"Tamil" => "Tamilisch",
"Tatar" => "Tatar",
"Telugu" => "Telugu",
"Thai" => "Thailändisch",
"Tibetan" => "Tibetisch",
"Tigrinya" => "Tigrinya",
"Tonga" => "Tonga",
"Tsonga" => "Tsonga",
"Tswana" => "Tswana",
"Turkish" => "Türkisch",
"Turkmen" => "Turkmenisch",
"Twi" => "Twi",
"Uighur" => "Uighurisch",
"Ukrainian" => "Ukrainisch",
"Urdu" => "Urdu",
"Uzbek" => "Uzbek",
"Venda" => "Venda",
"Vietnamese" => "Vietnamesisch",
"Volapuk" => "Volapuk",
"Walloon" => "Walloon",
"Welsh" => "Walisisch",
"Western Frisian" => "West Friesisch",
"Wolof" => "Wolof",
"Xhosa" => "Xhosa",
"Yiddish" => "Jiddisch",
"Yoruba" => "Yoruba",
"Zhuang" => "Zhuang",
"Zulu" => "Zulu",

'The document has errors and cannot be published.' => 'Das Dokument hat Fehler und kann nicht veröffentlicht werden.',

'unexpected_ending: [_1] [_2]' => 'Statt des Endes von &lt;[_1]&gt; wurde &lt;/[_2]&gt; gefunden.',

'missing_ending: [_1] [_2]' => 'Das Ende von &lt;[_1]&gt; wurde nicht gefunden.',

'Path' => 'Pfad',

'Parent directory' => 'Übergeordnetes Verzeichnis',

'Start of course contents' => 'Anfang des Kursinhaltes',

'End of course contents' => 'Ende des Kursinhaltes',

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

'New user [_1]' => 'Neuer Nutzer [_1]',

'Existing user [_1]' => 'Existierender Nutzer [_1]',

'New or existing user' => 'Neuer oder existierender Nutzer',

'[_1] users selected' => '[_1] Nutzer ausgewählt',

'Manual' => 'Manuell',

'Automatic' => 'Automatisch',

'Modify Enrollment List' => 'Teilnehmerliste ändern',

'Please upload a spreadsheet with enrollment information.' => 'Bitte laden Sie in Spreadsheet mit Teilnehmerinformation hoch.',

'Please identify the columns in your spreadsheet.' => 'Bitte identifizieren Sie die Spalten in Ihrem Spreadsheet.',

'The spreadsheet must at minimum contain a username.' => 'Das Spreadsheet muss mindestens die Benutzerkennung enthalten.',

'Ignore first row' => 'Erste Reihe ignorieren',

'Identify Columns' => 'Spalten zuordnen',

'Finalize' => 'Abschließen',

'Future' => 'Zukünftig',

'Past' => 'Vergangen',

'Welcome!' => 'Willkommen!',

'Welcome' => 'Willkommen',

'Username' => 'Benutzerkennung',

'Username: [_1]' => 'Benutzerkennnung: [_1]',

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

'Skip' => 'Überspringen',

'Continue' => 'Weiter',

'Upload complete.' => 'Hochladen beendet.',

'Changes complete.' => 'Änderungen beendet.', 

'Right click or CTRL-click: menu' => 'Rechte Maustaste oder Strg-klick: Menü',

'Drag and CTRL: copy' => 'Ziehen und Strg: kopieren',

'Done' => 'Fertig',

'Success.' => 'Erfolg.',

'Failure.' => 'Fehlschlag.',

'Language' => 'Sprache',

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

'Canceled.' => 'Abgebrochen.',

'Some required items were not specified.' => 'Einige benötigte Informationen wurden nicht ausgefüllt.',

'The user does not yet exist.' => 'Der Benutzer existiert noch nicht.',

'Some additional information is needed.' => 'Zusätzliche Information wird benötigt.',

'Unrecognized role "[_1]"' => 'Unbekannte Rolle "[_1]"',

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

'Type' => 'Typ',

'Name' => 'Name',

'Publication State' => 'Veröffentlichungsstatus',

'Publication' => 'Veröffentlichung',

'Choose how this file is shared.' => 'Wählen Sie, wie diese Datei verwendet werden kann.',

'Obsolete' => 'Veraltet',

'Published' => 'Veröffentlicht',

'Unpublished' => 'Unveröffentlicht',

'Modified' => 'Verändert',

'Untitled' => 'Ohne Titel',

'Show/Hide Obsolete' => 'Veraltete anzeigen/verbergen',

'File Size' => 'Dateigröße',

'Version' => 'Version',

'First Published' => 'Erstveröffentlichung',

'Last Published' => 'Letzte Veröffentlichung',

'Last Modified' => 'Letzte Änderung',

'Select a course to enter' => 'Wählen Sie einen Kurs aus',

'Select a community to enter' => 'Wählen Sie eine Gemeinschaft aus',

'New Title' => 'Neuer Titel',

'Please enter a new title' => 'Bitte einen neuen Titel eingeben',

'A problem occurred while entering the course.' => 'Bei der Auswahl des Kurses trat ein Problem auf.',

'A problem occurred while entering the community.' => 'Bei der Auswahl der Gemeinschaft trat ein Problem auf.',

'Could not interpret spreadsheet data. Please make sure your file has the proper extension (e.g., ".xls") or try another format.'
=> 'Das Spreadsheet konnte nicht interpretiert werden. Bitte stellen Sie sicher, dass Ihre Datei die richtige Extension (z.B. ".xls") hat, oder versuchen Sie, ein anderes Format zu verwenden.',

'The spreadsheet may have been misinterpreted. Please make sure your file has the proper extension (e.g., ".xls") or try another format.'
=> 'Das Spreadsheet ist möglicherweise nicht richtig interpretiert worden. Bitte stellen Sie sicher, dass Ihre Datei die richtige Extension (z.B. ".xls") hat, oder versuchen Sie, ein anderes Format zu verwenden.',

'Sample Entries' => 'Beispieleinträge',

'Assignment' => 'Zuordnung',

'Last Name, First Name Middle Name' => 'Nachname, Vorname Weitere Vornamen',

'Username and ID Number' => 'Benutzerkennung und Matrikelnummer', 

'Password and ID Number' => 'Passwort und Matrikelnummer',

'Authentication Mode' => 'Authentifizierungsmodus',

'Selections will not override existing account authentication settings.' => 'Die Auswahlen überschreiben nicht existierende Authentifizierungseinstellungen.',

'Override existing account authentication settings' => 'Überschreibe existierende Authentifizierungseinstellungen',

'Selections will not override existing ID numbers.' => 'Die Auswahlen überschreiben nicht existierende Matrikelnummern.',

'Override existing ID numbers' => 'Überschreibe existierende Matrikelnummern',

'Selections will not override existing names.' => 'Die Auswahlen überschreiben nicht existierende Namen.',

'Override existing names' => 'Überschreibe existierende Namen',

'Username and EMail' => 'Benutzerkennung und EMail',

'EMail' => 'EMail',

'-' => '-',

'Cut' => 'Ausschneiden',

'Copy' => 'Kopieren',

'Remove' => 'Entfernen',

'Recover' => 'Wiederherstellen',

'Delete' => 'Löschen',

'Publish' => 'Veröffentlichen',

'Add' => 'Hinzufügen',

'any' => 'alle',

'View' => 'Betrachten',

'Edit' => 'Editieren',

'Grade by instructor' => 'Benoten durch Lehrpersonal',

'Clone (make derivatives)' => 'Clonen (Derivate erzeugen)',

'Use/assign in courses/communities' => 'Verwenden/Aufgeben in Kursen/Gemeinschaften',

'Allowed Activity' => 'Erlaubte Aktivität',

'Course/Community or User' => 'Kurs/Gemeinschaft oder Nutzer',

'Course/Community' => 'Kurs/Gemeinschaft',

'Course entered.' => 'Kurs ausgewählt.',

'Community entered.' => 'Gemeinschaft ausgewählt.',

'Content' => 'Inhalt',

'Grades' => 'Noten',

'Grading' => 'Benotung',

'My Grades' => 'Meine Noten',

'Course' => 'Kurs',

'Community' => 'Gemeinschaft',

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

"Search" => 'Suche',

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
