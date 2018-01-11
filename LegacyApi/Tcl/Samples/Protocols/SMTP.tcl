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
$ixAppPluginManager load "SMTP"

#
# setup logger
#
set logtag "IxLoad-api"
set logName "simplesmtpclientandserver"
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
    -gateway        "0.0.0.0" \
    -firstMac       "00:C6:12:02:01:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
    -vlanEnable     0 \
    -vlanId         1 \
    -mssEnable      0 \
    -mss            100
$clnt_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)

set svr_network [::IxLoad new ixServerNetwork $chassisChain]
$svr_network config -name "svr_network"
$svr_network networkRangeList.appendItem \
    -name           "svr_range" \
    -enable         1 \
    -firstIp        "198.18.200.1" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        1 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0" \
    -firstMac       "00:C6:12:02:02:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
    -vlanEnable     0 \
    -vlanId         1 \
    -mssEnable      0 \
    -mss            100

# Add port to server network
$svr_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)


#-----------------------------------------------------------------------
# Construct Client Traffic
#-----------------------------------------------------------------------
set expected "clnt_traffic"
set clnt_traffic [::IxLoad new ixClientTraffic -name $expected]

$clnt_traffic agentList.appendItem \
    -name               "my_smtp_client" \
    -protocol           "SMTP" \
    -type               "Client" \
    -commandTimeout     120 

$clnt_traffic agentList(0).mailMessageList.appendItem \
    -name           "my_simple_mail_message" \
    -description    "100 bytes plain text body" \
    -bodyFormat     $::MailMessage(kBodyFormatPlainText) \
    -bodySizeType   $::MailMessage(kBodySizeTypeFixed) \
    -bodySizeFixed  100

$clnt_traffic agentList(0).mailMessageList(0).headerList(0).config \
    -data "From:fromName@company.com"
$clnt_traffic agentList(0).mailMessageList(0).headerList(1).config \
    -data "To:toName@company.com"
$clnt_traffic agentList(0).mailMessageList(0).headerList(2).config \
    -data [format "%s:%s" $::MailHeader(kSubjectName) $::MailHeader(kSubjectDefault)]

$clnt_traffic agentList(0).mailMessageList(0).attachmentList.appendItem \
    -type       $::MailAttachment(kGeneratedData) \
    -dataType   $::MailAttachment(kPlainText) \
    -sizeMin    1024 \
    -sizeMax    4096 \
    -countMin   1 \
    -countMax   3 \
    -fileName   "attachment.txt"

$clnt_traffic agentList(0).commandList.appendItem \
    -command        $::SmtpCommand(kSend) \
    -mailMessage    "my_simple_mail_message: 100 bytes plain text body" \
    -destination    "svr_traffic_my_smtp_server:25" 

#-----------------------------------------------------------------------
# Construct Server Traffic
#-----------------------------------------------------------------------
set expected "svr_traffic"
set svr_traffic [::IxLoad new ixServerTraffic -name $expected]
set actual [$svr_traffic cget -name]
$svr_traffic agentList.appendItem \
    -name                   "my_smtp_server" \
    -protocol               "SMTP" \
    -type                   "Server" \
    -concurrentSessionLimit [expr $::SMTP_Server(kConcurrentSessionLimitDefault)/100]   ;# 10000/100


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
    -statsRequired  0 
]

$test clientCommunityList.appendItem -object $clnt_t_n_mapping
$test serverCommunityList.appendItem -object $svr_t_n_mapping

#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]

foreach helloType {Ehlo Helo} {
    set resultDir "RESULTS/simplesmtpclientandserver_${helloType}_"      
    $testController setResultDir $resultDir

    set helloType [format "kHelloType%s" $helloType]
    $clnt_traffic agentList(0).config \
        -helloType      $::SMTP_Client($helloType)

    $testController run $test
    
    vwait ::ixTestControllerMonitor
    puts $::ixTestControllerMonitor

}


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


