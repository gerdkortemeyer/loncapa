use strict;
use lib '/home/httpd/lib/perl';
use JSON::DWIW();
use Apache::lc_entity_contents();

my $string='';
open(IN,"toc.json");
while (my $line=<IN>) {
   $string.=$line;
}
close(IN);
my $toc=JSON::DWIW->from_json($string);

my $series=&Apache::lc_entity_contents::toc_to_display($toc);
print JSON::DWIW->to_json($series,{ pretty => 1 });

