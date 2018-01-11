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
$ixAppPluginManager load "HTTP"

#
# setup logger
#
set logtag "IxLoad-api"
set logName "simplehttpclientandserver-ipdhcprelay"
set logger [::IxLoad new ixLogger $logtag 1]
set logEngine [$logger getEngine]
$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
$logEngine setFile $logName 2 256 1

set repository [::IxLoad new ixRepository]
#-----------------------------------------------------------------------
# package require the stat collection utilities
#-----------------------------------------------------------------------
package require statCollectorUtils
set scu_version [package require statCollectorUtils]
puts "statCollectorUtils package version = $scu_version"

#-----------------------------------------------------------------------
# Build Chassis Chain
#-----------------------------------------------------------------------
set chassisChain [$repository cget -chassisChain]
$chassisChain addChassis $::IxLoadPrivate::SimpleSettings::chassisName


#-----------------------------------------------------------------------
# Build client and server Network
#-----------------------------------------------------------------------
set clnt_network [$repository clientNetworkList.addItem \
                              -name "clnt_network"]

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

set DHCP_1 [::IxLoad new ixNetDHCPPlugin]
# ixNet objects needs to be added in the list before they are configured!
$MAC_VLAN_1 childrenList.appendItem -object $DHCP_1

$DHCP_1 config \
	-name                                    "DHCP-1" 

$DHCP_1 childrenList.clear

$DHCP_1 extensionList.clear

set Impair_1 [::IxLoad new ixNetImpairPlugin]
# ixNet objects needs to be added in the list before they are configured!
$DHCP_1 extensionList.appendItem -object $Impair_1

$Impair_1 config \
	-name                                    "Impair-1" 

$MAC_VLAN_1 extensionList.clear

$Ethernet__PHY_1 extensionList.clear

#################################################
# Setting the ranges starting with the plugin on top of the stack
#################################################
$DHCP_1 rangeList.clear

set dhcp_1 [::IxLoad new ixNetDHCPRange]
# ixNet objects needs to be added in the list before they are configured!
$DHCP_1 rangeList.appendItem -object $dhcp_1

set DefaultOptionSet [::IxLoad new ixNetDHCPOptionSet]
$DefaultOptionSet config \
	-name                                    "DefaultOptionSet" \
	-defaultp                                true 

$DefaultOptionSet optionTlvs.clear

$dhcp_1 config \
	-dhcp6IaT1                               2000 \
	-relayFirstAddress                       "220.22.0.1" \
	-dhcp6ParamRequestList                   "2;7;23;24" \
	-suboption6FirstAddress                  "11.0.1.1" \
	-relayRemoteId                           "Ixia-host-\[0000-\]" \
	-relayCircuitId                          "123\[000-999\]" \
	-relayOverrideVlanSettings               true \
	-dhcp4ServerAddress                      "222.222.22.1" \
	-vendorClassId                           "MSFT 5.0" \
	-relay6OptInterfaceId                    "Ixia-host-\[0000-\]" \
	-relayDestination                        "220.22.201.222" \
	-suboption6AddressSubnet                 8 \
	-count                                   100 \
	-name                                    "dhcp-1" \
	-relayGateway                            "0.0.0.0" \
	-relayFirstVlanId                        22 \
	-dhcp4ParamRequestList                   "1;3;58;59" \
	-clientOptionSet                         $DefaultOptionSet 

set impair_1 [$dhcp_1 getExtensionRange $Impair_1]

set clnt_network_CustomProfile1 [::IxLoad new ixNetImpairProfile]
$clnt_network_CustomProfile1 config \
	-typeOfService                           "0xff" \
	-addDelay                                false \
	-bandwidthUnitsIn                        "kbit" \
	-name                                    "clnt_network-CustomProfile1" \
	-bandwidthUnits                          "kbit" 

$impair_1 config \
	-enabled                                 true \
	-name                                    "impair-1" \
	-profile                                 $clnt_network_CustomProfile1 

set mac_1 [$dhcp_1 getLowerRelatedRange "MacRange"]

$mac_1 config \
	-count                                   100 \
	-mac                                     "00:00:12:02:01:00" \
	-name                                    "mac-1" 

set vlan_1 [$dhcp_1 getLowerRelatedRange "VlanIdRange"]

