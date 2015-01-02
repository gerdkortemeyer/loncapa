# The LearningOnline Network with CAPA - LON-CAPA
# The central XML parser
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
package Apache::lc_asset_xml;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common :http);
use HTML::TokeParser();
use Apache::lc_asset_safeeval();
use Apache::lc_ui_localize;
use Apache::lc_entity_sessions();
use Apache::lc_entity_urls();
use Apache::lc_date_utils();
use Apache::lc_random();

# Import all tag definitions (without "()")
#
use Apache::lc_xml_standard;
use Apache::lc_xml_localize;
use Apache::lc_xml_forms;
use Apache::lc_xml_perl;
use Apache::lc_xml_tex;
use Apache::lc_xml_trees;
use Apache::lc_xml_tables;
use Apache::lc_xml_conditionals;
use Apache::lc_xml_include;
use Apache::lc_xml_gadgets;
use Apache::lc_xml_parameters;

# Problem tags
#
use Apache::xml_problem_tags::problemparts;
use Apache::xml_problem_tags::inputtags;
use Apache::xml_problem_tags::numericalresponse;
use Apache::xml_problem_tags::hints;

use Apache::lc_logs;

sub error {
   my ($stack,$type,$notes)=@_;
   $notes->{'type'}=$type;
   push(@{$stack->{'errors'}},$notes);
}

#
# Go up the stack until argument with name is found
#
sub cascade_attribute {
   my ($name,$stack)=@_;
   if ($stack->{'tags'}) {
      for (my $i=$#{$stack->{'tags'}}; $i>=0; $i--) {
         if (defined($stack->{'tags'}->[$i]->{'args'}->{$name})) {
            return $stack->{'tags'}->[$i]->{'args'}->{$name};
         }
      }
   }
   return undef;
}

#
# Return the attribute $name from an enclosing $tag
#
sub tag_attribute {
   my ($tag,$name,$stack)=@_;
   if ($stack->{'tags'}) {
      for (my $i=$#{$stack->{'tags'}}; $i>=0; $i--) {
         if ($stack->{'tags'}->[$i]->{'name'} eq $tag) {
            return $stack->{'tags'}->[$i]->{'args'}->{$name};
         }
      }
   }
   return undef;
}

#
# Return an attribute from the opening tag
# of one that we are closing
#
sub open_tag_attribute {
   my ($name,$stack)=@_;
   if ($stack->{'tags'}) {
      if ($#{$stack->{'tags'}}>=0) {
         return $stack->{'tags'}->[-1]->{'args'}->{$name};
      }
   }
   return undef;
}

#
# Returns 0 or 1
#
sub open_tag_switch {
   my ($name,$stack)=@_;
   return ((&open_tag_attribute($name,$stack)=~/^(\Q$name\E|y|yes|1|on|true)$/i)?1:0);
}

sub cascade_switch {
   my ($name,$stack)=@_;
   return ((&cascade_attribute($name,$stack)=~/^(\Q$name\E|y|yes|1|on|true)$/i)?1:0);
}

#
# Check if we are inside of tag
#
sub enclosed_in {
   my ($tag,$stack)=@_;
   if ($stack->{'tags'}) {
      for (my $i=$#{$stack->{'tags'}}; $i>=0; $i--) {
         if ($stack->{'tags'}->[$i]->{'name'} eq $tag) { return 1; }
      }
   }
   return undef;
}


#
# Get the depth indicator
#
sub depth_ids {
   my ($stack)=@_;
   my @levels=();
   foreach my $tag (@{$stack->{'tags'}}) {
      push(@levels,$tag->{'args'}->{'id'});
   }
   return @levels;
}

#
# Get a parameter
#
sub cascade_parameter {
   my ($name,$stack)=@_;
   my @levels=&depth_ids($stack);
   while ($#levels>=0) {
       my $indicator=join(':',@levels);
       if ($stack->{'parameters'}->{$indicator}->{$name}->{'value'}) {
          return $stack->{'parameters'}->{$indicator}->{$name}->{'value'};
       }
       if ($stack->{'parameters'}->{$indicator}->{$name}->{'default'}) {
          return $stack->{'parameters'}->{$indicator}->{$name}->{'default'};
       }
       pop(@levels);
   }
}

