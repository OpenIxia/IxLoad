#
# setup path and load IxLoad package
#

source ../setup_simple.tcl

#-----------------------------------------------------------------------
# Connect
#-----------------------------------------------------------------------

# IxLoad onnect should always be called, even for local scripts
::IxLoad connect $::IxLoadPrivate::SimpleSettings::remoteServer

if [catch {

#-----------------------------------------------------------------------
# package require the stat collection utilities
#-----------------------------------------------------------------------
global ixAppPluginManager
$ixAppPluginManager load "capturereplay"
#package require statCollectorUtils
#set scu_version [package require statCollectorUtils]
#puts stderr "statCollectorUtils package version = $scu_version"


#-----------------------------------------------------------------------
# setup logger
#-----------------------------------------------------------------------
set logtag "IxLoad-api"
set logName "simple_tracefilereplay"
set logger [::IxLoad new ixLogger $logtag 1]
set logEngine [$logger getEngine]
$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
$logEngine setFile $logName 2 256 1




#-----------------------------------------------------------------------
# Build Chassis Chain
#--------------------------------------------------------:---------------
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
    -ipCount        20 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0" \
    -firstMac       "00:C6:12:02:01:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
    -vlanEnable     0 \
    -vlanId         1



$clnt_network arpSettings.config \
                    -gratuitousArp 1

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
    -ipCount        20 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0" \
    -firstMac       "00:C6:12:02:02:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
    -vlanEnable     0 \
    -vlanId         1

$svr_network arpSettings.config \
                    -gratuitousArp 1

$svr_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)


#-----------------------------------------------------------------------
# Construct Client Traffic
# The ActivityModel acts as a factory for creating agents which actually
# generate the test traffic
#-----------------------------------------------------------------------
set clnt_traffic [::IxLoad new ixClientTraffic -name "client_traffic"]

$clnt_traffic agentList.appendItem  \
    -name                   "my_client" \
    -protocol               "capturereplay" \
    -type                   "Client"

set traceFileName [format "%s\\TclScripts\\Samples\\Protocols\\2.1.10_src_trace_http.cap" [::IxLoad getInstallRoot]]
$clnt_traffic agentList(0).pm.options.config \
    -destinationServerActivity  "server_traffic_my_server" \
    -replayBidirectionalTraffic 1 \
    -traceFileName              $traceFileName \
    -enableFilter               0


#-----------------------------------------------------------------------
# Construct Server Traffic
#-----------------------------------------------------------------------
set svr_traffic [::IxLoad new ixServerTraffic -name "server_traffic"]

$svr_traffic agentList.appendItem       \
    -name               "my_server"     \
    -protocol           "capturereplay" \
    -type               "Server"

$svr_traffic agentList(0).pm.traceFileOptions.config    \
    -sourceClientActivity   "client_traffic_my_client"  \
    -traceFileName          $traceFileName \
    -enableFilter           0

$svr_traffic agentList(0).pm.advancedOptions.config \
            -useSpecifiedServerAddr     0

#-----------------------------------------------------------------------
# Create a client and server mapping and bind into the
# network and traffic that they will be employing
#-----------------------------------------------------------------------
set clnt_t_n_mapping [::IxLoad new ixClientTrafficNetworkMapping \
    -network                $clnt_network \
    -traffic                $clnt_traffic \
    -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
    -objectiveValue         1 \
    -rampUpValue            1 \
    -sustainTime            20 \
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
    -enableResetPorts   1 \
    -enableReleaseConfigAfterRun   1 \
    -csvInterval        1
]

$test clientCommunityList.appendItem -object $clnt_t_n_mapping
$test serverCommunityList.appendItem -object $svr_t_n_mapping


#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]
$testController setResultDir "RESULTS/simple_tracefilereplay"

# Run Test
$testController run $test

puts "Make the script (v)wait until the test is over"
# Make the script (v)wait until the test is over
vwait ::ixTestControllerMonitor


#-----------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------
puts "releaseConfigWaitFinish"

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

