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
$ixAppPluginManager load "QuickHTTP"

#
# setup logger
#
set logtag "IxLoad-api"
set logName "simplequickhttpclientandserver"
set logger [::IxLoad new ixLogger $logtag 1]
set logEngine [$logger getEngine]
$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
$logEngine setFile $logName 2 256 1


#-----------------------------------------------------------------------
# package require the stat collection utilities
#-----------------------------------------------------------------------
set ::env(IXLOAD_STATVIEWER_ENABLE) "YES"
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
set clnt_traffic [::IxLoad new ixClientTraffic -name "client_traffic"]

$clnt_traffic agentList.appendItem  \
    -name       "my_client" \
    -protocol   "QuickHTTP" \
    -type       "Client"

$clnt_traffic agentList(0).pm.http.config \
    -standardVersion                "HTTP/1.1" \
    -keepAlive                      0 \
    -concurrentConnectionsPerUser   1 \
    -limitTransactionsPerConnection "upto" \
    -maxTransactionsPerConnection   1 \
    -browserEmulation               "custom" \
    -additionalHeaders              ""

$clnt_traffic agentList(0).pm.advanced.config \
    -enableESM      0 \
    -esm            1460 \
    -closeWithRST   0 \
    -threeWayClose  1 \
    -noClose        0

# GET
$clnt_traffic agentList(0).pm.commands.appendItem \
    -id             "GET" \
    -destination    "server_traffic_my_server:80" \
    -page           "/#64"

# {Think}
$clnt_traffic agentList(0).pm.commands.appendItem \
    -id             "THINK" \
    -duration       1000

# GET
$clnt_traffic agentList(0).pm.commands.appendItem \
    -id             "GET" \
    -destination    "server_traffic_my_server:80" \
    -page           "/#64"  


#-----------------------------------------------------------------------
# Construct Server Traffic
#-----------------------------------------------------------------------
set svr_traffic [::IxLoad new ixServerTraffic -name "server_traffic"]

$svr_traffic agentList.appendItem \
    -name       "my_server" \
    -protocol   "QuickHTTP" \
    -type       "Server" 
    
$svr_traffic agentList(0).pm.http.config \
    -listenPort             80 \
    -enableRequestTimeout   1 \
    -requestTimeout         300000

$svr_traffic agentList(0).pm.advanced.config \
    -enableESM       0 \
    -esm             1460 \
    -closeWithRST    0 \
    -threeWayClose   1


#-----------------------------------------------------------------------
# Create a client and server mapping and bind into the
# network and traffic that they will be employing
#-----------------------------------------------------------------------
set clnt_t_n_mapping [::IxLoad new ixClientTrafficNetworkMapping \
    -network                $clnt_network \
    -traffic                $clnt_traffic \
    -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
    -objectiveValue         3 \
    -rampUpValue            1 \
    -sustainTime            40 \
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

$testController setResultDir "RESULTS/simplequickhttpclientandserver"

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
    -statSourceType "QuickHTTP Client" \
    -statName "TCP SYN Sent" \
    -aggregationType $aggregation_type \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_2" \
    -statSourceType "QuickHTTP Server" \
    -statName "TCP SYN_SYN-ACK Received" \
    -aggregationType $aggregation_type \
    -filterList {}

#
# Start the collector (runs in the tcl event loop)
#
proc ::my_stat_collector_command {args} {
    puts "====================================="
    puts "INCOMING STAT RECORD >>> $args"
    puts "====================================="
}
${NS}::StartCollector -command ::my_stat_collector_command

$testController run $test

#
# have the script (v)wait until the test is over
#
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

