use strict;
use JSON::DWIW;
open(IN,'mime.types');
my $types;
while (my $line=<IN>) {
   chomp($line);
   my ($mime,@extensions)=split(/\s+/,$line);
   unless ($#extensions>-1) { next; }
   my $found='';
   foreach my $ext (@extensions) {
      if (-e '../app/images/fileicons/'.$ext.'.gif' ) {
         $found=$ext;
      }
   }
   foreach my $ext (@extensions) {
      $types->{$ext}->{'mime'}=$mime;
      if ($found) {
         $types->{$ext}->{'icon'}=$found;
      }
   }
}
close(IN);
print JSON::DWIW->to_json($types,{ pretty => 1 });
