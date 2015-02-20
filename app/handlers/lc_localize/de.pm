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

'Incorrect.' => 'Unkorrekt.',

'Correct.' => 'Korrekt',

'Ungraded.' => 'Nicht benotet.',

'Total tries: [_1]' => 'Gesamtversuche: [_1]',

'Counted tries: [_1]' => 'Gezählte Versuche: [_1]',

'All components of the union must be intervals.' =>
'Alle Komponenten einer Vereinigungsmenge müssen Intervalle sein.',

'Cannot calculate [_1] of something with units.' =>
'Kann [_1] nicht mit einer einheitenbelasteten Größe berechnen.',

'Cannot calculate atan2 if second argument is not a quantity.' =>
'Kann den atan2 nicht berechnen wenn das zweite Argument keine Größe ist.',

'Cannot calculate the modulus with respect to something that is not a quantity.' =>
'Kann den Modulo nur bezüglich einer Größe berechnen.',

'Cannot divide by something that is not a quantity.' =>
'Kann nicht durch etwas teilen das keine Größe ist.',

'Cannot form a union if second  member is not an interval union or an interval.' =>
'Kann keine Vereinigung bilden wenn die zweite Kompenente weder ein Interval noch eine Intervalvereinigung ist.',

'Cannot form an intersection if second member is not an interval union or an interval.' =>
'Kann keinen Schnitt bilden wenn die zweite Kompenente weder ein Interval noch eine Intervalvereinigung ist..',

'Cannot multiply with something that is not a quantity, vector, matrix, set, or interval.' =>
'Kann nicht multiplizieren mit etwas was weder Größe, Vektor Matrix, Menge noch Interval ist.',

'Cannot raise to the power of something that is not a number.' =>
'Kann nicht mit etwas potenzieren das keine Nummer ist.',

'Different units are used in the intervals.' =>
'Verschiedene Einheiten in einem Interval genutzt.',

'Division by zero.' =>
'Teilen durch Null.',

"Expected '[_1]'." =>
"Erwartete '[_1]'.",

"Expected '[_1]' at the end." =>
"Erwartete '[_1]' am Ende.",

'Expected something at the end.' =>
'Erwartete etwas am Ende.',

'Expected the end.' =>
'Erwartete das Ende.',

'Factorial of a number smaller than zero.' =>
'Fakultät einer negativen Zahl.',

'Function name expected before a parenthesis.' =>
'Vor den Klammern wurde ein Funktionsname erwartet.',

'Inconsistent number of elements in a matrix.' =>
'Inkonsistente Anzahl von Elementen in einer Matrix.',

'Interval contains: second member is not a quantity.' =>
'Intervalerzeugung: die zweite Grenze ist keine Größe.',

'Interval creation: different units are used for the two endpoints.' =>
'Intervalerzeugung: verschiedene Einheiten in den beiden Grenzen.',

'Interval creation: lower limit greater than upper limit.' =>
'Intervalerzeugung: die untere Grenze ist größer als die obere.',

'Interval intersection: different units are used in the two intervals.' =>
'Intervalschnitt: verschiedene Einheiten in den beiden Intervallen.',

'Interval intersection: second member is not an interval or an interval union.' =>
'Intervalschnitt: die zweite Komponente ist weder ein Interval noch eine Intervalvereinigung.',

'Interval multiplication: second member is not a quantity.' =>
'Intervalmultiplikation: die zweite Komponente ist keine Größe.',

'Interval should have two parameters.' =>
'Intervalle benötigen zwei Parameter.',

'Interval union: different units are used in the two intervals.' =>
'Intervalvereinigung: verschiedene Einheiten in den beiden Intervallen.',

'Interval union: second member is not an interval or an interval union.' =>
'Intervalvereinigung: die zweite Komponente ist weder ein Interval noch eine Intervalvereinigung.',

'Intervals can only be multiplied by quantities.' =>
'Intervalle können nur mit Größen multipliziert werden.',

'Logarithm of zero.' =>
'Logarithmus von Null.',

'Matrix addition: second member is not a matrix.' =>
'Matrizenaddition: die zweite Komponente ist keine Matrix.',

'Matrix addition: the matrices have different sizes.' =>
'Matrizenaddition: die Matrizengrößen stimmen nicht überein.',

