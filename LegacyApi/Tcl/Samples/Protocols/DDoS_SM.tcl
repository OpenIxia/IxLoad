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

set clnt_network [::IxLoad new ixNetworkGroup $chassisChain]
$clnt_network config \
	-name                                    "clnt_network" 

$clnt_network globalPlugins.clear

set Filter [::IxLoad new ixNetFilterPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $Filter

$Filter config \
	-name                                    "Filter" 

set GratArp [::IxLoad new ixNetGratArpPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $GratArp

$GratArp config \
	-name                                    "GratArp" 

set TCP [::IxLoad new ixNetTCPPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $TCP

$TCP config \
	-tcp_tw_recycle                          true \
	-tcp_keepalive_time                      75 \
	-tcp_keepalive_intvl                     7200 \
	-tcp_wmem_default                        4096 \
	-tcp_port_min                            1024 \
	-tcp_port_max                            65535 \
	-tcp_window_scaling                      false \
	-name                                    "TCP" \
	-tcp_rmem_default                        4096 

set DNS [::IxLoad new ixNetDnsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $DNS

$DNS config \
	-name                                    "DNS" 

$DNS hostList.clear

$DNS searchList.clear

$DNS nameServerList.clear

set Settings [::IxLoad new ixNetIxLoadSettingsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $Settings

$Settings config \
	-name                                    "Settings" 

set Ethernet__PHY_1 [$clnt_network getL1Plugin]

set my_ixNetEthernetELMPlugin [::IxLoad new ixNetEthernetELMPlugin]
$my_ixNetEthernetELMPlugin config 

$Ethernet__PHY_1 config \
	-name                                    "Ethernet /PHY-1" \
	-cardElm                                 $my_ixNetEthernetELMPlugin 

$Ethernet__PHY_1 childrenList.clear

set MAC_VLAN_1 [::IxLoad new ixNetL2EthernetPlugin]
# ixNet objects needs to be added in the list before they are configured!
$Ethernet__PHY_1 childrenList.appendItem -object $MAC_VLAN_1

$MAC_VLAN_1 config \
	-name                                    "MAC/VLAN-1" 

$MAC_VLAN_1 childrenList.clear

set IP_1 [::IxLoad new ixNetIpV4V6Plugin]
# ixNet objects needs to be added in the list before they are configured!
$MAC_VLAN_1 childrenList.appendItem -object $IP_1

$IP_1 config \
	-name                                    "IP-1" 

$IP_1 childrenList.clear

$IP_1 extensionList.clear

$MAC_VLAN_1 extensionList.clear

$Ethernet__PHY_1 extensionList.clear

#################################################
# Setting the ranges starting with the plugin on top of the stack
#################################################
$IP_1 rangeList.clear

set ip_1 [::IxLoad new ixNetIpV4V6Range]
# ixNet objects needs to be added in the list before they are configured!
$IP_1 rangeList.appendItem -object $ip_1

$ip_1 config \
	-count                                   100 \
	-name                                    "ip-1" \
	-gatewayAddress                          "0.0.0.0" \
	-autoMacGeneration                       true \
	-prefix                                  16 \
	-mss                                     100 \
	-ipAddress                               "198.18.2.1" 

set mac_1 [$ip_1 getLowerRelatedRange "MacRange"]

$mac_1 config \
	-count                                   100 \
	-mac                                     "00:C6:12:02:01:00" \
	-name                                    "mac-1" 

set vlan_1 [$ip_1 getLowerRelatedRange "VlanIdRange"]

$vlan_1 config \
	-name                                    "vlan-1" \
	-idIncrMode                              1 \
	-priority                                0 \
	-innerPriority                           0 


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

$testController setResultDir "[pwd]/RESULTS/simpleddosclient"


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

