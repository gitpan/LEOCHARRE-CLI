package LEOCHARRE::CLI;
use strict;
use Carp;
use Cwd;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.11 $ =~ /(\d+)/g;

=pod

=head1 NAME

LEOCHARRE::CLI - useful subs for coding cli scripts

=head1 DESCRIPTION

I use this module as base for my CLI scripts.
It standardizes some things

CLI options:

	-d is always debug
	-h is always print help and exit
	-v is always print version and exit
	
=head1 SUBS

=head2 config()

argument is abs paht to YAML conf file
returns conf hash
warns and returns undef if file is not there

=head2 yn()

prompt user for y/n confirmation
will loop until it returs true or false
argument is the question for the user

	yn('are you sure you want to X?') or exit;



=head2 _scriptname()

returns name of script, just the name.

=head2 DEBUG

returns boolean
if script has -d flag, this is on.

=cut


$main::DEBUG = 0;
$main::USAGE = 0;

sub main::DEBUG : lvalue {
   $main::DEBUG;   
}

sub main::debug {
   $main::DEBUG or return 1;
   my $msg = shift;
   
   print STDERR " $0, $msg\n";
   return 1;
}


=head1 USER TYPE SUBS

=head2 force_root()

will force program to exit if user if whoami is not root.

=head2 running_as_root()

returns boolean

=head2 whoami()

returns who you are running as, name
if which('whoami') does not return, returns undef

=head2 get_uid()

argument is username
returns user id number
returns nothing if not a user on this system
this is a way to test if user exists on system

=head2 get_gid()

aregument is group name
returns gid of group
if the argument is not a group on the system, returns undef
with this you can test for the user on system

=cut

sub main::whoami {	
	unless (defined $::WHOAMI){
      require File::Which;
		if (my $wb = File::Which::which('whoami')){
			my $whoami = `$wb`;
			chomp $whoami;
			$::WHOAMI = $whoami;	
		}
		else {
			$::WHOAMI = 0;
			return;	
		}
	}
	$::WHOAMI or return;

	return $::WHOAMI;	
}

sub main::force_root {
	main::running_as_root() or print "$0, only root can use this." and exit;
	return 1;
}

sub main::running_as_root {
   my $whoami = main::whoami() or return 0;
   $whoami eq 'root' or return 0;
   return 1;
}

sub main::get_uid {
  my $name = shift;
  require Linux::usermod;
  my $user = Linux::usermod->new($name);
  my $id = $user->get('uid');
  $id=~/^\d+$/ or return;
  return $id;
}

sub main::get_gid {
  my $name = shift;   
  require Linux::usermod;  
  my $g = Linux::usermod->new($name,1);
  my $id = $g->get('gid');
  $id=~/^\d+$/ or return;
  return $id;
}



=head1 FILE SUBS

=head2 get_mode()

argument is path to file on disk
returns mode in the form 755
if not on disk returns undef

=cut

sub main::get_mode {
   my $abs = shift;
   require File::chmod;
   my $mod = File::chmod::getmod($abs) or return;
   return $mod;
}




=head1 CLI PARAMETERS AND OPTIONS

=cut

sub main::gopts {
	my $opts = shift;
	$opts||='';

	if($opts=~s/v\:?|h\:?|d\:?//sg){
		print STDERR("$0, options changed") if ::DEBUG;
	}

	$opts.='vhd';
	
	my $o = {};	
   
   require Getopt::Std;
	Getopt::Std::getopts($opts, $o); 
	
	if($o->{v}){
		if (defined $::VERSION){
			print $::VERSION;
			exit;
		}		
		print STDERR "$0 has no version\n";
		exit;					
	}

	if ($o->{d}){
		$main::DEBUG = 1;
	}


	if($o->{h}){
		main::man()
	}	
	
	return $o;
}







sub main::man {

   if( defined $main::usage ){
      my $output = $main::usage;
      print STDERR "$output\n";
   }

   elsif( defined &main::usage ){
      my $output = main::usage();
      print STDERR "$output\n";
   }

   else {
   	my $name = main::_scriptname();
      print `man $name`; 
   }

   exit;
}






