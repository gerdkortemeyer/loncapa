use strict;
use Data::Uniqid qw(luniqid);
use JSON::DWIW;

my $depth=0;

print &perl_to_json(&make_folder());

sub make_folder {


   $depth++;
   my $toc;

   for (my $i=0;$i<=int(rand(30));$i++) {
      if ((int(rand()+0.6)) || ($depth>4)) {
         push(@{$toc},&new_asset(&make_unique_id(),('msu','sfu','ostfalia')[int(rand(2)+0.5)],&make_fake_title()));
      } else {
         push(@{$toc},&new_folder('Chapter '.&make_fake_title()));
         $toc->[-1]->{'content'}=&make_folder();
      }
   }
   $depth--;
   return $toc;
}


sub perl_to_json {
   return JSON::DWIW->new->to_json(@_[0],{ pretty => 1 });
}


sub make_fake_title {
   my @title=();
   for (my $i=0; $i<=2+int(rand(2)); $i++) {
      push(@title,('capacity','electronic','current','resistance','field','energy','fusion')[int(rand(6)+0.5)]);
   }
   return join(' ',@title);
}

sub new_asset {
   my ($resentity,$resdomain,$restitle)=@_;
   return { entity => $resentity, domain => $resdomain, 
            title => $restitle, 
            type => 'asset', 
            active => 1, hidden => 0, 
            id => &long_unique_id() }
}

sub new_folder {
   my ($foldertitle)=@_;
   return { title => $foldertitle, type => 'folder',
            active => 1, hidden => 0, 
            id => &long_unique_id(), 
            content => [] } 
}


sub make_unique_id {
   return &luniqid();
}

sub long_unique_id {
   return &make_unique_id().'_'.$$.'_'.time;
}

