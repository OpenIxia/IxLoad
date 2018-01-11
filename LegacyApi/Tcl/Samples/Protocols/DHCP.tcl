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


$testController setResultDir "RESULTS/simpledhcpclient" 
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
