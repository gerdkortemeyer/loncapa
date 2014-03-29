use strict;

use DateTime;
use DateTime::TimeZone;

print join("\n",DateTime::TimeZone->countries());
print "\n========\n";
print join("\n",DateTime::TimeZone->all_names());