#
# Get things ready for a response
#
sub init_response {
   my ($id,$stack)=@_;
   $stack->{'response_inputs'}->{$id}=[];
   $stack->{'response_hints'}->{$id}=[];
   $stack->{'response_id'}=$id;
}

#
# Add an input ID to a response
#
sub add_response_input {
   my ($stack)=@_;
   push(@{$stack->{'response_inputs'}->{$stack->{'response_id'}}},${$stack->{'tags'}}[-1]);
}

#
# Collect all inputs made to the response
#
sub collect_response_inputs {
   my ($stack)=@_;
   my $answers=[];
   foreach my $response (@{$stack->{'response_inputs'}->{$stack->{'response_id'}}}) {
       push(@{$answers},$stack->{'content'}->{$response->{'args'}->{'id'}});
   }
   return $answers;
}

#
# Collect all OLD inputs made to the response
#
sub collect_old_response_inputs {
   my ($stack)=@_;
   my $answers=[];
   foreach my $response (@{$stack->{'response_inputs'}->{$stack->{'response_id'}}}) {
      my $inputid=$response->{'args'}->{'id'};
      my $responsedetails=&get_response_details($inputid,$stack);
      my $value=undef;
      if (ref($responsedetails) eq 'ARRAY') {
#FIXME: more than one input field
         if ($#{$responsedetails}>1) {
            $value=$responsedetails->[-2]->{'value'};
         }
      }
      push(@{$answers},$value);
   }
   return $answers;
}

#
# Get all the inputs
#
sub get_response_inputs {
   my ($stack)=@_;
   return $stack->{'response_inputs'};
}

sub add_response_hint {
   my ($stack)=@_;
   push(@{$stack->{'response_hints'}->{$stack->{'response_id'}}},${$stack->{'tags'}}[-1]);
}

sub add_response_hint_parameters {
   my ($stack,@collect)=@_;
   foreach my $name (@collect) {
      $stack->{'response_hints'}->{$stack->{'response_id'}}->[-1]->{'parameters'}->{$name}=
                                                                 &cascade_parameter($name,$stack);
   }
}

sub add_response_hint_attribute {
   my ($stack,$name,$value)=@_;
   $stack->{'response_hints'}->{$stack->{'response_id'}}->[-1]->{'args'}->{$name}=$value;
}

#
# Response details
#
sub add_response_details {
   my ($responseid,$details,$stack)=@_;
   unless (ref($stack->{'response_details'}->{$responseid}) eq 'ARRAY') {
      $stack->{'response_details'}->{$responseid}=[];
   }
   $details->{'date'}=&Apache::lc_date_utils::now2str();
   push(@{$stack->{'response_details'}->{$responseid}},$details);
}

sub get_response_details {
   my ($responseid,$stack)=@_;
   return $stack->{'response_details'}->{$responseid};
}

#
# Add a grade, to be collected by end_part
#
sub add_response_grade {
   my ($id,$status,$message,$previously,$stack)=@_;
   $stack->{'response_grades'}->{$stack->{'context'}->{'asset'}->{'partid'}}->{$id}={ 
                                        'status' => $status, 
                                        'message' => $message,
                                        'previously_submitted' => $previously };
}

#
# Get an individual response
# Gets result of grading the named response if called inside of it
#
sub get_response_grade {
   my ($responsetag,$stack)=@_;
   return $stack->{'response_grades'}->{$stack->{'context'}->{'asset'}->{'partid'}}->{&tag_attribute($responsetag,'id',$stack)};
}

#
# Redirecting
# Needed if within a group, only at the end we know what needs outputting
# 
sub clear_redirect {
   my ($stack)=@_;
   $stack->{'redirecting'}=undef;
}

#
# Will redirect all output into a buffer on the stack under
# under $stack->{'redirecting'}
#
sub set_redirect {
   my ($name,$stack)=@_;
   $stack->{'redirecting'}=$name;
}

#
# Retrieve redirected output
#
sub get_redirected_output {
   my ($name,$stack)=@_;
   return $stack->{'outputbuffer'}->{$name};
}

