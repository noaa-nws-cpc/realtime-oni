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
2. The script `$REATIME_ONI/scripts/update-sst-archive.pl` is executed to update the daily SST archive with data for the update date and any dates that had preliminary data or no data on previous runs using the list in `$REALTIME_ONI/work/update-sst-archive.dates`
3. The script `$REATIME_ONI/scripts/update-daily-oni-archive.pl` is executed to calculate the ONI using the 90-day period ending on the update date and to update the daily ONI archive (the file `$DATA_OUT/observations/ocean/long_range/global/oni-avhrr/{yyyy}/oni-90day-ending-{yyyy}{mm}{dd}.txt` is created)
4. The script `$REATIME_ONI/scripts/update-monthly-oni-archive.pl` is executed to calculate the ONI using the most recent three completed months prior to the update date and to update the monthly ONI archive (the file `$DATA_OUT/observations/ocean/long_range/global/oni-avhrr/{yyyy}/oni-{MMM}.txt` is created)
5. If anything failed, the driver script exits with a non-zero value

The driver script can take a date as an argument, and that date will be used as the update date instead of the default (yesterday's date). For example, executing:

`$REALTIME_ONI/drivers/daily/update-archives.csh 20180601`

will update the SST archive for June 1, 2018, and calculate the daily ONI for the 90 days ending June 1, 2018, and the March-May 2018 monthly ONI value.

### Rerunning for past dates

To rerun for a single day, use a date argument with the driver script as described above. If multiple days need to be rerun, a second script is provided, `$REALTIME_ONI/drivers/daily/backfill-oni-archives.csh`, which takes two dates as arguments. The dates are the starting and ending dates of the period to rerun in YYYYMMDD format, and the driver script is run for each date in the period. So for example, executing:

`$REALTIME_ONI/drivers/daily/backfill-oni-archives.csh 20180101 20180601`

will update the SST and ONI archives for every day between January 1, 2018 and June 1, 2018.

**NOTE:** At least 90 days/3 complete months worth of SST data prior to the start date of the backfilling period is required to compute the ONI for the start date. If your backfilling period is for dates subsequent to the date realtime-oni was initially installed on your system, then there should be no issues, because setting up an initial 120-day SST archive is part of the installation process. If you want to backfill for dates prior to the installation date, then you must first backfill the SST archive. To do this, execute the following script:

`$REALTIME_ONI/scripts/initialize-sst-archive.csh YYYYMMDD`

where YYYYMMDD is the starting date of the period you want to backfill.

Updating the SST Archive
---------------

Updating the Daily and Monthly ONI
---------------

Calculating the ONI
---------------
