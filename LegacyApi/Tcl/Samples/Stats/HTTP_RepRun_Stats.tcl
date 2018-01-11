#
# A simple script to run all the tests in a repository with stats.
#
# All the tests must be HTTP tests, because the stats
# specified here are HTTP stats. The script must
# specify stats that are available in the test being run, 
# even if that test comes from a repository.
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
set logName "reprunhttpstats"
set logger [::IxLoad new ixLogger $logtag 1]
set logEngine [$logger getEngine]
$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
$logEngine setFile $logName 2 256 1

#-----------------------------------------------------------------------
# package require the stat collection utilities
#-----------------------------------------------------------------------
package require statCollectorUtils
set scu_version [package require statCollectorUtils]
puts "statCollectorUtils package version = $scu_version"


#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]

$testController setResultDir "RESULTS/reprunsimplehttp"

#-----------------------------------------------------------------------
# Set up stat Collection
#-----------------------------------------------------------------------
set NS statCollectorUtils
set ::test_server_handle [$testController getTestServerHandle]
${NS}::Initialize -testServerHandle $::test_server_handle

#
# Clear any stats that may have been registered previously
#
${NS}::ClearStats

#
# Define the stats we would like to collect
#
set aggregation_type "kSum"
${NS}::AddStat \
    -caption "Watch_Stat_1" \
    -statSourceType "HTTP Client" \
    -statName "HTTP Bytes Sent" \
    -aggregationType $aggregation_type \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_2" \
    -statSourceType "HTTP Client" \
    -statName "HTTP Bytes Received" \
    -aggregationType $aggregation_type \
    -filterList {}

proc ::my_stat_collector_command {args} {
    puts "====================================="
    puts "INCOMING STAT RECORD >>> $args"
    puts "====================================="
}

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

  # Start the stat collector
  ${NS}::StartCollector -command ::my_stat_collector_command

  # Start the test
  $testController run $test

  vwait ::ixTestControllerMonitor
  puts $::ixTestControllerMonitor

  # Stop the collector (running in the tcl event loop)
  ${NS}::StopCollector

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