# Output a piece of text
#
sub process_text {
   my ($p,$safe,$stack,$status,$target,$token)=@_;
   return &Apache::lc_asset_safeeval::texteval($safe,$token->[1]);
}

# Process an HTML tag, call routines if defined
#
sub process_tag {
   my ($type,$tag,$p,$safe,$stack,$status,$target,$token)=@_;
# The output that this script is going to produce
   my $tag_output='';
# The routine that would run any commands for this
# These would be things that should always be run independent of target
# prior to actually rendering anything
   my $cmdtag=$type.'_'.$tag.'_cmd';
# The routine that would produce the output
   my $outtag=$type.'_'.$tag.'_'.$target;
   no strict 'refs';
   if (defined(&$cmdtag)) {
      &{$cmdtag}($safe,$stack);
   }
   if (defined(&$outtag)) {
      $tag_output.=&{$outtag}($p,$safe,$stack,$token);
   } elsif ($target eq 'html') {
# If nothing is defined and we render for html, just output what we got
      $tag_output.=&default_html($token);
   }
   use strict 'refs';
}

# Give out the tag again unchanged, except for the evaluated args
#
sub default_html {
   my ($token)=@_;
   if ($token->[0] eq 'S') {
# Start tag
      my @arguments=keys(%{$token->[2]});
      if ($#arguments<0) {
# No arguments here, just return
         return $token->[-1];
      } else {
# Rebuild this, since arguments may have been evaluated
         return '<'.$token->[1].' '.join(' ',map{$_.'="'.$token->[2]->{$_}.'"'}(@arguments)).'>';
      }
   } else {
# End tag
      return $token->[-1];
   }
}

# Central parser routine
#
sub parser {
   my ($p,$safe,$stack,$status,$target)=@_;
# Output collected here
   my $output='';
# Counter to assign IDs
   my $idcnt=1;
# We are not redirecting
   &clear_redirect($stack);
# Initialize random numbers
   &Apache::lc_random::resetseed();
   &Apache::lc_random::set_context_random_seed(&Apache::lc_random::contextseed($stack->{'context'},0));
# If we are only rendering a subpart of the document
   my $outputid=$stack->{'outputid'};
   my $outputactive=0;
   while (my $token = $p->get_token) {
      my $tmpout='';
      my $outputdone=0;
      if ($token->[0] eq 'T') {
         $tmpout=&process_text($p,$safe,$stack,$status,$target,$token);
      } elsif ($token->[0] eq 'S') {
# A start tag - evaluate the attributes in here
         foreach my $key (keys(%{$token->[2]})) {
# Except some attributes that need late evaluation 
            if ($key eq 'test') { next; }
# Evaluate in safespace
            $token->[2]->{$key}=&Apache::lc_asset_safeeval::argeval($safe,$token->[2]->{$key}); 
         }
# Don't have an ID yet? Make up a temporary one.
         unless ($token->[2]->{'id'}) {
            $token->[2]->{'id'}='TMP_'.$idcnt;
            $idcnt++;
         }
# If we are only rendering part of the document, is this it?
         if ($token->[2]->{'id'} eq $outputid) {
            $outputactive=1;
         }
# - remember for embedded tags and for the end tag
         push(@{$stack->{'tags'}},{ 'name' => $token->[1], 'args' => $token->[2] });
         $tmpout=&process_tag('start',$token->[1],$p,$safe,$stack,$status,$target,$token);
      } elsif ($token->[0] eq 'E') {
# An ending tag
         $tmpout=&process_tag('end',$token->[1],$p,$safe,$stack,$status,$target,$token);
# Unexpected ending tags
         if ($#{$stack->{'tags'}}>=0) {
            if ($stack->{'tags'}->[-1]->{'name'} ne $token->[1]) {
               &error($stack,'unexpected_ending',{'expected' => $stack->{'tags'}->[-1]->{'name'},
                                                  'found'    => $token->[1] });
            }
         } else {
            &error($stack,'unexpected_ending',{'expected' => '-',
                                               'found'    => $token->[-1] });
         }
# If we are only rendering part of the document, see if we are done after this
         if ($stack->{'tags'}->[-1]->{'args'}->{'id'} eq $outputid) {
            $outputdone=1;
         }
# Pop the stack again
         pop(@{$stack->{'tags'}});
      } else {
# Other stuff, remember and keep going
         $tmpout=$token->[-1];
      }
# Only output if within tag of a certain ID, for AJAX
      if ($outputid) {
         if ($outputactive) {
            if ($stack->{'redirecting'}) {
# We are redirecting
               $stack->{'outputbuffer'}->{$stack->{'redirecting'}}.=$tmpout;
            } else {
# Just business as usual
               $output.=$tmpout;
            }
         }
         if ($outputdone) { $outputactive=0; }
      } else {
# We are not asked to selectively output, show everything
         if ($stack->{'redirecting'}) {
# We are redirecting, collecting output under an ID stored in $stack->{'redirecting'}
            $stack->{'outputbuffer'}->{$stack->{'redirecting'}}.=$tmpout;
         } else {
# Just business as usual
            $output.=$tmpout;
         }
      }
   }
# The tag stack should be empty again
   for (my $i=0;$i<=$#{$stack->{'tags'}};$i++) {
      &error($stack,'missing_ending',{'expected' => $stack->{'tags'}->[$i]->{'name'} });
   }
# Done with random numbers
   &Apache::lc_random::popseed();
   return $output;
}