'Matrix element-by-element multiplication: second member is not a quantity, vector or matrix.' =>
'Matrizen kompentenweise Multiplikation: die zweite Kompenente ist weder Größe, Vektor noch Matrix.',

'Matrix product: second member is not a vector or a matrix.' =>
'Matrizenprodukt: die zweite Kompenente ist weder ein Vektor noch eine Matrix.',

'Matrix product: the matrices sizes do not match.' =>
'Matrizenprodukt: die Matrizengrößen stimmen nicht überein.',

'Matrix substraction: second member is not a matrix.' =>
'Matrizensubstraktion: die zweite Kompenente ist keine Matrix.',

'Matrix substraction: the matrices have different sizes.' =>
'Matrizensubstraktion: die Matrizen haben verschiedene Größen.',

'Maxima syntax: intervals are not implemented.' =>
'Maxima-Syntax: Intervalle sind nicht implementiert.',

'Missing parameter for function [_1].' =>
'Fehlendes Argument für die Funktion [_1].',

'Name expected before a square bracket.' =>
'Name vor der eckigen Klammer erwartet.',

'Natural logarithm of zero.' =>
'Natürlicher Logarithmus von Null.',

'No information found.' =>
'Keine Information gefunden.',

'Quantity addition: second member is not a quantity.' =>
'Größenaddition: das zweite Argument ist keine Größe.',

'Quantity comparison: second member is not a quantity.' =>
'Größenvergleich: das zweite Argument ist keine Größe.',

'Quantity greater or equal: second member is not a quantity.' =>
'Größen größer oder gleich: das zweite Argument ist keine Größe.',

'Quantity greater than: second member is not a quantity.' =>
'Größen größer als: das zweite Argument ist keine Größe.',

'Quantity smaller or equal: second member is not a quantity.' =>
'Größen kleiner oder gleich: das zweite Argument ist keine Größe.',

'Quantity smaller than: second member is not a quantity.' =>
'Größen kleiner als: das zweite Argument ist keine Größe.',

'Quantity substraction: second member is not a quantity.' =>
'Größensubtraktion: das zweite Argument ist keine Größe.',

'Second member of an interval is not a quantity.' =>
'Die zweite Grenze eines Intervals ist keine Größe.',

'Set intersection: second member is not a set.' =>
'Schnittmenge: das zweite Argument ist keine Menge.',

'Set multiplication: second member is not a quantity.' =>
'Multiplikation mit einer Menge: das zweite Argument ist keine Größe.',

'Set union: second member is not a set.' =>
'Vereinigungsmenge: das zweite Argument ist keine Menge.',

'Subscript cannot be evaluated: [_1].' =>
'Subskript kann nicht ausgewertet werden: [_1].',

'Syntax error in number exponent.' =>
'Syntaktischer Fehler im Exponenten einer Zahl.',

'Syntax error in number.' =>
'Syntaktischer Fehler in Zahl.',

"The [_1] function is not implemented for this type." =>
"Die Funktion [_1] ist für diesen Typ nicht implementiert.",

"The [_1] operator is not implemented for this type." =>
"Der Operator [_1] ist für diesen Typ nicht implementiert.",

"Unexpected operator '[_1]'." =>
"Unerwarteter Operator '[_1]'",

'Unit not found: [_1]' =>
'Einheit nicht gefunden: [_1]',

'Units [_1] do not match.' =>
'Einheiten [_1] passen nicht zueinander.',

'Unknown function: [_1].' =>
'Unbekannte Funktion: [_1].',

'Unknown node type: [_1].' =>
'Unbekannter Knotentyp: [_1].',

'Unknown operator: [_1].' =>
'Unbekannter operator: [_1].',

'Unrecognized operator.' =>
'Unerkannter Operator.',

'Variable has undefined value: [_1].' =>
'Variable hat nichtdefinierten Wert: [_1].',

'Vector addition: second member is not a vector.' =>
'Vektoraddition: das zweite Argument ist kein Vektor.',

'Vector addition: the vectors have different sizes.' =>
'Vektoraddition: die Vektoren haben verschiedenen Komponentenzahlen.',

'Vektor dot product: second member is not a vector.' =>
'Vektorskalarprodukt: das zweite Argument ist kein Vektor.',

