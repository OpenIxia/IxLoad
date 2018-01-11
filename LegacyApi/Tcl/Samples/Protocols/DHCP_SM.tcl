#
# setup path and load IxLoad package
#
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
$ixAppPluginManager load "dhcp"

# package require statCollectorUtils
#
# setup logger
#
set logtag "IxLoad-api"
set logName "simpledhcpclient" 
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
# Build client Network
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
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID) \
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)


#-----------------------------------------------------------------------
# Construct Client Traffic
#-----------------------------------------------------------------------
set expected "clnt_traffic"
set clnt_traffic [::IxLoad new ixClientTraffic -name $expected]

$clnt_traffic agentList.appendItem \
    -name               "my_dhcp_client" \
    -protocol           "dhcp" \
    -type               "Client"

# Populate the Advanced Options
#-----------------------------------------------------
$clnt_traffic agentList(0).pm.advancedOptions.config \
              -clientPort       12 \
              -serverPort       67 \
              -numRetransmit     1 \
              -initialTimeout    2 \
              -timeoutIncrFactor 1 \
              -maxDHCPMsgSize    576 \
              -vendorClass       "Something" \
              -optionsOverload   0 \
              -broadcastBit      0


# Populate the user defined Options
$clnt_traffic agentList(0).pm.optionSetMgr.optionSetList.appendItem \
              -name "Options   For    discover"

# Get the last index'th option list
set LastIndex [$clnt_traffic agentList(0).pm.optionSetMgr.optionSetList.indexCount]
incr LastIndex -1
# Configure the index 'th option set
set OptionListParameter [list \
      RequestedIPAddress clientIPAddr 11.0.0.1/16 \
      IPAddressLeaseTime interval  2500 \
      DHCPRenewalTime interval 1 \
      DHCPRebindingTime interval 100 \
      VendorClassIdentifier data "jashdjgfasghfsagh" \
      ClientIdentifier identifier 11111 \
      SubnetMaskValue mask 255.255.255.0 \
      TimeOffsetUTC  offset 8 \
      HostnameString hostName dhcp \
      DNSDomainNameClient domainName calakol \
      InterfaceMTUSize size  444 \
      SubnetsLocal val 1 \
      BroadcastAddress address 10.222.3.2 \
      PerformMaskDiscovery val 1 \
      PerformRouterDiscovery val 0 \
      ARPCacheTimeOut timeout 8 \
      VendorSpecificInfo info "xyz " \
      UserClassInfo  info "aaas sdf" \
]

set ipAddrList [list \
    "198.18.0.1" \
    "10.205.17.71" \
    "10.205.17.176" \
    "198.18.0.101" \
]

set OptionListParameter_Router_DNS [list \
    RouterAddresses addresses \
    DNSServerAddresses addresses \
]

foreach {option id val} $OptionListParameter {
        $clnt_traffic agentList(0).pm.optionSetMgr.optionSetList($LastIndex).optionsList.appendItem \
              -id $option \
              -$id $val
}

foreach {option id} $OptionListParameter_Router_DNS {
        $clnt_traffic agentList(0).pm.optionSetMgr.optionSetList($LastIndex).optionsList.appendItem \
              -id $option
        set index [$clnt_traffic agentList(0).pm.optionSetMgr.optionSetList($LastIndex).optionsList.indexCount]
        incr index -1

        foreach ip $ipAddrList {
             $clnt_traffic agentList(0).pm.optionSetMgr.optionSetList($LastIndex).optionsList($index).${id}.appendItem \
                   -address $ip
        }
}

# Populate the command list
#-----------------------------------------------------
$clnt_traffic agentList(0).pm.DHCPCommandList.appendItem \
        -id        "DHCPDiscover"               \
        -optionSet "Options   For    discover"  \
        -serverAlgo 1

# Populate the Expected Options
#-----------------------------------------------------
# TODO


#-----------------------------------------------------------------------
# Create a client mapping and bind into the
# network and traffic that they will be employing
#-----------------------------------------------------------------------
set clnt_t_n_mapping [::IxLoad new ixClientTrafficNetworkMapping \
    -network                $clnt_network \
    -traffic                $clnt_traffic \
    -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
    -objectiveValue         1 \
    -rampUpValue            1 \
    -sustainTime            120 \
    -rampDownTime           20  \
]

#-----------------------------------------------------------------------
# Create the test and bind in the network-traffic mapping it is going
# to employ.
#-----------------------------------------------------------------------
set test [::IxLoad new ixTest \
    -name           "my_test" \
    -statsRequired  0 \
    -enableForceOwnership 1 \
    -enableResetPorts 1 \
]

$test clientCommunityList.appendItem -object $clnt_t_n_mapping


#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]


$testController setResultDir "[pwd]/RESULTS/simpledhcpclient" 
#-----------------------------------------------------------------------
# Set up stat Collection
#-----------------------------------------------------------------------
$testController run $test
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
