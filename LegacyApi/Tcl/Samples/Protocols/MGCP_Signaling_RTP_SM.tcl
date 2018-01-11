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
$ixAppPluginManager load "MGCP"
# setup logger
set logtag "IxLoad-api"
set logName  "simplemgcpclientandserver"
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

set clnt_network1 [::IxLoad new ixNetworkGroup $chassisChain]
$clnt_network1 config \
	-name                                    "clnt_network1" 

$clnt_network1 globalPlugins.clear

set Filter [::IxLoad new ixNetFilterPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network1 globalPlugins.appendItem -object $Filter

$Filter config \
	-name                                    "Filter" 

set GratArp [::IxLoad new ixNetGratArpPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network1 globalPlugins.appendItem -object $GratArp

$GratArp config \
	-enabled                                 true \
	-name                                    "GratArp" 

set TCP [::IxLoad new ixNetTCPPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network1 globalPlugins.appendItem -object $TCP

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
$clnt_network1 globalPlugins.appendItem -object $DNS

$DNS config \
	-name                                    "DNS" 

$DNS hostList.clear

$DNS searchList.clear

$DNS nameServerList.clear

set Settings [::IxLoad new ixNetIxLoadSettingsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network1 globalPlugins.appendItem -object $Settings

$Settings config \
	-name                                    "Settings" 

set Ethernet__PHY_1 [$clnt_network1 getL1Plugin]

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
	-count                                   7500 \
	-name                                    "ip-1" \
	-gatewayAddress                          "0.0.0.0" \
	-prefix                                  16 \
	-mss                                     100 \
	-ipAddress                               "198.5.0.1" 

set mac_1 [$ip_1 getLowerRelatedRange "MacRange"]

$mac_1 config \
	-count                                   7500 \
	-mac                                     "00:AC:13:00:01:00" \
	-name                                    "mac-1" \
	-incrementBy                             "00:00:00:00:01:00" 

set vlan_1 [$ip_1 getLowerRelatedRange "VlanIdRange"]

$vlan_1 config \
	-name                                    "vlan-1" \
	-idIncrMode                              1 \
	-priority                                0 \
	-innerPriority                           0 


$clnt_network1 portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID) \
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)


set clnt_network2 [::IxLoad new ixNetworkGroup $chassisChain]
$clnt_network2 config \
	-name                                    "clnt_network2" 

$clnt_network2 globalPlugins.clear

set Filter [::IxLoad new ixNetFilterPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network2 globalPlugins.appendItem -object $Filter

$Filter config \
	-name                                    "Filter" 

set GratArp [::IxLoad new ixNetGratArpPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network2 globalPlugins.appendItem -object $GratArp

$GratArp config \
	-enabled                                 true \
	-name                                    "GratArp" 

set TCP [::IxLoad new ixNetTCPPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network2 globalPlugins.appendItem -object $TCP

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
$clnt_network2 globalPlugins.appendItem -object $DNS

$DNS config \
	-name                                    "DNS" 

$DNS hostList.clear

$DNS searchList.clear

$DNS nameServerList.clear

set Settings [::IxLoad new ixNetIxLoadSettingsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network2 globalPlugins.appendItem -object $Settings

$Settings config \
	-name                                    "Settings" 

set Ethernet__PHY_2 [$clnt_network2 getL1Plugin]

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
	-count                                   7500 \
	-name                                    "ip-2" \
	-gatewayAddress                          "0.0.0.0" \
	-prefix                                  16 \
	-mss                                     100 \
	-ipAddress                               "198.5.30.1" 

set mac_2 [$ip_2 getLowerRelatedRange "MacRange"]

$mac_2 config \
	-count                                   7500 \
	-mac                                     "00:AC:13:1D:4D:00" \
	-name                                    "mac-2" \
	-incrementBy                             "00:00:00:00:01:00" 

set vlan_2 [$ip_2 getLowerRelatedRange "VlanIdRange"]

$vlan_2 config \
	-name                                    "vlan-2" \
	-idIncrMode                              1 \
	-priority                                0 \
	-innerPriority                           0 


$clnt_network2 portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::port3(CARD_ID) \
    -portId     $::IxLoadPrivate::SimpleSettings::port3(PORT_ID)


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

set Ethernet__PHY_3 [$svr_network getL1Plugin]

set my_ixNetEthernetELMPlugin [::IxLoad new ixNetEthernetELMPlugin]
$my_ixNetEthernetELMPlugin config 

$Ethernet__PHY_3 config \
	-name                                    "Ethernet /PHY-3" \
	-cardElm                                 $my_ixNetEthernetELMPlugin 

$Ethernet__PHY_3 childrenList.clear

set MAC_VLAN_3 [::IxLoad new ixNetL2EthernetPlugin]
# ixNet objects needs to be added in the list before they are configured!
$Ethernet__PHY_3 childrenList.appendItem -object $MAC_VLAN_3

$MAC_VLAN_3 config \
	-name                                    "MAC/VLAN-3" 

$MAC_VLAN_3 childrenList.clear

set IP_3 [::IxLoad new ixNetIpV4V6Plugin]
# ixNet objects needs to be added in the list before they are configured!
$MAC_VLAN_3 childrenList.appendItem -object $IP_3

$IP_3 config \
	-name                                    "IP-3" 

$IP_3 childrenList.clear

$IP_3 extensionList.clear

$MAC_VLAN_3 extensionList.clear

$Ethernet__PHY_3 extensionList.clear

#################################################
# Setting the ranges starting with the plugin on top of the stack
#################################################
$IP_3 rangeList.clear

set ip_3 [::IxLoad new ixNetIpV4V6Range]
# ixNet objects needs to be added in the list before they are configured!
$IP_3 rangeList.appendItem -object $ip_3

$ip_3 config \
	-name                                    "ip-3" \
	-gatewayAddress                          "0.0.0.0" \
	-prefix                                  16 \
	-ipAddress                               "198.5.100.101" 

set mac_3 [$ip_3 getLowerRelatedRange "MacRange"]

$mac_3 config \
	-mac                                     "00:AC:13:64:65:00" \
	-name                                    "mac-3" \
	-incrementBy                             "00:00:00:00:01:00" 

set vlan_3 [$ip_3 getLowerRelatedRange "VlanIdRange"]

$vlan_3 config \
	-name                                    "vlan-3" \
	-idIncrMode                              1 \
	-priority                                0 \
	-innerPriority                           0 


$svr_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID) \
    -portId     $::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)


#-----------------------------------------
# MGCP Server Configuration
#-----------------------------------------

set svr_traffic [::IxLoad new ixServerTraffic -name "server_traffic"]
$svr_traffic agentList.appendItem \
    -name                   "my_mgcp_server" \
    -protocol               "MGCP" \
    -type                   "Server"

$svr_traffic agentList(0).pm.parameters.config \
	-listen_port_start		2727

$svr_traffic agentList(0).pm.ll_parameters.config \
     -CommandTimeout        120 

$svr_traffic agentList(0).pm.endpoint_parameters.config \
     -NumberOfEndpoints     10 \
     -NumGateways           60 \
     -EndpointPhoneStartAt	1000 \
	 -EndpointPhoneStep		1 \
	 -EndpointNamePrefix	"aaln/" \
	 -EndpointNameExpandOn	1 \
	 -EndpointNameStartAt	0 \
	 -EndpointNameStep		1 \
	 -GatewayNameStartAt	3000 \
	 -GatewayNamePrefix		"ix" \
	 -GatewayNameStep		1 \
	 -GatewayNameSuffix		".ixia-lab.com" \
	 -GatewayNameExpandOn	1

#-----------------------------------------
# MGCP Clients Configuration
#-----------------------------------------

set clnt_traffic1 [::IxLoad new ixClientTraffic -name "client_traffic1"]
$clnt_traffic1 agentList.appendItem \
    -name                   "mgcp_client1" \
    -protocol               "MGCP" \
    -type                   "Client"

$clnt_traffic1 agentList(0).pm.parameters.config \
     -CallAgent_port        "server_traffic_my_mgcp_server:2727" \
	 -GatewaySourcePort		2427

$clnt_traffic1 agentList(0).pm.ll_parameters.config \
     -CommandTimeout        120 \
	 -LocalMediaProperties	"v:on, e:off"

$clnt_traffic1 agentList(0).pm.endpoint_parameters.config \
     -NumberOfEndpoints     10 \
     -EndpointPhoneStartAt	1300 \
     -NumGateways           30 \
 	 -GatewayNameStartAt    3000 \
	 -EndpointPhoneStep		1 \
	 -EndpointNamePrefix	"aaln/" \
	 -EndpointNameExpandOn	1 \
	 -EndpointNameStartAt	0 \
	 -EndpointNameStep		1 \
	 -GatewayNamePrefix		"ix" \
	 -GatewayNameStep		1 \
	 -GatewayNameSuffix		".ixia-lab.com" \
	 -GatewayNameExpandOn	1
     
$clnt_traffic1 agentList(0).pm.mediaSettings.config \
    -szCodecName           "G729B" \
    -szCodecDetails        "BF22PT20" \
    -bModifyPowerLevel		0 \
    -bUseJitter				0 \
	-bUseMOS				0
	
$clnt_traffic1 agentList(0).pm.mediaSettings.audioClipsTable.appendItem  \
        -szWaveName 		"pcmlinear.wav" \
        -szDataFormat 		"PCM" \
        -nSampleRate 		8000 \
        -nResolution 		16 \
        -nChannels 			1 \
        -nDuration 			4756 \
        -nSize 				76154


$clnt_traffic1 agentList(0).pm.scenarios.appendItem \
     -id                    "OriginateCall"


$clnt_traffic1 agentList(0).pm.scenarios.appendItem \
     -id                    "VOICESESSION" 

$clnt_traffic1 agentList(0).pm.scenarios(1).config \
	-szAudioFile           "pcmlinear.wav" \
	-nPlayMode				1	\
	-nRepeatCount			1	\
	-nPlayTime				30	\
	-nTimeUnit				0 \
	-nTotalTime				30000 \
	-nSessionType			0 \
	-nWavDuration			4756
    
$clnt_traffic1 agentList(0).pm.scenarios.appendItem \
     -id                    "EndCall"



#second client traffic


set clnt_traffic2 [::IxLoad new ixClientTraffic -name "client_traffic2"]
$clnt_traffic2 agentList.appendItem \
    -name                   "mgcp_client2" \
    -protocol               "MGCP" \
    -type                   "Client"

$clnt_traffic2 agentList(0).pm.parameters.config \
     -CallAgent_port        "server_traffic_my_mgcp_server:2727" \
	 -GatewaySourcePort		2427

$clnt_traffic2 agentList(0).pm.ll_parameters.config \
     -CommandTimeout        120 \
	 -LocalMediaProperties	"v:on, e:off"

$clnt_traffic2 agentList(0).pm.endpoint_parameters.config \
     -NumberOfEndpoints     10 \
	 -EndpointPhoneStartAt	1000 \
     -NumGateways           30 \
     -GatewayNameStartAt    3030 \
	 -EndpointPhoneStep		1 \
	 -EndpointNamePrefix	"aaln/" \
	 -EndpointNameExpandOn	1 \
	 -EndpointNameStartAt	0 \
	 -EndpointNameStep		1 \
	 -GatewayNamePrefix		"ix" \
	 -GatewayNameStep		1 \
	 -GatewayNameSuffix		".ixia-lab.com" \
	 -GatewayNameExpandOn	1
     
$clnt_traffic2 agentList(0).pm.mediaSettings.config \
    -szCodecName           "G729B" \
    -szCodecDetails        "BF22PT20" \
    -bModifyPowerLevel		0 \
    -bUseJitter				0 \
	-bUseMOS				0
$clnt_traffic2 agentList(0).pm.mediaSettings.audioClipsTable.appendItem  \
        -szWaveName 		"pcmlinear.wav" \
        -szDataFormat 		"PCM" \
        -nSampleRate 		8000 \
        -nResolution 		16 \
        -nChannels 			1 \
        -nDuration 			4756 \
        -nSize 				76154

$clnt_traffic2 agentList(0).pm.scenarios.appendItem \
     -id                    "ReceiveCall"

$clnt_traffic2 agentList(0).pm.scenarios.appendItem \
    -id                    "VOICESESSION"
    
$clnt_traffic2 agentList(0).pm.scenarios(1).config \
	-szAudioFile           "pcmlinear.wav" \
	-nPlayMode				1	\
	-nRepeatCount			1	\
	-nPlayTime				30	\
	-nTimeUnit				0 \
	-nTotalTime				30000 \
	-nSessionType			0 \
	-nWavDuration			4756

     
$clnt_traffic2 agentList(0).pm.scenarios.appendItem \
     -id                    "EndCall"





#-----------------------------------------------------------------------
# Create a client and server mapping and bind into the
# network and traffic that they will be employing
#-----------------------------------------------------------------------
set clnt_t_n_mapping1 [::IxLoad new ixClientTrafficNetworkMapping \
    -network                $clnt_network1 \
    -traffic                $clnt_traffic1 \
    -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
    -objectiveValue         100 \
    -standbyTime            130 \
    -rampUpValue            100 \
    -sustainTime            320 \
    -rampDownTime           320

]

set clnt_t_n_mapping2 [::IxLoad new ixClientTrafficNetworkMapping \
    -network                $clnt_network2 \
    -traffic                $clnt_traffic2 \
    -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
    -objectiveValue         100 \
    -standbyTime            10 \
    -rampUpValue            100 \
    -sustainTime            320 \
    -rampDownTime           220

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
    -statsRequired  0 \
    -enableResetPorts 0 \
    -enableForceOwnership 1 \
]

$test clientCommunityList.appendItem -object $clnt_t_n_mapping1
$test clientCommunityList.appendItem -object $clnt_t_n_mapping2
$test serverCommunityList.appendItem -object $svr_t_n_mapping

#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]
$testController setResultDir "[pwd]/RESULTS/simplemgcpclientandserver"

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
    -statSourceType "MGCP Client" \
    -statName "MGCP Simulated Users" \
    -aggregationType $aggregation_type \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_2" \
    -statSourceType "MGCP Client" \
    -statName "MGCP connections initiated" \
    -aggregationType $aggregation_type \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_3" \
    -statSourceType "MGCP Client" \
    -statName "MGCP connections completed" \
    -aggregationType $aggregation_type \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_4" \
    -statSourceType "MGCP Client" \
    -statName "RTP Packets Sent" \
    -aggregationType $aggregation_type \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_4" \
    -statSourceType "MGCP Client" \
    -statName "RTP Packets Received" \
    -aggregationType $aggregation_type \
    -filterList {}
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
::IxLoad delete $clnt_network1
::IxLoad delete $clnt_network2
::IxLoad delete $svr_network
::IxLoad delete $clnt_traffic1
::IxLoad delete $clnt_traffic2
::IxLoad delete $svr_traffic
::IxLoad delete $clnt_t_n_mapping1
::IxLoad delete $clnt_t_n_mapping2
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

