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
# Loads plugins for specific protocols configured in this test
#
global ixAppPluginManager
$ixAppPluginManager load "SIP"
# setup logger
set logtag "IxLoad-api"
set logName  "SIP_PerStreamStats"
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
    -name           "clnt_range" \
    -enable         1 \
    -firstIp        "198.18.0.1" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        10 \
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
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID) \
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)

set svr_network [::IxLoad new ixServerNetwork $chassisChain]
$svr_network config -name "svr_network"
$svr_network networkRangeList.appendItem \
    -name           "svr_range" \
    -enable         1 \
    -firstIp        "198.18.0.101" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        10 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0" \
    -firstMac       "00:C6:12:02:02:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
    -vlanEnable     0 \
    -vlanId         1 \
    -mssEnable      0 \
    -mss            1460

# Add port to server network
$svr_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID) \
    -portId     $::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)


#-----------------------------------------
# SIP Client Configuration
#-----------------------------------------

set clnt_traffic [::IxLoad new ixClientTraffic -name "client_traffic"]
$clnt_traffic agentList.appendItem \
    -name                   "my_sip_client" \
    -protocol               "SIP" \
    -type                   "Client"


$clnt_traffic agentList(0).pm.generalSettings.config \
     -szAuthUsername         "user" \
     -szAuthPassword         "password" \
     -szAuthDomain           "domain" \
     -szTransport            "UDP" \
     -nUdpPort               5060 \
     -nTcpPort               5060 \
     -nUdpMaxSize            1024 \
     -szRegistrar            "127.0.0.1:5060" \
     -bRegBefore             0

 $clnt_traffic agentList(0).pm.contentOfMessages.config \
     -bRoute                 0 \
     -szRoute                "Route: &lt;sip:p1.example.com;lr&gt;,&lt;sip:p2.domain.com;lr&gt;" \
     -bCompact               0 \
     -bFolding               0 \
     -bScattered             0 \
     -bAdvisable             0 \
     -bOptional              0 \
     -bBestPerformance       1 \
     -szREQUESTURI           "sip:id@IP" \
     -szFROM                 "sip:id@IP" \
     -szTO                   "sip:id@IP" \
     -szCONTACT              "sip:id@IP"

$clnt_traffic agentList(0).pm.stateMachine.config \
     -nTimersT1              500 \
     -nTimersT2              4000 \
     -nTimersT4              5000 \
     -nTimersTC              180000 \
     -nTimersTD              32000 


$clnt_traffic agentList(0).pm.mediaSettings.config \
    -szCodecName           "G729B" \
    -szCodecDetails        "" \
    -bModifyPowerLevel	   0 \
    -szPowerLevel          "PL_20" \
    -nJitterBuffer         1


$clnt_traffic agentList(0).pm.scenarios.appendItem \
     -id                     "ORIGINATECALL" \
     -symDestination         "server_traffic_my_sip_server:5060"

$clnt_traffic agentList(0).pm.scenarios.appendItem \
     -id                     "VOICESESSION" \
     -szAudioFile            "speech.wav" \
     -nPlayMode              1 \
     -nRepeatCount           1 \
     -nPlayTime              1 \
     -nTimeUnit              0

$clnt_traffic agentList(0).pm.scenarios.appendItem \
     -id                     "ENDCALL"


#-----------------------------------------
# SIP Server Configuration
#-----------------------------------------

set svr_traffic [::IxLoad new ixServerTraffic -name "server_traffic"]
$svr_traffic agentList.appendItem \
    -name                   "my_sip_server" \
    -protocol               "SIP" \
    -type                   "Server"

$svr_traffic agentList(0).pm.generalSettings.config \
     -szAuthUsername         "user" \
     -szAuthPassword         "password" \
     -szAuthDomain           "domain" \
     -szTransport            "UDP" \
     -nUdpPort               5060 \
     -nTcpPort               5060 \
     -nUdpMaxSize            1024 \
     -szRegistrar            "127.0.0.1:5060" \
     -bRegBefore             0

$svr_traffic agentList(0).pm.contentOfMessages.config \
     -bCompact               0 \
     -bFolding               0 \
     -bScattered             0 \
     -bAdvisable             0 \
     -bOptional              0 \
     -bBestPerformance       1 \
     -szREQUESTURI           "sip:IP" \
     -szFROM                 "sip:id@IP" \
     -szTO                   "sip:id@IP" \
     -szCONTACT              "sip:id@IP"


$svr_traffic agentList(0).pm.scenarios.appendItem \
     -id                     "RECEIVEUSING180"

$svr_traffic agentList(0).pm.scenarios.appendItem \
     -id                     "VOICESESSION" \
     -szAudioFile            "speech.wav" \
     -nPlayMode              1 \
     -nRepeatCount           1 \
     -nPlayTime              1 \
     -nTimeUnit              0



#-----------------------------------------------------------------------
# Create a client and server mapping and bind into the
# network and traffic that they will be employing
#-----------------------------------------------------------------------
set clnt_t_n_mapping [::IxLoad new ixClientTrafficNetworkMapping \
    -network                $clnt_network \
    -traffic                $clnt_traffic \
    -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
    -objectiveValue         10 \
    -standbyTime            0 \
    -rampUpValue            10 \
    -sustainTime            120 \
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
$testController setResultDir "RESULTS/$logName"

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
    -statSourceType "SIP Client" \
    -statName "SIP Simulated Users" \
    -aggregationType $aggregation_type \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_2" \
    -statSourceType "SIP Client" \
    -statName "SIP calls initiated" \
    -aggregationType $aggregation_type \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_3" \
    -statSourceType "SIP Client" \
    -statName "SIP calls completed" \
    -aggregationType $aggregation_type \
    -filterList {}

#
# Clear any grid stats that may have been registered previously
#
$test clearGridStats

# For sip per stream grid stats, formats are as follows.
# statList - list of {statName, aggregationFunction} like {"Packets" "kSum"} {"Mos_Value" "kString"}
# instanceList - list of {port, sipClientAgentName, index of Caller or Called}

set port "1.$::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID).$::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)"
${NS}::AddSIPPerStreamStats \
    -test $test \
    -statSourceType "SIP Client Per Stream" \
    -statList {{"RTP Packets" "kSum"} {"RTP Bytes" "kSum"} {"RTP MOS" "kSum"}} \
    -instanceList [list [list $port "my_sip_client" "0"]]

#
# Start the collector (runs in the tcl event loop)
#
proc ::my_stat_collector_command {args} {
    puts "====================================="
    puts "INCOMING STAT RECORD >>> $args"
    puts "Len = [llength $args]"
    puts  [lindex $args 0]
    puts  [lindex $args 1]
    puts "====================================="
}
${NS}::StartCollector -command ::my_stat_collector_command

$testController run $test

vwait ::ixTestControllerMonitor
puts $::ixTestControllerMonitor

#
# Stop the collector (running in the tcl event loop)
#
${NS}::StopCollector
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

