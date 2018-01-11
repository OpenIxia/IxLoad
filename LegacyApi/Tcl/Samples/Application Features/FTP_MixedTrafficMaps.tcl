#
# mixedtrafficmaps.tcl
#
# This example shows how to setup a different traffic map for each of two symbolic destinations.
# This is not a very practical example unless 6 ports are available because it takes two
# ports to see the different between port pairs and full mesh modes.
#
# client -> server_traffic1_my_ftp_svr  : Full Mesh (client port1 and port2 both go to both traffic1 server ports)
# client -> server_traffic2_my_ftp_svr  : Port Mesh (client port1 -> server_traffic2 port1, client port2 -> server_traffic2 port2)
#
# In any event, this sample does demonstrate the API usage
#

#
# setup path and load IxLoad package
#

source ../setup_simple.tcl

#
# Check number of ports
#
if {$::IxLoadPrivate::SimpleSettings::numPorts < 3} {
    puts "Cannot run mixedtrafficmaps.tcl with fewer than three ports. Skipping."
    exit
}

if {$::IxLoadPrivate::SimpleSettings::numPorts >= 6} {
    puts "Running mixedtrafficmaps.tcl with all features"
} else {
    puts "Running mixedtrafficmaps.tcl with reduced features. Run with 6 or more ports to produce distinct traffic patterns"
}

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
$ixAppPluginManager load "FTP"

#
# setup logger
#
set logtag "IxLoad-api"
set logName "mixedtrafficmaps"
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
set clnt_network [::IxLoad new ixClientNetwork $chassisChain]
$clnt_network config -name "clnt_network"
$clnt_network networkRangeList.appendItem \
    -name           "clnt_range" \
    -enable         1 \
    -firstIp        "198.18.2.1" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        100 \
    -networkMask    "255.255.0.0" \
    -vlanEnable     0 \
    -vlanId         1 \
    -mssEnable      0 \
    -mss            100 \
    -firstMac       "00:C6:12:02:01:00"

$clnt_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)

if {$::IxLoadPrivate::SimpleSettings::numPorts >= 6} {
$clnt_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::port3(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::port3(PORT_ID)
}

set svr_network1 [::IxLoad new ixServerNetwork $chassisChain]
$svr_network1 config -name "svr_network1"
$svr_network1 networkRangeList.appendItem \
    -name           "svr_range" \
    -enable         1 \
    -firstIp        "198.18.100.1" \
    -ipIncrStep     "0.0.0.1" \
    -ipCount        100 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0" \
    -vlanEnable     0 \
    -vlanId         1 \
    -mssEnable      0 \
    -mss            100 \
    -firstMac       "00:C6:12:64:01:00"

# Add port to server network
$svr_network1 portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)

if {$::IxLoadPrivate::SimpleSettings::numPorts >= 6} {
    $svr_network1 portList.appendItem \
	    -chassisId  1 \
	    -cardId     $::IxLoadPrivate::SimpleSettings::port4(CARD_ID)\
	    -portId     $::IxLoadPrivate::SimpleSettings::port4(PORT_ID)

}


set svr_network2 [::IxLoad new ixServerNetwork $chassisChain]
$svr_network2 config -name "svr_network2"
$svr_network2 networkRangeList.appendItem \
    -name           "svr_range" \
    -enable         1 \
    -firstIp        "198.18.200.1" \
    -ipIncrStep     "0.0.0.1" \
    -ipCount        100 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0" \
    -vlanEnable     0 \
    -vlanId         1 \
    -mssEnable      0 \
    -mss            100 \
    -firstMac       "00:C6:12:C8:01:00"

# Add port to server network
if {$::IxLoadPrivate::SimpleSettings::numPorts >= 6} {
    $svr_network2 portList.appendItem \
	    -chassisId  1 \
	    -cardId     $::IxLoadPrivate::SimpleSettings::port5(CARD_ID)\
	    -portId     $::IxLoadPrivate::SimpleSettings::port5(PORT_ID)
    $svr_network2 portList.appendItem \
	    -chassisId  1 \
	    -cardId     $::IxLoadPrivate::SimpleSettings::port6(CARD_ID)\
	    -portId     $::IxLoadPrivate::SimpleSettings::port6(PORT_ID)
} else {
    $svr_network2 portList.appendItem \
	    -chassisId  1 \
	    -cardId     $::IxLoadPrivate::SimpleSettings::port3(CARD_ID)\
	    -portId     $::IxLoadPrivate::SimpleSettings::port3(PORT_ID)
}

