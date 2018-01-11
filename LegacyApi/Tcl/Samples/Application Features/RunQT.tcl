#
# A simple script to run all the QuickTests in a repository.
#
if {$::argc > 0} {
    set repositoryName [lindex $::argv 0]
} else {
    puts -nonewline "Enter full path of rxf file to run: "
    flush stdout
    gets stdin repositoryName
}

puts "Running QuickTests in repository $repositoryName"

#
# setup path and load IxLoad package
#

source "../setup_simplegui.tcl"

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
set logName "QTRun"
set logger [::IxLoad new ixLogger $logtag 1]
set logEngine [$logger getEngine]
$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
$logEngine setFile $logName 2 256 1

#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]

$testController setResultDir "RESULTS/QTRun"

#
# Load the repository
#
set repository [::IxLoad new ixRepository -name $repositoryName]

proc sleep {ms} {
      after [expr 1000*$ms] set end 1
      vwait end
}
#
# Loop through the tests, running them
#
set qtConfig [$repository getQuickTestConfig]
# Wait until SDM service is initialized
sleep 10
#$qtConfig doWizardApply "QuickTest1"

puts "Starting QuickTest..."
$qtConfig startQuickTest "QuickTest1"

while { [$qtConfig checkTestRunning] } {
    sleep 2
}
puts "QuickTest has finished execution."
set qtStatus [$qtConfig getResult "QuickTest1"]
set qtResultDir [$qtConfig getResultPath "QuickTest1"]
puts "QuickTest run result status: $qtStatus" 
puts "QuickTest result directory: $qtResultDir" 


#-----------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------

$testController releaseConfigWaitFinish
::IxLoad delete $qtConfig
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
