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
set logName "simplehttpclientandserver-ipsec"
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
set clnt_network [::IxLoad new ixClientNetwork $chassisChain]
$clnt_network config -name "clnt_network"
$clnt_network networkRangeList.appendItem \
    -name           "clnt_range" \
    -enable         1 \
    -firstIp        "150.0.0.1" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        100 \
    -networkMask    "255.255.0.0" \
    -rangeType      $::ixIP(kIPSec)

$clnt_network networkRangeList(0).ipsecParameters.config \
    -role                       $::ixIpsec(kRoleP2PInitiator) \
    -emulatedSubnet             "140.0.0.0" \
    -emulatedSubnetMask         "255.255.255.0" \
    -protectedSubnet            "170.0.0.0" \
    -protectedSubnetMask        "255.255.255.0" \
    -incrementBy                "0.0.1.0" \
    -peerPublicIp               "160.0.0.1" \
    -emulatedHosts              1 \
    -preSharedKey               "ixload" \
    -ikeMode                    $::ixIpsec(kIkeModeMain) \
    -phase1HashAlgorithm        $::ixIpsec(kHashAlgMd5) \
    -dhGroup                    $::ixIpsec(kDh2) \
    -phase1EncryptionAlgorithm  $::ixIpsec(kEncrAlg3Des) \
    -phase1Lifetime             3600 \
    -ahEspOptions               $::ixIpsec(kAhEspModeEspOnly) \
    -phase2HashAlgorithm        $::ixIpsec(kHashAlgMd5) \
    -pfsGroup                   $::ixIpsec(kDh2) \
    -phase2EncryptionAlgorithm  $::ixIpsec(kEncrAlg3Des) \
    -phase2Lifetime             28800 \
    -enablePfs                  False \
    -numRetries                 0 \
    -retryInterval              10 \
    -retryDelay                 10

$clnt_network config -emulatedRouterGateway "155.0.0.2"
$clnt_network config -emulatedRouterSubnet "255.255.0.0"
$clnt_network config -macMappingMode 1

$clnt_network emulatedRouterIpAddressPool.appendItem \
    -enable         1 \
    -firstIp        "155.0.0.1" \
    -ipCount        1 \
    -firstMac       "00:9B:00:00:01:00"

$clnt_network arpSettings.config -gratuitousArp 0

$clnt_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)

set svr_network [::IxLoad new ixServerNetwork $chassisChain]
$svr_network config -name "svr_network"
$svr_network networkRangeList.appendItem \
    -name           "svr_range" \
    -enable         1 \
    -firstIp        "160.0.0.1" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        100 \
    -networkMask    "255.255.0.0" \
    -rangeType      $::ixIP(kIPSec)

$svr_network networkRangeList(0).ipsecParameters.config \
    -role                       $::ixIpsec(kRoleP2PResponder) \
    -emulatedSubnet             "170.0.0.0" \
    -emulatedSubnetMask         "255.255.255.0" \
    -protectedSubnet            "140.0.0.0" \
    -protectedSubnetMask        "255.255.255.0" \
    -incrementBy                "0.0.1.0" \
    -peerPublicIp               "150.0.0.1" \
    -emulatedHosts              1 \
    -preSharedKey               "ixload" \
    -ikeMode                    $::ixIpsec(kIkeModeMain) \
    -phase1HashAlgorithm        $::ixIpsec(kHashAlgMd5) \
    -dhGroup                    $::ixIpsec(kDh2) \
    -phase1EncryptionAlgorithm  $::ixIpsec(kEncrAlg3Des) \
    -phase1Lifetime             3600 \
    -ahEspOptions               $::ixIpsec(kAhEspModeEspOnly) \
    -phase2HashAlgorithm        $::ixIpsec(kHashAlgMd5) \
    -pfsGroup                   $::ixIpsec(kDh2) \
    -phase2EncryptionAlgorithm  $::ixIpsec(kEncrAlg3Des) \
    -phase2Lifetime             28800 \
    -enablePfs                  False \
    -numRetries                 0 \
    -retryInterval              10 \
    -retryDelay                 10

$svr_network config -emulatedRouterGateway "155.0.0.1"
$svr_network config -emulatedRouterSubnet  "255.255.0.0"
$svr_network config -macMappingMode 1

$svr_network emulatedRouterIpAddressPool.appendItem \
    -enable         1 \
    -firstIp        "155.0.0.2" \
    -ipCount        1 \
    -firstMac       "00:9B:00:00:02:00"

$svr_network arpSettings.config -gratuitousArp 0

# Add port to server network
$svr_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)


#-----------------------------------------------------------------------
# Construct Client Traffic
# The ActivityModel acts as a factory for creating agents which actually
# generate the test traffic
#-----------------------------------------------------------------------
set clnt_traffic [::IxLoad new ixClientTraffic -name "client_traffic"]

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
set svr_traffic [::IxLoad new ixServerTraffic -name "svr_traffic"]

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
$test serverCommunityList.appendItem -object $svr_t_n_mapping


#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]

$testController setResultDir "RESULTS/simplehttpclientandserver-ipsec"

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
    -statSourceType "HTTP Client" \
    -statName "HTTP Bytes Sent" \
    -aggregationType $aggregation_type \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_2" \
    -statSourceType "HTTP Client" \
    -statName "HTTP Bytes Received" \
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
