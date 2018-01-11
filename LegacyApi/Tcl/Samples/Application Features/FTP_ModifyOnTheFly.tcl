#
# setup path and load IxLoad package
#
#
# setup path and load IxLoad package
#

source ../setup_simple.tcl

#
# Initialize IxLoad
#

# IxLoad onnect should always be called, even for local scripts
::IxLoad connect $::IxLoadPrivate::SimpleSettings::remoteServer

# once we've connected, make sure we disconnect, even if there's a problem
if [catch {

#
# Loads plugins for specific protocols configured in this test
#
global ixAppPluginManager
$ixAppPluginManager load "FTP"

#
# setup logger
#
set logtag "IxLoad-api"
set logName "simpleftpclientandserver"
set logger [::IxLoad new ixLogger $logtag 1]
set logEngine [$logger getEngine]
$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
$logEngine setFile $logName 2 256 1


#-----------------------------------------------------------------------
# Build Chassis Chain
#-----------------------------------------------------------------------
set chassisChain [::IxLoad new ixChassisChain]
$chassisChain addChassis $::IxLoadPrivate::SimpleSettings::chassisName


#-----------------------------------------------------------------------
# Build client and server Network
#-----------------------------------------------------------------------
set clnt_network [::IxLoad new ixClientNetwork $chassisChain]
$clnt_network config -name "clnt_network"
$clnt_network networkRangeList.appendItem \
    -name           "clnt_range" \
    -enable         1 \
    -firstIp        "198.18.2.1" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        100 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0" \
    -firstMac       "00:C6:12:02:01:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
    -vlanEnable     0 \
    -vlanId         1 \
    -mssEnable      0 \
    -mss            100
$clnt_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)

set svr_network [::IxLoad new ixServerNetwork $chassisChain]
$svr_network config -name "svr_network"
$svr_network networkRangeList.appendItem \
    -name           "svr_range" \
    -enable         1 \
    -firstIp        "198.18.200.1" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        1 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0" \
    -firstMac       "00:C6:12:02:02:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
    -vlanEnable     0 \
    -vlanId         1 \
    -mssEnable      0 \
    -mss            100

# Add port to server network
$svr_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)


#-----------------------------------------------------------------------
# Construct Client Traffic
#-----------------------------------------------------------------------
set expected "clnt_traffic"
set clnt_traffic [::IxLoad new ixClientTraffic -name $expected]

$clnt_traffic agentList.appendItem \
    -name       "my_ftp_client" \
    -protocol   "FTP" \
    -type       "Client" \
    -userName   "root" \
    -password   "noreply@ixiacom.com" \
    -fileList   {'/#64', '/#256', '/#1024', '/#4096'} \
    -mode       $::FTP_Client(kModeActive) \
    -enableEsm  0 \
    -esm        300        

#
# Add actions to this client agent
#
$clnt_traffic agentList(0).actionList.appendItem \
                    -command    "GET" \
                    -destination "svr_traffic_my_ftp_server" \
                    -userName    "root" \
                    -password    "noreply@ixiacom.com" \
                    -arguments   "/#4096"
   

#-----------------------------------------------------------------------
# Construct Server Traffic
#-----------------------------------------------------------------------
set expected "svr_traffic"
set svr_traffic [::IxLoad new ixServerTraffic -name $expected]
set actual [$svr_traffic cget -name]

#
# Create a server agent
#
$svr_traffic agentList.appendItem \
    -name       "my_ftp_server" \
    -protocol   "FTP" \
    -type       "Server" \
    -ftpPort    21 \
    -enableEsm  0 \
    -esm        300


#-----------------------------------------------------------------------
# Create a client and server mapping and bind into the
# network and traffic that they will be employing
#-----------------------------------------------------------------------
set clnt_t_n_mapping [::IxLoad new ixClientTrafficNetworkMapping \
    -network                $clnt_network \
    -traffic                $clnt_traffic \
    -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
    -objectiveValue         200 \
    -rampUpValue            5 \
    -sustainTime            200 \
    -rampDownTime           20
]
set svr_t_n_mapping [::IxLoad new ixServerTrafficNetworkMapping \
    -network                $svr_network \
    -traffic                $svr_traffic \
    -matchClientTotalTime   1
]

#-----------------------------------------------------------------------
# Create the test and bind in the network-traffic mapping it is going
# to employ.
#-----------------------------------------------------------------------
set test [::IxLoad new ixTest \
    -name               "my_test" \
    -statsRequired      0 \
    -enableResetPorts   0
]

$test clientCommunityList.appendItem -object $clnt_t_n_mapping
$test serverCommunityList.appendItem -object $svr_t_n_mapping

#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]

$testController setResultDir "RESULTS/simpleftpclientandserver"

set ::ixTestControllerMonitor ""
$testController run $test

proc sleep {n} {
    
    for {set i 0} {$i < $n && $::ixTestControllerMonitor == ""} {incr i} {
        after 1000 set timeElapsed 1000
        vwait timeElapsed
    }
    
}

# Modify objective value on the fly every 20s
set tempObjectiveValue 200
for {set j 0} {$j < 10 && $::ixTestControllerMonitor == ""} {incr j} {
    sleep 20
    incr tempObjectiveValue 20
    $clnt_t_n_mapping config -objectiveValue $tempObjectiveValue
    set canSetObjectiveValue [$clnt_t_n_mapping canSetObjectiveValue]
    if { $canSetObjectiveValue } {
        $clnt_t_n_mapping applyObjectiveValues
    }
}
puts "###################################################"
set tstmp [clock format [clock seconds] -format {%Y %m %d %H %M %S}]
puts $tstmp

sleep 10

puts "###################################################"
set tstmp [clock format [clock seconds] -format {%Y %m %d %H %M %S}]
puts $tstmp

set canSetObjectiveValue [$clnt_t_n_mapping canSetObjectiveValue]
if { $canSetObjectiveValue } {
    $clnt_t_n_mapping config -objectiveValue 300
    $clnt_t_n_mapping applyObjectiveValues
}

vwait ::ixTestControllerMonitor
puts $::ixTestControllerMonitor

#-----------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------

$testController releaseConfigWaitFinish

::IxLoad delete $logger
::IxLoad delete $logEngine
::IxLoad delete $chassisChain
::IxLoad delete $clnt_network
::IxLoad delete $svr_network
::IxLoad delete $clnt_traffic
::IxLoad delete $svr_traffic
::IxLoad delete $clnt_t_n_mapping
::IxLoad delete $svr_t_n_mapping
::IxLoad delete $test
::IxLoad delete $testController

}] {
    puts $errorInfo
}

#
#   Disconnect/Release application lock
#
::IxLoad disconnect

