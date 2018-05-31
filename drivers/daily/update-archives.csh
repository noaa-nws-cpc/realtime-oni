#!/bin/csh
#
##########################################################################################
# File:              update_archives.csh
# Process Name:      Realtime-ONI
# Functionality:     Driver script to update daily SST archive and realtime ONI archives
# Author:            Adam Allgood
# Date created:      2017-11-17
##########################################################################################
#

# --- Get the latest date for which SST data are expected to be available ---

# Default date!

set default = 1
set upDate  = `date +%Y%m%d --d 'yesterday'`

# Override the default with a date from the command line if supplied!

if ($#argv >= 1) then
    set default = 0
    set upDate  = $1
endif

# Validate the date!

set date_test = `date --d ${upDate}`
echo

if ($?) then
   echo The date $upDate is invalid!
   goto error
else
   echo The update date: $upDate has been validated!
endif

# --- Set up failure flag ---

set failure = 0

# --- Update the daily SST archive (default date only) ---

if ($default == 1) then
    perl ${REALTIME_ONI}/scripts/update-sst-archive.pl -d ${upDate} -l ${REALTIME_ONI}/work/update-sst-archive.dates -f ${REALTIME_ONI}/work/update-sst-archive.dates

    if ( $status != 0) then
        set failure = 1
    endif
endif

# --- Update the daily (90-day window) ONI ---

perl ${REALTIME_ONI}/scripts/update-daily-oni-archive.pl -d ${upDate}

if ( $status != 0) then
    set failure = 1
endif

# --- Update the monthly (3-month window) ONI ---

set lastMonth = `date +%Y%m --d "${upDate} - 1 month"`
perl ${REALTIME_ONI}/scripts/update-monthly-oni-archive.pl -d ${lastMonth}

if ( $status != 0) then
    set failure = 1
endif

# --- End script ---

if ($failure != 0) then
    goto error
endif

echo
echo All done for ${upDate}!
echo

exit 0

error:
echo
echo "Exiting with driver script errors :("
echo

exit 1