# ==== Render for target
# fn: filename
# targets: pointer to an array of targets that need to be parsed in sequence
# stack: where we store stuff, recycled between targets
# content: anything posted to the page
# context: the user and course, etc.
# outputid: only render inside this ID
#
sub target_render {
   my ($fn,$targets,$stack,$content,$context,$outputid)=@_;
# Clear out and initialize everything
   unless ($stack) {
      $stack={};
   }
# Get parser going (fresh)
   my $p=HTML::TokeParser->new($fn);
   unless ($p) {
      &logerror("Could not inititialize parser for file [$fn]");
      return (undef,undef);
   }
   $p->empty_element_tags(1);
# Get safe space going (fresh)
   my $safe=&Apache::lc_asset_safeeval::init_safe();
# Coming here for the first time? Remember stuff
   if ($content) {
      $stack->{'content'}=$content;
   }
   if ($context) {
      $stack->{'context'}=$context;
   }
   if ($outputid) {
      $stack->{'outputid'}=$outputid;
   }
# Status determination
   my $status;
#FIXME: actually find status
#...
# Render for all requested targets except the last one
   for (my $i=0; $i<$#{$targets}; $i++) {
      &target_render($fn,[$targets->[$i]],$stack);
   }
# The final one actually produces the output
   my $output=&parser($p,$safe,$stack,$status,$targets->[-1]);
   return ($output,$stack);
}

# ==== Main handler
#
sub handler {
   my $r = shift;
   my $fn=$r->filename();
   unless (-e $fn) {
      return HTTP_NOT_FOUND;
   }
   $r->content_type('text/html; charset=utf-8');
   if ($r->uri=~/^\/asset\//) {
      my %content=&Apache::lc_entity_sessions::posted_content();
      my $context={};
      ($context->{'user'}->{'entity'},$context->{'user'}->{'domain'})=
           &Apache::lc_entity_sessions::user_entity_domain();
      ($context->{'course'}->{'entity'},$context->{'course'}->{'domain'})=
           &Apache::lc_entity_sessions::course_entity_domain();
      my $full_url=$r->uri;
      $context->{'asset'}->{'entity'}=&Apache::lc_entity_urls::url_to_entity($full_url);
      ($context->{'asset'}->{'version_type'},
       $context->{'asset'}->{'version_arg'},
       $context->{'asset'}->{'domain'},
       $context->{'asset'}->{'author'},
       $context->{'asset'}->{'url'})=&Apache::lc_entity_urls::split_url($full_url);
      $context->{'asset'}->{'assetid'}=$content{'assetid'};
      $context->{'asset'}->{'problemid'}=$content{'problemid'};
      my $outputid=undef;
      if ($content{'outputid'}=~/\w/) { $outputid=$content{'outputid'}; }
      $r->print((&target_render($fn,['analysis','grade','html'],{},\%content,$context,$outputid))[0]);
   } else {
      $r->print((&target_render($fn,['html'],{}))[0]);
   }
   return OK;
}

1;
__END__
