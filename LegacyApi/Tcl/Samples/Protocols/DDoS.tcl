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
catch {

#
# Loads plugins for specific protocols configured in this test
#
global ixAppPluginManager
$ixAppPluginManager load "DDoS"

#
# setup logger
#
set logtag "IxLoad-api"
set logName "simpleddosclient"
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


#-----------------------------------------------------------------------
# Construct Client Traffic
#-----------------------------------------------------------------------
set clnt_traffic [::IxLoad new ixClientTraffic -name "client_traffic"]

$clnt_traffic agentList.appendItem  \
    -name       "my_client" \
    -protocol   "DDoS" \
    -type       "Client"

$clnt_traffic agentList(0).pm.commands.appendItem \
    -id                     "SynFloodAttack" \
    -destinationHostsFrom   "1.1.1.1" \
    -destinationHostsTo     "1.1.1.2" \
    -destinationPortsFrom   1024 \
    -destinationPortsTo     2048 \
    -sourceHostsFrom        "20.0.1.1" \
    -sourceHostsTo          "20.0.1.8"\
    -sourcePortsFrom        1024 \
    -sourcePortsTo          2048\
    -numberOfPackets        100 \
    -packetRate             10 \
    -sourceNetworkConfig    "useCustomNetwork"
     
$clnt_traffic agentList(0).pm.commands.appendItem \
    -id                     "RstFloodAttack" \
    -destinationHostsFrom   "1.1.1.1" \
    -destinationHostsTo     "1.1.1.2" \
    -destinationPortsFrom   1024 \
    -destinationPortsTo     2048 \
    -sourceHostsFrom        "20.0.1.1" \
    -sourceHostsTo          "20.0.1.8" \
    -sourcePortsFrom        1024 \
    -sourcePortsTo          2048 \
    -numberOfPackets        100 \
    -packetRate             1 \
    -sourceNetworkConfig    "useCustomNetwork"

$clnt_traffic agentList(0).pm.commands.appendItem \
    -id                     "SmurfAttack" \
    -sourceHosts            "198.18.0.255" \
    -destinationHostsFrom   "198.18.0.101" \
    -destinationHostsTo     "198.18.0.108" \
    -numberOfPackets        5 \
    -packetRate             1 \
    -sourceNetworkConfig    "useCustomNetwork"

$clnt_traffic agentList(0).pm.commands.appendItem \
    -id                     "LandAttack" \
    -destinationHostsFrom   "1.1.1.1" \
    -destinationHostsTo     "1.1.1.2" \
    -destinationPortsFrom   1024 \
    -destinationPortsTo     2048 \
    -numberOfPackets        100 \
    -packetRate             1

$clnt_traffic agentList(0).pm.commands.appendItem \
    -id                     "PingSweepAttack" \
    -destinationHostsFrom   "1.1.1.1" \
    -destinationHostsTo     "1.1.1.2" \
    -sourceHostsFrom        "20.0.1.1" \
    -sourceHostsTo          "20.0.1.8" \
    -packetSize             1024 \
    -numberOfPackets        100 \
    -packetRate             1 \
    -sourceNetworkConfig    "useCustomNetwork"

$clnt_traffic agentList(0).pm.commands.appendItem \
    -id                     "UDPScanAttack" \
    -destinationHostsFrom   "1.1.1.1" \
    -destinationHostsTo     "1.1.1.2" \
    -destinationPortsFrom   1024 \
    -destinationPortsTo     2048 \
    -sourceHostsFrom        "20.0.1.1" \
    -sourceHostsTo          "20.0.1.8" \
    -sourcePortsFrom        1024 \
    -sourcePortsTo          2048 \
    -packetSize             1024 \
    -packetRate             1 \
    -sourceNetworkConfig    "useCustomNetwork"

$clnt_traffic agentList(0).pm.commands.appendItem \
    -id                     "TearDropAttack" \
    -destinationHostsFrom   "1.1.1.1" \
    -destinationHostsTo     "1.1.1.2" \
    -destinationPortsFrom   1024 \
    -destinationPortsTo     2048 \
    -sourceHostsFrom        "20.0.1.1" \
    -sourceHostsTo          "20.0.1.8" \
    -sourcePortsFrom        1024 \
    -sourcePortsTo          2048 \
    -numberOfPackets        100 \
    -packetRate             1 \
    -sourceNetworkConfig    "useCustomNetwork"

$clnt_traffic agentList(0).pm.commands.appendItem \
    -id                     "PingOfDeathAttack" \
    -destinationHostsFrom   "1.1.1.1" \
    -destinationHostsTo     "1.1.1.2" \
    -sourceHostsFrom        "20.0.1.1" \
    -sourceHostsTo          "20.0.1.8" \
    -packetSize             1024 \
    -numberOfPackets        100 \
    -packetRate             1 \
    -sourceNetworkConfig    "useCustomNetwork"

$clnt_traffic agentList(0).pm.commands.appendItem \
    -id                     "ArpFloodAttack" \
    -arpType                "ARP_REQUEST" \
    -destinationHostsFrom   "1.1.1.1" \
    -destinationHostsTo     "1.1.1.2" \
    -sourceHostsFrom        "20.0.1.1" \
    -sourceHostsTo          "20.0.1.8" \
    -destinationMACFrom     "00:00:00:00:00:00" \
    -destinationMACTo       "FF:FF:FF:FF:FF:FF" \
    -sourceMACFrom          "00:00:00:00:00:00" \
    -sourceMACTo            "FF:FF:FF:FF:FF:FF" \
    -numberOfPackets        100 \
    -packetRate             1 \
    -sourceNetworkConfig    "useCustomNetwork"


#-----------------------------------------------------------------------
# Construct Server Traffic
#-----------------------------------------------------------------------
set clnt_t_n_mapping [::IxLoad new ixClientTrafficNetworkMapping \
    -network                $clnt_network \
    -traffic                $clnt_traffic \
    -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
    -objectiveValue         10 \
    -rampUpValue            5 \
    -sustainTime            20 \
    -rampDownTime           20
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


#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]

$testController setResultDir "RESULTS/simpleddosclient"


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
    -caption            "Watch_Stat_1" \
    -statSourceType     "DDoS Client" \
    -statName           "SynFloodAttack_PacketsSent" \
    -aggregationType    $aggregation_type \
    -filterList         {}

${NS}::AddStat \
    -caption            "Watch_Stat_2" \
    -statSourceType     "DDoS Client" \
    -statName           "RstFloodAttack_PacketsSent" \
    -aggregationType    $aggregation_type \
    -filterList         {}

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
::IxLoad delete $clnt_traffic
::IxLoad delete $clnt_t_n_mapping
::IxLoad delete $test
::IxLoad delete $testController


#-----------------------------------------------------------------------
# Disconnect
#-----------------------------------------------------------------------

} connectResult

puts $connectResult

#
#   Disconnect/Release application lock
#
::IxLoad disconnect

