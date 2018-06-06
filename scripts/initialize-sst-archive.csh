#!/bin/csh
#
#############################################################################################
# File:              initialize-sst-archive.csh
# App Name:          Realtime-ONI
# Functionality:     Set up a list of the last 120 days and run update-sst-archive.pl to
#                    update that list
# Author:            Adam Allgood
# Date created:      2018-06-06
#############################################################################################
#

# --- Get the last date of the 120-day update period ---

# Default date!

set endDate  = `date +%Y%m%d --d 'yesterday'`

# Override the default with a date from the command line if supplied!

if ($#argv >= 1) then
    set endDate  = $1
endif

# Validate the date!

set date_test = `date --d ${upDate}`
echo

if ($?) then
   echo The date $endDate is invalid!
   goto error
else
   echo The date provided: $endDate has been validated!
endif

# --- Get the first date of the 120-day update period ---

set startDate = `date +%Y%m%d --d "${endDate}-120days"`
echo
echo The daily SST archive will be updated from $startDate to $endDate

# --- Set failure flag ---

set failure = 0

# --- Create blank date list file (destroys contents if it exists) ---

rm -f ${REALTIME_ONI}/work/update-sst-archive.dates
touch ${REALTIME_ONI}/work/update-sst-archives.dates

# --- Generate list of dates to update ---

set yyyymmdd = $startDate

while ( ${yyyymmdd} <= ${endDate} )
    echo $yyyymmdd >> $REALTIME_ONI/work/update-sst-archive.dates
    set yyyymmdd = `date +%Y%m%d --d "${yyyymmdd} + 1day"`
end

# --- Run script to generate the archive files ---

perl ${REALTIME_ONI}/scripts/update-sst-archive.pl -l $REALTIME_ONI/work/update-sst-archive.dates -f $REALTIME_ONI/work/update-sst-archive.dates

if ( $status != 0) then
    set failure = 1
endif

# --- End script ---

if ($failure != 0) then
    goto error
endif

exit 0

error:
echo
echo "There was a problem updating the SST archive :("
echo

exit 1

