# The LearningOnline Network with CAPA - LON-CAPA
# Deal with MongoDB
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
package Apache::lc_mongodb;

use strict;
use MongoDB;
use Apache::lc_logs;

require Exporter;
our @ISA = qw (Exporter);
our @EXPORT = qw();


use vars qw($client $database $usernames);



#
# Initialize the MongoDB client, local host
#
sub init_mongo {
   if ($client=MongoDB::MongoClient->new()) {
      &lognotice("Connected to MongoDB");
   } else {
      &logerror("Could not connect to MongoDB");
   } 
}

BEGIN {
   &init_mongo();
}

1;
__END__
