#!/usr/bin/perl

=pod

=head1 NAME

update-daily-oni-archive - Calculate the ONI over a 90-day period and store data in an archive

=head1 SYNOPSIS

 $REALTIME_ONI/scripts/update-daily-oni-archive.pl [-d]
 $REALTIME_ONI/scripts/update-daily-oni-archive.pl -h
 $REALTIME_ONI/scripts/update-daily-oni-archive.pl -man

 [OPTION]            [DESCRIPTION]                                    [VALUES]

 -date, -d           The last day in the 90-day period                yyyymmdd
 -help, -h           Print usage message and exit
 -manual, -man       Display script documentation
 -windows, -w        Averaging windows to calculate                   comma-delimited positive integers

=head1 DESCRIPTION

=head2 PURPOSE

Given a date, this script:

=over 3

=item * Defines a list of averaging windows ending on the date supplied

=item * Runs calculate-oni.pl to compute the ONI over each period

=item * Writes the resulting values to text files in an archive

=back

=head2 REQUIREMENTS

The following must be installed on the system running this script:

=over 3

=item * GrADS (2.0.2 or above)

=item * Perl CPAN library

=item * CPC Perl5 Library

=back

=head1 AUTHOR

L<Adam Allgood|mailto:Adam.Allgood@noaa.gov>

L<Climate Prediction Center - NOAA/NWS/NCEP|http://www.cpc.ncep.noaa.gov>

This documentation was last updated on: 20JUN2018

=cut

# --- Standard and CPAN Perl packages ---

use strict;
use warnings;
use Getopt::Long;
use File::Basename qw(fileparse basename);
use File::Copy qw(copy move);
use File::Path qw(mkpath);
use Scalar::Util qw(blessed looks_like_number openhandle);
use Pod::Usage;

# --- CPC Perl5 Library packages ---

use CPC::Day;
use CPC::Env qw(CheckENV RemoveSlash);
use CPC::SpawnGrads qw(grads);

# --- Establish script environment ---

my($scriptName,$scriptPath,$scriptSuffix);

BEGIN { ($scriptName,$scriptPath,$scriptSuffix) = fileparse($0, qr/\.[^.]*/); }

my $APP_PATH;
my($DATA_IN,$DATA_OUT);

BEGIN {
    die "REALTIME_ONI must be set to a valid directory - exiting" unless(CheckENV('REALTIME_ONI'));
    $APP_PATH   = $ENV{REALTIME_ONI};
    $APP_PATH   = RemoveSlash($APP_PATH);
    die "DATA_IN must be set to a valid directory - exiting" unless(CheckENV('DATA_IN'));
    $DATA_IN    = $ENV{DATA_IN};
    $DATA_IN    = RemoveSlash($DATA_IN);
    die "DATA_OUT must be set to a valid directory - exiting" unless(CheckENV('DATA_OUT'));
    $DATA_OUT   = $ENV{DATA_OUT};
    $DATA_OUT   = RemoveSlash($DATA_OUT);
}

my $error = 0;

# --- Get the command-line options ---

my $date       = int(CPC::Day->new() - 1);
my $help       = undef;
my $manual     = undef;

GetOptions(
    'date|d=i'   => \$date,
    'help|h'     => \$help,
    'manual|man' => \$manual,
);

# --- Actions for -help or -manual options if invoked ---

if($help) {

    pod2usage( {
        -message => ' ',
        -exitval => 0,
        -verbose => 0,
    } );

}

if($manual) {

    pod2usage( {
        -message => ' ',
        -exitval => 0,
        -verbose => 2,
    } );

}

# --- Define the start and end dates of the season ---

my $end;
eval   { $end = CPC::Day->new($date); };
if($@) { die "Option --date=$date is invalid! Please try again. Exiting"; }
my $start = $end - 89;
my $startInt   = int($start);
my $endInt     = int($end);

# --- Prepare archive ---

my $outputRoot = "$DATA_OUT/observations/ocean/long_range/global/oni-avhrr";
my $yyyy       = $end->Year;
unless(-d "$outputRoot/$yyyy") { mkpath("$outputRoot/$yyyy") or die "Could not create directory $outputRoot/$yyyy - $! - exiting"; }
my $outputFile = "$outputRoot/$yyyy/oni-90day-ending-$endInt.txt";

# --- Execute script to create ONI data ---

print "\n";
if(-s "$APP_PATH/work/update-daily-oni-archive.bin") { unlink("$APP_PATH/work/update-daily-oni-archive.bin"); }
my $badreturn = system("perl $APP_PATH/scripts/calculate-oni.pl -d $startInt-$endInt -o $APP_PATH/work/update-daily-oni-archive.bin");

if($badreturn) {
    warn "   ERROR: ONI calculation failed - see logfile\n";
    $error = 1;
}
else {

    # --- Create archive file ---

    open(BININ,'<',"$APP_PATH/work/update-daily-oni-archive.bin") or die "\nERROR: Could not open $APP_PATH/work/update-daily-oni-archive.bin for reading - $! - exiting";
    binmode(BININ);
    my $resultStr = join('',<BININ>);
    close(BININ);
    my @result    = unpack('f*',$resultStr);
    my $oniVal    = sprintf("%8s",sprintf("%.3f",$result[0]));
    my $sstVal    = sprintf("%8s",sprintf("%.3f",$result[1]));

    open(ARCHIVE,'>',$outputFile) or die "Could not open $outputFile for writing - $! - exiting";
    print ARCHIVE "90-days-ending-$endInt $sstVal $oniVal\n";
    close(ARCHIVE);
    print "   $outputFile written!\n";
}

# --- Cleanup and end script ---

if($error)  { die "\nErrors or Warnings detected - please check the log file for more information\n"; }

exit 0;

