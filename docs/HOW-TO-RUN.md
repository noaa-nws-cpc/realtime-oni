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

### Rerunning for past dates

Updating the SST Archive
---------------

Updating the Daily and Monthly ONI
---------------

Calculating the ONI
---------------
