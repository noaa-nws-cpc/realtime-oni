How to Run
===============

Table of Contents
---------------

- [Overview](#overview)
- [Other Documents](#other-documents)
- [Operational Usage](#operational-usage)
- [Updating the SST Archive](#updating-the-sst-archive)
- [Updating the Daily and Monthly ONI](#updating-the-daily-and-monthly-oni)
- [Calculating the ONI](#calculating-the-oni)

Overview
---------------

The realtime-oni application is designed to run via cron in an automated fashion, producing a set of [output files](../README.md#output-data) intended for CPC operations. Should the automated runs fail, either due to an interruption in the availability of the [input data](../README.md#input-data) or a system outage, a utility to rerun the application for the missing days is provided. Beyond this setup, however, each component of the application can be run independently if needed. See [Operational Usage](#operational-usage) to get instructions for running or rerunning the operational realtime-oni cron driver. For further information about the scripts that make up the application, visit the subsequent sections in this document.

Other Documents
---------------

- [How to Install](HOW-TO-INSTALL.md)
- [README](../README.md)

Operational Usage
---------------

### Driver script

`$REALTIME_ONI/drivers/daily/update-archives.csh`

This script can be run with no arguments. When executed, the following things happen:

1. Yesterday's date is set as the update date by default
2. The script `$REATIME_ONI/scripts/update-sst-archive.pl` is executed to update the daily SST archive with data for the update date and any dates that had preliminary data or no data on previous runs using the list in `$REALTIME_ONI/work/update-sst-archive.dates`. The 30 days prior to the update date are also scanned for missing data, and any missing dates are also added to the update list.
3. The script `$REATIME_ONI/scripts/update-daily-oni-archive.pl` is executed to calculate the ONI using the 1-, 14-, and 90-day periods ending on the update date and to update the daily ONI archive (the files `$DATA_OUT/observations/ocean/long_range/global/oni-avhrr/{yyyy}/oni-{n}day-ending-{yyyy}{mm}{dd}.txt` are created)
4. The script `$REATIME_ONI/scripts/update-monthly-oni-archive.pl` is executed to calculate the ONI using the most recent three completed months prior to the update date and to update the monthly ONI archive (the file `$DATA_OUT/observations/ocean/long_range/global/oni-avhrr/{yyyy}/oni-{MMM}.txt` is created)
5. If anything failed, the driver script exits with a non-zero value

The driver script can take a date as an argument, and that date will be used as the update date instead of the default (yesterday's date). For example, executing:

`$REALTIME_ONI/drivers/daily/update-archives.csh 20180601`

will update the SST archive for June 1, 2018, and calculate the daily ONI for the 1-, 14-, and 90-days ending June 1, 2018, and the March-May 2018 monthly ONI value.

### Rerunning for past dates

To rerun for a single day, use a date argument with the driver script as described above. If multiple days need to be rerun, a second script is provided, `$REALTIME_ONI/drivers/daily/backfill-oni-archives.csh`, which takes two dates as arguments. The dates are the starting and ending dates of the period to rerun in YYYYMMDD format, and the driver script is run for each date in the period. So for example, executing:

`$REALTIME_ONI/drivers/daily/backfill-oni-archives.csh 20180101 20180601`

will update the SST and ONI archives for every day between January 1, 2018 and June 1, 2018.

**NOTE:** At least 90 days/3 complete months worth of SST data prior to the start date of the backfilling period is required to compute the ONI for the start date. If your backfilling period is for dates subsequent to the date realtime-oni was initially installed on your system, and there has been no downtime on cron, then there should be no issues, because setting up an initial 120-day SST archive is part of the installation process. If you want to backfill for dates prior to the installation date or the cron was down for more than 4 weeks (the SST archiver checks the past 4 weeks in the archive for missing data), then you must first backfill the SST archive. To do this, execute the following script:

`$REALTIME_ONI/scripts/initialize-sst-archive.csh YYYYMMDD`

where YYYYMMDD is the ending date of the 120 day period you want to backfill (e.g., the first day for which you want to rerun the ONI calculations). If you do this to produce SST data prior to the installation date, you will also need to modify the start date in the TDEF specifier of the GrADS data descriptor file in the SST archive - `$DATA_OUT/observations/ocean/short_range/global/sst-avhrr/daily-data/ncei-avhrr-only-v2.ctl` to match the new start date of your updated archive.

Updating the SST Archive
---------------

The AVHRR-only daily SST archive used as input to compute the ONI is updated and maintained by the driver script (see [Operational Usage](#operational-usage)). The updater script that the driver script calls can be run independently as well, if desired for some reason. This is the script usage:
```
 $REALTIME_ONI/scripts/update-sst-archive.pl [-l|-d]
 $REALTIME_ONI/scripts/update-sst-archive.pl -h
 $REALTIME_ONI/scripts/update-sst-archive.pl -man

 [OPTION]            [DESCRIPTION]                                    [VALUES]

 -date, -d           Date forecast data are available                 yyyymmdd
 -list, -l           File containing a list of dates to archive       filename
 -failed, -f         Write dates where archiving failed to file       filename
 -help, -h           Print usage message and exit
 -manual, -man       Display script documentation
```
Given no arguments, the script will do nothing and exit. The script can take a single date argument via the `-date` option, and will attempt to download and archive the daily SST file for that date. Additionally, a filename containing a list of dates to archive can be supplied via the `-list` option. The script keeps track of dates where no data or only preliminary data were available, and these can be written out to a list file via the `-failed` option. By setting `-list` and `failed` to the same file, a running list of what needs to be updated after each run of the script can be maintained. This is how the script is used in the operational driver.

Updating the Daily and Monthly ONI Archives
---------------

The daily (1-, 14-, and 90-day) and monthly (3-calendar month) ONI values are calculated and archived by the driver script (see [Operational Usage](#operational-usage)). The updater scripts that the driver script calls can be run independently as well, if desired for some reason. The usage statements for each script are:
```
Usage:
     $REALTIME_ONI/scripts/update-daily-oni-archive.pl [-d|w]
     $REALTIME_ONI/scripts/update-daily-oni-archive.pl -h
     $REALTIME_ONI/scripts/update-daily-oni-archive.pl -man

     [OPTION]            [DESCRIPTION]                                    [VALUES]

     -date, -d           The last day in the 90-day period                yyyymmdd
     -help, -h           Print usage message and exit
     -manual, -man       Display script documentation
     -windows, -w        Averaging windows to calculate                   comma-delimited positive integers
```
```
Usage:
     $REALTIME_ONI/scripts/update-monthly-oni-archive.pl [-d]
     $REALTIME_ONI/scripts/update-monthly-oni-archive.pl -h
     $REALTIME_ONI/scripts/update-monthly-oni-archive.pl -man

     [OPTION]            [DESCRIPTION]                                    [VALUES]

     -date, -d           The last month in the season                     yyyymm
     -help, -h           Print usage message and exit
     -manual, -man       Display script documentation
```

For the daily updater, the `-w` option accepts multiple values or a comma-separated list so that indicies over multiple time windows can be produced. Therefore, providing either `-w 1,14,90` or `-w 1 -w 14 -w 90` will tell the script to compute the ONI using a 1-, 14-, and 90-day averaging window.

Calculating the ONI
---------------

To calculate the ONI, both the daily and monthly archive updaters use a script called `$REALTIME_ONI/scripts/calculate-oni.pl`, which uses the [GrADS script](http://cola.gmu.edu/grads/gadoc/script.html) `$REALTIME_ONI/scripts/calculate-oni.gs` to actually compute the index. The GrADS script writes the Niño 3.4 basin average SST for the requested period and the departure from normal (ONI) to an unformatted binary file. The Perl script then read the binary file and writes them back out in ascii format.

The usage statement for the Perl script is:
```
Usage:
     $REALTIME_ONI/scripts/calculate-oni.pl [-d|-o]
     $REALTIME_ONI/scripts/calculate-oni.pl -h
     $REALTIME_ONI/scripts/calculate-oni.pl -man

     [OPTION]            [DESCRIPTION]                                    [VALUES]

     -dates, -d          Date range for computing the ONI, e.g., 3-months yyyymmdd-yyyymmdd
     -help, -h           Print usage message and exit
     -manual, -man       Display script documentation
     -output, -o         Output filename (override default)               filename
```
Note that this script has an option to take a date range. This is how the same script can compute the ONI for multiple time windows. If desired, this script could be run manually for any time range (e.g., if you wanted a 30-day or 120-day ONI). Also, using the `-output` option, the ascii data file can be written anywhere you want. The archive updaters set the `-o` option to the archive files described in the [README](../README.md).