#-----------------------------------------------------------------------
# Construct Client FTP Traffic
#-----------------------------------------------------------------------
set expected "clnt_traffic"
set clnt_traffic [::IxLoad new ixClientTraffic -name $expected]


$clnt_traffic agentList.appendItem \
    -name       "my_ftp_client" \
    -protocol   "FTP" \
    -type       "Client" \
    -userName   "root" \
    -password   "noreply@ixiacom.com" \
    -fileList   {'/#64', '/#256', '/#1024', '/#4096'} \
    -mode       $::FTP_Client(kModeActive) \
    -enableEsm  0 \
    -esm        300        

#
# Add actions to this client agent.
#
# One action is a symbolic destination to svr_traffic1, and
# another is a symbolic destination to svr_traffic2
#
$clnt_traffic agentList(0).actionList.appendItem \
                    -command    "GET" \
                    -destination "svr_traffic1_my_ftp_server" \
                    -userName    "root" \
                    -password    "noreply@ixiacom.com" \
                    -arguments   "/#4096"
$clnt_traffic agentList(0).actionList.appendItem \
                    -command    "GET" \
                    -destination "svr_traffic2_my_ftp_server" \
                    -userName    "root" \
                    -password    "noreply@ixiacom.com" \
                    -arguments   "/#4096"
   
#-----------------------------------------------------------------------
# Construct Two Server FTP Traffic elements
#-----------------------------------------------------------------------
set expected "svr_traffic1"
set svr_traffic1 [::IxLoad new ixServerTraffic -name $expected]

#
# Create a server agent
#
$svr_traffic1 agentList.appendItem \
    -name       "my_ftp_server" \
    -protocol   "FTP" \
    -type       "Server" \
    -ftpPort    21 \
    -enableEsm  0 \
    -esm        300

set expected "svr_traffic2"
set svr_traffic2 [::IxLoad new ixServerTraffic -name $expected]

#
# Create another server agent
#
$svr_traffic2 agentList.appendItem \
    -name       "my_ftp_server" \
    -protocol   "FTP" \
    -type       "Server" \
    -ftpPort    21 \
    -enableEsm  0 \
    -esm        300

#-----------------------------------------------------------------------
# Create a client and server mapping and bind into the
# network and traffic that they will be employing
#-----------------------------------------------------------------------
set clnt_t_n_mapping [::IxLoad new ixClientTrafficNetworkMapping \
    -network                $clnt_network \
    -traffic                $clnt_traffic \
    -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
    -objectiveValue         20 \
    -rampUpValue            5 \
    -sustainTime            20 \
    -rampDownTime           20
]
set svr_t_n_mapping1 [::IxLoad new ixServerTrafficNetworkMapping \
    -network                $svr_network1 \
    -traffic                $svr_traffic1 \
    -matchClientTotalTime   1
]
set svr_t_n_mapping2 [::IxLoad new ixServerTrafficNetworkMapping \
    -network                $svr_network2 \
    -traffic                $svr_traffic2 \
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
$test serverCommunityList.appendItem -object $svr_t_n_mapping1
$test serverCommunityList.appendItem -object $svr_t_n_mapping2

#-----------------------------------------------------------------------
# Specify the traffic maps for each symbolic destination to be different
#-----------------------------------------------------------------------

set destination1 [$clnt_t_n_mapping getDestinationForActivity my_ftp_client svr_traffic1_my_ftp_server]
set destination2 [$clnt_t_n_mapping getDestinationForActivity my_ftp_client svr_traffic2_my_ftp_server]

$destination1 config -portMapPolicy $ixPortMap(kPortMapFullMesh)
$destination2 config -portMapPolicy $ixPortMap(kPortMapPortPairs)

#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]

$testController setResultDir "RESULTS/mixedtrafficmaps"

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
::IxLoad delete $svr_network1
::IxLoad delete $svr_network2
::IxLoad delete $clnt_traffic
::IxLoad delete $svr_traffic1
::IxLoad delete $svr_traffic2
::IxLoad delete $clnt_t_n_mapping
::IxLoad delete $svr_t_n_mapping1
::IxLoad delete $svr_t_n_mapping2
::IxLoad delete $destination1
::IxLoad delete $destination2
::IxLoad delete $test
::IxLoad delete $testController

}] {
    puts $errorInfo
}

#
#   Disconnect/Release application lock
#
::IxLoad disconnect
