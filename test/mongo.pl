use strict;
use warnings;
use MongoDB;
use Data::Dumper;

my $client=MongoDB::MongoClient->new();

my $db=$client->get_database('test');

my $users = $db->get_collection( 'users' );

my $id=$users->insert({"name" => "Joe",
        "age" => 52,
        "likes" => [qw/skiing math ponies/]});

print $id."\n";

my $all_users=$users->find;

while (my $user=$all_users->next) {
   print "User: ".$user->{'name'}."\n";
}
