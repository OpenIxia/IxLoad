# Test configurations
#-----------------------
# Dns test for showing Dns stats.
source ../setup_simple.tcl
catch {
        #
        # Loads plugins for specific protocols configured in this test
        #
        global ixAppPluginManager
        $ixAppPluginManager load "DNS"
        
        #
        # setup logger
        #
        set logtag "IxLoad-api"
        set logName "MyDNSLog"
        set logger [::IxLoad new ixLogger $logtag 1]
        set logEngine [$logger getEngine]
        $logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
        $logEngine setFile $logName 2 256 1
        
        set scu_version [package require statCollectorUtils]
        puts "statCollectorUtils package version = $scu_version"

        set repository [::IxLoad new ixRepository]
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
	-count                                   10 \
	-name                                    "ip-1" \
	-gatewayAddress                          "0.0.0.0" \
	-prefix                                  16 \
	-mss                                     100 \
	-ipAddress                               "198.18.100.1" 

set mac_1 [$ip_1 getLowerRelatedRange "MacRange"]

$mac_1 config \
	-count                                   10 \
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
            -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID)\
            -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)

        set svr_network [$repository serverNetworkList.addItem \
                        -name "svr_network"]
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
	-mss                                     100 \
	-ipAddress                               "198.18.200.1" 

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
            -cardId     $::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID)\
            -portId     $::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)


        #-----------------------------------------------------------------------
        # Construct Client Traffic
        #-----------------------------------------------------------------------
        set expected "clnt_traffic"
        set clnt_traffic [$repository clientTrafficList.addItem -name $expected]

        $clnt_traffic agentList.appendItem \
            -name               "my_dns_client" \
            -protocol           "DNS" \
            -type               "Client" \

        $clnt_traffic agentList(0).pm.advancedOptions.config \
            -responseTimeout     2  \
            -lowerLayerTransport 1   \
            -numberOfRetries     0

        $clnt_traffic agentList(0).pm.dnsConfig.dnsQueries.appendItem \
                -id        "DnsQuery" \
                -hostName  "ABCDEFGHIJK-LMNOPQRSTWVXYZ.ABCDEFGHIJK-LMNOPQRSTWVXYZ"  \
                -queryType "A" \
                -dnsServer "198.18.200.1"  \
                -recursionDesired 0 \
                -expect "1.2.3.4"


        #        -hostName  "server1.myzone"
        #-----------------------------------------------------------------------
        # Construct Server Traffic
        #-----------------------------------------------------------------------
        set expected "svr_traffic"
        set svr_traffic [$repository serverTrafficList.addItem -name $expected]
        set actual [$svr_traffic cget -name]

        $svr_traffic agentList.appendItem \
            -name               "my_dns_server" \
            -protocol           "DNS" \
            -type               "Server"

        $svr_traffic agentList(0).pm.advancedOptions.config \
            -listeningPort 53

        $svr_traffic agentList(0).pm.zoneMgr.zoneChoices.appendItem \
           -id        "Zone"    \
           -name      "ABCDEFGHIJK-LMNOPQRSTWVXYZ"  \
           -serial    1234      \
           -expire    8888      \
           -predefine 0


        $svr_traffic agentList(0).pm.zoneMgr.zoneChoices(2).resourceRecordList.appendItem \
           -id         "A"    \
           -hostName   "ABCDEFGHIJK-LMNOPQRSTWVXYZ"     \
           -address    "1.2.3.4"


        $svr_traffic agentList(0).pm.zoneMgr.zoneChoices(2).resourceRecordList.appendItem \
           -id         "NS"     \
           -zoneName   "ABCDEFGHIJK-LMNOPQRSTWVXYZ" \
           -nameServer "198.18.200.1"

        $svr_traffic agentList(0).pm.zoneConfig.zoneList.appendItem \
           -id   "ZoneList" \
           -name "ABCDEFGHIJK-LMNOPQRSTWVXYZ"
        #-----------------------------------------------------------------------
        # Create a client and server mapping and bind into the
        # network and traffic that they will be employing
        #-----------------------------------------------------------------------
        set clnt_t_n_mapping [::IxLoad new ixClientTrafficNetworkMapping \
            -network                $clnt_network \
            -traffic                $clnt_traffic \
            -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
            -objectiveValue         10 \
            -rampUpValue            10 \
            -sustainTime            120 \
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
        set test [$repository testList.addItem \
            -name           "my_test" \
            -statsRequired  0 \
            -enableResetPorts 0 \
        ]

        $test clientCommunityList.appendItem -object $clnt_t_n_mapping
        $test serverCommunityList.appendItem -object $svr_t_n_mapping
        
        
        #-----------------------------------------------------------------------
        # Create a test controller bound to the previosuly allocated
        # chassis chain. This will eventually run the test we created earlier.
        #-----------------------------------------------------------------------
        set testController [::IxLoad new ixTestController -outputDir 1]
        
        $testController setResultDir "[pwd]/RESULTS/simplednsclientandserver"


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
        		"DNS Total Queries Sent" \
        		"DNS Total Queries Successful" \
        		"DNS Total Queries Retried" \
        		"DNS Total Queries Failed" \
        		"DNS Total Queries Failed (Format Error)" \
        		"DNS Total Queries Failed (Server Failure)" \
        		"DNS Total Queries Failed (Name Error)" \
        		"DNS Total Queries Failed (Not Implemented)" \
        		"DNS Total Queries Failed (Refused)" \
        		"DNS Total Queries Failed (Other)" \
        		"DNS Total Queries Failed (Timeout)" \
        		"DNS Total Queries Failed (Aborted)" \
        ]
        set aggregation_type "kSum"
                                                                                        
        set cnt 1
        foreach statitem $::StatList {
                set caption [format "Watch_Stat_%s" $cnt]
                                                                                        
                ${NS}::AddStat \
                        -caption            $caption \
                        -statSourceType     "DNS Client" \
                        -statName           $statitem \
                        -aggregationType    $aggregation_type \
                        -filterList         {}
               incr cnt
        }
        # Start the collector (runs in the tcl event loop)
        #
        proc ::my_stat_collector_command {args} {
            puts stderr "====================================="
            puts stderr "INCOMING STAT RECORD >>> $args"
            array set statlist [lindex $args end]
            puts stderr "***** $statlist(stats)"
            array set stat {};
            set str ""
            puts "Length = [llength $::StatList]"
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
        $testController run $test -repository $repository

        vwait ::ixTestControllerMonitor

        ${NS}::StopCollector
        #-----------------------------------------------------------------------
        # Cleanup
        #-----------------------------------------------------------------------

        puts "Going to generate report in pdf"
        $testController generateReport -detailedReport 1 -format "PDF;HTML"

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
        ::IxLoad delete $testController
        
        
        #-----------------------------------------------------------------------
        # Disconnect
        #-----------------------------------------------------------------------

} connectResult

puts $connectResult


