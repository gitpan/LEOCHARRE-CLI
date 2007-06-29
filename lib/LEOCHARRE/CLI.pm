package LEOCHARRE::CLI;
use strict;
use Carp;
use Cwd;
use Getopt::Std;
use File::Which 'which';
our $VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;
$main::DEBUG=0;

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

=head2 force_root()

will force program to exit if user if whoami is not root.

=head2 _scriptname()

returns name of script, just the name.

=head2 DEBUG

returns boolean
if script has -d flag, this is on.

=cut

sub main::DEBUG {
	my $val = shift;
	if (defined $val){
		$main::DEBUG = $val;
	}	
	return $main::DEBUG;
}






sub main::whoami {
	
	unless (defined $::WHOAMI){
		if (my $wb = which('whoami')){
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

=head2 whoami()

returns who you are running as, name
if which('whoami') does not return, returns undef

=cut



sub main::force_root {
	( whoami() and whoami() eq 'root') or print "$0, only root can use this." and exit;
	return 1;
}

sub main::gopts {
	my $opts = shift;
	$opts||='';

	if($opts=~s/v\:?|h\:?|d\:?//sg){
		print STDERR("$0, options changed") if ::DEBUG;
	}

	$opts.='vhd';
	
	my $o = {};	
	
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
		$::DEBUG = 1;
	}


	if($o->{h}){
		main::man()
	}	
	
	return $o;
}

sub main::man {
	my $name = main::_scriptname();
   print `man $name` and exit; 
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


1;





=head1 PATH ARGUMENTS

=head2 argv_aspaths()

returns array ref of argument variables treated as paths, they are resolved with Cwd::abs_path()
Any arguments that do not resolve, are skipped with a warning.
if no abs paths are present after checking, returns undef
files are checked for existence
returns undef if no @ARGVS or none of the args are on disk
skips over files not on disk with warnings


=head2 argv_aspaths_strict()

Same as argv_aspaths(), but returns false if any of the file arguments are no longer on disk

=head2 argv_aspaths_loose()

Same as argv_aspaths(), but does not check for existence, only resolved to abs paths






=head2 man()

will print manual and exit.


=head1 CLI OPTIONS AND PARAMETERS

=head2 gopts()

returns hash of options
uses Getopt::Std, forces v for version, h for help d for debug

To get standard with v and h:

	my $o = gopts(); 

To add options

	my $o = gopts('af:');

Adds a (bool) and f(value), v and h are still enforced.

=head1 OTHER IMPORTED SUBS

File::Which 'which'
Cwd



=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 COPYRIGHT

Copyright (c) 2007 Leo Charre. All rights reserved.

=cut
