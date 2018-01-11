# Test configurations
#-----------------------
# Dns test for showing Dns stats.
source ../setup_simple.tcl

# IxLoad onnect should always be called, even for local scripts
::IxLoad connect $::IxLoadPrivate::SimpleSettings::remoteServer

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
        $clnt_network networkRangeList.appendItem \
            -name           "clnt_range" \
            -enable         1 \
            -firstIp        "198.18.100.1" \
            -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
            -ipCount        10 \
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

        set svr_network [$repository serverNetworkList.addItem \
                        -name "svr_network"]
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
            -statsRequired  1 \
            -enableResetPorts 0 \
        ]

        $test clientCommunityList.appendItem -object $clnt_t_n_mapping
        $test serverCommunityList.appendItem -object $svr_t_n_mapping
        
        
        #-----------------------------------------------------------------------
        # Create a test controller bound to the previosuly allocated
        # chassis chain. This will eventually run the test we created earlier.
        #-----------------------------------------------------------------------
        set testController [::IxLoad new ixTestController -outputDir 1]
        
        $testController setResultDir "RESULTS/simplednsclientandserver"

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


