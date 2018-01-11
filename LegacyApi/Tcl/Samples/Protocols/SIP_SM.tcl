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
set logName  "simplesipclientandserver"
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
	-name                                    "ip-1" \
	-gatewayAddress                          "0.0.0.0" \
	-prefix                                  16 \
	-mss                                     100 \
	-ipAddress                               "198.18.0.1" 

set mac_1 [$ip_1 getLowerRelatedRange "MacRange"]

$mac_1 config \
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
	-name                                    "ip-2" \
	-gatewayAddress                          "0.0.0.0" \
	-prefix                                  16 \
	-ipAddress                               "198.18.0.101" 

set mac_2 [$ip_2 getLowerRelatedRange "MacRange"]

$mac_2 config \
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

#---------------------------------------------------------------------------------------------------------
#pm.mediaSettings.config
#
#Configuring codec and codec settings:
#-szCodecName - defines the codec to be used for RTP streams and can have the following values:
#	"G711ALaw" - for G.711 A-law
#	"G711ULaw" - for G.711 mu-law
#	"G729A"  - for G.729A
#	"G729B"  - for G.729B
#	"G726"   - for G.726
#	"G723_1" - for G.723.1
#	"AMR"    - for AMR
#	"iLBC"   - for ILBC
#-szBitRate - defines the bit rate for the codec being used. Depending on the codec the following values are valid:
#	G711Alaw	"64 kbps"
#	G711Ulaw	"64 kbps"
#	G723.1		"5.3 kbps", "6.3 kbps"
#	G726		"40 kbps"
#	G729A		"8 kbps"
#	G729B		"8 kbps"
#	AMR		"4.75 kbps", "5.15 kbps", "5.9 kbps", "6.7 kbps", "7.4 kbps", "7.95 kbps", "10.2 kbps", "12.2 kbps"
#	iLBC		"13.33 kbps", "15.2 kbps"
#-szCodecDetails - defines the codec details and has the following format:
#	BF<val1>PT<val2>
#   - <val1> represents number of codec bytes per frame
#   - <val2> represents the packet time
#  The possible values for <val1> and <val2> depend on codec type and bitrate
#
#Silence generation options:
#-bUseSilence - specifies if silence generation should be used (value 1) or not (value 0)
#-bSilenceMode - specifies the type of silence:
#	0 - Comfort Noise
#	1 - NULL data encoded using the configured codec
#---------------------------------------------------------------------------------------------------------
$clnt_traffic agentList(0).pm.mediaSettings.config \
    -szCodecName           "G711ALaw" \
    -szCodecDetails        "BF160PT20" \
    -bModifyPowerLevel     0 \
    -szPowerLevel          "PL_20" \
    -nJitterBuffer         1 \
    -bUseSilence           1 \
    -bSilenceMode          1 \
    -bRtpStartCollector    0


$clnt_traffic agentList(0).pm.scenarios.appendItem \
     -id                     "ORIGINATECALL" \
     -symDestination         "198.18.0.101:5060"

$clnt_traffic agentList(0).pm.scenarios.appendItem \
     -id                     "VOICESESSION" \
     -szAudioFile            "speech.wav" \
     -nPlayMode              1 \
     -nRepeatCount           1 \
     -nPlayTime              1 \
     -nTimeUnit              0


#---------------------------------------------------------------------------------------------------------
#The GENERATEMF comand has the following possible paramters:
#-szMfSeq - the sequence of MF digits to be generated
#-nMfDuration - the duration of a MF digit; value range [10 990]
#-nInterMfInterval - the silence between the MF digits; value range [10 9990]
#-nMfAmplitude - the amplitude of the signal generated by the sending sequence; value range [-30 -10]
#-nPlayMode - the pley mode; possible values: 0 - generate fo a specified period of time
#					      1 - repeat for a specified number of times
#-nRepeatCount - number of times to repeat the generation of the sequence
#-nPlayTime - the time units to plays the specified sequence
#-nTimeUnit - time unit type; possible values: 0 - seconds
#					       1 - minutes
#					       2 - hours
#					       3 - days
#---------------------------------------------------------------------------------------------------------
$clnt_traffic agentList(0).pm.scenarios.appendItem \
     -id                     "GENERATEMF" \
     -szMfSeq                12345 \
     -nMfDuration            200 \
	 -szCodecDetails        "BF160PT20"
     -nInterMfInterval       40 \
     -nMfAmplitude           -10 \
     -nPlayMode              1 \
     -nRepeatCount           1 \
     -nPlayTime              30 \
     -nTimeUnit              0

#---------------------------------------------------------------------------------------------------------
#The GENERATETONE comand has the following possible paramters:
#-nToneName - the id for the tone
#		possible values: 0 - "600-10"
#     				 1 - "1400-10"
#				 2 - "2500-10"
#				 3 - "550-20"
#				 4 - "1350-20"
#				 5 - "2450-20"
#				 6 - "650-30"
#				 7 - "2550-30"
#				 8 - "1450-30"
#				 9 - "3400-10"
#				 10 - "3400-30"
#				 11 - "2100-10"
#				 12 - "2150-30"
#				 13 - "400-10"
#				 14 - "450-30"
#				 15 - "Confirmation Tone"
#				 16 - "Call Waiting Tone"
#				 17 - "TN_1"
#				 -1 -"Custom Tone"
#
#-nPlayMode - the pley mode; possible values: 0 - generate fo a specified period of time
#					      1 - repeat for a specified number of times
#-nRepeatCount - number of times to repeat the generation of the sequence
#-nPlayTime - the time units to plays the specified sequence
#-nTimeUnit - time unit type; possible values: 0 - seconds
#					       1 - minutes
#					       2 - hours
#					       3 - days
#-nToneDuration - the duration of a tone with only one frequency
#-nFrequency1 - first frequency
#-nFrequency2 - second frequency
#-nAmplitude1 - first amplitude
#-nAmplitude2 - second amplitude
#-nOnTime - nOnTime must be equal to nToneDuration
#-nOffTime - the duration of silence 
#-nRepetitionCount - the number of repetition for the specified tone
#-nToneType - the tone type; possible values: 	0 -"Single Tone"
#						1 - "Dual Tone"
#						2 - "Single Tone Cadence"
#						3 - "Dual Tone Cadence"
#---------------------------------------------------------------------------------------------------------
$clnt_traffic agentList(0).pm.scenarios.appendItem \
     -id                     "GENERATETONE" \
     -nToneName              0 \
     -nToneDuration          100 \
     -nFrequency1            615 \
     -nFrequency2            0 \
     -nAmplitude1            -10 \
     -nAmplitude2            0 \
     -nOnTime                100 \
     -nOffTime               0 \
     -nRepetitionCount       1 \
     -nToneType              0 \
     -nPlayMode              1 \
     -nRepeatCount           1 \
     -nPlayTime              30 \
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
    -name           "simplesiptest" \
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
$testController setResultDir "[pwd]/RESULTS/simplesipclientandserver"

$testController run $test -autorepository "test.rxf"

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

