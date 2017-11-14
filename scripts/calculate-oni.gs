*
* calculate-oni.gs - Calculate the Oceanic Nino Index from gridded daily SST anomaly data
*
* Usage:
*   cd ${REALTIME_ONI}/scripts
*   grads -blc "run calculate-oni.gs ctlFile var startDate endDate output"
*
* Arguments:
*   ctlFile    Dataset descriptor filename
*   var        Variable name of the SST anomalies in the dataset
*   startDate  Starting date of the averaging period in ddMONyyyy format
*   endDate    Ending date of the averaging period in ddMONyyyy format
*   output     Filename where ONI value will be written
*

function calconi (args)

* --- Get command line arguments ---

ctlFile=subwrd(args,1)
var=subwrd(args,2)
startDate=subwrd(args,3)
endDate=subwrd(args,4)
output=subwrd(args,5)

* --- Make sure all required arguments are set ---

if(ctlFile='' | var='' | startDate='' | endDate='' | output='')
    say 'ERROR: calculate-oni.gs cannot run - missing arguments'
    'quit'
endif

* --- Print out the arguments for logging ---

say 'ctlFile given:   'ctlFile
say 'var given:       'var
say 'startDate given: 'startDate
say 'endDate given:   'endDate
say 'output given:    'output

* --- Open dataset ---

* --- Set the Nino 3.4 region boundaries ---

* --- Compute the period regional mean ---

* --- Write the result to the output file ---

* --- End GrADS script ---

'reinit'
say 'Script is done, have a nice day!'
'quit'

