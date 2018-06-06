# realtime-oni

README
===============

- *App Owner: [Adam Allgood](mailto:adam.allgood@noaa.gov)*  
- *CPC Operational Backup: [Daniel Harnos](mailto:daniel.harnos@noaa.gov)*

Table of Contents
-----------------

- [Overview](#overview)
- [Other Documents](#other-documents)
- [NOAA Disclaimer](#noaa-disclaimer)
- [Global Variables Used](#global-variables-used)
- [Input Data](#input-data)
- [Output Data](#output-data)
- [Process Flow](#process-flow)
- [NOAA Disclaimer](#noaa-disclaimer)

Overview
---------------

This application downloads and archives daily AVHRR-only gridded SST data created by the National Centers for Environmental Prediction (NCEI) and calculates both the daily Oceanic Nino Index (ONI) using the past 90-day SST anomalies and the monthly ONI using the past three calendar months daily anomalies.

Since realtime-oni is intended for use in Climate Prediction Center (CPC) operations, the AVHRR-only SST data download is first attempted through NCEP Central Operations dataflow. If this fails, however, the application then attempts to download the data directly from the public NCEI servers, so realtime-oni can be installed and run outside of CPC as well.

Other Documents
---------------

- [How to Install](docs/HOW-TO-INSTALL.md)
- [How to Run](docs/HOW-TO-RUN.md)
- [Contributing Guidelines](docs/CONTRIBUTING.md)
- [Software License](LICENSE)

Global Variables Used
---------------

- `$REALTIME_ONI` The app location
- `NCO_COM_DATA` The operational NCO dataflow mount
- `DATA_IN` Root path to expected location of input data (e.g., the SST archive)
- `DATA_OUT` Root path to output location

Input Data
---------------

Output Data
---------------

Process Flow
---------------

NOAA Disclaimer
===============

This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is provided on an ‘as is’ basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government.
