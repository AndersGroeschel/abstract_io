## [0.1.2+6] - 8/3/2020
* now it works for sure

## [0.1.2+5] - 8/3/2020
* made some iteration mistakes that caused errors next time I'll need to make proper tests

## [0.1.2+4] - 8/3/2020
* made mistake with map optimizations that cause an error (now fixed)
* removed some unnessacary casts

## [0.1.2+3] - 8/3/2020
* moved MapIO functionality into seperate file
* added missing exports in abstract_io
* added flag to MapIOInterface to allow it to asyncly load individual entries rather than the whole map at once

## [0.1.2+2] - 8/2/2020
* improved some of the map functionality
* made MapIO functionality reflect the functionality of AbstractIO better

## [0.1.2+1] - 7/30/2020
* added on entry recieved for maps for better async loading

## [0.1.2] - 7/30/2020
* seperated the map functionality from locking

## [0.1.1+2] - 6/20/2020
* made sure example app was working and updated its pubspec.yaml to reflect the latest version

## [0.1.1+1] - 6/20/2020
* fix to translators so that translateWritable can handle a null value
* fix to ValueAccess so that setting value works properly now

## [0.1.1] - 6/20/2020
* added example app
* lots of little tweaks for formating and dart doc
* changes to automatic notifying and saving system in ValueStorage
* updated some code to support IOInterface not throwing errors during requestData 

## [0.1.0] - 6/19/2020
* initial release of Abstract IO

