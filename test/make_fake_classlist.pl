use strict;
for (my $i=0;$i<=5000;$i++) {
   my $padding='00000'.$i;
   my ($index)=($padding=~/(\d\d\d\d\d)$/);
   my $section=int(20*rand())+1;
   my $suffix=('Sr.','Jr.','2nd','3rd')[int(4*rand())];
   print "'First$index','Middle$index','Last$index','$suffix','a414$index','pass$index','user$index','$section'\n";
}
