#!/usr/bin/perl

=pod

=head1 NAME

update-sst-archive - Download, unzip, and archive NCEI-based SST data

=head1 SYNOPSIS

 $REALTIME_ONI/scripts/update-sst-archive.pl [-l|-d]
 $REALTIME_ONI/scripts/update-sst-archive.pl -h
 $REALTIME_ONI/scripts/update-sst-archive.pl -man

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
my($NCO_COM_DATA,$DATA_OUT);

BEGIN {
    die "REALTIME_ONI must be set to a valid directory - exiting" unless(CheckENV('REALTIME_ONI'));
    $APP_PATH     = $ENV{REALTIME_ONI};
    $APP_PATH     = RemoveSlash($APP_PATH);
    die "NCO_COM_DATA must be set to a valid directory - exiting" unless(CheckENV('NCO_COM_DATA'));
    $NCO_COM_DATA = $ENV{NCO_COM_DATA};
    $NCO_COM_DATA = RemoveSlash($NCO_COM_DATA);
    die "DATA_OUT must be set to a valid directory - exiting" unless(CheckENV('DATA_OUT'));
    $DATA_OUT     = $ENV{DATA_OUT};
    $DATA_OUT     = RemoveSlash($DATA_OUT);
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

my @daylist;

# Add date from -date option if supplied!

if($date) {
    my $day;
    eval   { $day = CPC::Day->new($date); };
    if($@) { die "Option --date=$date is invalid! Reason: $@ - exiting"; }
    else   { push(@daylist,$day); }
}

# Add dates from file if -list option supplied!

if($datelist) {

    if(-s $datelist and open(DATELIST,'<',$datelist)) {
        my @datelist = <DATELIST>; chomp(@datelist);
        close(DATELIST);

        foreach my $row (@datelist) {
            my $day;
            eval   { $day = CPC::Day->new($row); };
            if($@) { die "In $datelist, $row is an invalid date! Reason: $@ - exiting"; }
            else   { push(@daylist,$day); }
        }

    }
    else {
        warn "Could not open $datelist for reading - $! - no new dates added";
        $error = 1;
    }

}

# --- Open failed dates file if -failed option supplied ---

if($failed) { open(FAILED,'>',$failed) or die "Could not open $failed for writing - $! - exiting"; }

# --- Set output root path ---

my $outputRoot = "$DATA_OUT/observations/ocean/short_range/global/sst-avhrr/daily-data";
print "\nOutput root directory: $outputRoot\n\n";

# --- Update the archive ---

DAY: foreach my $day (@daylist) {
    print "Archiving AVHRR SST data for $day...\n";

    # --- Create output directory if needed ---

    my $yyyy       = $day->Year;
    my $mm         = sprintf("%02d",$day->Mnum);
    my $yyyymmdd   = int($day);
    my $outputDir  = join('/',$outputRoot,$yyyy);
    unless(-d $outputDir) { mkpath($outputDir) or die "\nCould not create directory $outputDir - check app permissions on your system - exiting"; }

    # --- Set output filename and delete existing copy if needed ---

    my $destFile   = "$outputDir/ncei-avhrr-only-v2-$yyyymmdd.nc";
    if(-s $destFile) { unlink($destFile); }

    # --- Attempt to copy the source file ---

    my $sourceFile = "$NCO_COM_DATA/observations/satellite/netcdf/avhrr/avhrr-only-v2.$yyyymmdd.nc";

    unless(copy($sourceFile,$destFile)) {
        warn "   WARNING: Unable to download final AVHRR SST file from operational mount - looking for a preliminary version\n";

        # --- If attempt fails, try the preliminary version of the source file ---

        $sourceFile = "$NCO_COM_DATA/observations/satellite/netcdf/avhrr/avhrr-only-v2.$yyyymmdd\_preliminary.nc";

        unless(copy($sourceFile,$destFile)) {
            warn "  WARNING: Unable to download preliminary AVHRR SST file - checking NCEI FTP archives for data\n";

            # --- If nothing was found on the operational mount, attempt to download the source file from the NCEI archives ---

            $sourceFile    = "https://www.ncei.noaa.gov/data/sea-surface-temperature-optimum-interpolation/access/avhrr-only/$yyyy$mm/avhrr-only-v2.$yyyymmdd.nc";
            my $wgetFailed = system("wget $sourceFile -O $destFile >& /dev/null");

            if($wgetFailed) {
                warn "  WARNING: Unable to download final AVHRR SST file from NCEI archives - looking for a preliminary version\n";

                # --- If attempt fails, try the preliminary version of the source file ---

                $sourceFile = "https://www.ncei.noaa.gov/data/sea-surface-temperature-optimum-interpolation/access/avhrr-only/$yyyy$mm/avhrr-only-v2.$yyyymmdd\_preliminary.nc";
                $wgetFailed = system("wget $sourceFile -O $destFile >& /dev/null");

                if($wgetFailed) {

                    # --- Give up time ---

                    warn "   ERROR: Unable to download any AVHRR data for $day - error caught";
                    $error = 1;
                    if($failed) { print FAILED "$yyyymmdd\n"; }
                    next DAY;
                }
                else {
                    warn "   Downloaded a preliminary AVHRR SST file for $day from NCEI archives - archive will need to update once final data are available\n";
                    if($failed) { print FAILED "$yyyymmdd\n"; }
                }

            }
            else { print "  Downloaded a final AVHRR SST file for $day from NCEI archives\n"; }

        }
        else {
            warn "   Downloaded a preliminary AVHRR SST file for $day - archive will need to update once final data are available\n";
            if($failed) { print FAILED "$yyyymmdd\n"; }
        }

    }
    else { print "   Downloaded a final AVHRR SST file for $day\n"; }

    # --- Check that the file actually exists in the output archive ---

    unless(-s $destFile) {
        warn "   ERROR: Archive file not found - check for uncaught errors - error caught";
        $error = 1;
        if($failed) { print FAILED "$yyyymmdd\n"; }
        next DAY;
    }

    print "   AVHRR SST data for $day has been archived!\n";
}  # :DAY

# --- Cleanup and end script ---

if($failed) { close(FAILED); }
if($error)  { die "\nErrors detected - please check the log file for more information\n"; }

exit 0;

