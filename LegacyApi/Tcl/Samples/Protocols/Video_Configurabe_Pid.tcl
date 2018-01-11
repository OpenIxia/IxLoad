#
# setup path and load IxLoad package
#

source ../setup_simple.tcl

#
# Initialize IxLoad
#

#-----------------------------------------------------------------------
# Connect
#-----------------------------------------------------------------------
# IxLoad connect should always be called, even for local scripts
::IxLoad connect $::IxLoadPrivate::SimpleSettings::remoteServer

# once we've connected, make sure we disconnect, even if there's a problem
if [catch {

#
# Loads plugins for specific protocols configured in this test
#
global ixAppPluginManager
$ixAppPluginManager load "Video"

#
# setup logger
#
set logtag "IxLoad-api"
set logName  "93357"
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
    -name	    "clnt_range" \
    -enable	    1 \
    -firstIp	    "198.18.0.1" \
    -ipIncrStep	    $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount	    100 \
    -networkMask    "255.255.0.0" \
    -gateway	    "0.0.0.0" \
    -firstMac	    "00:C6:12:02:01:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
    -vlanEnable	    0 \
    -vlanId	    1 \
    -mssEnable	    0 \
    -mss	    100

$clnt_network arpSettings.config -gratuitousArp 0

$clnt_network portList.appendItem \
    -chassisId	1 \
    -cardId	$::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID)\
    -portId	$::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)

set svr_network [::IxLoad new ixServerNetwork $chassisChain]
$svr_network config -name "svr_network"
$svr_network networkRangeList.appendItem \
    -name	    "svr_range" \
    -enable	    1 \
    -firstIp	    "198.18.0.101" \
    -ipIncrStep	    $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount	    1 \
    -networkMask    "255.255.0.0" \
    -gateway	    "0.0.0.0" \
    -firstMac	    "00:C6:12:02:02:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
    -vlanEnable	    0 \
    -vlanId	    1 \
    -mssEnable	    0 \
    -mss	    1460

$svr_network arpSettings.config -gratuitousArp 0

# Add port to server network
$svr_network portList.appendItem \
    -chassisId	1 \
    -cardId	$::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID)\
    -portId	$::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)

#-----------------------------------------------------------------------
# Construct Client Traffic
#-----------------------------------------------------------------------
set expected "clnt_traffic"
set clnt_traffic [::IxLoad new ixClientTraffic -name $expected]

$clnt_traffic agentList.appendItem \
    -name               "my_video_client" \
    -protocol           "Video" \
    -type               "Client"


# All Video client commands
#-------------------------------------------------------------------------
$clnt_traffic agentList(0).pm.commands.appendItem \
    -id                            "PlayMediaCommand"  \
    -symServerIP                   "svr_traffic_my_video_server:554"\
    -media                         "Stream1"


#-----------------------------------------------------------------------
# Construct Server Traffic
#-----------------------------------------------------------------------
set expected "svr_traffic"
set svr_traffic [::IxLoad new ixServerTraffic -name $expected]

$svr_traffic agentList.appendItem \
    -name                   "my_video_server" \
    -protocol               "Video" \
    -type                   "Server"

$svr_traffic agentList(0).pm.videoConfig.videoList.appendItem \
    -name                   "Stream1" \
    -type                   "VoD"     \
    -stream_count           10        \
    -duration               100        \

set payloadfile [format "%s/Samples/Videos/Cloud-vs11-withaudio(10Mbps).ts" [::IxLoad getInstallRoot]]
puts $payloadfile

$svr_traffic agentList(0).pm.videoProp.stream.appendItem \
    -name                   "Stream1" \
    -content                "Real Payload" \
    -filename               $payloadfile \
    -ip_bit_rate            "3.7500" \
    -type                   "VoD" \
    -stream_count           "10" \
    -duration               "100" \
    -tsperudp               "7"

$svr_traffic agentList(0).pm.videoProp.stream(1).program(0).config \
    -new_pid                "200" \
    -is_modified_pid        "1"

$svr_traffic agentList(0).pm.videoProp.stream(1).program(0).es_info(0).config \
    -new_pid                "400"

$svr_traffic agentList(0).pm.videoProp.stream(1).program(0).es_info(1).config \
    -new_pid                "600"

#-----------------------------------------------------------------------
# Create a client and server mapping and bind into the
# network and traffic that they will be employing
#-----------------------------------------------------------------------
set clnt_t_n_mapping [::IxLoad new ixClientTrafficNetworkMapping \
    -network                $clnt_network \
    -traffic                $clnt_traffic \
    -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
    -objectiveValue         1 \
    -standbyTime            30 \
    -rampUpValue            1 \
    -sustainTime            60 \
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
    -name           "my_test" \
    -statsRequired  1 \
    -enableResetPorts 1 \
    -enableForceOwnership 0 \
]
$test clientCommunityList.appendItem -object $clnt_t_n_mapping
$test serverCommunityList.appendItem -object $svr_t_n_mapping
#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]

$testController setResultDir "RESULTS/simplevideoclientandserver"

set NS statCollectorUtils
set ::test_server_handle [$testController getTestServerHandle]
${NS}::Initialize -testServerHandle $::test_server_handle

#
# Clear any stats that may have been registered previously
#
${NS}::ClearStats

set aggregation_type "kSum"
set port "1.$::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID).$::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)"
${NS}::AddVideoPerStreamStats \
    -test $test \
    -statSourceType "Video Client Per Stream" \
    -statList {{"Packets" "kSum"} {"Bytes" "kSum"} {"Stream Name" "kString"} {"MDI-DF" "kSum"}} \
    -instanceList [list [list $port "my_video_client" "0" "0"]]

$testController run $test
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


