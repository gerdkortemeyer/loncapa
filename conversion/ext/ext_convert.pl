use strict;

#
# Takes an EXT() call and turns it into a complete function call
#
sub ext_to_func {
   my ($ext)=@_;
   my $error="'*** ERROR ***'";
# This should not hve been called
   unless ($ext=~/^\s*\&EXT\(/) { return $ext; }
# We cannot deal with calls outside the problem
   if ($ext=~/\,/) { return $ext; }
   $ext=~s/^\s*\&EXT\s*\(\s*//;
   $ext=~s/\s*\)\s*$//s;
# Get rid of Perlisms
   $ext=~s/\'//gs;
   $ext=~s/\"//gs;
   $ext=~s/\.+/\./gs;
# Current part is default
   $ext=~s/\$external\:\:part//gs;
   $error.=' ('.$ext.')';
# Now argument looks like user.resource.resource.$partid.$responseid.submission
   my @comp=split(/\./,$ext);
   if ($comp[0] eq 'environment') {
      if ($comp[1] eq 'firstname') {
         return '&firstname()';
      } elsif ($comp[1] eq 'middlename') {
         return '&middlename()';
      } elsif ($comp[1] eq 'lastname') {
         return '&lastname()';
      } elsif ($comp[1] eq 'generation') {
         return '&suffix()';
      } elsif ($comp[1] eq 'id') {
         return '&student_number()';
      } elsif ($comp[1] eq 'nickname') {
         return '&nickname()';
      } elsif ($comp[1] eq 'screenname') {
         return '&screenname()';
      } elsif ($comp[1] eq 'picture') {
         return '0';
      } elsif ($comp[1] eq 'permanentemail') {
         return '&permanent_email()';
      } elsif ($comp[1] eq 'critnotification') {
         return '0';
      } elsif ($comp[1] eq 'notification') {
         return '0';
      } else {
         return $error;
      }
   } elsif ($comp[0] eq 'user') {
      if ($comp[1] eq 'resource') {
         my $sub=undef;
         unless ($comp[2] eq 'resource') {
            ($sub)=($comp[2]=~/^(\d+)\:/);
         }
         my $args='';
         if ($sub) {
            $args='"'.$comp[3].'","'.$comp[4].'","'.$sub.'"';
         } elsif ($comp[4]) {
            $args='"'.$comp[3].'","'.$comp[4].'"';
         } elsif ($comp[3]) {
            $args='"'.$comp[3].'"';
         }
         if ($comp[-1] eq 'submission') {
            return '&submission('.$args.')';
         } elsif ($comp[-1] eq 'award') {
            if ($comp[-2]) {
               return '&awarddetail("'.$comp[-2].'")';
            } else {
               return '&awarddetail()';
            }
         } elsif ($comp[-1] eq 'awarded') {
            if ($comp[-2]) {
               return '&awarded("'.$comp[-2].'")';
            } else {
               return '&awarded()';
            }
         } elsif ($comp[-1] eq 'awarddetail') {
            return '&awarddetail('.$args.')';
         } elsif ($comp[-1] eq 'tries') {
            if ($comp[-2]) {
               return '&tries("'.$comp[-2].'")';
            } else {
               return '&tries()';
            }
         } elsif ($comp[-1] eq 'solved') {
            if ($comp[-2]) {
               return '&solved("'.$comp[-2].'")';
            } else {
               return '&solved()';
            }
         } elsif ($comp[-1] eq 'title') {
            return '&title();';
         } else {
            return $error;
         }
      } elsif ($comp[1] eq 'environment') {
         if ($comp[2] eq 'lastname') {
            return '&lastname()';
         } elsif ($comp[2] eq 'firstname') {
            return '&firstname()';
         } elsif ($comp[2] eq 'remotenavmap') {
            return '0';
         } elsif ($comp[2] eq 'clickers') {
            return '&clickers()';
         } else {
            return $error;
         }
      } elsif ($comp[1] eq 'course') {
         if (($comp[2] eq 'section') || ($comp[2] eq 'sec')) {
            return '&sec()';
         } elsif ($comp[2] eq 'group') {
            return '&group()';
         } else {
            return $error;
         }
      } elsif ($comp[1] eq 'name') {
         return '&username()';
      } elsif ($comp[1] eq 'domain') {
         return '&userdomain()';
      } else {
         return $error;
      }
   } elsif ($comp[0] eq 'query') {
      return '';
   } elsif ($comp[0] eq 'request') {
      if ($comp[1] eq 'filename') {
         return '&request_filename()';
      } elsif ($comp[1] eq 'uri') {
         return '&request_uri()';
      } elsif ($comp[1] eq 'state') {
         return '&request_state()';
      } elsif ($comp[1] eq 'browser') {
         if ($comp[2] eq 'os') {
            return '&browser_os()';
         } elsif ($comp[2] eq 'unicode') {
            return '1';
         } elsif ($comp[2] eq 'mathml') {
            return '0';
         } elsif ($comp[2] eq 'textremote') {
            return '0';
         } elsif ($comp[2] eq 'type') {
            return '&browser_type()';
         } elsif ($comp[2] eq 'version') {
            return '&browser_version()';
         } else {
            return $error;
         }
      } elsif ($comp[1] eq 'host') {
         return '&request_host()';
      } elsif ($comp[1] eq 'role') {
         return '&request_role()';
      } elsif (($comp[1] eq 'course') && ($comp[2] eq 'id')) {
         return '&classid()';
      } elsif (($comp[1] eq 'course') && ($comp[2] eq 'sec')) {
         return '&sec()';
      } else {
         return $error;
      }
   } elsif ($comp[0] eq 'course') {
      if (($comp[1] eq 'description') || ($comp[1] eq 'decription')) {
         return '&class()';
      } elsif ($comp[1] eq 'domain') {
         return '&classdomain()';
      } elsif ($comp[1] eq 'num') {
         return '&classentity()';
      } elsif ($comp[1] eq 'url') {
         return '&classcode()';
      } elsif ($comp[1] eq 'id()') {
         return '&classid()';
      } else {
         return $error;
      }
   } elsif ($comp[0] eq 'resource') {
      if ($comp[-1] eq 'maxtries') {
         if ($comp[1]) {
            return '&maxtries("'.$comp[1].'")';
         } else {
            return '&maxtries()"';
         }
      } elsif ($comp[-1] eq 'weight') {
         if ($comp[1]) {
            return '&weight("'.$comp[1].'")';
         } else {
            return '&weight()"';
         }
      } elsif ($comp[-1] eq 'duedate') {
         if ($comp[1]) {
            return '&due_date_epoch("'.$comp[1].'")';
         } else {
            return '&due_date_epoch()';
         }
      } elsif ($comp[-1] eq 'answerdate') {
         if ($comp[1]) {
            return '&answer_date_epoch("'.$comp[1].'")';
         } else {
            return '&answer_date_epoch()"';
         }
      } elsif ($comp[-1] eq 'opendate') {
         if ($comp[1]) {
            return '&open_date_epoch("'.$comp[1].'")';
         } else {
            return '&open_date_epoch()"';
         }
      } elsif ($comp[-1] eq 'problemstatus') {
      } elsif ($comp[-1] eq 'scoreformat') {
         if ($comp[1]) {
            return '&scoreformat("'.$comp[1].'")';
         } else {
            return '&scoreformat()"';
         }
      } elsif ($comp[-1] eq 'title') {
         return '&title();';
      } elsif ($comp[-1] eq 'subject') {
      } elsif ($comp[-1] eq 'keywords') {
      } elsif ($comp[-1] eq 'author') {
      } else {
# Anything else would actually be a parameter
         if ($comp[1]) {
            return '&parameter_setting("'.$comp[2].'","'.$comp[1].'")';
         } else {
            return '&parameter_setting("'.$comp[2].'")';
         }
      }
   } elsif ($comp[0] eq 'system') {
      return '';
   } elsif ($comp[0]=~/^parameter/) {
      my (undef,$partid,$which)=split(/\_/,$comp[0]);
      if ($partid) {
         return '&parameter_setting("'.$which.'"."'.$partid.'")';
      } else {
         return '&parameter_setting("'.$which.'")';
      }
   } else {
      return $error;
   }
}

# Takes external::XX and converts to a function
#
sub external_to_func {
   my ($variable)=@_;
# this should not have been called
   unless ($variable=~/^external\:\:/) { return $variable; }
   if ($variable eq '$external::part') {
      return '&partid()';
   } elsif ($variable eq '$external::randomseed') {
      return '&seed()';
   }
}

open(IN,"ext_calls.txt");
while (my $line=<IN>) {
   chomp($line);
   print $line." => ".&ext_to_func($line)."\n";
}
close(IN);