sub main::_scriptname{
	my $name = $0 or return;
	$name=~s/^.+\///;
	return $name;
}

sub main::argv_aspaths {
	my @argv;
	scalar @ARGV or return;

	for(@ARGV){
		my $abs = Cwd::abs_path($_) or warn("$0, Does not resolve: $_, skipped.") and next;
		-e $abs or  warn("$0, Does not exist: $_, skipped.") and next;
		push @argv, $abs;
	}

	scalar @argv or return;

	return \@argv;
}

sub main::argv_aspaths_strict {
	my @argv;
	scalar @ARGV or return;

	for(@ARGV){
		my $abs = Cwd::abs_path($_) or warn("Does not resolve: $_.") and return;
		-e $abs or  warn("Is not on disk: $_.") and return;
		push @argv, $abs;
	}
	scalar @argv or return;
	return \@argv;
}

sub main::argv_aspaths_loose {
	my @argv;
	scalar @ARGV or return;

	for(@ARGV){
		my $abs = Cwd::abs_path($_) or warn("$0, Does not resolve: $_, skipped.") and next;
		push @argv, $abs;
	}
	scalar @argv or return;
	return \@argv;
}





sub main::yn {
        my $question = shift; $question ||='Your answer? ';
        my $val = undef;

        until (defined $val){
                print "$question (y/n): ";
                $val = <STDIN>;
                chomp $val;
                if ($val eq 'y'){ $val = 1; }
                elsif ($val eq 'n'){ $val = 0;}
                else { $val = undef; }
        }
        return $val;
}







sub main::config {
	my $abs_conf = shift;

	require YAML;
	-f $abs_conf or warn("$0, [$abs_conf] does not exist.") and return;
	my $conf = YAML::LoadFile($abs_conf);
	return $conf;
}




sub main::mktmpdir {
   my $d = '/tmp/tmp_'.time().( int rand(2000000) );

   return undef and warn("$0, $d exists") if -d $d;

   mkdir $d or die("$0, cannot make $d, $!");

   return $d;
}







1;





=head1 PATH ARGUMENTS

You MUST call gopts() BEFORE you call these, if you expect both filename
arguments AND command arguments. Otherwise you will get garble- because
you'll interpret things like -f and -d as file instead of options.

=head2 argv_aspaths()

returns array ref of argument variables treated as paths, they are resolved with Cwd::abs_path()
Any arguments that do not resolve, are skipped with a warning.
if no abs paths are present after checking, returns undef
files are checked for existence
returns undef if no @ARGVS or none of the args are on disk
skips over files not on disk with warnings


=head2 argv_aspaths_strict()

Same as argv_aspaths(), but returns false if 
any of the file arguments are no longer on disk

=head2 argv_aspaths_loose()

Same as argv_aspaths(), but does not check for existence, 
only resolved to abs paths






=head2 man()

will print manual and exit.

This first seeks your script for a global variable $usage,  
then a subroutine named usage()
prints to screen and exits.
otherwise it calls man ./pathtoscript

when you invoke -h via the commandline, this is called automatically.


=head2 mktmpdir()

will make a temp dir in /tmp/tmp_$rand
returns abs path to dir
returns undef and warns if it cant
will not overrite an existing dir, returns undef if already exists (unlikely).

=head1 CLI OPTIONS AND PARAMETERS

This is part of the most useful of subs here.

=head2 gopts()

returns hash of options
uses Getopt::Std, forces v for version, h for help d for debug

To get standard with v and h:

	my $o = gopts(); 

To add options

	my $o = gopts('af:');

Adds a (bool) and f(value), v and h are still enforced.

=head1 SEE ALSO

File::Which
Linux::usermod
Cwd
Getopt::Std

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same 
terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 COPYRIGHT

Copyright (c) 2008 Leo Charre. All rights reserved.

=cut
