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

for {set range 0} {$range < 1} {incr range} {

      set vlanID 22
      set mac "00"
      set mac [format %02x $mac]

      if {[string length $mac] > 2} {
         set mac [string range $mac 1 end]
      }

      if {$vlanID == 22} {
         set vlanID 23
      } else {
         set vlanID 22
      }

      $clnt_network networkRangeList.appendItem \
          -name           "clnt_range" \
          -enable         1 \
          -ipCount        100 \
          -firstMac       "00:${mac}:12:02:01:00" \
          -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
          -rangeType      $::ixIP(kDHCP)  \
          -enableStats    1 \
          -vlanEnable     1  \
          -vlanId         $vlanID \
          -vlanCount      1 \
          -vlanIncrStep   1 \
          -vlanPriority   1



      $clnt_network networkRangeList($range).dhcpParameters.config \
          -firstServerReply       True \
          -serverIp               "222.222.22.1" \
          -timeout                60 \
          -maxOutstandingRequests 1000 \
          -maxClientsPerSecond    100  \
          -packetForwardMode      1    \
          -firstRelayIp           "220.22.0.1/8" \
          -raServerIp             "220.22.201.222" \
          -numRelayAgents         100  \
          -vlanEnable             1 \
          -vlanId                 22 \
          -vlanCount              1 \
          -vlanIncrStep           1 \


}



$clnt_network arpSettings.config -gratuitousArp 0
$clnt_network impairment.config -typeOfService 255 \
                                -enable 1

$clnt_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)

set svr_network [$repository serverNetworkList.addItem \
                             -name "svr_network"]


for {set range 0} {$range < 1} {incr range} {

      set vlanID 22
      set mac "00"
      set mac [format %02x $mac]

      if {[string length $mac] > 2} {
         set mac [string range $mac 1 end]
      }

      if {$vlanID == 22} {
         set vlanID 23
      } else {
         set vlanID 22
      }

      $svr_network networkRangeList.appendItem \
          -name           "svr_range" \
          -enable         1 \
          -ipCount        5 \
          -firstMac       "00:EE:${mac}:02:01:00" \
          -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
          -rangeType      "$::ixIP(kDHCP)"  \
          -enableStats    1 \
          -vlanEnable     1  \
          -vlanId         $vlanID \
          -vlanCount      1 \
          -vlanIncrStep   1 \
          -vlanPriority   1




      $svr_network networkRangeList($range).dhcpParameters.config \
          -firstServerReply       True \
          -serverIp               "10.0.0.1" \
          -timeout                60 \
          -maxOutstandingRequests 1000 \
          -maxClientsPerSecond    300 \
          -packetForwardMode      1    \
          -firstRelayIp           "220.22.1.1/8" \
          -raServerIp             "220.22.201.222" \
          -numRelayAgents         100  \
          -vlanEnable             1 \
          -vlanId                 22 \
          -vlanCount              1 \
          -vlanIncrStep           1 \



}

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

$testController setResultDir "RESULTS/simplehttpclientandserver-ipdhcprelay"



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