$vlan_1 config \
	-enable                                  true \
	-name                                    "vlan-1" \
	-idIncrMode                              1 \
	-firstId                                 23 \
	-innerPriority                           0 


$clnt_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)

set svr_network [$repository serverNetworkList.addItem \
                             -name "svr_network"]

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

set DHCP_2 [::IxLoad new ixNetDHCPPlugin]
# ixNet objects needs to be added in the list before they are configured!
$MAC_VLAN_2 childrenList.appendItem -object $DHCP_2

$DHCP_2 config \
	-name                                    "DHCP-2" 

$DHCP_2 childrenList.clear

$DHCP_2 extensionList.clear

$MAC_VLAN_2 extensionList.clear

$Ethernet__PHY_2 extensionList.clear

#################################################
# Setting the ranges starting with the plugin on top of the stack
#################################################
$DHCP_2 rangeList.clear

set dhcp_2 [::IxLoad new ixNetDHCPRange]
# ixNet objects needs to be added in the list before they are configured!
$DHCP_2 rangeList.appendItem -object $dhcp_2

set DefaultOptionSet [::IxLoad new ixNetDHCPOptionSet]
$DefaultOptionSet config \
	-name                                    "DefaultOptionSet" \
	-defaultp                                true 

$DefaultOptionSet optionTlvs.clear

$dhcp_2 config \
	-dhcp6IaT1                               2000 \
	-relayFirstAddress                       "220.22.1.1" \
	-dhcp6ParamRequestList                   "2;7;23;24" \
	-suboption6FirstAddress                  "11.0.1.1" \
	-relayRemoteId                           "Ixia-host-\[0000-\]" \
	-relayCircuitId                          "123\[000-999\]" \
	-relayOverrideVlanSettings               true \
	-vendorClassId                           "MSFT 5.0" \
	-relay6OptInterfaceId                    "Ixia-host-\[0000-\]" \
	-relayDestination                        "220.22.201.222" \
	-suboption6AddressSubnet                 8 \
	-count                                   5 \
	-name                                    "dhcp-2" \
	-relayGateway                            "0.0.0.0" \
	-relayFirstVlanId                        22 \
	-dhcp4ParamRequestList                   "1;3;58;59" \
	-clientOptionSet                         $DefaultOptionSet 

set mac_2 [$dhcp_2 getLowerRelatedRange "MacRange"]

$mac_2 config \
	-count                                   5 \
	-mac                                     "00:EE:00:02:01:00" \
	-name                                    "mac-2" 

set vlan_2 [$dhcp_2 getLowerRelatedRange "VlanIdRange"]

$vlan_2 config \
	-enable                                  true \
	-name                                    "vlan-2" \
	-idIncrMode                              1 \
	-firstId                                 23 \
	-innerPriority                           0 


$svr_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)


#-----------------------------------------------------------------------
# Construct Client Traffic
# The ActivityModel acts as a factory for creating agents which actually
# generate the test traffic
#-----------------------------------------------------------------------
set clnt_traffic [$repository clientTrafficList.addItem  -name "client_traffic"]

$clnt_traffic agentList.appendItem \
    -name                   "my_http_client" \
    -protocol               "HTTP" \
    -type                   "Client" \
    -maxSessions            3 \
    -httpVersion            $::HTTP_Client(kHttpVersion10) \
    -keepAlive              0 \
    -maxPersistentRequests  3 \
    -followHttpRedirects    0 \
    -enableCookieSupport    0 \
    -enableHttpProxy        0 \
    -enableHttpsProxy       0 \
    -browserEmulation       $::HTTP_Client(kBrowserTypeIE5) \
    -enableSsl              0

#
# Add actions to this client agent
#
foreach {pageObject destination} {
    "/4k.htm" "svr_traffic_my_http_server"
    "/8k.htm" "svr_traffic_my_http_server"
} {
    $clnt_traffic agentList(0).actionList.appendItem  \
        -command        "GET" \
        -destination    $destination \
        -pageObject     $pageObject
}



#-----------------------------------------------------------------------
# Construct Server Traffic
#-----------------------------------------------------------------------
set svr_traffic [$repository serverTrafficList.addItem -name "svr_traffic"]

$svr_traffic agentList.appendItem \
    -name       "my_http_server" \
    -protocol   "HTTP" \
    -type       "Server" \
    -httpPort   80

