*
* calculate-oni.gs - Calculate the Oceanic Nino Index and equivalent SST from gridded daily SST data
*
* Usage:
*   cd ${REALTIME_ONI}/scripts
*   grads -blc "run calculate-oni.gs ctlFile startDate endDate output"
*
* Arguments:
*   ctlFile    Dataset descriptor filename
*   startDate  Starting date of the averaging period in ddMONyyyy format
*   endDate    Ending date of the averaging period in ddMONyyyy format
*   output     Filename where ONI and SST values will be written
*

function calconi (args)

* --- Get command line arguments ---

ctlFile=subwrd(args,1)
startDate=subwrd(args,2)
endDate=subwrd(args,3)
output=subwrd(args,4)

* --- Make sure all required arguments are set ---

if(ctlFile='' | startDate='' | endDate='' | output='')
    say 'ERROR: calculate-oni.gs cannot run - missing arguments'
    'quit'
endif

* --- Print out the arguments for logging ---

say 'ctlFile given:   'ctlFile
say 'startDate given: 'startDate
say 'endDate given:   'endDate
say 'output given:    'output

* --- Open dataset ---

'xdfopen 'ctlFile

* --- Compute the Oceanic Nino Index and equivalent SST ---

'define oni=ave(aave(anom,lon=190,lon=240,lat=-5,lat=5),time='startDate',time='endDate')'
'define sst=ave(aave(sst,lon=190,lon=240,lat=-5,lat=5),time='startDate',time='endDate')'

* --- Write the result to the output file ---

'set gxout fwrite'
'set fwrite 'output
'd oni'
'd sst'
'disable fwrite'

* --- End GrADS script ---

'reinit'
say 'Script is done, have a nice day!'
'quit'

