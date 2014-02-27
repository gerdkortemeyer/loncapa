use strict;
use DBI;
use vars qw($dbh);


sub make_table {
   my $urltable=(<<ENDURLTABLE);
CREATE TABLE URLS
(URL TEXT PRIMARY KEY NOT NULL,
ENTITY TEXT NOT NULL,
HOMESERVER TEXT NOT NULL)
ENDURLTABLE
   my $rv=$dbh->do($urltable);
   if ($rv<0) {
      print $DBI::errstr;
   } else {
      print "Hurray!";
   }
}

#
# Initialize the postgreSQL handle, local host
#
sub init_postgres {
   if ($dbh=DBI->connect('DBI:Pg:dbname=loncapa;host=127.0.0.1;port=5432','loncapa','loncapa')) {
      print "Connected.\n";
   } else {
      print "Not connected, $DBI::errstr\n";
   } 
}

&init_postgres();
&make_table();