'Vector dot product: the vectors have different sizes.' =>
'Vektorskalarprodukt: die Vektoren haben verschiedene Komponentenzahlen.',

'Vector element-by-element multiplication: the vectors have different sizes.' =>
'Kompententweise Vektormultiplikation: die Vektoren haben verschiedene Komponentenzahlen.',

'Vector multiplication: second member is not a quantity or a vector.' =>
'Vektormultiplikation: das zweite Argument ist weder eine Zahl noch ein Vektor.',

'Vector power: second member is not a quantity.' =>
'Vektorexponentation: das zweite Argument ist keine Größe.',

'Vector substraction: second member is not a vector.' =>
'Vektorsubstraktion: das zweite Argument ist kein Vektor.',

'Vector substraction: the vectors have different sizes.' =>
'Vektorsubstraktion: die Vektoren haben verschiedene Komponentenzahlen.',

'Wrong interval syntax.' =>
'Falsche Intervalsyntax.',

'Wrong type for function [_1] (should be a set or interval).' =>
'Falscher Typ für Funktion [_1] (sollte Menge oder Interval sein).',

'[_1] cannot work in unit mode.' =>
'[_1] funktioniert nicht in Einheitenmodus.',

'[_1] should have four parameters.' =>
'[_1] sollte vier Parameter haben.',

'[_1] should have two parameters.' =>
'[_1] sollte zwei Parameter haben.',

'[_1]: are you trying to make me loop forever?' =>
'[_1]: soll das eine Endlosschleife sein?',

'[_1]: please use another variable name, i is the imaginary number.' =>
'[_1]: bitte benutzen Sie einen anderen Variablennamen, i ist die imaginäre Einheit.',

'correct' => 'Korrect', 
'incorrect' => 'Inkorrect',
'previously_submitted' => 'Bereits früher eingereicht', 
'numerical_error' => 'Numerischer Fehler', 
'bad_formula' => 'Unbrauchbare Formel', 
'wrong_dimension' => 'Falsche Dimension', 
'wrong_type' => 'Falscher Typ', 
'no_unit_required' => 'Keine Einheit benötigt', 
'unit_missing' => 'Einheit fehlt', 
'wrong_unit_dimension' => 'Falsche Einheitsdimension', 
'wrong_endpoint' => 'Falscher Endpunkt', 
'no_valid_answer' => 'Keine gültige Antwort', 
'no_valid_response' => 'Keine gültige Einreichung', 
'answer_scalar_required' => 'Skalare Antwort benötigt', 
'response_scalar_required' => 'Skalare Einreichung benötigt', 
'answer_array_required' => 'Mehrkomponentige Antwort benötigt', 
'response_array_required' => 'Mehrkomponentige Einreichung benötigt',
'internal_error' => 'Interner Fehler',

'Select the keywords' => 'Wählen Sie die Schlüsselwörter',

'Additional keywords' => 'Zusätzliche Schlüsselwörter',

'Add Keywords' => 'Schlüsselwörter hinzufügen',

'Select the taxonomy categories' => 'Wählen Sie die Taxonomie-Kategorien',

'Select the languages' => 'Wählen Sie die Sprachen aus',

'Add Language' => 'Sprache hinzufügen',

'Add Taxonomy' => 'Taxonomy hinzufügen',

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

'Back' => 'Zurück',

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

'View: [_1]' => 'Betrachten: [_1]',

'Edit' => 'Editieren',

'Edit: [_1]' => 'Editieren: [_1]',

'Grade by instructor' => 'Benoten durch Lehrpersonal',

'Grade: [_1]' => 'Benoten: [_1]',

'Clone (make derivatives)' => 'Clonen (Derivate erzeugen)',

'Clone: [_1]' => 'Clonen: [_1]',

'Use/assign in courses/communities' => 'Verwenden/Aufgeben in Kursen/Gemeinschaften',

'Use: [_1]' => 'Verwenden: [_1]',

'systemwide' => 'systemweit',

'domainwide' => 'domänenweit',

'course' => 'kursweit',

'custom' => 'maßgeschneidert',

'none or customize later' => 'keine oder später maßschneidern',

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

": activate to sort column descending" => ": aktiviere um Spalte absteigend zu ordnen",

'Unzoom' => 'Unzoom',

'Toggle grid' => 'Toggle grid'

);

1;
__END__
