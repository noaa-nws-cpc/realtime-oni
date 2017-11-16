#!/usr/bin/perl

=pod

=head1 NAME

update-monthly-oni-archive - Calculate the ONI over a three calendar month period and store data in an archive

=head1 SYNOPSIS

 $REALTIME_ONI/scripts/update-monthly-oni-archive.pl [-d]
 $REALTIME_ONI/scripts/update-monthly-oni-archive.pl -h
 $REALTIME_ONI/scripts/update-monthly-oni-archive.pl -man

 [OPTION]            [DESCRIPTION]                                    [VALUES]

 -date, -d           The last month in the season                     yyyymm
 -help, -h           Print usage message and exit
 -manual, -man       Display script documentation

=head1 DESCRIPTION

=head2 PURPOSE

Given a month, this script:

=over 3

=item * Defines a 3-month season including the month and the two prior months

=item * Runs calculate-oni.pl to compute the ONI over the season

=item * Writes the resulting value to a text file in an archive

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

This documentation was last updated on: 08NOV2017

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
use CPC::Month;
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

my $date       = int(CPC::Month->new() - 1);
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

my $endMonth;
eval   { $endMonth = CPC::Month->new($date); };
if($@) { die "Option --date=$date is invalid! Please try again. Exiting"; }
my $startMonth = $endMonth - 2;
my $midMonth   = $endMonth - 1;
my $start      = CPC::Day->new(100*int($startMonth)+1);
my $end        = $endMonth->Length;
my $startInt   = int($start);
my $endInt     = int($end);

# --- Prepare archive ---

my $outputRoot = "$DATA_OUT/observations/ocean/long_range/global/oni-avhrr";
my $yyyy       = $midMonth->Year;
unless(-d "$outputRoot/$yyyy") { mkpath("$outputRoot/$yyyy") or die "Could not create directory $outputRoot/$yyyy - $! - exiting"; }
my $season     = substr($startMonth->Name,0,1).substr($midMonth->Name,0,1).substr($endMonth->Name,0,1);
my $outputFile = "$outputRoot/$yyyy/$season.txt";

# --- Execute script to create ONI data ---

print "Archiving ONI data for $season $yyyy...\n";
if(-s "$APP_PATH/work/update-monthly-oni-archive.bin") { unlink("$APP_PATH/work/update-monthly-oni-archive.bin"); }
my $badreturn = system("perl $APP_PATH/scripts/calculate-oni.pl -d $startInt-$endInt -o $APP_PATH/work/update-monthly-oni-archive.bin");

if($badreturn) {
    warn "   ERROR: ONI calculation failed - see logfile\n";
    $error = 1;
}
else {

    # --- Create archive file ---

    open(BININ,'<',"$APP_PATH/work/update-monthly-oni-archive.bin") or die "\nERROR: Could not open $APP_PATH/work/update-monthly-oni-archive.bin for reading - $! - exiting";
    binmode(BININ);
    my $resultStr = join('',<BININ>);
    close(BININ);
    my @result    = unpack('f*',$resultStr);
    my $oniVal    = $result[0];
    my $sstVal    = $result[1];

    open(ARCHIVE,'>',$outputFile) or die "Could not open $outputFile for writing - $! - exiting";
    print ARCHIVE "$season $yyyy $oniVal $sstVal\n";
    close(ARCHIVE);
    print "   $outputFile written!\n";
}

# --- Cleanup and end script ---

if($error)  { die "\nErrors or Warnings detected - please check the log file for more information\n"; }

exit 0;

