use strict;
use JSON::DWIW;
use Data::Dumper;

my $definitions='';
open(IN,'old_loncapa_tags_clean.json');
while (my $line=<IN>) {
   $definitions.=$line;
}
close(IN);
my ($defs,$error)=JSON::DWIW->new->from_json($definitions);
print Dumper($defs)."\n==\n$error\n";
