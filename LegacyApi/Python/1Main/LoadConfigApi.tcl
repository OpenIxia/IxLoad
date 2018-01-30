o# Description
#
#    At the current moment, Ixia doesn't support Python3.
#    For those who are using Python3 will need to interact with Ixia's
#    TCL APIs using Python's TKinter in their Python script.
#    This is a temporary solution until Ixia supports Python3.
# 
#    This API library file is used by LoadConfigApiBridge.py.
#    This could not be used independently because these APIs uses
#    variables set in the LoadConfigApiBridge.py Python script.
#  
# 
# Written by: Hubert Gee
# Date: July 26, 2016
# Test with IxLoad 8.10.30.4

proc GetTime {} {
    return [clock format [clock seconds] -format "%H%M%S"]
}
     
proc IxL_GetIxLoadFiles { fromWindowsDir filesToGet localFileName} {
    foreach currentFile $filesToGet {
	puts "IxL_GetCsvStatFiles:  $currentFile ..."
	catch {::IxLoad retrieveFileCopy $fromWindowsDir\\$currentFile $localFileName} errMsg
	if {$errMsg != ""} {
	    puts "\nError: Copying file from Windows PC: $currentFile\n"
	}
    }
}

proc IxL_StatCollectorCommand {args} {
    # statcollectorutils {timestamp 140000 stats {{kInt 0} {kInt 1872} {kInt 0} {kInt 0}}}
    set stats [lindex [lindex $args 1] 3]
    set timestamp [lindex [lindex $args 1] 1]

    puts "============================================"
    puts "Incoming stats: Time interval: $timestamp"
    puts "============================================"

    # This is to collect all the stats for csv file logging
    set eachRowStatsForCsv {}

    for {set index 0} {$index <= [llength $stats]} {incr index} {
	# { "HTTP Server" "TCP Connections Established" "kSum" }
	set sourceType [lindex [lindex $::statList $index] 0]
	set statName   [lindex [lindex $::statList $index] 1]
	set statNumber      [lindex [lindex $stats $index] 1]

	if {$sourceType != "" || $statName != ""} {	    
	    puts "$sourceType: $statName: $statNumber"
	    if {$eachRowStatsForCsv == ""} {
		append eachRowStatsForCsv $statNumber
	    } else {
		append eachRowStatsForCsv ",$statNumber"
	    }
	}
    }

    if {[info exists ::csvFilePathAndName]} {
	exec echo $eachRowStatsForCsv >> $::csvFilePathAndName
    }
}

proc IxL_CreateCsvResultFile {} {
    # Create a csv result file on local Linux machine
    set topCsvColumnLine [join $::statList ,]
    if {[info exists ::csvFilePathAndName]} {
	puts "\nIxL_CreateCsvResultFile: $::csvFilePathAndName\n"
	exec echo $topCsvColumnLine > $::csvFilePathAndName
    }
}

proc IxL_GetIxLoadFiles { fromWindowsDir filesToGet localFileName} {
    foreach currentFile $filesToGet {
	puts "IxL_GetCsvStatFiles:  $currentFile ..."
	catch {::IxLoad retrieveFileCopy $fromWindowsDir\\$currentFile $localFileName} errMsg
	if {$errMsg != ""} {
	    puts "\nError: Copying file from Windows PC: $currentFile\n"
	}
    }
}

proc ReassignPorts { test repository portsToReassign } { 
    set chassisChain [$repository cget -chassisChain]
    set chassisList [$chassisChain getChassisNames]

    # communityTypes: clientCommunityList serverCommunityList    
    set communityTypes [list clientCommunityList serverCommunityList]
    
    set startListIdx -1
    set endListIdx -1
    set portsToSet {}
    
    foreach communityType $communityTypes {
	set numCommunities [$test ${communityType}.indexCount]
	puts "\nReassignPorts numCommunities: $numCommunities"

	set comunityDestinations {}
	
	# Run through the list of available communities (networks)
	for {set i 0} {$i < $numCommunities} {incr i} {
	    set networkObj [$test ${communityType}($i).cget -network]
	    set currentSourceList [$networkObj cget -portList]
	    set sourceListNum [llength $currentSourceList]
	    
	    # Extract the corresponding target ports 
	    set startListIdx [expr {$endListIdx+1}]
	    set endListIdx [expr { $startListIdx + $sourceListNum - 1 }]		
	    set partialDestinationList [lrange $portsToReassign $startListIdx $endListIdx]
	    set formattedDestinations {}
	    
	    if {[llength $partialDestinationList] == 0 && $sourceListNum != 0} {
		puts "\nError: Unable to remap the hardware. Too few ports.\n"
		::IxLoad delete $repository
		::IxLoad disconnect
	    }

	    # Run through the partial list of destinations and format them nicely
	    foreach currentDestination $partialDestinationList {
		set currentDestinationChassis [lindex $currentDestination 0]
		set currentDestinationCard [lindex $currentDestination 1]
		set currentDestinationPort [lindex $currentDestination 2]
		lappend formattedDestinations "\"$currentDestinationChassis;$currentDestinationCard;$currentDestinationPort\""
	    }
	    set comunityDestinations [concat $comunityDestinations \{$formattedDestinations\}]
	}
	set portsToSet [concat $portsToSet $comunityDestinations]
    }

    puts "\nReassigning ports: $portsToSet\n"
    
    if {[catch {$test setPorts $portsToSet}]} { 
	puts "\nError: Could not remap for target $portsToSet.\n"
	::IxLoad delete $repository
	::IxLoad disconnect
    }
}

