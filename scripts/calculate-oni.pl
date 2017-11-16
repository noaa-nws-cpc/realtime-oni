#!/usr/bin/perl

=pod

=head1 NAME

calculate-oni - Calculate the Oceanic Nino Index from daily SST data and write it to a binary file

=head1 SYNOPSIS

 $REALTIME_ONI/scripts/calculate-oni.pl [-d|-o]
 $REALTIME_ONI/scripts/calculate-oni.pl -h
 $REALTIME_ONI/scripts/calculate-oni.pl -man

 [OPTION]            [DESCRIPTION]                                    [VALUES]

 -dates, -d          Date range for computing the ONI, e.g., 3-months yyyymmdd-yyyymmdd
 -help, -h           Print usage message and exit
 -manual, -man       Display script documentation
 -output, -o         Output filename (override default)               filename

=head1 DESCRIPTION

=head2 PURPOSE

Given a date range, this script:

=over 3

=item * Sets up and calls a separate GrADS script that computes the Oceanic Nino Index

=item * Checks to make sure the GrADS script ran correctly

=item * Checks that the data file was created

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

my $dates      = undef;
my $help       = undef;
my $manual     = undef;
my $outputFile = undef;

GetOptions(
    'dates|d=s'  => \$dates,
    'help|h'     => \$help,
    'manual|man' => \$manual,
    'output|o=s' => \$outputFile,
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

# --- Set start and end dates for ONI calculation ---

unless($dates)        { die "Option --dates not found! Please include it and try again. Exiting"; }
unless($dates =~ /-/) { die "Option --dates=$dates is invalid! Please check the documentation, e.g., run with the -h option, and try again. Exiting"; }
my($startDate,$endDate) = split(/-/,$dates);
my($start,$end);
eval   { $start = CPC::Day->new($startDate); };
if($@) { die "Option --dates=$dates is invalid! $startDate is not a valid date. Please try again. Exiting"; }
eval   { $end   = CPC::Day->new($endDate);   };
if($@) { die "Option --dates=$dates is invalid! $endDate is not a valid date. Please try again. Exiting";   }

# --- Set default output filename if none supplied by user ---

unless($outputFile) {
    my $outputRoot = "$DATA_OUT/observations/ocean/short_range/global/oni-avhrr";
    my $yyyy       = $end->Year;
    my $mm         = sprintf("%02d",$end->Mnum);
    my $outputDir  = "$outputRoot/$yyyy/$mm";
    unless(-d $outputDir) { mkpath($outputDir) or die "Could not create directory $outputDir - $! - exiting"; }
    $outputFile = "$outputDir/oni.bin";
}

# --- Identify the SST dataset to be used ---

my $ctlFile    = "$DATA_OUT/observations/ocean/short_range/global/sst-avhrr/daily-data/ncei-avhrr-only-v2.ctl";
my $var        = 'anom';

# --- Calculate ONI using GrADS script ---

print "Calculating the ONI over the period $start to $end...\n";
chdir("$APP_PATH/scripts") or die "Could not chdir to $APP_PATH/scripts! Reason: $@ - exiting";
my $gradsErr = grads("run calculate-oni.gs $ctlFile $var $start $end $outputFile");

# --- Check for problems ---

if($gradsErr) {
    warn  "\n$gradsErr\n";
    $error = 1;
}
elsif(not -s $outputFile) {
    warn "   ERROR: $outputFile not created!\n";
    $error = 1;
}
else {
    open(CHKONI,'<',$outputFile) or die "\nERROR: Could not open $outputFile for reading - $! - exiting";
    binmode(CHKONI);
    my $chkonistr = join('',<CHKONI>);
    close(CHKONI);
    my $chkoni    = unpack('f*',$chkonistr);
    print "   $outputFile written!\n";
    print "   ONI Value Calculated: $chkoni\n";
}

# --- Cleanup and end script ---

if($error)  { die "\nErrors or Warnings detected - please check the log file for more information\n"; }

exit 0;

