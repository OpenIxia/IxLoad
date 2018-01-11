use warnings;use strict;
use lib '.'; use lib '..'; use lib '../lib'; use lib '../../lib';

use setup_simple;
use IxLoad;

#IxLoad::traceTclCalls(1);

IxLoadConnect->connect(remoteServer);

eval {

my $logtag = "IxLoad-api";
my $logName = "HTTP_legacy";
my $logger = IxLoad->new('ixLogger', $logtag, 1);
my $logEngine = $logger->getEngine();
$logEngine->setLevels($IxLoad::Info::ixLogger{kLevelDebug}, $IxLoad::Info::ixLogger{kLevelInfo});
$logEngine->setFile($logName,2,256,1);

IxLoad->pluginManager('load', 'HTTP');

#################################################
# Build chassis chain
#################################################
my $chassisChain = IxLoad->new("ixChassisChain");

$chassisChain->addChassis(chassisName);

my $Test1 = IxLoad->new("ixTest");

my $scenarioElementFactory = $Test1->getScenarioElementFactory();

my $scenarioFactory = $Test1->getScenarioFactory();

#################################################
# Profile Directory
#################################################
my $profileDirectory = $Test1->cget("profileDirectory");

my $my_ixEventHandlerSettings = IxLoad->new("ixEventHandlerSettings");

$my_ixEventHandlerSettings->config();

my $my_ixViewOptions = IxLoad->new("ixViewOptions");

$my_ixViewOptions->config();

$Test1->scenarioList->clear();

my $Scenario1 = $scenarioFactory->create("Scenario");

$Scenario1->columnList->clear();

my $Originate = IxLoad->new("ixTrafficColumn");

$Originate->elementList->clear();

#################################################
# Create ScenarioElement kNetTraffic
#################################################
my $Traffic1_Network1 = $scenarioElementFactory->create($IxLoad::Info::ixScenarioElementType{kNetTraffic});



#################################################
# Network Network1 of NetTraffic Traffic1@Network1
#################################################
my $Network1 = $Traffic1_Network1->cget("network");

my @clientPortList = split('\.', clientPort1);
my $clientChassis = $clientPortList[0];
my $clientCard = $clientPortList[1];
my $clientPort = $clientPortList[2];

$Network1->portList->appendItem({ 
	chassisId                               => $clientChassis, 
	cardId                                  => $clientCard, 
	portId                                  => $clientPort
});

$Network1->globalPlugins->clear();



my $Settings_1 = IxLoad->new("ixNetIxLoadSettingsPlugin");

# ixNet objects need to be added in the list before they are configured!
$Network1->globalPlugins->appendItem({ 
	object                                  => $Settings_1
});



$Settings_1->config();

my $Filter_1 = IxLoad->new("ixNetFilterPlugin");

# ixNet objects need to be added in the list before they are configured!
$Network1->globalPlugins->appendItem({ 
	object                                  => $Filter_1
});



$Filter_1->config();

my $GratARP_1 = IxLoad->new("ixNetGratArpPlugin");

# ixNet objects need to be added in the list before they are configured!
$Network1->globalPlugins->appendItem({ 
	object                                  => $GratARP_1
});



$GratARP_1->config();

my $TCP_1 = IxLoad->new("ixNetTCPPlugin");

# ixNet objects need to be added in the list before they are configured!
$Network1->globalPlugins->appendItem({ 
	object                                  => $TCP_1
});



$TCP_1->config({ 
	tcp_retries2                            => 5, 
	tcp_rto_max                             => 120000, 
	tcp_window_scaling                      => "False", 
	tcp_rto_min                             => 200, 
	tcp_wmem_default                        => 4096, 
	ip_no_pmtu_disc                         => "True", 
	tcp_rmem_default                        => 4096
});

my $DNS_1 = IxLoad->new("ixNetDnsPlugin");

# ixNet objects need to be added in the list before they are configured!
$Network1->globalPlugins->appendItem({ 
	object                                  => $DNS_1
});



$DNS_1->hostList->clear();



$DNS_1->searchList->clear();



$DNS_1->nameServerList->clear();



$DNS_1->config();

$Network1->config({ 
	name                                    => "Network1"
});

my $Ethernet_1 = $Network1->getL1Plugin();



my $my_ixNetDataCenterSettings = IxLoad->new("ixNetDataCenterSettings");

$my_ixNetDataCenterSettings->dcPfcMapping->clear();



$my_ixNetDataCenterSettings->config({ 
	dcMode                                  => 2, 
	dcFlowControl                           => 0
});

my $my_ixNetEthernetELMPlugin = IxLoad->new("ixNetEthernetELMPlugin");

$my_ixNetEthernetELMPlugin->config();

my $my_ixNetDualPhyPlugin = IxLoad->new("ixNetDualPhyPlugin");

$my_ixNetDualPhyPlugin->config();

$Ethernet_1->childrenList->clear();



my $MAC_VLAN_1 = IxLoad->new("ixNetL2EthernetPlugin");

# ixNet objects need to be added in the list before they are configured!
$Ethernet_1->childrenList->appendItem({ 
	object                                  => $MAC_VLAN_1
});



$MAC_VLAN_1->childrenList->clear();



my $IP_1 = IxLoad->new("ixNetIpV4V6Plugin");

# ixNet objects need to be added in the list before they are configured!
$MAC_VLAN_1->childrenList->appendItem({ 
	object                                  => $IP_1
});



$IP_1->childrenList->clear();



$IP_1->extensionList->clear();



$IP_1->config();

$MAC_VLAN_1->extensionList->clear();



$MAC_VLAN_1->config();

$Ethernet_1->extensionList->clear();



$Ethernet_1->config({ 
	dataCenter                              => $my_ixNetDataCenterSettings, 
	cardElm                                 => $my_ixNetEthernetELMPlugin, 
	cardDualPhy                             => $my_ixNetDualPhyPlugin
});

#################################################
# Setting the ranges starting with the plugins that need to be script gen first
#################################################
$IP_1->rangeList->clear();

my $IP_R1 = IxLoad->new("ixNetIpV4V6Range");

# ixNet objects need to be added in the list before they are configured.
$IP_1->rangeList->appendItem({ 
	object                                  => $IP_R1
});



$IP_R1->config({ 
	count                                   => 100, 
	enableGatewayArp                        => "False", 
	randomizeSeed                           => 2901885812, 
	generateStatistics                      => "False", 
	autoIpTypeEnabled                       => "False", 
	autoCountEnabled                        => "False", 
	enabled                                 => "True", 
	autoMacGeneration                       => "True", 
	incrementBy                             => "0.0.0.1", 
	prefix                                  => 16, 
	gatewayIncrement                        => "0.0.0.0", 
	gatewayIncrementMode                    => "perSubnet", 
	mss                                     => 1460, 
	randomizeAddress                        => "False", 
	gatewayAddress                          => "0.0.0.0", 
	ipAddress                               => "10.10.0.1", 
	ipType                                  => "IPv4"
});

my $MAC_R1 = $IP_R1->getLowerRelatedRange("MacRange");

$MAC_R1->config({ 
	count                                   => 100, 
	enabled                                 => "True", 
	mtu                                     => 1500, 
	mac                                     => "00:0A:0A:00:01:00", 
	incrementBy                             => "00:00:00:00:00:01"
});

my $VLAN_R1 = $IP_R1->getLowerRelatedRange("VlanIdRange");

$VLAN_R1->config({ 
	incrementStep                           => 1, 
	innerIncrement                          => 1, 
	uniqueCount                             => 4094, 
	firstId                                 => 1, 
	tpid                                    => "0x8100", 
	idIncrMode                              => 2, 
	enabled                                 => "False", 
	innerFirstId                            => 1, 
	innerIncrementStep                      => 1, 
	priority                                => 1, 
	increment                               => 1, 
	innerTpid                               => "0x8100", 
	innerUniqueCount                        => 4094, 
	innerEnable                             => "False", 
	innerPriority                           => 1
});

#################################################
# Creating the IP Distribution Groups
#################################################
$IP_1->rangeGroups->clear();



my $DistGroup1 = IxLoad->new("ixNetRangeGroup");

# ixNet objects need to be added in the list before they are configured!
$IP_1->rangeGroups->appendItem({ 
	object                                  => $DistGroup1
});



# ixNet objects need to be added in the list before they are configured.
$DistGroup1->rangeList->appendItem({ 
	object                                  => $IP_R1
});



$DistGroup1->config({ 
	distribType                             => 0, 
	name                                    => "DistGroup1"
});

$Traffic1_Network1->config({ 
	network                                 => $Network1
});

#################################################
# Activity HTTPClient1 of NetTraffic Traffic1@Network1
#################################################
my $Activity_HTTPClient1 = $Traffic1_Network1->activityList->appendItem({ 
	protocolAndType                         => "HTTP Client"
});

#################################################
# Timeline1 for activities HTTPClient1
#################################################
my $Timeline1 = IxLoad->new("ixTimeline");

$Timeline1->config();

$Activity_HTTPClient1->config({ 
	name                                    => "HTTPClient1", 
	userObjectiveValue                      => 100, 
	secondaryConstraintType                 => "TransactionRateConstraint", 
	constraintType                          => "ConnectionRateConstraint", 
	userObjectiveType                       => "simulatedUsers", 
	timeline                                => $Timeline1
});

$Activity_HTTPClient1->agent->actionList->clear();

my $my_ixHttpCommand = IxLoad->new("ixHttpCommand");

$my_ixHttpCommand->config({ 
	destination                             => "Traffic2_HTTPServer1:80", 
	cmdName                                 => "Get 1", 
	commandType                             => "GET", 
	pageObject                              => "/1b.html"
});

$Activity_HTTPClient1->agent->actionList->appendItem({ 
	object                                  => $my_ixHttpCommand
});



$Activity_HTTPClient1->agent->headerList->clear();

my $my_ixHttpHeaderString = IxLoad->new("ixHttpHeaderString");

$my_ixHttpHeaderString->config({ 
	data                                    => "Accept: */*"
});

$Activity_HTTPClient1->agent->headerList->appendItem({ 
	object                                  => $my_ixHttpHeaderString
});



my $my_ixHttpHeaderString1 = IxLoad->new("ixHttpHeaderString");

$my_ixHttpHeaderString1->config({ 
	data                                    => "Accept-Language: en-us"
});

$Activity_HTTPClient1->agent->headerList->appendItem({ 
	object                                  => $my_ixHttpHeaderString1
});



my $my_ixHttpHeaderString2 = IxLoad->new("ixHttpHeaderString");

$my_ixHttpHeaderString2->config({ 
	data                                    => "Accept-Encoding: gzip, deflate"
});

$Activity_HTTPClient1->agent->headerList->appendItem({ 
	object                                  => $my_ixHttpHeaderString2
});



my $my_ixHttpHeaderString3 = IxLoad->new("ixHttpHeaderString");

$my_ixHttpHeaderString3->config({ 
	data                                    => "User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322)"
});

$Activity_HTTPClient1->agent->headerList->appendItem({ 
	object                                  => $my_ixHttpHeaderString3
});



$Activity_HTTPClient1->agent->profileList->clear();

$Activity_HTTPClient1->agent->sslProfileList->clear();

$Activity_HTTPClient1->agent->config({ 
	browserEmulationName                    => "Microsoft IE 6.x"
});

$Activity_HTTPClient1->agent->cmdPercentagePool->percentageCommandList->clear();

$Activity_HTTPClient1->agent->cmdPercentagePool->config();

$Traffic1_Network1->traffic->config();

$Traffic1_Network1->setPortOperationModeAllowed($IxLoad::Info::ixPort{kOperationModeThroughputAcceleration}, "False");

$Traffic1_Network1->setPortOperationModeAllowed($IxLoad::Info::ixPort{kOperationModeFCoEOffload}, "True");

$Traffic1_Network1->setPortOperationModeAllowed($IxLoad::Info::ixPort{kOperationModeL23}, "True");

$Traffic1_Network1->setTcpAccelerationAllowed($IxLoad::Info::ixAgent{kTcpAcceleration}, "True");

$Originate->elementList->appendItem({ 
	object                                  => $Traffic1_Network1
});



$Originate->config({ 
	name                                    => "Originate"
});

$Scenario1->columnList->appendItem({ 
	object                                  => $Originate
});



my $DUT = IxLoad->new("ixTrafficColumn");

$DUT->elementList->clear();

#################################################
# Create ScenarioElement kNetTraffic
#################################################
my $Traffic2_Network2 = $scenarioElementFactory->create($IxLoad::Info::ixScenarioElementType{kNetTraffic});



#################################################
# Network Network2 of NetTraffic Traffic2@Network2
#################################################
my $Network2 = $Traffic2_Network2->cget("network");

my @serverPortList = split('\.', serverPort1);
my $serverChassis = $serverPortList[0];
my $serverCard = $serverPortList[1];
my $serverPort = $serverPortList[2];

$Network2->portList->appendItem({ 
	chassisId                               => $serverChassis, 
	cardId                                  => $serverCard, 
	portId                                  => $serverPort
});

$Network2->globalPlugins->clear();



my $Settings_2 = IxLoad->new("ixNetIxLoadSettingsPlugin");

# ixNet objects need to be added in the list before they are configured!
$Network2->globalPlugins->appendItem({ 
	object                                  => $Settings_2
});



$Settings_2->config();

my $Filter_2 = IxLoad->new("ixNetFilterPlugin");

# ixNet objects need to be added in the list before they are configured!
$Network2->globalPlugins->appendItem({ 
	object                                  => $Filter_2
});



$Filter_2->config();

my $GratARP_2 = IxLoad->new("ixNetGratArpPlugin");

# ixNet objects need to be added in the list before they are configured!
$Network2->globalPlugins->appendItem({ 
	object                                  => $GratARP_2
});



$GratARP_2->config();

my $TCP_2 = IxLoad->new("ixNetTCPPlugin");

# ixNet objects need to be added in the list before they are configured!
$Network2->globalPlugins->appendItem({ 
	object                                  => $TCP_2
});



$TCP_2->config({ 
	tcp_retries2                            => 5, 
	tcp_rto_max                             => 120000, 
	tcp_window_scaling                      => "False", 
	tcp_rto_min                             => 200, 
	tcp_wmem_default                        => 4096, 
	ip_no_pmtu_disc                         => "True", 
	tcp_rmem_default                        => 4096
});

my $DNS_2 = IxLoad->new("ixNetDnsPlugin");

# ixNet objects need to be added in the list before they are configured!
$Network2->globalPlugins->appendItem({ 
	object                                  => $DNS_2
});



$DNS_2->hostList->clear();



$DNS_2->searchList->clear();



$DNS_2->nameServerList->clear();



$DNS_2->config();

$Network2->config({ 
	name                                    => "Network2"
});

my $Ethernet_2 = $Network2->getL1Plugin();



my $my_ixNetDataCenterSettings1 = IxLoad->new("ixNetDataCenterSettings");

$my_ixNetDataCenterSettings1->dcPfcMapping->clear();



$my_ixNetDataCenterSettings1->config({ 
	dcMode                                  => 2, 
	dcFlowControl                           => 0
});

my $my_ixNetEthernetELMPlugin1 = IxLoad->new("ixNetEthernetELMPlugin");

$my_ixNetEthernetELMPlugin1->config();

my $my_ixNetDualPhyPlugin1 = IxLoad->new("ixNetDualPhyPlugin");

$my_ixNetDualPhyPlugin1->config();

$Ethernet_2->childrenList->clear();



my $MAC_VLAN_2 = IxLoad->new("ixNetL2EthernetPlugin");

# ixNet objects need to be added in the list before they are configured!
$Ethernet_2->childrenList->appendItem({ 
	object                                  => $MAC_VLAN_2
});



$MAC_VLAN_2->childrenList->clear();



my $IP_2 = IxLoad->new("ixNetIpV4V6Plugin");

# ixNet objects need to be added in the list before they are configured!
$MAC_VLAN_2->childrenList->appendItem({ 
	object                                  => $IP_2
});



$IP_2->childrenList->clear();



$IP_2->extensionList->clear();



$IP_2->config();

$MAC_VLAN_2->extensionList->clear();



$MAC_VLAN_2->config();

$Ethernet_2->extensionList->clear();



$Ethernet_2->config({ 
	dataCenter                              => $my_ixNetDataCenterSettings1, 
	cardElm                                 => $my_ixNetEthernetELMPlugin1, 
	cardDualPhy                             => $my_ixNetDualPhyPlugin1
});

#################################################
# Setting the ranges starting with the plugins that need to be script gen first
#################################################
$IP_2->rangeList->clear();

my $IP_R2 = IxLoad->new("ixNetIpV4V6Range");

# ixNet objects need to be added in the list before they are configured.
$IP_2->rangeList->appendItem({ 
	object                                  => $IP_R2
});



$IP_R2->config({ 
	count                                   => 100, 
	enableGatewayArp                        => "False", 
	randomizeSeed                           => 1597505884, 
	generateStatistics                      => "False", 
	autoIpTypeEnabled                       => "False", 
	autoCountEnabled                        => "False", 
	enabled                                 => "True", 
	autoMacGeneration                       => "True", 
	incrementBy                             => "0.0.0.1", 
	prefix                                  => 16, 
	gatewayIncrement                        => "0.0.0.0", 
	gatewayIncrementMode                    => "perSubnet", 
	mss                                     => 1460, 
	randomizeAddress                        => "False", 
	gatewayAddress                          => "0.0.0.0", 
	ipAddress                               => "10.10.0.101", 
	ipType                                  => "IPv4"
});

my $MAC_R2 = $IP_R2->getLowerRelatedRange("MacRange");

$MAC_R2->config({ 
	count                                   => 100, 
	enabled                                 => "True", 
	mtu                                     => 1500, 
	mac                                     => "00:0A:0A:00:65:00", 
	incrementBy                             => "00:00:00:00:00:01"
});

my $VLAN_R2 = $IP_R2->getLowerRelatedRange("VlanIdRange");

$VLAN_R2->config({ 
	incrementStep                           => 1, 
	innerIncrement                          => 1, 
	uniqueCount                             => 4094, 
	firstId                                 => 1, 
	tpid                                    => "0x8100", 
	idIncrMode                              => 2, 
	enabled                                 => "False", 
	innerFirstId                            => 1, 
	innerIncrementStep                      => 1, 
	priority                                => 1, 
	increment                               => 1, 
	innerTpid                               => "0x8100", 
	innerUniqueCount                        => 4094, 
	innerEnable                             => "False", 
	innerPriority                           => 1
});

#################################################
# Creating the IP Distribution Groups
#################################################
$IP_2->rangeGroups->clear();



my $DistGroup2 = IxLoad->new("ixNetRangeGroup");

# ixNet objects need to be added in the list before they are configured!
$IP_2->rangeGroups->appendItem({ 
	object                                  => $DistGroup2
});



# ixNet objects need to be added in the list before they are configured.
$DistGroup2->rangeList->appendItem({ 
	object                                  => $IP_R2
});



$DistGroup2->config({ 
	distribType                             => 0, 
	name                                    => "DistGroup1"
});

$Traffic2_Network2->config({ 
	network                                 => $Network2
});

#################################################
# Activity HTTPServer1 of NetTraffic Traffic2@Network2
#################################################
my $Activity_HTTPServer1 = $Traffic2_Network2->activityList->appendItem({ 
	protocolAndType                         => "HTTP Server"
});

my $_Match_Longest_ = IxLoad->new("ixMatchLongestTimeline");



$Activity_HTTPServer1->config({ 
	name                                    => "HTTPServer1", 
	timeline                                => $_Match_Longest_
});

$Activity_HTTPServer1->agent->webPageList->clear();

my $_200_OK = IxLoad->new("ResponseHeader");

$_200_OK->responseList->clear();

$_200_OK->config();

my $my_PageObject = IxLoad->new("PageObject");

$my_PageObject->config({ 
	chunkSize                               => "1", 
	payloadSize                             => "1-1", 
	page                                    => "/1b.html", 
	response                                => $_200_OK
});

$Activity_HTTPServer1->agent->webPageList->appendItem({ 
	object                                  => $my_PageObject
});



my $my_PageObject1 = IxLoad->new("PageObject");

$my_PageObject1->config({ 
	payloadSize                             => "4096-4096", 
	page                                    => "/4k.html", 
	response                                => $_200_OK
});

$Activity_HTTPServer1->agent->webPageList->appendItem({ 
	object                                  => $my_PageObject1
});



my $my_PageObject2 = IxLoad->new("PageObject");

$my_PageObject2->config({ 
	payloadSize                             => "8192-8192", 
	page                                    => "/8k.html", 
	response                                => $_200_OK
});

$Activity_HTTPServer1->agent->webPageList->appendItem({ 
	object                                  => $my_PageObject2
});



my $my_PageObject3 = IxLoad->new("PageObject");

$my_PageObject3->config({ 
	payloadSize                             => "16536-16536", 
	page                                    => "/16k.html", 
	response                                => $_200_OK
});

$Activity_HTTPServer1->agent->webPageList->appendItem({ 
	object                                  => $my_PageObject3
});



my $my_PageObject4 = IxLoad->new("PageObject");

$my_PageObject4->config({ 
	payloadSize                             => "32768", 
	page                                    => "/32k.html", 
	response                                => $_200_OK
});

$Activity_HTTPServer1->agent->webPageList->appendItem({ 
	object                                  => $my_PageObject4
});



my $my_PageObject5 = IxLoad->new("PageObject");

$my_PageObject5->config({ 
	payloadSize                             => "65536", 
	page                                    => "/64k.html", 
	response                                => $_200_OK
});

$Activity_HTTPServer1->agent->webPageList->appendItem({ 
	object                                  => $my_PageObject5
});



my $my_PageObject6 = IxLoad->new("PageObject");

$my_PageObject6->config({ 
	payloadSize                             => "131072", 
	page                                    => "/128k.html", 
	response                                => $_200_OK
});

$Activity_HTTPServer1->agent->webPageList->appendItem({ 
	object                                  => $my_PageObject6
});



my $my_PageObject7 = IxLoad->new("PageObject");

$my_PageObject7->config({ 
	payloadSize                             => "262144", 
	page                                    => "/256k.html", 
	response                                => $_200_OK
});

$Activity_HTTPServer1->agent->webPageList->appendItem({ 
	object                                  => $my_PageObject7
});



my $my_PageObject8 = IxLoad->new("PageObject");

$my_PageObject8->config({ 
	payloadSize                             => "524288", 
	page                                    => "/512k.html", 
	response                                => $_200_OK
});

$Activity_HTTPServer1->agent->webPageList->appendItem({ 
	object                                  => $my_PageObject8
});



my $my_PageObject9 = IxLoad->new("PageObject");

$my_PageObject9->config({ 
	payloadSize                             => "1048576", 
	page                                    => "/1024k.html", 
	response                                => $_200_OK
});

$Activity_HTTPServer1->agent->webPageList->appendItem({ 
	object                                  => $my_PageObject9
});



$Activity_HTTPServer1->agent->cookieList->clear();

my $UserCookie = IxLoad->new("CookieObject");

$UserCookie->cookieContentList->clear();

my $firstName = IxLoad->new("ixCookieContent");

$firstName->config({ 
	name                                    => "firstName", 
	value                                   => "Joe"
});

$UserCookie->cookieContentList->appendItem({ 
	object                                  => $firstName
});



my $lastName = IxLoad->new("ixCookieContent");

$lastName->config({ 
	name                                    => "lastName", 
	value                                   => "Smith"
});

$UserCookie->cookieContentList->appendItem({ 
	object                                  => $lastName
});



$UserCookie->config();

$Activity_HTTPServer1->agent->cookieList->appendItem({ 
	object                                  => $UserCookie
});



my $LoginCookie = IxLoad->new("CookieObject");

$LoginCookie->cookieContentList->clear();

my $name = IxLoad->new("ixCookieContent");

$name->config({ 
	value                                   => "joesmith"
});

$LoginCookie->cookieContentList->appendItem({ 
	object                                  => $name
});



my $password = IxLoad->new("ixCookieContent");

$password->config({ 
	name                                    => "password", 
	value                                   => "foobar"
});

$LoginCookie->cookieContentList->appendItem({ 
	object                                  => $password
});



$LoginCookie->config({ 
	mode                                    => 2, 
	name                                    => "LoginCookie", 
	description                             => "Login name and password"
});

$Activity_HTTPServer1->agent->cookieList->appendItem({ 
	object                                  => $LoginCookie
});



$Activity_HTTPServer1->agent->customPayloadList->clear();

my $AsciiCustomPayload = IxLoad->new("CustomPayloadObject");

$AsciiCustomPayload->config({ 
	name                                    => "AsciiCustomPayload", 
	asciiPayloadValue                       => "Ixia-Ixload-Http-Server-Custom-Payload", 
	payloadPosition                         => "Start With"
});

$Activity_HTTPServer1->agent->customPayloadList->appendItem({ 
	object                                  => $AsciiCustomPayload
});



my $HexCustomPayload = IxLoad->new("CustomPayloadObject");

$HexCustomPayload->config({ 
	name                                    => "HexCustomPayload", 
	payloadmode                             => 1, 
	hexPayloadValue                         => "49 78 69 61 2d 49 78 6c 6f 61 64 2d 48 74 74 70 2d 53 65 72 76 65 72 2d 43 75 73 74 6f 6d 2d 50 61 79 6c 6f 61 64", 
	payloadPosition                         => "Start With", 
	id                                      => 1
});

$Activity_HTTPServer1->agent->customPayloadList->appendItem({ 
	object                                  => $HexCustomPayload
});



$Activity_HTTPServer1->agent->responseHeaderList->clear();

my $_201 = IxLoad->new("ResponseHeader");

$_201->responseList->clear();

$_201->config();

$Activity_HTTPServer1->agent->responseHeaderList->appendItem({ 
	object                                  => $_201
});



my $_404_PageNotFound = IxLoad->new("ResponseHeader");

$_404_PageNotFound->responseList->clear();

$_404_PageNotFound->config({ 
	code                                    => 404, 
	name                                    => "404_PageNotFound", 
	description                             => "Page not found"
});

$Activity_HTTPServer1->agent->responseHeaderList->appendItem({ 
	object                                  => $_404_PageNotFound
});



$Activity_HTTPServer1->agent->config();

$Traffic2_Network2->traffic->config({ 
	name                                    => "Traffic2"
});

$Traffic2_Network2->setPortOperationModeAllowed($IxLoad::Info::ixPort{kOperationModeThroughputAcceleration}, "False");

$Traffic2_Network2->setPortOperationModeAllowed($IxLoad::Info::ixPort{kOperationModeFCoEOffload}, "True");

$Traffic2_Network2->setPortOperationModeAllowed($IxLoad::Info::ixPort{kOperationModeL23}, "True");

$Traffic2_Network2->setTcpAccelerationAllowed($IxLoad::Info::ixAgent{kTcpAcceleration}, "True");

$DUT->elementList->appendItem({ 
	object                                  => $Traffic2_Network2
});



$DUT->config({ 
	name                                    => "DUT"
});

$Scenario1->columnList->appendItem({ 
	object                                  => $DUT
});



my $Terminate = IxLoad->new("ixTrafficColumn");

$Terminate->elementList->clear();

$Terminate->config({ 
	name                                    => "Terminate"
});

$Scenario1->columnList->appendItem({ 
	object                                  => $Terminate
});



$Scenario1->links->clear();

$Scenario1->config();

$Test1->config({ 
	csvThroughputScalingFactor              => 1000, 
	enableNetworkDiagnostics                => "False", 
	currentUniqueIDForAgent                 => 8, 
	profileDirectory                        => $profileDirectory, 
	eventHandlerSettings                    => $my_ixEventHandlerSettings, 
	captureViewOptions                      => $my_ixViewOptions
});

#################################################
# Destination HTTPServer1 for HTTPClient1
#################################################
my $destination = $Traffic1_Network1->getDestinationForActivity("HTTPClient1", "Traffic2_HTTPServer1");

$destination->config();

#################################################
# Session Specific Settings
#################################################
my $my_ixNetMacSessionData = $Test1->getSessionSpecificData("L2EthernetPlugin");

$my_ixNetMacSessionData->config({ 
	duplicateCheckingScope                  => 2
});

my $my_ixNetIpSessionData = $Test1->getSessionSpecificData("IpV4V6Plugin");

$my_ixNetIpSessionData->config({ 
	duplicateCheckingScope                  => 2
});

#################################################
# Create the test controller to run the test
#################################################
my $testController = IxLoad->new("ixTestController", { 
	outputDir                               => "True"
});



$testController->initPerlApi();

$testController->setResultDir('RESULTS//HTTP_legacy');

my $NS = IxLoad::StatCollector->new();

my $test_server_handle = $testController->getTestServerHandle();
$NS->Initialize($test_server_handle);

$NS->ClearStats();

my @HTTP_Server_Per_URL_StatList = ( [ "HTTP Server Per URL", "HTTP Requests Received" , "kSum"], 
[ "HTTP Server Per URL", "HTTP Requests Successful" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Requests Failed (404)" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Requests Failed (50x)" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Requests Failed (Write Error)" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Responses Sent" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Responses Sent (1xx)" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Responses Sent (2xx)" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Responses Sent (3xx)" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Responses Sent (4xx)" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Responses Sent (5xx)" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Responses Sent (Other)" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Responses Failed (Write Error)" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Responses Failed (Aborted)" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Responses Failed (Other)" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Chunk Encoded Responses Sent" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Total Chunks Sent" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Average Chunk Size" , "kWeightedAverage"] , 
[ "HTTP Server Per URL", "HTTP Average Chunks per Response" , "kWeightedAverage"] , 
[ "HTTP Server Per URL", "HTTP Chunk Encoded Requests Received" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Total Chunks Received" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Average Received Chunk Size" , "kWeightedAverage"] , 
[ "HTTP Server Per URL", "HTTP Average Chunks per Request" , "kWeightedAverage"] , 
[ "HTTP Server Per URL", "HTTP Content-MD5 Requests Received" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Content-MD5 Check Successful" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP Content-MD5 Check Failed" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP OPTIONS Request Received" , "kSum"] , 
[ "HTTP Server Per URL", "HTTP OPTIONS Response Sent" , "kSum"] 
);

my @HTTP_Server_StatList = ( [ "HTTP Server", "HTTP Requests Received" , "kSum"], 
[ "HTTP Server", "HTTP Requests Successful" , "kSum"] , 
[ "HTTP Server", "HTTP Requests Failed" , "kSum"] , 
[ "HTTP Server", "HTTP Requests Failed (404)" , "kSum"] , 
[ "HTTP Server", "HTTP Requests Failed (50x)" , "kSum"] , 
[ "HTTP Server", "HTTP Requests Failed (Write Error)" , "kSum"] , 
[ "HTTP Server", "HTTP Requests Failed (Aborted)" , "kSum"] , 
[ "HTTP Server", "HTTP Sessions Rejected (503)" , "kSum"] , 
[ "HTTP Server", "HTTP Session Timeouts (408)" , "kSum"] , 
[ "HTTP Server", "HTTP Responses Sent (1xx)" , "kSum"] , 
[ "HTTP Server", "HTTP Responses Sent (2xx)" , "kSum"] , 
[ "HTTP Server", "HTTP Responses Sent (3xx)" , "kSum"] , 
[ "HTTP Server", "HTTP Responses Sent (4xx)" , "kSum"] , 
[ "HTTP Server", "HTTP Responses Sent (5xx)" , "kSum"] , 
[ "HTTP Server", "HTTP Responses Sent (Other)" , "kSum"] , 
[ "HTTP Server", "HTTP Bytes Received" , "kSum"] , 
[ "HTTP Server", "HTTP Bytes Sent" , "kSum"] , 
[ "HTTP Server", "HTTP Content Bytes Received" , "kSum"] , 
[ "HTTP Server", "HTTP Content Bytes Sent" , "kSum"] , 
[ "HTTP Server", "HTTP Cookies Received" , "kSum"] , 
[ "HTTP Server", "HTTP Cookies Sent" , "kSum"] , 
[ "HTTP Server", "HTTP Cookies Received With Matching ServerID" , "kSum"] , 
[ "HTTP Server", "HTTP Cookies Received With Non-matching ServerID" , "kSum"] , 
[ "HTTP Server", "HTTP Chunked Encoded Responses Sent" , "kSum"] , 
[ "HTTP Server", "HTTP Total Chunks Sent" , "kSum"] , 
[ "HTTP Server", "HTTP Chunked Transfer-Encoded Requests Received" , "kSum"] , 
[ "HTTP Server", "HTTP Total Chunks Received" , "kSum"] , 
[ "HTTP Server", "HTTP Content-MD5 Requests Received" , "kSum"] , 
[ "HTTP Server", "HTTP Content-MD5 Check Successful" , "kSum"] , 
[ "HTTP Server", "HTTP Content-MD5 Check Failed" , "kSum"] , 
[ "HTTP Server", "HTTP OPTIONS Request Received" , "kSum"] , 
[ "HTTP Server", "HTTP OPTIONS Response Sent" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (close_notify)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (close_notify)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (unexpected_message)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (unexpected_message)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (bad_record_mac)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (bad_record_mac)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (decryption_failed)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (decryption_failed)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (record_overflow)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (record_overflow)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (decompression_failure)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (decompression_failure)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (handshake_failure)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (handshake_failure)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (no_certificate)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (no_certificate)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (bad_certificate)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (bad_certificate)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (unsupported_certificate)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (unsupported_certificate)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (certificate_revoked)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (certificate_revoked)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (certificate_expired)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (certificate_expired)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (certificate_unknown)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (certificate_unknown)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (illegal_parameter)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (illegal_parameter)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (unknown_ca)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (unknown_ca)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (access_denied)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (access_denied)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (decode_error)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (decode_error)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (decrypt_error)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (decrypt_error)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (export_restriction)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (export_restriction)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (protocol_version)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (protocol_version)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (insufficient_security)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (insufficient_security)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (internal_error)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (internal_error)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (user_canceled)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (user_canceled)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (no_renegotiation)" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Sent (no_renegotiation)" , "kSum"] , 
[ "HTTP Server", "SSL Errors Received (undefined error)" , "kSum"] , 
[ "HTTP Server", "SSL Errors Sent (undefined error)" , "kSum"] , 
[ "HTTP Server", "SSL Errors Received (no cipher)" , "kSum"] , 
[ "HTTP Server", "SSL Errors Sent (no cipher)" , "kSum"] , 
[ "HTTP Server", "SSL Errors Received (no certificate)" , "kSum"] , 
[ "HTTP Server", "SSL Errors Sent (no certificate)" , "kSum"] , 
[ "HTTP Server", "SSL Errors Received (bad certificate)" , "kSum"] , 
[ "HTTP Server", "SSL Errors Sent (bad certificate)" , "kSum"] , 
[ "HTTP Server", "SSL Errors Received (unsupported certificate)" , "kSum"] , 
[ "HTTP Server", "SSL Errors Sent (unsupported certificate)" , "kSum"] , 
[ "HTTP Server", "SSL Errors Received" , "kSum"] , 
[ "HTTP Server", "SSL Errors Sent" , "kSum"] , 
[ "HTTP Server", "Client Hello Sent" , "kSum"] , 
[ "HTTP Server", "Client Hello Received" , "kSum"] , 
[ "HTTP Server", "Server Hello Sent" , "kSum"] , 
[ "HTTP Server", "Server Hello Received" , "kSum"] , 
[ "HTTP Server", "Hello Requests Sent" , "kSum"] , 
[ "HTTP Server", "Hello Requests Received" , "kSum"] , 
[ "HTTP Server", "SSL Session Reuse Success" , "kSum"] , 
[ "HTTP Server", "SSL Session Reuse Failed" , "kSum"] , 
[ "HTTP Server", "SSL Concurrent Sessions" , "kSum"] , 
[ "HTTP Server", "SSL Bytes Sent" , "kSum"] , 
[ "HTTP Server", "SSL Bytes Received" , "kSum"] , 
[ "HTTP Server", "SSL Throughput Bytes" , "kSum"] , 
[ "HTTP Server", "SSL Application Data Bytes" , "kSum"] , 
[ "HTTP Server", "SSL Certificate Validation Failure" , "kSum"] , 
[ "HTTP Server", "SSL Certificate Self Signed" , "kSum"] , 
[ "HTTP Server", "SSL Certificate CA Signed" , "kSum"] , 
[ "HTTP Server", "SSL Alerts Received (unrecognized name)" , "kSum"] , 
[ "HTTP Server", "SSL SNI extension sent successfully" , "kSum"] , 
[ "HTTP Server", "SSL SNI extension mismatch" , "kSum"] , 
[ "HTTP Server", "SSL session ticket reuse success" , "kSum"] , 
[ "HTTP Server", "SSL session ticket reuse failure" , "kSum"] , 
[ "HTTP Server", "SSL Negotiation Finished Successfully" , "kSum"] , 
[ "HTTP Server", "TCP SYN Sent" , "kSum"] , 
[ "HTTP Server", "TCP SYN_SYN-ACK Received" , "kSum"] , 
[ "HTTP Server", "TCP SYN Failed" , "kSum"] , 
[ "HTTP Server", "TCP SYN-ACK Sent" , "kSum"] , 
[ "HTTP Server", "TCP Connection Requests Failed" , "kSum"] , 
[ "HTTP Server", "TCP Connections Established" , "kSum"] , 
[ "HTTP Server", "TCP FIN Sent" , "kSum"] , 
[ "HTTP Server", "TCP FIN Received" , "kSum"] , 
[ "HTTP Server", "TCP FIN-ACK Sent" , "kSum"] , 
[ "HTTP Server", "TCP FIN-ACK Received" , "kSum"] , 
[ "HTTP Server", "TCP Resets Sent" , "kSum"] , 
[ "HTTP Server", "TCP Resets Received" , "kSum"] , 
[ "HTTP Server", "TCP Retries" , "kSum"] , 
[ "HTTP Server", "TCP Timeouts" , "kSum"] , 
[ "HTTP Server", "TCP Accept Queue Entries" , "kSum"] , 
[ "HTTP Server", "TCP Listen Queue Drops" , "kSum"] , 
[ "HTTP Server", "TCP Connections in ESTABLISHED State" , "kSum"] , 
[ "HTTP Server", "TCP Connections in SYN-SENT State" , "kSum"] , 
[ "HTTP Server", "TCP Connections in SYN-RECEIVED State" , "kSum"] , 
[ "HTTP Server", "TCP Connections in FIN-WAIT-1 State" , "kSum"] , 
[ "HTTP Server", "TCP Connections in FIN-WAIT-2 State" , "kSum"] , 
[ "HTTP Server", "TCP Connections in TIME-WAIT State" , "kSum"] , 
[ "HTTP Server", "TCP Connections in CLOSE STATE" , "kSum"] , 
[ "HTTP Server", "TCP Connections in CLOSE-WAIT State" , "kSum"] , 
[ "HTTP Server", "TCP Connections in LAST-ACK State" , "kSum"] , 
[ "HTTP Server", "TCP Connections in LISTENING State" , "kSum"] , 
[ "HTTP Server", "TCP Connections in CLOSING State" , "kSum"] , 
[ "HTTP Server", "TCP Internally Aborted Connections" , "kSum"] 
);

my @HTTP_Client_Per_URL_StatList = ( [ "HTTP Client Per URL", "HTTP Requests Sent" , "kSum"], 
[ "HTTP Client Per URL", "HTTP Requests Successful" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Successful (Provisional)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (Write)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (Read)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (Bad Header)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (4xx)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (400)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (401)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (403)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (404)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (407)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (408)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (4xx other)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (5xx)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (505)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (5xx other)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (other)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (Timeout)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Failed (Aborted)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Aborted Before Request" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Aborted After Request" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Responses Received With Match" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Responses Received Without Match" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Intermediate Responses Received (1xx)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Successful (2xx)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Successful (3xx)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Successful (301)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Successful (302)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Successful (303)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Requests Successful (307)" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Content-MD5 Requests Sent" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Chunk Encoded Headers Received" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Chunk Encoded Responses Successful" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Chunk Encoded Responses Failed" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Total Chunks Received" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Average Chunk Size" , "kWeightedAverage"] , 
[ "HTTP Client Per URL", "HTTP Average Chunks per Response" , "kWeightedAverage"] , 
[ "HTTP Client Per URL", "HTTP Chunk Encoded Requests Sent" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Total Chunks Sent" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Average Chunk Size in Request" , "kWeightedAverage"] , 
[ "HTTP Client Per URL", "HTTP Average Chunks per Request" , "kWeightedAverage"] , 
[ "HTTP Client Per URL", "Name1-Value1" , "kString"] , 
[ "HTTP Client Per URL", "Counter1" , "kSum"] , 
[ "HTTP Client Per URL", "Name2-Value2" , "kString"] , 
[ "HTTP Client Per URL", "Counter2" , "kSum"] , 
[ "HTTP Client Per URL", "Name3-Value3" , "kString"] , 
[ "HTTP Client Per URL", "Counter3" , "kSum"] , 
[ "HTTP Client Per URL", "Name4-Value4" , "kString"] , 
[ "HTTP Client Per URL", "Counter4" , "kSum"] , 
[ "HTTP Client Per URL", "Name5-Value5" , "kString"] , 
[ "HTTP Client Per URL", "Counter5" , "kSum"] , 
[ "HTTP Client Per URL", "Name6-Value6" , "kString"] , 
[ "HTTP Client Per URL", "Counter6" , "kSum"] , 
[ "HTTP Client Per URL", "Name7-Value7" , "kString"] , 
[ "HTTP Client Per URL", "Counter7" , "kSum"] , 
[ "HTTP Client Per URL", "Name8-Value8" , "kString"] , 
[ "HTTP Client Per URL", "Counter8" , "kSum"] , 
[ "HTTP Client Per URL", "Name9-Value9" , "kString"] , 
[ "HTTP Client Per URL", "Counter9" , "kSum"] , 
[ "HTTP Client Per URL", "Name10-Value10" , "kString"] , 
[ "HTTP Client Per URL", "Counter10" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Gzip-Encoded Responses Received" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Gzip-Encoded Responses Successful" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Gzip-Encoded Responses Failed" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Deflate-Encoded Responses Received" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Deflate-Encoded Responses Successful" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Deflate-Encoded Responses Failed" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Content-MD5 Responses Received" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Content-MD5 Responses Successful" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Content-MD5 Responses Failed" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Custom MD5 Responses Received" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Custom MD5 Responses Successful" , "kSum"] , 
[ "HTTP Client Per URL", "HTTP Custom MD5 Responses Failed" , "kSum"] , 
[ "HTTP Client Per URL", "Average Compression Ratio" , "kWeightedAverage"] 
);

my @HTTP_Client_StatList = ( [ "HTTP Client", "HTTP Simulated Users" , "kSum"], 
[ "HTTP Client", "HTTP Concurrent Connections" , "kSum"] , 
[ "HTTP Client", "HTTP Connections" , "kSum"] , 
[ "HTTP Client", "HTTP Connection Attempts" , "kSum"] , 
[ "HTTP Client", "HTTP Connection Aborts" , "kSum"] , 
[ "HTTP Client", "HTTP Old Session Aborts" , "kSum"] , 
[ "HTTP Client", "HTTP Transactions" , "kSum"] , 
[ "HTTP Client", "HTTP Bytes" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Sent" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Successful" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Successful (Provisional)" , "kSum"] , 
[ "HTTP Client", "HTTP Intermediate Responses Received (1xx)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Successful (2xx)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Successful (3xx)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Successful (301)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Successful (302)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Successful (303)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Successful (307)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (Write)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (Read)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (Bad Header)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (4xx)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (400)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (401)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (403)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (404)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (407)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (408)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (4xx other)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (5xx)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (505)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (5xx other)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (other)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (Timeout)" , "kSum"] , 
[ "HTTP Client", "HTTP Requests Failed (Aborted)" , "kSum"] , 
[ "HTTP Client", "HTTP Session Timeouts (408)" , "kSum"] , 
[ "HTTP Client", "HTTP Request Precondition Failed (412)" , "kSum"] , 
[ "HTTP Client", "HTTP Sessions Rejected (503)" , "kSum"] , 
[ "HTTP Client", "HTTP Aborted Before Request" , "kSum"] , 
[ "HTTP Client", "HTTP Aborted After Request" , "kSum"] , 
[ "HTTP Client", "HTTP Transactions Active" , "kSum"] , 
[ "HTTP Client", "HTTP Users Active" , "kSum"] , 
[ "HTTP Client", "Content-Encoded Responses Received" , "kSum"] , 
[ "HTTP Client", "Gzip Content-Encoding Received" , "kSum"] , 
[ "HTTP Client", "Deflate Content-Encoding Received" , "kSum"] , 
[ "HTTP Client", "Unrecognized Content-Encoding Received" , "kSum"] , 
[ "HTTP Client", "Content-Encoded Responses Decode Successful" , "kSum"] , 
[ "HTTP Client", "Gzip Content-Encoding Decode Successful" , "kSum"] , 
[ "HTTP Client", "Deflate Content-Encoding Decode Successful" , "kSum"] , 
[ "HTTP Client", "Content-Encoded Responses Decode Failed" , "kSum"] , 
[ "HTTP Client", "Gzip Content-Encoding Decode Failed" , "kSum"] , 
[ "HTTP Client", "Deflate Content-Encoding Decode Failed" , "kSum"] , 
[ "HTTP Client", "Gzip Content-Encoding Decode Failed - Data Error" , "kSum"] , 
[ "HTTP Client", "Gzip Content-Encoding Decode Failed - Decoding Error" , "kSum"] , 
[ "HTTP Client", "Deflate Content-Encoding Decode Failed - Data Error" , "kSum"] , 
[ "HTTP Client", "Deflate Content-Encoding Decode Failed - Decoding Error" , "kSum"] , 
[ "HTTP Client", "Chunked Transfer-Encoded Headers Received" , "kSum"] , 
[ "HTTP Client", "Chunked Transfer-Encoding Decode Successful" , "kSum"] , 
[ "HTTP Client", "Chunked Transfer-Encoding Decode Failed" , "kSum"] , 
[ "HTTP Client", "Total Chunks Received" , "kSum"] , 
[ "HTTP Client", "Chunked Transfer-Encoding Headers Sent" , "kSum"] , 
[ "HTTP Client", "Total Chunks Sent" , "kSum"] , 
[ "HTTP Client", "Content-MD5 Responses Received" , "kSum"] , 
[ "HTTP Client", "Content-MD5 Check Successful" , "kSum"] , 
[ "HTTP Client", "Content-MD5 Check Failed" , "kSum"] , 
[ "HTTP Client", "Custom-MD5 Responses Received" , "kSum"] , 
[ "HTTP Client", "Custom-MD5 Check Successful" , "kSum"] , 
[ "HTTP Client", "Custom-MD5 Check Failed" , "kSum"] , 
[ "HTTP Client", "HTTP Bytes Sent" , "kSum"] , 
[ "HTTP Client", "HTTP Bytes Received" , "kSum"] , 
[ "HTTP Client", "HTTP Content Bytes Sent" , "kSum"] , 
[ "HTTP Client", "HTTP Content Bytes Received" , "kSum"] , 
[ "HTTP Client", "HTTP Decompressed Content Bytes Received" , "kSum"] , 
[ "HTTP Client", "HTTP Cookies Received" , "kSum"] , 
[ "HTTP Client", "HTTP Cookies Sent" , "kSum"] , 
[ "HTTP Client", "HTTP Cookies Rejected" , "kSum"] , 
[ "HTTP Client", "HTTP Cookies Rejected - (Path Match Failed)" , "kSum"] , 
[ "HTTP Client", "HTTP Cookies Rejected - (Domain Match Failed)" , "kSum"] , 
[ "HTTP Client", "HTTP Cookies Rejected - (Cookiejar Overflow)" , "kSum"] , 
[ "HTTP Client", "HTTP Cookies Rejected - (Probabilistic Reject)" , "kSum"] , 
[ "HTTP Client", "HTTP Cookie headers Rejected - (Memory Overflow)" , "kSum"] , 
[ "HTTP Client", "HTTP Connect Time (us)" , "kWeightedAverage"] , 
[ "HTTP Client", "HTTP Time To First Byte (us)" , "kWeightedAverage"] , 
[ "HTTP Client", "HTTP Time To Last Byte (us)" , "kWeightedAverage"] , 
[ "HTTP Client", "HTTP Old Session Abort Delay - Average (us)" , "kWeightedAverage"] , 
[ "HTTP Client", "HTTP Old Session Abort Delay - Minimum (us)" , "kSum"] , 
[ "HTTP Client", "HTTP Old Session Abort Delay - Maximum (us)" , "kSum"] , 
[ "HTTP Client", "HTTP Client Total Data Integrity Check Failed" , "kSum"] , 
[ "HTTP Client", "HTTP Client Total Data Integrity Check Succeeded" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (close_notify)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (close_notify)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (unexpected_message)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (unexpected_message)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (bad_record_mac)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (bad_record_mac)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (decryption_failed)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (decryption_failed)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (record_overflow)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (record_overflow)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (decompression_failure)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (decompression_failure)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (handshake_failure)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (handshake_failure)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (no_certificate)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (no_certificate)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (bad_certificate)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (bad_certificate)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (unsupported_certificate)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (unsupported_certificate)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (certificate_revoked)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (certificate_revoked)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (certificate_expired)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (certificate_expired)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (certificate_unknown)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (certificate_unknown)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (illegal_parameter)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (illegal_parameter)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (unknown_ca)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (unknown_ca)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (access_denied)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (access_denied)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (decode_error)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (decode_error)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (decrypt_error)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (decrypt_error)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (export_restriction)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (export_restriction)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (protocol_version)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (protocol_version)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (insufficient_security)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (insufficient_security)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (internal_error)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (internal_error)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (user_canceled)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (user_canceled)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (no_renegotiation)" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Sent (no_renegotiation)" , "kSum"] , 
[ "HTTP Client", "SSL Errors Received (undefined error)" , "kSum"] , 
[ "HTTP Client", "SSL Errors Sent (undefined error)" , "kSum"] , 
[ "HTTP Client", "SSL Errors Received (no cipher)" , "kSum"] , 
[ "HTTP Client", "SSL Errors Sent (no cipher)" , "kSum"] , 
[ "HTTP Client", "SSL Errors Received (no certificate)" , "kSum"] , 
[ "HTTP Client", "SSL Errors Sent (no certificate)" , "kSum"] , 
[ "HTTP Client", "SSL Errors Received (bad certificate)" , "kSum"] , 
[ "HTTP Client", "SSL Errors Sent (bad certificate)" , "kSum"] , 
[ "HTTP Client", "SSL Errors Received (unsupported certificate)" , "kSum"] , 
[ "HTTP Client", "SSL Errors Sent (unsupported certificate)" , "kSum"] , 
[ "HTTP Client", "SSL Errors Received" , "kSum"] , 
[ "HTTP Client", "SSL Errors Sent" , "kSum"] , 
[ "HTTP Client", "Client Hello Sent" , "kSum"] , 
[ "HTTP Client", "Client Hello Received" , "kSum"] , 
[ "HTTP Client", "Server Hello Sent" , "kSum"] , 
[ "HTTP Client", "Server Hello Received" , "kSum"] , 
[ "HTTP Client", "Hello Requests Sent" , "kSum"] , 
[ "HTTP Client", "Hello Requests Received" , "kSum"] , 
[ "HTTP Client", "SSL Session Reuse Success" , "kSum"] , 
[ "HTTP Client", "SSL Session Reuse Failed" , "kSum"] , 
[ "HTTP Client", "SSL Concurrent Sessions" , "kSum"] , 
[ "HTTP Client", "SSL Bytes Sent" , "kSum"] , 
[ "HTTP Client", "SSL Bytes Received" , "kSum"] , 
[ "HTTP Client", "SSL Throughput Bytes" , "kSum"] , 
[ "HTTP Client", "SSL Application Data Bytes" , "kSum"] , 
[ "HTTP Client", "SSL Certificate Validation Failure" , "kSum"] , 
[ "HTTP Client", "SSL Certificate Self Signed" , "kSum"] , 
[ "HTTP Client", "SSL Certificate CA Signed" , "kSum"] , 
[ "HTTP Client", "SSL Alerts Received (unrecognized name)" , "kSum"] , 
[ "HTTP Client", "SSL SNI extension sent successfully" , "kSum"] , 
[ "HTTP Client", "SSL SNI extension mismatch" , "kSum"] , 
[ "HTTP Client", "SSL session ticket reuse success" , "kSum"] , 
[ "HTTP Client", "SSL session ticket reuse failure" , "kSum"] , 
[ "HTTP Client", "SSL Negotiation Finished Successfully" , "kSum"] , 
[ "HTTP Client", "TCP SYN Sent" , "kSum"] , 
[ "HTTP Client", "TCP SYN_SYN-ACK Received" , "kSum"] , 
[ "HTTP Client", "TCP SYN Failed" , "kSum"] , 
[ "HTTP Client", "TCP SYN-ACK Sent" , "kSum"] , 
[ "HTTP Client", "TCP Connection Requests Failed" , "kSum"] , 
[ "HTTP Client", "TCP Connections Established" , "kSum"] , 
[ "HTTP Client", "TCP FIN Sent" , "kSum"] , 
[ "HTTP Client", "TCP FIN Received" , "kSum"] , 
[ "HTTP Client", "TCP FIN-ACK Sent" , "kSum"] , 
[ "HTTP Client", "TCP FIN-ACK Received" , "kSum"] , 
[ "HTTP Client", "TCP Resets Sent" , "kSum"] , 
[ "HTTP Client", "TCP Resets Received" , "kSum"] , 
[ "HTTP Client", "TCP Retries" , "kSum"] , 
[ "HTTP Client", "TCP Timeouts" , "kSum"] , 
[ "HTTP Client", "TCP Accept Queue Entries" , "kSum"] , 
[ "HTTP Client", "TCP Listen Queue Drops" , "kSum"] , 
[ "HTTP Client", "TCP Connections in ESTABLISHED State" , "kSum"] , 
[ "HTTP Client", "TCP Connections in SYN-SENT State" , "kSum"] , 
[ "HTTP Client", "TCP Connections in SYN-RECEIVED State" , "kSum"] , 
[ "HTTP Client", "TCP Connections in FIN-WAIT-1 State" , "kSum"] , 
[ "HTTP Client", "TCP Connections in FIN-WAIT-2 State" , "kSum"] , 
[ "HTTP Client", "TCP Connections in TIME-WAIT State" , "kSum"] , 
[ "HTTP Client", "TCP Connections in CLOSE STATE" , "kSum"] , 
[ "HTTP Client", "TCP Connections in CLOSE-WAIT State" , "kSum"] , 
[ "HTTP Client", "TCP Connections in LAST-ACK State" , "kSum"] , 
[ "HTTP Client", "TCP Connections in LISTENING State" , "kSum"] , 
[ "HTTP Client", "TCP Connections in CLOSING State" , "kSum"] , 
[ "HTTP Client", "TCP Internally Aborted Connections" , "kSum"] 
);

my @statList = (@HTTP_Server_Per_URL_StatList, @HTTP_Server_StatList, @HTTP_Client_Per_URL_StatList, @HTTP_Client_StatList);

my $count = 1;

my @stat;
foreach my $ref (@statList) {
	@stat = @$ref;
	my $caption = sprintf('Watch_Stat_%s', $count);
	my $statSourceType = $stat[0];
	my $statName = $stat[1];
	my $aggregationType = $stat[2];
	$NS->AddStat({ 
	filterList                              => {}, 
	caption                                 => $caption, 
	statSourceType                          => $statSourceType, 
	statName                                => $statName, 
	aggregationType                         => $aggregationType
});
	$count += 1;
}

sub my_stat_collector_command{
	my $tclName = shift;
	my $methodName = shift;
	my $statCollector = shift;
	my $stat = shift;

	my $statString = shift;
	print "=====================================\n";
	print "INCOMING STAT RECORD >>> $statString
";
	print "=====================================\n
";
};
$NS->StartCollector({
	command  => \&my_stat_collector_command
});

eval {
	$testController->run($Test1);

	my $wait_result = IxLoad::TestControllerWait();
	print $wait_result."\n";
};

$NS->StopCollector();

#################################################
# Cleanup
#################################################
# Release config is only strictly necessary if enableReleaseConfigAfterRun is 0.
$testController->releaseConfigWaitFinish();

$Test1->clearDUTList();

$Traffic1_Network1->removeAllPortsFromAnalyzer();

$Traffic2_Network2->removeAllPortsFromAnalyzer();

IxLoad->delete($chassisChain);

IxLoad->delete($Test1);

IxLoad->delete($profileDirectory);

IxLoad->delete($my_ixEventHandlerSettings);

IxLoad->delete($my_ixViewOptions);

IxLoad->delete($Scenario1);

IxLoad->delete($Originate);

IxLoad->delete($Traffic1_Network1);

IxLoad->delete($Network1);

IxLoad->delete($Settings_1);

IxLoad->delete($Filter_1);

IxLoad->delete($GratARP_1);

IxLoad->delete($TCP_1);

IxLoad->delete($DNS_1);

IxLoad->delete($Ethernet_1);

IxLoad->delete($my_ixNetDataCenterSettings);

IxLoad->delete($my_ixNetEthernetELMPlugin);

IxLoad->delete($my_ixNetDualPhyPlugin);

IxLoad->delete($MAC_VLAN_1);

IxLoad->delete($IP_1);

IxLoad->delete($IP_R1);

IxLoad->delete($MAC_R1);

IxLoad->delete($VLAN_R1);

IxLoad->delete($DistGroup1);

IxLoad->delete($Activity_HTTPClient1);

IxLoad->delete($Timeline1);

IxLoad->delete($my_ixHttpCommand);

IxLoad->delete($my_ixHttpHeaderString);

IxLoad->delete($my_ixHttpHeaderString1);

IxLoad->delete($my_ixHttpHeaderString2);

IxLoad->delete($my_ixHttpHeaderString3);

IxLoad->delete($DUT);

IxLoad->delete($Traffic2_Network2);

IxLoad->delete($Network2);

IxLoad->delete($Settings_2);

IxLoad->delete($Filter_2);

IxLoad->delete($GratARP_2);

IxLoad->delete($TCP_2);

IxLoad->delete($DNS_2);

IxLoad->delete($Ethernet_2);

IxLoad->delete($my_ixNetDataCenterSettings1);

IxLoad->delete($my_ixNetEthernetELMPlugin1);

IxLoad->delete($my_ixNetDualPhyPlugin1);

IxLoad->delete($MAC_VLAN_2);

IxLoad->delete($IP_2);

IxLoad->delete($IP_R2);

IxLoad->delete($MAC_R2);

IxLoad->delete($VLAN_R2);

IxLoad->delete($DistGroup2);

IxLoad->delete($Activity_HTTPServer1);

IxLoad->delete($_Match_Longest_);

IxLoad->delete($my_PageObject);

IxLoad->delete($_200_OK);

IxLoad->delete($my_PageObject1);

IxLoad->delete($my_PageObject2);

IxLoad->delete($my_PageObject3);

IxLoad->delete($my_PageObject4);

IxLoad->delete($my_PageObject5);

IxLoad->delete($my_PageObject6);

IxLoad->delete($my_PageObject7);

IxLoad->delete($my_PageObject8);

IxLoad->delete($my_PageObject9);

IxLoad->delete($UserCookie);

IxLoad->delete($firstName);

IxLoad->delete($lastName);

IxLoad->delete($LoginCookie);

IxLoad->delete($name);

IxLoad->delete($password);

IxLoad->delete($AsciiCustomPayload);

IxLoad->delete($HexCustomPayload);

IxLoad->delete($_201);

IxLoad->delete($_404_PageNotFound);

IxLoad->delete($Terminate);

IxLoad->delete($destination);

IxLoad->delete($my_ixNetMacSessionData);

IxLoad->delete($my_ixNetIpSessionData);

IxLoad->delete($testController);


#################################################
# Disconnect / Release application lock
#################################################
};
if ($@) {
	print "Error: $@\n";}

IxLoad->disconnect();
exit(0);