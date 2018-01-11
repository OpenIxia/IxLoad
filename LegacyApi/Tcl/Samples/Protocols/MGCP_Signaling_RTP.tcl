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
set clnt_network1 [::IxLoad new ixClientNetwork $chassisChain]
$clnt_network1 config -name "clnt_network1"
$clnt_network1 networkRangeList.appendItem \
    -name           "clnt_range" \
    -enable         1 \
    -firstIp        "198.5.0.1" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        7500 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0" \
    -firstMac       "00:AC:13:00:01:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetFifth) \
    -vlanEnable     0 \
    -vlanId         1 \
    -mssEnable      0 \
    -mss            100

$clnt_network1 portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID) \
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)

set clnt_network2 [::IxLoad new ixClientNetwork $chassisChain]
$clnt_network2 config -name "clnt_network2"
$clnt_network2 networkRangeList.appendItem \
    -name           "clnt_range" \
    -enable         1 \
    -firstIp        "198.5.30.1" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        7500 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0" \
    -firstMac       "00:AC:13:1D:4D:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetFifth) \
    -vlanEnable     0 \
    -vlanId         1 \
    -mssEnable      0 \
    -mss            100

$clnt_network2 portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::port3(CARD_ID) \
    -portId     $::IxLoadPrivate::SimpleSettings::port3(PORT_ID)

set svr_network [::IxLoad new ixServerNetwork $chassisChain]
$svr_network config -name "svr_network"
$svr_network networkRangeList.appendItem \
    -name           "svr_range" \
    -enable         1 \
    -firstIp        "198.5.100.101" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        1 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0" \
    -firstMac       "00:AC:13:64:65:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetFifth) \
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
$testController setResultDir "RESULTS/simplemgcpclientandserver"

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