proc IxL_Main {} {
    package req IxLoadCsv

    if {[catch {
	set connectStatus [::IxLoad connect $::windowsClientIp]
	if {$connectStatus == ""} {
	    puts "\nSuccessfully connected to $::windowsClientIp"
	    # signal action siglist ?command?
	} else {
	    puts "\nFailed to connect to $::windowsClientIp"
	    exit
	}

	#signal trap [list SIGKILL SIGHUP SIGTERM] [::IxLoad disconnect;exit]

	# setup logger
	set logtag "IxLoad-api"

	# This statCollectorUtils package must be loaded AFTER IxLoad connect and aafter set logtag
	package require statCollectorUtils

	# Stats are located at: C:\Program x86\Ixia\IxLoad\6.50EA\TclScripts\remoteScriptingService\RESULTS
	set logName "reprun"
	set logger [::IxLoad new ixLogger $logtag 1]
	set logEngine [$logger getEngine]

	$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
	$logEngine setFile $logName 4 2048 1

	#-----------------------------------------------------------------------
	# Create a test controller bound to the previosuly allocated # chassis chain. 
	# This will eventually run the test we created earlier.
	#-----------------------------------------------------------------------
	# By stating -outputDir = 1, means to enable csv logging
	set testController [::IxLoad new ixTestController -outputDir 1]
	set repository  [::IxLoad new ixRepository -name $::configFile]
	set testName    [$repository testList(0).cget -name]
	set test        [$repository testList.getItem $testName]
	$testController setResultDir $::resultDirectoryOnWindows

	puts "\nTest Controller: $testController"
	puts "\Repository: $repository"
	puts "\Test name: $testName"
	puts "\Test: $test"

	# To capture ctrl-c signal and exit gracefully. This works for Expect.
	#trap  {$testController stopRun;::IxLoad disconnect;exit} SIGINT

	#----- Inserting port remapping begin ------"
	if {[info exists ::portsToReassign]} {
	    ReassignPorts $test $repository $::portsToReassign
	}

	$test config \
	    -csvInterval 2 \
	    -enableForceOwnership true \
	    -enableResetPorts 0 \
	    -statsRequired 1 \
	 
	puts "\nRunning all tests in repository $testName"

	# Get real time stats
	set NS statCollectorUtils

	set test_server_handle [$testController getTestServerHandle]
	${NS}::Initialize -testServerHandle $test_server_handle

	${NS}::ClearStats
	$test clearGridStats

	#global statList
	#set statList [concat $::clientStatList $::serverStatList]

	set count 1
	foreach stat $::statList {
	    set caption         [format "Watch_Stat_%s" $count]
	    set statSourceType  [lindex $stat 0]
	    set statName        [lindex $stat 1]
	    set aggregationType [lindex $stat 2]
	    
	    # StatUtils::AddStat
	    ${NS}::AddStat \
		-caption            $caption \
		-statSourceType     $statSourceType \
		-statName           $statName \
		-aggregationType    $aggregationType \
		-filterList         {}
	    
	    incr count
	}

	IxL_CreateCsvResultFile

	${NS}::StartCollector -command IxL_StatCollectorCommand -interval 2

	# Start the test
	$testController run $test

	vwait ::ixTestControllerMonitor
	puts $::ixTestControllerMonitor

	${NS}::StopCollector

	# Cleanup
	$testController releaseConfigWaitFinish
	
	# No IxLoad platform failures = eventType TEST_STOPPED status OK
	#return $::ixTestControllerMonitor

	::IxLoad delete $repository
	::IxLoad delete $testController
	::IxLoad delete $logger
	::IxLoad delete $logEngine

	if {$::ixTestControllerMonitor == "eventType TEST_STOPPED status OK"} {
	    # This last part is commented out. Enable it only if you need to copy/retrieve
	    # something from the Windows PC to your local Linux machine.
	    # This is just an example to show you how to retrieve files off of the Windows
	    # C: drive.
	    
	    # Retrieve the csv statistic files from Windows to local Linux machine
	    foreach statFile $::statsFilesToGet {
		set localStatFile ixLoad_[string map {" " ""} [string map {- _} $statFile]]
		puts "Getting csv stats:  $statFile ..."
		catch {::IxLoad retrieveFileCopy $::resultDirectoryOnWindows\\$statFile $::localLinuxPath/$localStatFile\_[GetTime]} errMsg
		if {$errMsg != ""} {
		    puts "\nError: Copying csv stat file from Windows PC: $statFile\n"
		}
	    }
	}

	::IxLoad disconnect

	# No IxLoad platform failures = eventType TEST_STOPPED status OK
	return $::ixTestControllerMonitor

    } errMsg]} {
	return $errMsg
    }
}
