#!/usr/bin/perl
#
# The LearningOnline Network with CAPA
# Connect to R CAS
#
# Copyright Michigan State University Board of Trustees
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

use Expect; 
use IO::Select;
use IO::Socket;
use IO::File;
use Symbol;
use POSIX;
use lib '/home/httpd/lib/perl/';
use LONCAPA::Configuration;
 
use strict;

# global variables
my $PREFORK                = 5;        # number of children to maintain
my $MAX_CLIENTS_PER_CHILD  = 50;       # number of clients each child should process
my $extra_children         = 0;
my %children               = ();       # keys are current child process IDs
my $children               = 0;        # current number of children
my $status;                            # string for current status
my $pidfile;                           # file containg parent process pid
my $port;                              # path to UNIX socket file
my %perlvar;                           # configuration file info
my $lastlog;                           # last string that was logged

use vars qw($PREFORK $MAX_CLIENTS_PER_CHILD %children $children $status
	    $pidfile $port %perlvar $lastlog);
 
# ------------------------------------------------------------ Service routines 
sub REAPER {                        # takes care of dead children 
                                    # and R processes
    $SIG{CHLD} = \&REAPER;
    my $pid = wait;
    if (exists($children{$pid})) {
	$children--;
	delete($children{$pid});
	if ($extra_children) {
	    $extra_children--;
	}
    }    
}
 
sub HUNTSMAN {                      # signal handler for SIGINT
    local($SIG{CHLD}) = 'IGNORE';   # we're going to kill our children
    kill('INT' => keys(%children));
    unlink($pidfile);
    unlink($port);
    &logthis('---- Shutdown ----');
    exit;                           # clean up with dignity
}


 
# --------------------------------------------------------------------- Logging
 
sub logthis {
    my ($message)=@_;
    my $execdir=$perlvar{'lonDaemons'};
    my $fh=IO::File->new(">>$execdir/logs/lonr.log");
    my $now=time;
    my $local=localtime($now);
    $lastlog=$local.': '.$message;
    print $fh "$local ($$): $message\n";
}
 
# -------------------------------------------------------------- Status setting
 
sub status {
    my ($what)=@_;
    my $now=time;
    my $local=localtime($now);
    $status=$local.': '.$what;
    $0='lonr: '.$what.' '.$local;
}
 
# -------------------------------------------------------- Escape Special Chars
 
sub escape {
    my ($str)=@_;
    $str =~ s/(\W)/"%".unpack('H2',$1)/eg;
    return $str;
}
 
# ----------------------------------------------------- Un-Escape Special Chars
 
sub unescape {
    my ($str)=@_;
    $str =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
    return $str;
}
 
# ------------------------ grabs exception and records it to log before exiting
sub catchexception {
    my ($signal)=@_;
    $SIG{QUIT}='DEFAULT';
    $SIG{__DIE__}='DEFAULT';
    chomp($signal);
    &logthis("<font color=\"red\">CRITICAL: "
	     ."ABNORMAL EXIT. Child $$ died through "
	     ."\"$signal\"</font>");
    die("Signal abend");
}


sub child_announce_death {
    $SIG{USR1} = \&child_announce_death;
    if ($extra_children < $PREFORK*10) {
	$extra_children++;
    }
}

# ---------------------------------------------------------------- Main program
# -------------------------------- Set signal handlers to record abnormal exits
 
 
$SIG{'QUIT'}=\&catchexception;
$SIG{__DIE__}=\&catchexception;
$SIG{USR1} = \&child_announce_death;
 
# ---------------------------------- Read loncapa_apache.conf and loncapa.conf
&status("Read loncapa.conf and loncapa_apache.conf");
%perlvar=%{&LONCAPA::Configuration::read_conf('loncapa.conf')};
 
# ----------------------------- Make sure this process is running from user=www
my $wwwid=getpwnam('www');
if ($wwwid!=$<) {
    my $emailto="$perlvar{'lonAdmEMail'},$perlvar{'lonSysEMail'}";
    my $subj="LON: User ID mismatch";
    system("echo 'User ID mismatch.  lonr must be run as user www.' |\
 mailto $emailto -s '$subj' > /dev/null");
    exit 1;
}
 
# --------------------------------------------- Check if other instance running
 
$pidfile="$perlvar{'lonDaemons'}/logs/lonr.pid";
 
if (-e $pidfile) {
    my $lfh=IO::File->new("$pidfile");
    my $pide=<$lfh>;
    chomp($pide);
    if (kill(0 => $pide)) { die "already running"; }
}

# ------------------------------------------------------- Listen to UNIX socket
&status("Opening socket");
 
$port = "$perlvar{'lonSockDir'}/rsock";
 
unlink($port);
 

my $server = IO::Socket::UNIX->new(Local  => $port,
				   Type   => SOCK_STREAM,
				   Listen => 10 );
