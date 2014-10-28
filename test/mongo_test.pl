# The LearningOnline Network with CAPA - LON-CAPA
# Deal with MongoDB

use strict;
use MongoDB;

use Hash::Merge;
use Data::Dumper;

#
my $client;
my $database;
my $metadata;


&dump_metadata('tyxxZY5e7R8lMXvDZhn','msu');
#
# Metadata
# Assets have metadata, which includes searchable information
#

sub dump_metadata {
   my ($entity,$domain)=@_;
   unless ($metadata) { &init_mongo(); }
   my $result=$metadata->find({ entity => $entity, domain => $domain });
   while (my $record=$result->next) {
      print Dumper($record);
      print "Keep?";
      my $input=<STDIN>;
      if ($input=~/n/i) {
         my $result=$metadata->remove({'_id' => $record->{'_id'}});
         print "delete: ".Dumper($result);
      }
   }
}


#
# Initialize the MongoDB client, local host
#
sub init_mongo {
# Open the client. If fail, will likely take down Apache child,
# but that's okay - we need the database to run
   if ($client=MongoDB::MongoClient->new()) {
      print "Connected to MongoDB\n";
   } else {
      print "Could not connect to MongoDB\n";
   }
# Get the LON-CAPA database in MongoDB
   $database=$client->get_database('loncapa');
   $metadata=$database->get_collection('metadata');
}


1;
__END__
