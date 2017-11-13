#!/usr/bin/perl

=pod

=head1 NAME

update-sst-archive - Download, unzip, and archive NCEI-based SST data

=head1 SYNOPSIS

 $REALTIME_SST/scripts/update-sst-archive.pl [-l|-d]
 $REALTIME_SST/scripts/create_images.pl -h
 $REALTIME_SST/scripts/create_images.pl -man

 [OPTION]            [DESCRIPTION]                                    [VALUES]

 -date, -d           Date forecast data are available (default today) yyyymmdd
 -list, -l           File containing a list of dates to archive       filename
 -failed, -f         Write dates where archiving failed to file       filename
 -help, -h           Print usage message and exit
 -manual, -man       Display script documentation

=head1 DESCRIPTION

=head2 PURPOSE

Given a date, this script:

=over 3

=item * Obtains the associated AVHRR-based SST grid from NCEI and unzips it

=item * Checks the file for non-missing data

=item * Writes the data into a binary archive

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
    die "REALTIME_SST must be set to a valid directory - exiting" unless(CheckENV('REALTIME_SST'));
    $APP_PATH   = $ENV{REALTIME_SST};
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

my $date        = undef;
my $datelist    = undef;
my $failed      = undef;
my $help        = undef;
my $manual      = undef;

GetOptions(
    'date|d=i'       => \$date,
    'list|l=s'       => \$datelist,
    'failed|f=s'     => \$failed,
    'help|h'         => \$help,
    'manual|man'     => \$manual,
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

# --- Create list of dates to archive ---

my @datelist;

# Add date from -date option if supplied!

if($date) {
    my $day;
    eval   { $day = CPC::Day->new($date); };
    if($@) { die "Option --date=$date is invalid! Reason: $@ - exiting"; }
    else   { push(@datelist,$day); }
}

# Add dates from file if -list option supplied!

if($datelist) {

    if(-s $datelist and open(DATELIST,'<',$datelist)) {
        my @datelist = <DATELIST>; chomp(@datelist);
        close(DATELIST);

        foreach my $row (@datelist) {
            my $day;
            eval   { $day = CPC::Day->new($date); };
            if($@) { die "Option --date=$date is invalid! Reason: $@ - exiting"; }
            else   { push(@datelist,$day); }
        }

    }
    else {
        warn "Could not open $datelist for reading - $! - no new dates added";
        $error = 1;
    }

}

# --- Open failed dates file if -failed option supplied ---

if($failed) { open(FAILED,'>',$failed) or die "Could not open $failed for writing - $! - exiting"; }

# --- Create app work directory if needed ---

unless(-d "$APP_PATH/work") { mkpath("$APP_PATH/work"); }

# --- Set output root path ---

my $outputRoot = "$DATA_OUT/observations/ocean/short_range/global/sst-avhrr/daily-data";

# --- Update the archive ---

DAY: foreach my $day (@datelist) {

    # --- Download source file ---

    my $yyyy       = $day->Year;
    my $yyyymmdd   = int($day);
    my $sourceFile = "ftp://eclipse.ncdc.noaa.gov/pub/OI-daily-v2/NetCDF/$yyyy/AVHRR/avhrr-only-v2.$yyyymmdd.nc.gz";
    my $destFile   = "$APP_PATH/work/ncei-avhrr-only-v2.nc.gz";
    if(-s $destFile) { unlink($destFile); }
    my $badresult  = system("wget $sourceFile -O $destFile");

    if($badresult) {

        # --- Attempt to download a preliminary file ---

        $sourceFile = "ftp://eclipse.ncdc.noaa.gov/pub/OI-daily-v2/NetCDF/$yyyy/AVHRR/avhrr-only-v2.$yyyymmdd\_preliminary.nc.gz";
        $badresult  = system("wget $sourceFile -O $destFile");

        if($badresult) {
            warn "Unable to download AVHRR SST file - will not update archive for $day - logged";
            $error = 1;
            next DAY;
        }
        else {
            warn "WARNING: Downloaded a preliminary AVHRR SST file for $day - logged";
            $error = 1;
        }

    }

    # --- Unzip source file ---

    # --- Use a GrADS script to create the archive file ---

}  # :DAY

# --- Cleanup and end script ---

if($error) { die "An error has occurred - please check the log file for more information - exiting"; }

sub date_dirs {
    my $day  = shift;
    my $yyyy = $day->Year();
    my $mm   = sprintf("%02d",$day->Mnum());
    my $dd   = sprintf("%02d",$day->Mday());
    return join('/',$yyyy,$mm,$dd);
}

exit 0;