for {set idx 0} {$idx < [$svr_traffic agentList(0).responseHeaderList.indexCount]} {incr idx} {
    set response [$svr_traffic agentList(0).responseHeaderList.getItem $idx]
    if {[$response cget -name] == "200_OK"} {
        set response200ok $response
    }
    if {[$response cget -name] == "404_PageNotFound"} {
        set response404_PageNotFound $response
    }
}

#
# Clear pre-defined web pages, add new web pages
#
$svr_traffic agentList(0).webPageList.clear

$svr_traffic agentList(0).webPageList.appendItem \
    -page           "/4k.html" \
    -payloadType    "range" \
    -payloadSize    "4096-4096" \
    -response       $response200ok

$svr_traffic agentList(0).webPageList.appendItem \
    -page           "/8k.html" \
    -payloadType    "range" \
    -payloadSize    "8192-8192" \
    -response       $response404_PageNotFound



#-----------------------------------------------------------------------
# Create the test and bind in the network-traffic mapping it is going
# to employ.
#-----------------------------------------------------------------------
set test [$repository testList.addItem \
    -name               "my_test" \
    -statsRequired      0 \
    -enableForceOwnership 1 \
    -enableResetPorts   0
]

#-----------------------------------------------------------------------
# Create a client and server mapping and bind into the
# network and traffic that they will be employing
#-----------------------------------------------------------------------
set clnt_t_n_mapping [::IxLoad new ixClientTrafficNetworkMapping \
    -network                $clnt_network \
    -traffic                $clnt_traffic \
    -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
    -objectiveValue         100 \
    -rampUpValue            5 \
    -sustainTime            80 \
    -rampDownTime           20
]


#
# Set objective type, value and port map for client activity
#
$clnt_t_n_mapping setObjectiveTypeForActivity "my_http_client" $::ixObjective(kObjectiveTypeConnectionRate)
$clnt_t_n_mapping setObjectiveValueForActivity "my_http_client" 200
$clnt_t_n_mapping setPortMapForActivity "my_http_client" $::ixPortMap(kPortMapFullMesh)


set svr_t_n_mapping [::IxLoad new ixServerTrafficNetworkMapping \
    -network                $svr_network \
    -traffic                $svr_traffic \
    -matchClientTotalTime   1
]



$test clientCommunityList.appendItem -object $clnt_t_n_mapping
$test serverCommunityList.appendItem -object $svr_t_n_mapping


#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]

$testController setResultDir "[pwd]/RESULTS/simplehttpclientandserver-ipdhcprelay"



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
set ::StatList [list \
        "HTTP Bytes Sent" \
        "HTTP Bytes Received" \
]


set aggregation_type "kSum"

set cnt 1
foreach statitem $::StatList {
        set caption [format "Watch_Stat_%s" $cnt]

        ${NS}::AddStat \
                -caption            $caption \
                -statSourceType     "HTTP Client" \
                -statName           $statitem \
                -aggregationType    $aggregation_type \
                -filterList         {}
       incr cnt
}

#
# Start the collector (runs in the tcl event loop)
#
proc ::my_stat_collector_command {args} {
    puts stderr "====================================="
    puts stderr "INCOMING STAT RECORD"
    array set statlist [lindex $args end]
    array set stat {};
    set str ""
    for {set id 0} {$id < [llength $::StatList]} {incr id} {
        set stat($id) [lindex [lindex $statlist(stats) $id] 1]
        set statName [lindex $::StatList $id]
        append str "$statName = $stat($id)"
        if {[expr $id + 1] != [llength $::StatList]} {
           append str "\n"
        }
    }
    puts stderr "$str"
    puts stderr "====================================="
}

${NS}::StartCollector -command ::my_stat_collector_command

$testController run $test -autorepository dhcp_relay.rxf
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

$testController generateReport -detailedReport 1

$testController releaseConfigWaitFinish
::IxLoad delete $chassisChain
::IxLoad delete $clnt_network
::IxLoad delete $svr_network
::IxLoad delete $clnt_traffic
::IxLoad delete $svr_traffic
::IxLoad delete $clnt_t_n_mapping
::IxLoad delete $svr_t_n_mapping
::IxLoad delete $test
::IxLoad delete $testController
::IxLoad delete $logger
::IxLoad delete $logEngine
::IxLoad delete $repository


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
