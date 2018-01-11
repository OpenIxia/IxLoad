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
set logName  "simplesipclientandserver-perStreamStats"
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
	-enabled                                 true \
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
	-count                                   10 \
	-name                                    "ip-1" \
	-gatewayAddress                          "0.0.0.0" \
	-prefix                                  16 \
	-mss                                     100 \
	-ipAddress                               "198.18.0.1" 

set mac_1 [$ip_1 getLowerRelatedRange "MacRange"]

$mac_1 config \
	-count                                   10 \
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
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID) \
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)


set svr_network [::IxLoad new ixNetworkGroup $chassisChain]
$svr_network config \
	-name                                    "svr_network" 

$svr_network globalPlugins.clear

set Filter [::IxLoad new ixNetFilterPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $Filter

$Filter config \
	-name                                    "Filter" 

set GratArp [::IxLoad new ixNetGratArpPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $GratArp

$GratArp config \
	-enabled                                 true \
	-name                                    "GratArp" 

set TCP [::IxLoad new ixNetTCPPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $TCP

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
$svr_network globalPlugins.appendItem -object $DNS

$DNS config \
	-name                                    "DNS" 

$DNS hostList.clear

$DNS searchList.clear

$DNS nameServerList.clear

set Settings [::IxLoad new ixNetIxLoadSettingsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $Settings

$Settings config \
	-name                                    "Settings" 

set Ethernet__PHY_2 [$svr_network getL1Plugin]

set my_ixNetEthernetELMPlugin [::IxLoad new ixNetEthernetELMPlugin]
$my_ixNetEthernetELMPlugin config 

$Ethernet__PHY_2 config \
	-name                                    "Ethernet /PHY-2" \
	-cardElm                                 $my_ixNetEthernetELMPlugin 

$Ethernet__PHY_2 childrenList.clear

set MAC_VLAN_2 [::IxLoad new ixNetL2EthernetPlugin]
# ixNet objects needs to be added in the list before they are configured!
$Ethernet__PHY_2 childrenList.appendItem -object $MAC_VLAN_2

$MAC_VLAN_2 config \
	-name                                    "MAC/VLAN-2" 

$MAC_VLAN_2 childrenList.clear

set IP_2 [::IxLoad new ixNetIpV4V6Plugin]
# ixNet objects needs to be added in the list before they are configured!
$MAC_VLAN_2 childrenList.appendItem -object $IP_2

$IP_2 config \
	-name                                    "IP-2" 

$IP_2 childrenList.clear

$IP_2 extensionList.clear

$MAC_VLAN_2 extensionList.clear

$Ethernet__PHY_2 extensionList.clear

#################################################
# Setting the ranges starting with the plugin on top of the stack
#################################################
$IP_2 rangeList.clear

set ip_2 [::IxLoad new ixNetIpV4V6Range]
# ixNet objects needs to be added in the list before they are configured!
$IP_2 rangeList.appendItem -object $ip_2

$ip_2 config \
	-count                                   10 \
	-name                                    "ip-2" \
	-gatewayAddress                          "0.0.0.0" \
	-prefix                                  16 \
	-ipAddress                               "198.18.0.101" 

set mac_2 [$ip_2 getLowerRelatedRange "MacRange"]

$mac_2 config \
	-count                                   10 \
	-mac                                     "00:C6:12:02:02:00" \
	-name                                    "mac-2" 

set vlan_2 [$ip_2 getLowerRelatedRange "VlanIdRange"]

$vlan_2 config \
	-name                                    "vlan-2" \
	-idIncrMode                              1 \
	-priority                                0 \
	-innerPriority                           0 


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
$testController setResultDir "[pwd]/RESULTS/simplesipclientandserver-perStreamStats"

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
# statList - list of {statName, aggregationFunction} like {"Packets" "kSum"} {"Mos_Value" "kSum"}
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

