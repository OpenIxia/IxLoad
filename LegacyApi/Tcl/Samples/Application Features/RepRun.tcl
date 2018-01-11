#
# A simple script to run all the tests in a repository.
#


if {$::argc > 0} {
    set repositoryName [lindex $::argv 0]
} else {
    puts -nonewline "Enter full path of HTTP rxf file to run: "
    flush stdout
    gets stdin repositoryName
}

puts "Running all tests in repository $repositoryName"

#
# setup path and load IxLoad package
#

source "../setup_simple.tcl"

#
# Initialize IxLoad
#

# IxLoad onnect should always be called, even for local scripts
::IxLoad connect $::IxLoadPrivate::SimpleSettings::remoteServer

# once we've connected, make sure we disconnect, even if there's a problem
if [catch {


#
# setup logger
#
set logtag "IxLoad-api"
set logName "reprun"
set logger [::IxLoad new ixLogger $logtag 1]
set logEngine [$logger getEngine]
$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
$logEngine setFile $logName 2 256 1

#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]

$testController setResultDir "RESULTS/reprun"

#
# Load the repository
#
set repository [::IxLoad new ixRepository -name $repositoryName]


#
# Loop through the tests, running them
#
set numTests [$repository testList.indexCount ]

for {set testNo 0} {$testNo < $numTests} {incr testNo} {

  set testName [$repository testList($testNo).cget -name]

  set test [$repository testList.getItem $testName]

  # Start the test
  $testController run $test

  vwait ::ixTestControllerMonitor
  puts $::ixTestControllerMonitor

}


#-----------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------

$testController releaseConfigWaitFinish

::IxLoad delete $repository
::IxLoad delete $testController
::IxLoad delete $logger
::IxLoad delete $logEngine


#-----------------------------------------------------------------------
# Disconnect
#-----------------------------------------------------------------------

}] {

    puts $errorInfo
}

#
#   Disconnect/Release application lock
#
::IxLoad disconnect














