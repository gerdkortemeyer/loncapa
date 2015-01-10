#
# Warning: this will produce different IDs every time
#
use strict;
use Data::Uniqid qw(luniqid);
use JSON::DWIW;

print &perl_to_json(&make_toc())."\n";

sub make_toc {


   my $toc;

         push(@{$toc},&new_folder('Mathematical Pre-Course'));
         $toc->[-1]->{'content'}=[
               &new_asset('/msu/PHAfXtFFPjT4zq7hhGL/01_Math_1/msu-prob04.problem.lc','Balloon Surface Area'),
               &new_asset('/msu/PHAfXtFFPjT4zq7hhGL/01_Math_1/msu-prob06.problem.lc','Value of a Variable')
                                 ];
   return $toc;
}


sub perl_to_json {
   return JSON::DWIW->new->to_json(@_[0],{ pretty => 1 });
}

sub new_asset {
   my ($resurl,$restitle)=@_;
   return { url => $resurl,
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