if (!$server) {
    my $st=120+int(rand(240));

    &logthis("<font color=blue>WARNING: ".
	     "Can't make server socket ($st secs):  .. exiting</font>");

    sleep($st);
    exit;
}
    
 
# ---------------------------------------------------- Fork once and dissociate
 
my $fpid=fork;
exit if $fpid;
die("Couldn't fork: $!") unless defined($fpid);
 
POSIX::setsid() or die "Can't start new session: $!";
 
# ------------------------------------------------------- Write our PID on disk
 
my $execdir=$perlvar{'lonDaemons'};
open(PIDSAVE,">$execdir/logs/lonr.pid");
print PIDSAVE "$$\n";
close(PIDSAVE);
&logthis("<font color='red'>CRITICAL: ---------- Starting ----------</font>");
&status('Starting');
     

# Install signal handlers.
$SIG{CHLD} = \&REAPER;
$SIG{INT}  = $SIG{TERM} = \&HUNTSMAN;
 
# Fork off our children.
for (1 .. $PREFORK) {
    &make_new_child($server);
}
 
# And maintain the population.
while (1) {
    &status('Parent process, sleeping');
    sleep;                          # wait for a signal (i.e., child's death)
    for (my $i = $children; $i < $PREFORK+$extra_children; $i++) {
        &status('Parent process, starting child');
        &make_new_child($server);           # top up the child pool
    }
}
                                                                                
sub make_new_child {
    my ($server) = @_;

    # block signal for fork
    my $sigset = POSIX::SigSet->new(SIGINT);
    sigprocmask(SIG_BLOCK, $sigset)
        or die("Can't block SIGINT for fork: $!\n");
     
    die("fork: $!") unless defined(my $pid = fork);
     
    if ($pid) {
        # Parent records the child's birth and returns.
        sigprocmask(SIG_UNBLOCK, $sigset)
            or die("Can't unblock SIGINT for fork: $!\n");
        $children{$pid} = 1;
        $children++;
        return;
    } else {
        # Child can *not* return from this subroutine.
        
	my $ppid = getppid();
     
        # unblock signals
        sigprocmask(SIG_UNBLOCK, $sigset)
            or die("Can't unblock SIGINT for fork: $!\n");

        &logthis('New process started');

        my $command=Expect->spawn('R --vanilla');
	# soft/hard_close can take awhile and we really
        # don't care we just want it gone
	$SIG{INT} = sub {
	    my $pid = $command->pid();
	    kill('KILL'=>$pid);
	    exit; 
	};

	$command->log_stdout(0);
#	$command->log_file("$execdir/logs/lonr.session.log");

        for (my $i=0; $i < $MAX_CLIENTS_PER_CHILD; $i++) {
            &status('Accepting connections');
            my $client = $server->accept()     or last;
            &sync($command);
            print $command ("library(phpSerialize);\n");
	    &getroutput($command);
            &sync($command);
            my $syntaxerr = 0;
            while (my $cmd=<$client>) {
                &status('Processing command');
                print $command &unescape($cmd);
                my ($reply,$syntaxerr) = &getroutput($command);
                print $client &escape($reply)."\n";
                if ($syntaxerr) {
                    last;
                } elsif ($reply=~/^Error\:/) {
                    &logthis('Died through '.$reply);
		    kill('USR1' => $ppid);
                    $client->close();
                    $command->hard_close();     
                    exit;
                }
	        &sync($command);
                &status('Waiting for commands');
            }
        }

	kill('USR1' => $ppid);
	print $command ("q();\n");
        # tidy up gracefully and finish
	sleep(15);
        $command->soft_close();

        # this exit is VERY important, otherwise the child will become
        # a producer of more and more children, forking yourself into
        # process death.
        exit;
    }
}

{
    my $counter;
    sub sync {
	my ($command)=@_;
	$counter++;
	my $expect=$counter;
	print $command "$expect;\n";
	while (1) {
	    my $output=&getroutput($command);
	    if (($output=~/\Q$expect\E/) || ($output=~/^Error\:/)) {
		return;
	    }
	}
    }
}

sub getroutput {
    my ($command)=@_;
    my $regexp = '>';
    my $syntaxerr=0;
    my $timeout = 20;
    my (undef,$error,$matched,$output) =
	$command->expect($timeout, -re => $regexp);
    if ($matched eq 'Incorrect syntax:') {
	$syntaxerr = 1;
	if (wantarray) {
	    return ($matched,$syntaxerr);
	} else {
	    return $matched;
	}
    }
    if ($error) {
	return 'Error: '.$error;
    }

    my $foundoutput=0;
    my $found_label=0;
    my $realoutput='';
    foreach my $line (split(/\n/,$output)) {
       $line=~s/\s$//gs;
       if ($line=~/^Error\:/) { $syntaxerr=1; next; }
       if (my ($result)=($line=~/^\[?\d+\,*\]?\s*(.*)/)) { $realoutput.=$result."\n"; }
    }
    if (wantarray) {
        return ($realoutput,$syntaxerr);
    } else {
        return $realoutput;
    }
}
