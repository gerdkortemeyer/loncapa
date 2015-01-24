use strict;

#
# Takes an EXT() call and turns it into a complete function call
#
sub ext_to_func {
   my ($ext)=@_;
   unless ($ext=~/^\s*\&EXT\(/) { return $ext; }
   $ext=~s/^\s*\&EXT\s*\(\s*//;
   $ext=~s/\s*\)\s*$//s;
# Get rid of Perlisms
   $ext=~s/\'//gs;
   $ext=~s/\"//gs;
   $ext=~s/\.+/\./gs;
# Now argument looks like user.resource.resource.$partid.$responseid.submission
   print $ext."\n";
}

open(IN,"ext_calls.txt");
while (my $line=<IN>) {
   &ext_to_func($line);
}
close(IN);

