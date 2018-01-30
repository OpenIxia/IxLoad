#!/bin/tclsh
#
# By Hubert Gee
#
# Description
#
#    - Convert a scriptgen script into a dynamic script.
#    - Modify the scriptgen stat collector to get stats that you want only.
#    - Modify the script to abort the test by pressing the Enter key.
#

# 1> Wrap entire script into a Proc called Main.
#
# 2> Change IxLoad connect IP address to IxLoad Client IP address.
#
# 3> Fix a scriptgen bug.  Go to the bottom and add "errorInfo" to the end of the catch statement:
#       } errorInfo] {  <---
#	   $logger error $errorInfo
#	   puts $errorInfo
#       } 
#
# 4> Copy and paste all of Hubert's APIs to the scriptgen tcl script.
#
# 5> Create a variable ::statList containing all the stats that you want at
#    real time and put it inside the Main Proc at the top.  Example:
#  
#        set ::statList { \
#		       {"HTTP Client" "TCP Connections Established" "kSum"} \
#		       {"HTTP Client" "TCP Connection Requests Failed" "kSum"} \
#		       {"HTTP Client" "HTTP Simulated Users" "kSum"} \
#		       {"HTTP Client" "HTTP Concurrent Connections" "kSum"} \
#		       {"HTTP Client" "HTTP Connections" "kSum"} \
#		       {"HTTP Client" "HTTP Transactions" "kSum"} \
#		       {"HTTP Client" "HTTP Connection Attempts" "kSum"} \
#		       {"HTTP Server" "TCP Connections Established" "kSum"} \
#		       {"HTTP Server" "TCP Connection Requests Failed" "kSum"} \
#		   }
#
# 6> Remove all the stats that was created by scriptgen.
#
# 7> Do a wordsearch for "clearGridStats". Beneath clearGridStats, there 
#    is a foreach loop. Make $statList to $::statList.
#
# 8> Beneath the for loop block of codes, replace ::my_stat_collector_command to IxL_StatCollectorCommand like this:
#  	From: ${NS}::StartCollector -command ::my_stat_collector_command -interval 2
#         To: ${NS}::StartCollector -command IxL_StatCollectorCommand -interval 2
#
# 9> To ABORT the test by pressing the <Enter> key:
#    - Do a wordsearch for "run $Test".
#    - Right above that line, add: 	set ::ixTestControllerMonitor ""
#    - Beneath the line: "$testController run $Test#", add: IxL_EnterKeyToAbortTest
#    - Comment out all the following lines. There could be two areas. One above Cleanup and one below Cleanup.
#	  vwait ::ixTestControllerMonitor
#	  puts $::ixTestControllerMonitor


proc GetTime {} {
    return [clock format [clock seconds] -format "%H%M%S"]
}
     
proc IxL_GetIxLoadFiles { fromWindowsDir filesToGet localFileName} {
    foreach currentFile $filesToGet {
	puts "IxL_GetCsvStatFiles:  $currentFile ..."
	catch {::IxLoad retrieveFileCopy $fromWindowsDir\\$currentFile $localFileName} errMsg
	if {$errMsg != ""} {
	    puts "\nError: Copying file from Windows PC: $currentFile\n"
	}
    }
}

proc IxL_StatCollectorCommand {args} {
    # statcollectorutils {timestamp 140000 stats {{kInt 0} {kInt 1872} {kInt 0} {kInt 0}}}
    set stats [lindex [lindex $args 1] 3]
    set timestamp [lindex [lindex $args 1] 1]

    puts "============================================"
    puts "Incoming stats: Time interval: $timestamp"
    puts "============================================"

    # This is to collect all the stats for csv file logging
    set eachRowStatsForCsv {}

    for {set index 0} {$index <= [llength $stats]} {incr index} {
	# { "HTTP Server" "TCP Connections Established" "kSum" }
	set sourceType [lindex [lindex $::statList $index] 0]
	set statName   [lindex [lindex $::statList $index] 1]
	set statNumber      [lindex [lindex $stats $index] 1]

	if {$sourceType != "" || $statName != ""} {	    
	    puts "$sourceType: $statName: $statNumber"
	    if {$eachRowStatsForCsv == ""} {
		append eachRowStatsForCsv $statNumber
	    } else {
		append eachRowStatsForCsv ",$statNumber"
	    }
	}
    }

    if {[info exists ::csvFilePathAndName]} {
	exec echo $eachRowStatsForCsv >> $::csvFilePathAndName
    }
}

proc IxL_CreateCsvResultFile {} {
    # Create a csv result file on local Linux machine
    set topCsvColumnLine [join $::statList ,]
    if {[info exists ::csvFilePathAndName]} {
	puts "\nIxL_CreateCsvResultFile: $::csvFilePathAndName\n"
	exec echo $topCsvColumnLine > $::csvFilePathAndName
    }
}

proc IxL_GetIxLoadFiles { fromWindowsDir filesToGet localFileName} {
    foreach currentFile $filesToGet {
	puts "IxL_GetCsvStatFiles:  $currentFile ..."
	catch {::IxLoad retrieveFileCopy $fromWindowsDir\\$currentFile $localFileName} errMsg
	if {$errMsg != ""} {
	    puts "\nError: Copying file from Windows PC: $currentFile\n"
	}
    }
}

proc IxL_EnterKeyToAbortTest {} {
    # configure stdin for polling
    fconfigure stdin -blocking 0 -buffering none

    # wait for the first sample or test stop
    while {$::ixTestControllerMonitor == "" && [read stdin] == ""} {
	after 100 set wakeup 1
	# the script must call vwait or update while test runs 
	# to keep TCL event loop going. Otherwise, no stat collector
	# callbacks will be made, and ixTestControllerMonitor will
	# never be set.
	vwait wakeup
    }

    if {$::ixTestControllerMonitor == ""} {
	puts "\nAborting test at earliest opportunity"
	# stop the run
	$::testController stopRun
	#
	# (v)wait until the test really stops
	#
	vwait ::ixTestControllerMonitor
	puts $::ixTestControllerMonitor
    }
}

#################################################
# IxLoad ScriptGen created script
# Test1 serialized using version 8.10.30.130
# scriptgen_ixload.tcl made on Dec 21 2016 09:27
#################################################


#################################################
# Copy content of setup_ixload_paths.tcl
#################################################

proc Main { configParams } {
    upvar $configParams params
    set paramList {}

    foreach {properties values} [array get params *] {
	set property [lindex [split $properties ,] end]
	set item [lindex [split $properties ,] 0]

	if {[regexp "timeLine" $property]} {
	    # 'timeLine_rampUpTime': '1'
	    set property1 [lindex [split $property _] 1]
	    set timeLine($property1) $values
	    
	} elseif {$item == "clientPortList"} {
	    # clientPortList,0,httpClientPort_cardId
	    set index [lindex [split $properties ,] 1]
	    set property1 [lindex [split $property _] 1]
	    set clientPort($index,$property1) $values
	    
	} elseif {$item == "serverPortList"} {
	    set index [lindex [split $properties ,] 1]
	    set property1 [lindex [split $property _] 1]
	    set serverPort($index,$property1) $values
	    
	} elseif {$item == "clientNetwork"} {
	    set index [lindex [split $properties ,] 1]
	    set property1 [lindex [split $property _] 1] ;# range1
	    set property2 [lindex [split $property _] end] ;# vlanId
	    if {$property2 == "totalRangeGroups"} {
		set clientNetwork($index,$property2) $values
	    } else {
		set clientNetwork($index,$property1,$property2) $values
	    }
	    
	} elseif {$item == "serverNetwork"} {
	    # serverNetwork,0,serverIp_range5_vlanIdCount
	    set index [lindex [split $properties ,] 1]
	    set property1 [lindex [split $property _] 1]
	    set property2 [lindex [split $property _] end]
	    if {$property2 == "totalRangeGroups"} {
		set serverNetwork($index,$property2) $values
	    } else {
		# $serverNetwork($index,range$number,vlanId)
		set serverNetwork($index,$property1,$property2) $values
	    }
	    
	} elseif {$item == "dutNetwork"} {
	    set index [lindex [split $properties ,] 1]
	    set property1 [lindex [split $property _] 1]
	    set property2 [lindex [split $property _] end]
	    if {[lsearch "totalRangeGroups name type" $property2] != -1} {
		set dutNetwork($index,$property2) $values
	    } else {
		set dutNetwork($index,$property1,$property2) $values
	    }
	    
	} elseif {$item == "httpClient"} {
	    # httpClient(0,1,destination) = DUT1
	    # httpClient(0,totalClientGroups) = 4
	    set index [lindex [split $properties ,] 1]
	    set property [lindex [split $properties ,] 2]

	    if {$property == "totalClientGroups"} {
		set httpClient($index,totalClientGroups) $values
	    } else {
		set property2 [lindex [split $properties ,] 3]
		set httpClient($index,$property,$property2) $values
	    }

	} elseif {[regexp "csvFilePathAndName" $property]} {
	    # Must globalize this variable so IxL_CreateCsvResultFile
	    # and IxL_StatCollectorCommand can use it
	    set ::$property $values
	} else {
	    set $property $values
	}
	
	append paramList " -$property $values"
    }
    
    puts "[parray clientNetwork]"
    puts "[parray serverNetwork]"
    puts [parray dutNetwork]
    puts [parray httpClient]

    puts "\nixLoadTclServer: $ixLoadTclServer"
    puts "ixLoadChassis: $ixChassisIp"

    puts "\nTotalClientNetworks: $totalClientNetworks"
    puts "\nTotalDutNetworks: $totalDutNetworks"

    #--------------- Scriptgen starts below ----------------#

    package require IxLoad

    ::IxLoad connect $ixLoadTclServer

    set ::statList { \
		       {"HTTP Client" "TCP Connections Established" "kSum"} \
		       {"HTTP Client" "TCP Connection Requests Failed" "kSum"} \
		       {"HTTP Client" "HTTP Simulated Users" "kSum"} \
		       {"HTTP Client" "HTTP Concurrent Connections" "kSum"} \
		       {"HTTP Client" "HTTP Connections" "kSum"} \
		       {"HTTP Client" "HTTP Transactions" "kSum"} \
		       {"HTTP Client" "HTTP Connection Attempts" "kSum"} \
		       {"HTTP Server" "TCP Connections Established" "kSum"} \
		       {"HTTP Server" "TCP Connection Requests Failed" "kSum"} \
		   }
    
    if [catch {
	
	package require statCollectorUtils
	set scu_version [package require statCollectorUtils]
	puts "statCollectorUtils package version = $scu_version"

	set logtag "IxLoad-api"
	set logName "scriptgen_ixload"
	set logger [::IxLoad new ixLogger $logtag 1]
	set logEngine [$logger getEngine]
	$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
	$logEngine setFile $logName 2 256 1

	global ixAppPluginManager
	$ixAppPluginManager load "HTTP"

	#################################################
	# Build chassis chain
	#################################################
	set chassisChain [::IxLoad new ixChassisChain]

	$chassisChain addChassis $ixChassisIp

	set Test1 [::IxLoad new ixTest]

	set scenarioElementFactory [$Test1 getScenarioElementFactory]

	set scenarioFactory [$Test1 getScenarioFactory]

	#################################################
	# Profile Directory
	#################################################
	set profileDirectory [$Test1 cget -profileDirectory]

	set my_ixEventHandlerSettings [::IxLoad new ixEventHandlerSettings]

	$my_ixEventHandlerSettings config \
	    -disabledEventClasses                    "" \
	    -disabledPorts                           "" 

	set my_ixViewOptions [::IxLoad new ixViewOptions]

	$my_ixViewOptions config \
	    -runMode                                 1 \
	    -captureRunDuration                      0 \
	    -captureRunAfter                         0 \
	    -collectScheme                           0 \
	    -allocatedBufferMemoryPercentage         30 

	$Test1 scenarioList.clear

	set Scenario1 [$scenarioFactory create "Scenario"]

	$Scenario1 columnList.clear

	set Originate [::IxLoad new ixTrafficColumn]

	$Originate elementList.clear

	#################################################
	# Create ScenarioElement kNetTraffic
	#################################################
	set Traffic0_CltNetwork_0 [$scenarioElementFactory create $::ixScenarioElementType(kNetTraffic)]



	#################################################
	# Network CltNetwork_0 of NetTraffic Traffic0@CltNetwork_0
	#################################################
	set CltNetwork_0 [$Traffic0_CltNetwork_0 cget -network]

	$CltNetwork_0 portList.appendItem \
	    -chassisId                               1 \
	    -cardId                                  1 \
	    -portId                                  1 

	$CltNetwork_0 globalPlugins.clear



	set Settings_2 [::IxLoad new ixNetIxLoadSettingsPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$CltNetwork_0 globalPlugins.appendItem -object $Settings_2



	$Settings_2 config \
	    -teardownInterfaceWithUser               false \
	    -_Stale                                  false \
	    -interfaceBehavior                       0 

	set Filter_1 [::IxLoad new ixNetFilterPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$CltNetwork_0 globalPlugins.appendItem -object $Filter_1



	$Filter_1 config \
	    -all                                     false \
	    -pppoecontrol                            false \
	    -isis                                    false \
	    -auto                                    true \
	    -udp                                     "" \
	    -tcp                                     "" \
	    -mac                                     "" \
	    -_Stale                                  false \
	    -pppoenetwork                            false \
	    -ip                                      "" \
	    -icmp                                    "" 

	set GratARP_1 [::IxLoad new ixNetGratArpPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$CltNetwork_0 globalPlugins.appendItem -object $GratARP_1



	$GratARP_1 config \
	    -forwardGratArp                          false \
	    -enabled                                 true \
	    -maxFramesPerSecond                      0 \
	    -_Stale                                  false \
	    -rateControlEnabled                      false 

	set TCP_2 [::IxLoad new ixNetTCPPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$CltNetwork_0 globalPlugins.appendItem -object $TCP_2



	$TCP_2 config \
	    -tcp_bic                                 0 \
	    -tcp_tw_recycle                          true \
	    -tcp_retries2                            5 \
	    -disable_min_max_buffer_size             true \
	    -tcp_retries1                            3 \
	    -tcp_keepalive_time                      7200 \
	    -tcp_mgmt_rmem                           87380 \
	    -tcp_rfc1337                             false \
	    -tcp_ipfrag_time                         30 \
	    -tcp_rto_max                             120000 \
	    -tcp_window_scaling                      false \
	    -adjust_tcp_buffers                      true \
	    -udp_port_randomization                  false \
	    -tcp_vegas_alpha                         2 \
	    -tcp_vegas_beta                          6 \
	    -tcp_wmem_max                            262144 \
	    -tcp_ecn                                 false \
	    -tcp_westwood                            0 \
	    -tcp_rto_min                             200 \
	    -delayed_acks_segments                   0 \
	    -tcp_vegas_cong_avoid                    0 \
	    -tcp_keepalive_intvl                     75 \
	    -tcp_rmem_max                            262144 \
	    -tcp_orphan_retries                      0 \
	    -bestPerfSettings                        false \
	    -tcp_max_tw_buckets                      180000 \
	    -_Stale                                  false \
	    -tcp_low_latency                         0 \
	    -tcp_rmem_min                            4096 \
	    -accept_ra_all                           false \
	    -tcp_adv_win_scale                       2 \
	    -tcp_wmem_default                        4096 \
	    -tcp_wmem_min                            4096 \
	    -tcp_port_min                            1024 \
	    -tcp_stdurg                              false \
	    -tcp_port_max                            65535 \
	    -tcp_fin_timeout                         60 \
	    -tcp_no_metrics_save                     false \
	    -tcp_dsack                               true \
	    -tcp_mgmt_wmem                           32768 \
	    -tcp_abort_on_overflow                   false \
	    -tcp_frto                                0 \
	    -tcp_mem_pressure                        32768 \
	    -tcp_app_win                             31 \
	    -ip_no_pmtu_disc                         true \
	    -llm_hdr_gap                             8 \
	    -tcp_max_orphans                         8192 \
	    -accept_ra_default                       false \
	    -tcp_syn_retries                         5 \
	    -tcp_moderate_rcvbuf                     0 \
	    -tcp_max_syn_backlog                     1024 \
	    -tcp_mem_low                             24576 \
	    -tcp_tw_rfc1323_strict                   false \
	    -tcp_fack                                true \
	    -tcp_retrans_collapse                    true \
	    -inter_packet_granular_delay             0.0 \
	    -llm_hdr_gap_ns                          10 \
	    -tcp_large_icwnd                         0 \
	    -tcp_rmem_default                        4096 \
	    -tcp_keepalive_probes                    9 \
	    -tcp_mem_high                            49152 \
	    -tcp_tw_reuse                            false \
	    -delayed_acks_timeout                    0 \
	    -tcp_vegas_gamma                         2 \
	    -delayed_acks                            true \
	    -tcp_synack_retries                      5 \
	    -tcp_timestamps                          true \
	    -tcp_reordering                          3 \
	    -rps_needed                              false \
	    -tcp_sack                                true \
	    -tcp_bic_fast_convergence                1 \
	    -tcp_bic_low_window                      14 

	set DNS_2 [::IxLoad new ixNetDnsPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$CltNetwork_0 globalPlugins.appendItem -object $DNS_2



	$DNS_2 hostList.clear



	$DNS_2 searchList.clear



	$DNS_2 nameServerList.clear



	$DNS_2 config \
	    -domain                                  "" \
	    -_Stale                                  false \
	    -timeout                                 30 

	set Meshing_1 [::IxLoad new ixNetMeshingPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$CltNetwork_0 globalPlugins.appendItem -object $Meshing_1



	$Meshing_1 trafficMaps.clear



	$Meshing_1 config -_Stale false

	$CltNetwork_0 config \
	    -comment                                 "" \
	    -name                                    "CltNetwork_0" \
	    -lineSpeed                               "Default" \
	    -aggregation                             0 

	set Ethernet_1 [$CltNetwork_0 getL1Plugin]



	set my_ixNetDataCenterSettings [::IxLoad new ixNetDataCenterSettings]

	$my_ixNetDataCenterSettings dcPfcMapping.clear



	$my_ixNetDataCenterSettings config \
	    -dcSupported                             true \
	    -dcEnabled                               false \
	    -dcPfcPauseDelay                         1 \
	    -_Stale                                  false \
	    -dcMode                                  2 \
	    -dcPfcPauseEnable                        false \
	    -dcFlowControl                           0 

	set my_ixNetEthernetELMPlugin [::IxLoad new ixNetEthernetELMPlugin]

	$my_ixNetEthernetELMPlugin config \
	    -negotiationType                         "master" \
	    -_Stale                                  false \
	    -negotiateMasterSlave                    true 

	set my_ixNetDualPhyPlugin [::IxLoad new ixNetDualPhyPlugin]

	$my_ixNetDualPhyPlugin config \
	    -medium                                  "auto" \
	    -_Stale                                  false 

	$Ethernet_1 childrenList.clear



	set MAC_VLAN_1 [::IxLoad new ixNetL2EthernetPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$Ethernet_1 childrenList.appendItem -object $MAC_VLAN_1



	$MAC_VLAN_1 childrenList.clear



	set IP_1 [::IxLoad new ixNetIpV4V6Plugin]

	# ixNet objects need to be added in the list before they are configured!
	$MAC_VLAN_1 childrenList.appendItem -object $IP_1



	$IP_1 childrenList.clear



	$IP_1 extensionList.clear



	$IP_1 config -_Stale false

	$MAC_VLAN_1 extensionList.clear



	$MAC_VLAN_1 config -_Stale false

	$Ethernet_1 extensionList.clear



	$Ethernet_1 config \
	    -advertise10Full                         true \
	    -directedAddress                         "01:80:C2:00:00:01" \
	    -autoNegotiate                           true \
	    -advertise100Half                        true \
	    -advertise10Half                         true \
	    -enableFlowControl                       false \
	    -_Stale                                  false \
	    -speed                                   "k100FD" \
	    -advertise1000Full                       true \
	    -advertise100Full                        true \
	    -dataCenter                              $my_ixNetDataCenterSettings \
	    -cardElm                                 $my_ixNetEthernetELMPlugin \
	    -cardDualPhy                             $my_ixNetDualPhyPlugin 

	#################################################
	# Setting the ranges starting with the plugins that need to be script gen first
	#################################################
	$IP_1 rangeList.clear

	set IP_R1 [::IxLoad new ixNetIpV4V6Range]

	# ixNet objects need to be added in the list before they are configured.
	$IP_1 rangeList.appendItem -object $IP_R1



	$IP_R1 config \
	    -count                                   100 \
	    -enableGatewayArp                        true \
	    -randomizeSeed                           155196417 \
	    -generateStatistics                      false \
	    -autoIpTypeEnabled                       false \
	    -autoCountEnabled                        false \
	    -enabled                                 true \
	    -autoMacGeneration                       true \
	    -publishStats                            false \
	    -incrementBy                             "0.0.1.0" \
	    -prefix                                  24 \
	    -_Stale                                  false \
	    -gatewayIncrement                        "0.0.1.0" \
	    -gatewayIncrementMode                    "perSubnet" \
	    -mss                                     1460 \
	    -randomizeAddress                        false \
	    -gatewayAddress                          "1.1.1.101" \
	    -ipAddress                               "1.1.1.1" \
	    -ipType                                  "IPv4" 

	set MAC_R1 [$IP_R1 getLowerRelatedRange "MacRange"]

	$MAC_R1 config \
	    -count                                   100 \
	    -enabled                                 true \
	    -mtu                                     1500 \
	    -mac                                     "00:01:01:01:01:01" \
	    -_Stale                                  false \
	    -incrementBy                             "00:00:00:00:00:01" 

	set VLAN_R1 [$IP_R1 getLowerRelatedRange "VlanIdRange"]

	$VLAN_R1 config \
	    -incrementStep                           1 \
	    -innerIncrement                          1 \
	    -uniqueCount                             100 \
	    -firstId                                 2001 \
	    -tpid                                    "0x8100" \
	    -idIncrMode                              2 \
	    -enabled                                 true \
	    -innerFirstId                            1 \
	    -innerIncrementStep                      1 \
	    -priority                                1 \
	    -_Stale                                  false \
	    -increment                               1 \
	    -innerTpid                               "0x8100" \
	    -innerUniqueCount                        4094 \
	    -innerEnable                             false \
	    -innerPriority                           1 

	set IP_R2 [::IxLoad new ixNetIpV4V6Range]

	# ixNet objects need to be added in the list before they are configured.
	$IP_1 rangeList.appendItem -object $IP_R2



	$IP_R2 config \
	    -count                                   100 \
	    -enableGatewayArp                        true \
	    -randomizeSeed                           155196417 \
	    -generateStatistics                      false \
	    -autoIpTypeEnabled                       false \
	    -autoCountEnabled                        false \
	    -enabled                                 true \
	    -autoMacGeneration                       true \
	    -publishStats                            false \
	    -incrementBy                             "0.0.1.0" \
	    -prefix                                  24 \
	    -_Stale                                  false \
	    -gatewayIncrement                        "0.0.1.0" \
	    -gatewayIncrementMode                    "perSubnet" \
	    -mss                                     1460 \
	    -randomizeAddress                        false \
	    -gatewayAddress                          "2.1.1.101" \
	    -ipAddress                               "2.1.1.1" \
	    -ipType                                  "IPv4" 

	set MAC_R2 [$IP_R2 getLowerRelatedRange "MacRange"]

	$MAC_R2 config \
	    -count                                   100 \
	    -enabled                                 true \
	    -mtu                                     1500 \
	    -mac                                     "00:01:01:01:01:01" \
	    -_Stale                                  false \
	    -incrementBy                             "00:00:00:00:00:01" 

	set VLAN_R2 [$IP_R2 getLowerRelatedRange "VlanIdRange"]

	$VLAN_R2 config \
	    -incrementStep                           1 \
	    -innerIncrement                          1 \
	    -uniqueCount                             100 \
	    -firstId                                 2101 \
	    -tpid                                    "0x8100" \
	    -idIncrMode                              2 \
	    -enabled                                 true \
	    -innerFirstId                            1 \
	    -innerIncrementStep                      1 \
	    -priority                                1 \
	    -_Stale                                  false \
	    -increment                               1 \
	    -innerTpid                               "0x8100" \
	    -innerUniqueCount                        4094 \
	    -innerEnable                             false \
	    -innerPriority                           1 

	set IP_R3 [::IxLoad new ixNetIpV4V6Range]

	# ixNet objects need to be added in the list before they are configured.
	$IP_1 rangeList.appendItem -object $IP_R3



	$IP_R3 config \
	    -count                                   100 \
	    -enableGatewayArp                        true \
	    -randomizeSeed                           155196417 \
	    -generateStatistics                      false \
	    -autoIpTypeEnabled                       false \
	    -autoCountEnabled                        false \
	    -enabled                                 true \
	    -autoMacGeneration                       true \
	    -publishStats                            false \
	    -incrementBy                             "0.0.1.0" \
	    -prefix                                  24 \
	    -_Stale                                  false \
	    -gatewayIncrement                        "0.0.1.0" \
	    -gatewayIncrementMode                    "perSubnet" \
	    -mss                                     1460 \
	    -randomizeAddress                        false \
	    -gatewayAddress                          "3.1.1.101" \
	    -ipAddress                               "3.1.1.1" \
	    -ipType                                  "IPv4" 

	set MAC_R3 [$IP_R3 getLowerRelatedRange "MacRange"]

	$MAC_R3 config \
	    -count                                   100 \
	    -enabled                                 true \
	    -mtu                                     1500 \
	    -mac                                     "00:01:01:01:01:01" \
	    -_Stale                                  false \
	    -incrementBy                             "00:00:00:00:00:01" 

	set VLAN_R3 [$IP_R3 getLowerRelatedRange "VlanIdRange"]

	$VLAN_R3 config \
	    -incrementStep                           1 \
	    -innerIncrement                          1 \
	    -uniqueCount                             100 \
	    -firstId                                 2201 \
	    -tpid                                    "0x8100" \
	    -idIncrMode                              2 \
	    -enabled                                 true \
	    -innerFirstId                            1 \
	    -innerIncrementStep                      1 \
	    -priority                                1 \
	    -_Stale                                  false \
	    -increment                               1 \
	    -innerTpid                               "0x8100" \
	    -innerUniqueCount                        4094 \
	    -innerEnable                             false \
	    -innerPriority                           1 

	#################################################
	# Creating the IP Distribution Groups
	#################################################
	$IP_1 rangeGroups.clear



	set DistGroup1 [::IxLoad new ixNetRangeGroup]

	# ixNet objects need to be added in the list before they are configured!
	$IP_1 rangeGroups.appendItem -object $DistGroup1



	# ixNet objects need to be added in the list before they are configured.
	$DistGroup1 rangeList.appendItem -object $IP_R1



	# ixNet objects need to be added in the list before they are configured.
	$DistGroup1 rangeList.appendItem -object $IP_R2



	# ixNet objects need to be added in the list before they are configured.
	$DistGroup1 rangeList.appendItem -object $IP_R3



	$DistGroup1 config \
	    -distribType                             0 \
	    -_Stale                                  false \
	    -name                                    "DistGroup1" 

	$Traffic0_CltNetwork_0 config \
	    -enable                                  true \
	    -tcpAccelerationAllowedFlag              true \
	    -network                                 $CltNetwork_0 

	#################################################
	# Activity HTTP_Client1_1 of NetTraffic Traffic0@CltNetwork_0
	#################################################
	set Activity_HTTP_Client1_1 [$Traffic0_CltNetwork_0 activityList.appendItem -protocolAndType "HTTP Client"]

	#################################################
	# timeLine_0 for activities HTTP_Client1_1
	#################################################
	set timeLine_0 [::IxLoad new ixTimeline]

	$timeLine_0 config \
	    -rampUpValue                             1 \
	    -rampUpType                              0 \
	    -offlineTime                             0 \
	    -rampDownTime                            20 \
	    -standbyTime                             0 \
	    -rampDownValue                           0 \
	    -iterations                              1 \
	    -rampUpInterval                          1 \
	    -sustainTime                             20 \
	    -timelineType                            0 \
	    -name                                    "timeLine_0" 

	$Activity_HTTP_Client1_1 config \
	    -secondaryConstraintValue                100 \
	    -enable                                  true \
	    -name                                    "HTTP_Client1_1" \
	    -userIpMapping                           "1:1" \
	    -enableConstraint                        true \
	    -timerGranularity                        100 \
	    -secondaryEnableConstraint               false \
	    -constraintValue                         99 \
	    -userObjectiveValue                      9 \
	    -secondaryConstraintType                 "SimulatedUserConstraint" \
	    -constraintType                          "SimulatedUserConstraint" \
	    -userObjectiveType                       "throughputMbps" \
	    -destinationIpMapping                    "Consecutive" \
	    -timeline                                $timeLine_0 

	$Activity_HTTP_Client1_1 agent.actionList.clear

	set my_ixHttpCommand [::IxLoad new ixHttpCommand]

	$my_ixHttpCommand config \
	    -profile                                 -1 \
	    -enableDi                                false \
	    -namevalueargs                           "" \
	    -useSsl                                  false \
	    -pingFreq                                10 \
	    -streamIden                              3 \
	    -destination                             "DUT1:80" \
	    -sendMD5ChkSumHeader                     false \
	    -windowSize                              "65536" \
	    -cmdName                                 "Get 1" \
	    -method                                  -1 \
	    -commandType                             "GET" \
	    -abort                                   "None" \
	    -arguments                               "" \
	    -sslProfile                              -1 \
	    -pageObject                              "/32k.html" \
	    -sendingChunkSize                        "None" 

	$Activity_HTTP_Client1_1 agent.actionList.appendItem -object $my_ixHttpCommand



	$Activity_HTTP_Client1_1 agent.headerList.clear

	set my_ixHttpHeaderString [::IxLoad new ixHttpHeaderString]

	$my_ixHttpHeaderString config -data "Accept: */*"

	$Activity_HTTP_Client1_1 agent.headerList.appendItem -object $my_ixHttpHeaderString



	set my_ixHttpHeaderString1 [::IxLoad new ixHttpHeaderString]

	$my_ixHttpHeaderString1 config -data "Accept-Language: en-us"

	$Activity_HTTP_Client1_1 agent.headerList.appendItem -object $my_ixHttpHeaderString1



	set my_ixHttpHeaderString2 [::IxLoad new ixHttpHeaderString]

	$my_ixHttpHeaderString2 config -data "Accept-Encoding: gzip, deflate"

	$Activity_HTTP_Client1_1 agent.headerList.appendItem -object $my_ixHttpHeaderString2



	set my_ixHttpHeaderString3 [::IxLoad new ixHttpHeaderString]

	$my_ixHttpHeaderString3 config -data "User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322)"

	$Activity_HTTP_Client1_1 agent.headerList.appendItem -object $my_ixHttpHeaderString3



	$Activity_HTTP_Client1_1 agent.profileList.clear

	$Activity_HTTP_Client1_1 agent.methodProfileList.clear

	$Activity_HTTP_Client1_1 agent.sslProfileList.clear

	$Activity_HTTP_Client1_1 agent.config \
	    -cmdListLoops                            0 \
	    -vlanPriority                            0 \
	    -validateCertificate                     false \
	    -enableDecompressSupport                 false \
	    -exactTransactions                       false \
	    -enableHttpsProxy                        false \
	    -perHeaderPercentDist                    false \
	    -enableSsl                               false \
	    -enablePerConnCookieSupport              false \
	    -cookieRejectProbability                 0.0 \
	    -enableUnidirectionalClose               false \
	    -httpsTunnel                             "0.0.0.0" \
	    -piggybackAck                            true \
	    -maxPersistentRequests                   100 \
	    -enableEsm                               false \
	    -certificate                             "" \
	    -sequentialSessionReuse                  0 \
	    -browserEmulationName                    "Custom1" \
	    -enableSslSendCloseNotify                false \
	    -cookieJarSize                           10 \
	    -dontUseUpgrade                          0 \
	    -maxPipeline                             1 \
	    -contentLengthDeviationTolerance         0 \
	    -caCert                                  "" \
	    -maxSessions                             3 \
	    -enableHttpProxy                         false \
	    -disableDnsResolutionCache               false \
	    -enableTrafficDistributionForCC          0 \
	    -enableTos                               false \
	    -precedenceTOS                           0 \
	    -ipPreference                            2 \
	    -maxHeaderLen                            1024 \
	    -flowPercentage                          100.0 \
	    -maxStreams                              1 \
	    -reliabilityTOS                          0 \
	    -sslRecordSize                           "16384" \
	    -privateKey                              "" \
	    -commandTimeout                          600 \
	    -enablemetaRedirectSupport               false \
	    -delayTOS                                0 \
	    -enableIntegrityCheckSupport             false \
	    -commandTimeout_ms                       0 \
	    -privateKeyPassword                      "" \
	    -urlStatsCount                           10 \
	    -followHttpRedirects                     false \
	    -tcpCloseOption                          0 \
	    -enableVlanPriority                      false \
	    -esm                                     1460 \
	    -httpVersion                             1 \
	    -enablesslRecordSize                     false \
	    -sslReuseMethod                          0 \
	    -sslVersion                              3 \
	    -enableLargeHeader                       false \
	    -throughputTOS                           0 \
	    -enableCookieSupport                     false \
	    -enableConsecutiveIpsPerSession          false \
	    -clientCiphers                           "DEFAULT" \
	    -enableHttpsTunnel                       false \
	    -enableAchieveCCFirst                    false \
	    -tos                                     0 \
	    -httpProxy                               "0.0.0.0" \
	    -keepAlive                               false \
	    -enableCRCCheckSupport                   false \
	    -httpsProxy                              "0.0.0.0" 

	$Activity_HTTP_Client1_1 agent.cmdPercentagePool.percentageCommandList.clear

	$Activity_HTTP_Client1_1 agent.cmdPercentagePool.config -seed 1

	$Traffic0_CltNetwork_0 traffic.config -name "Traffic0"

	$Traffic0_CltNetwork_0 setPortOperationModeAllowed $::ixPort(kOperationModeThroughputAcceleration) false

	$Traffic0_CltNetwork_0 setPortOperationModeAllowed $::ixPort(kOperationModeFCoEOffload) true

	$Traffic0_CltNetwork_0 setPortOperationModeAllowed $::ixPort(kOperationModeL23) true

	$Traffic0_CltNetwork_0 setTcpAccelerationAllowed $::ixAgent(kTcpAcceleration) true

	$Originate elementList.appendItem -object $Traffic0_CltNetwork_0



	$Originate config -name "Originate"

	$Scenario1 columnList.appendItem -object $Originate



	set DUT [::IxLoad new ixTrafficColumn]

	$DUT elementList.clear

	$DUT config -name "DUT"

	$Scenario1 columnList.appendItem -object $DUT



	set Terminate [::IxLoad new ixTrafficColumn]

	$Terminate elementList.clear

	#################################################
	# Create ScenarioElement kNetTraffic
	#################################################
	set SvrTraffic0_SvrNetwork_0 [$scenarioElementFactory create $::ixScenarioElementType(kNetTraffic)]



	#################################################
	# Network SvrNetwork_0 of NetTraffic SvrTraffic0@SvrNetwork_0
	#################################################
	set SvrNetwork_0 [$SvrTraffic0_SvrNetwork_0 cget -network]

	$SvrNetwork_0 portList.appendItem \
	    -chassisId                               1 \
	    -cardId                                  1 \
	    -portId                                  2 

	$SvrNetwork_0 globalPlugins.clear



	set Settings_4 [::IxLoad new ixNetIxLoadSettingsPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$SvrNetwork_0 globalPlugins.appendItem -object $Settings_4



	$Settings_4 config \
	    -teardownInterfaceWithUser               false \
	    -_Stale                                  false \
	    -interfaceBehavior                       0 

	set Filter_2 [::IxLoad new ixNetFilterPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$SvrNetwork_0 globalPlugins.appendItem -object $Filter_2



	$Filter_2 config \
	    -all                                     false \
	    -pppoecontrol                            false \
	    -isis                                    false \
	    -auto                                    true \
	    -udp                                     "" \
	    -tcp                                     "" \
	    -mac                                     "" \
	    -_Stale                                  false \
	    -pppoenetwork                            false \
	    -ip                                      "" \
	    -icmp                                    "" 

	set GratARP_2 [::IxLoad new ixNetGratArpPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$SvrNetwork_0 globalPlugins.appendItem -object $GratARP_2



	$GratARP_2 config \
	    -forwardGratArp                          false \
	    -enabled                                 true \
	    -maxFramesPerSecond                      0 \
	    -_Stale                                  false \
	    -rateControlEnabled                      false 

	set TCP_4 [::IxLoad new ixNetTCPPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$SvrNetwork_0 globalPlugins.appendItem -object $TCP_4



	$TCP_4 config \
	    -tcp_bic                                 0 \
	    -tcp_tw_recycle                          true \
	    -tcp_retries2                            5 \
	    -disable_min_max_buffer_size             true \
	    -tcp_retries1                            3 \
	    -tcp_keepalive_time                      7200 \
	    -tcp_mgmt_rmem                           87380 \
	    -tcp_rfc1337                             false \
	    -tcp_ipfrag_time                         30 \
	    -tcp_rto_max                             120000 \
	    -tcp_window_scaling                      false \
	    -adjust_tcp_buffers                      true \
	    -udp_port_randomization                  false \
	    -tcp_vegas_alpha                         2 \
	    -tcp_vegas_beta                          6 \
	    -tcp_wmem_max                            262144 \
	    -tcp_ecn                                 false \
	    -tcp_westwood                            0 \
	    -tcp_rto_min                             200 \
	    -delayed_acks_segments                   0 \
	    -tcp_vegas_cong_avoid                    0 \
	    -tcp_keepalive_intvl                     75 \
	    -tcp_rmem_max                            262144 \
	    -tcp_orphan_retries                      0 \
	    -bestPerfSettings                        false \
	    -tcp_max_tw_buckets                      180000 \
	    -_Stale                                  false \
	    -tcp_low_latency                         0 \
	    -tcp_rmem_min                            4096 \
	    -accept_ra_all                           false \
	    -tcp_adv_win_scale                       2 \
	    -tcp_wmem_default                        4096 \
	    -tcp_wmem_min                            4096 \
	    -tcp_port_min                            1024 \
	    -tcp_stdurg                              false \
	    -tcp_port_max                            65535 \
	    -tcp_fin_timeout                         60 \
	    -tcp_no_metrics_save                     false \
	    -tcp_dsack                               true \
	    -tcp_mgmt_wmem                           32768 \
	    -tcp_abort_on_overflow                   false \
	    -tcp_frto                                0 \
	    -tcp_mem_pressure                        32768 \
	    -tcp_app_win                             31 \
	    -ip_no_pmtu_disc                         true \
	    -llm_hdr_gap                             8 \
	    -tcp_max_orphans                         8192 \
	    -accept_ra_default                       false \
	    -tcp_syn_retries                         5 \
	    -tcp_moderate_rcvbuf                     0 \
	    -tcp_max_syn_backlog                     1024 \
	    -tcp_mem_low                             24576 \
	    -tcp_tw_rfc1323_strict                   false \
	    -tcp_fack                                true \
	    -tcp_retrans_collapse                    true \
	    -inter_packet_granular_delay             0.0 \
	    -llm_hdr_gap_ns                          10 \
	    -tcp_large_icwnd                         0 \
	    -tcp_rmem_default                        4096 \
	    -tcp_keepalive_probes                    9 \
	    -tcp_mem_high                            49152 \
	    -tcp_tw_reuse                            false \
	    -delayed_acks_timeout                    0 \
	    -tcp_vegas_gamma                         2 \
	    -delayed_acks                            true \
	    -tcp_synack_retries                      5 \
	    -tcp_timestamps                          true \
	    -tcp_reordering                          3 \
	    -rps_needed                              false \
	    -tcp_sack                                true \
	    -tcp_bic_fast_convergence                1 \
	    -tcp_bic_low_window                      14 

	set DNS_4 [::IxLoad new ixNetDnsPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$SvrNetwork_0 globalPlugins.appendItem -object $DNS_4



	$DNS_4 hostList.clear



	$DNS_4 searchList.clear



	$DNS_4 nameServerList.clear



	$DNS_4 config \
	    -domain                                  "" \
	    -_Stale                                  false \
	    -timeout                                 30 

	set Meshing_2 [::IxLoad new ixNetMeshingPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$SvrNetwork_0 globalPlugins.appendItem -object $Meshing_2



	$Meshing_2 trafficMaps.clear



	$Meshing_2 config -_Stale false

	$SvrNetwork_0 config \
	    -comment                                 "" \
	    -name                                    "SvrNetwork_0" \
	    -lineSpeed                               "Default" \
	    -aggregation                             0 

	set Ethernet_2 [$SvrNetwork_0 getL1Plugin]



	set my_ixNetDataCenterSettings1 [::IxLoad new ixNetDataCenterSettings]

	$my_ixNetDataCenterSettings1 dcPfcMapping.clear



	$my_ixNetDataCenterSettings1 config \
	    -dcSupported                             true \
	    -dcEnabled                               false \
	    -dcPfcPauseDelay                         1 \
	    -_Stale                                  false \
	    -dcMode                                  2 \
	    -dcPfcPauseEnable                        false \
	    -dcFlowControl                           0 

	set my_ixNetEthernetELMPlugin1 [::IxLoad new ixNetEthernetELMPlugin]

	$my_ixNetEthernetELMPlugin1 config \
	    -negotiationType                         "master" \
	    -_Stale                                  false \
	    -negotiateMasterSlave                    true 

	set my_ixNetDualPhyPlugin1 [::IxLoad new ixNetDualPhyPlugin]

	$my_ixNetDualPhyPlugin1 config \
	    -medium                                  "auto" \
	    -_Stale                                  false 

	$Ethernet_2 childrenList.clear



	set MAC_VLAN_2 [::IxLoad new ixNetL2EthernetPlugin]

	# ixNet objects need to be added in the list before they are configured!
	$Ethernet_2 childrenList.appendItem -object $MAC_VLAN_2



	$MAC_VLAN_2 childrenList.clear



	set IP_2 [::IxLoad new ixNetIpV4V6Plugin]

	# ixNet objects need to be added in the list before they are configured!
	$MAC_VLAN_2 childrenList.appendItem -object $IP_2



	$IP_2 childrenList.clear



	$IP_2 extensionList.clear



	$IP_2 config -_Stale false

	$MAC_VLAN_2 extensionList.clear



	$MAC_VLAN_2 config -_Stale false

	$Ethernet_2 extensionList.clear



	$Ethernet_2 config \
	    -advertise10Full                         true \
	    -directedAddress                         "01:80:C2:00:00:01" \
	    -autoNegotiate                           true \
	    -advertise100Half                        true \
	    -advertise10Half                         true \
	    -enableFlowControl                       false \
	    -_Stale                                  false \
	    -speed                                   "k100FD" \
	    -advertise1000Full                       true \
	    -advertise100Full                        true \
	    -dataCenter                              $my_ixNetDataCenterSettings1 \
	    -cardElm                                 $my_ixNetEthernetELMPlugin1 \
	    -cardDualPhy                             $my_ixNetDualPhyPlugin1 

	#################################################
	# Setting the ranges starting with the plugins that need to be script gen first
	#################################################
	$IP_2 rangeList.clear

	set IP_R4 [::IxLoad new ixNetIpV4V6Range]

	# ixNet objects need to be added in the list before they are configured.
	$IP_2 rangeList.appendItem -object $IP_R4



	$IP_R4 config \
	    -count                                   100 \
	    -enableGatewayArp                        true \
	    -randomizeSeed                           155196417 \
	    -generateStatistics                      false \
	    -autoIpTypeEnabled                       false \
	    -autoCountEnabled                        false \
	    -enabled                                 true \
	    -autoMacGeneration                       true \
	    -publishStats                            false \
	    -incrementBy                             "0.0.1.0" \
	    -prefix                                  24 \
	    -_Stale                                  false \
	    -gatewayIncrement                        "0.0.1.0" \
	    -gatewayIncrementMode                    "perSubnet" \
	    -mss                                     1460 \
	    -randomizeAddress                        false \
	    -gatewayAddress                          "11.1.1.100" \
	    -ipAddress                               "11.1.1.1" \
	    -ipType                                  "IPv4" 

	set MAC_R4 [$IP_R4 getLowerRelatedRange "MacRange"]

	$MAC_R4 config \
	    -count                                   100 \
	    -enabled                                 true \
	    -mtu                                     1500 \
	    -mac                                     "00:01:01:02:01:01" \
	    -_Stale                                  false \
	    -incrementBy                             "00:00:00:00:00:01" 

	set VLAN_R4 [$IP_R4 getLowerRelatedRange "VlanIdRange"]

	$VLAN_R4 config \
	    -incrementStep                           1 \
	    -innerIncrement                          1 \
	    -uniqueCount                             100 \
	    -firstId                                 2501 \
	    -tpid                                    "0x8100" \
	    -idIncrMode                              2 \
	    -enabled                                 true \
	    -innerFirstId                            1 \
	    -innerIncrementStep                      1 \
	    -priority                                1 \
	    -_Stale                                  false \
	    -increment                               1 \
	    -innerTpid                               "0x8100" \
	    -innerUniqueCount                        4094 \
	    -innerEnable                             false \
	    -innerPriority                           1 

	set IP_R5 [::IxLoad new ixNetIpV4V6Range]

	# ixNet objects need to be added in the list before they are configured.
	$IP_2 rangeList.appendItem -object $IP_R5



	$IP_R5 config \
	    -count                                   100 \
	    -enableGatewayArp                        true \
	    -randomizeSeed                           155196417 \
	    -generateStatistics                      false \
	    -autoIpTypeEnabled                       false \
	    -autoCountEnabled                        false \
	    -enabled                                 true \
	    -autoMacGeneration                       true \
	    -publishStats                            false \
	    -incrementBy                             "0.0.1.0" \
	    -prefix                                  24 \
	    -_Stale                                  false \
	    -gatewayIncrement                        "0.0.1.0" \
	    -gatewayIncrementMode                    "perSubnet" \
	    -mss                                     1460 \
	    -randomizeAddress                        false \
	    -gatewayAddress                          "11.1.1.100" \
	    -ipAddress                               "11.1.1.2" \
	    -ipType                                  "IPv4" 

	set MAC_R5 [$IP_R5 getLowerRelatedRange "MacRange"]

	$MAC_R5 config \
	    -count                                   100 \
	    -enabled                                 true \
	    -mtu                                     1500 \
	    -mac                                     "00:01:01:02:01:01" \
	    -_Stale                                  false \
	    -incrementBy                             "00:00:00:00:00:01" 

	set VLAN_R5 [$IP_R5 getLowerRelatedRange "VlanIdRange"]

	$VLAN_R5 config \
	    -incrementStep                           1 \
	    -innerIncrement                          1 \
	    -uniqueCount                             100 \
	    -firstId                                 2501 \
	    -tpid                                    "0x8100" \
	    -idIncrMode                              2 \
	    -enabled                                 true \
	    -innerFirstId                            1 \
	    -innerIncrementStep                      1 \
	    -priority                                1 \
	    -_Stale                                  false \
	    -increment                               1 \
	    -innerTpid                               "0x8100" \
	    -innerUniqueCount                        4094 \
	    -innerEnable                             false \
	    -innerPriority                           1 

	set IP_R6 [::IxLoad new ixNetIpV4V6Range]

	# ixNet objects need to be added in the list before they are configured.
	$IP_2 rangeList.appendItem -object $IP_R6



	$IP_R6 config \
	    -count                                   100 \
	    -enableGatewayArp                        true \
	    -randomizeSeed                           155196417 \
	    -generateStatistics                      false \
	    -autoIpTypeEnabled                       false \
	    -autoCountEnabled                        false \
	    -enabled                                 true \
	    -autoMacGeneration                       true \
	    -publishStats                            false \
	    -incrementBy                             "0.0.1.0" \
	    -prefix                                  24 \
	    -_Stale                                  false \
	    -gatewayIncrement                        "0.0.1.0" \
	    -gatewayIncrementMode                    "perSubnet" \
	    -mss                                     1460 \
	    -randomizeAddress                        false \
	    -gatewayAddress                          "12.1.1.100" \
	    -ipAddress                               "12.1.1.1" \
	    -ipType                                  "IPv4" 

	set MAC_R6 [$IP_R6 getLowerRelatedRange "MacRange"]

	$MAC_R6 config \
	    -count                                   100 \
	    -enabled                                 true \
	    -mtu                                     1500 \
	    -mac                                     "00:01:01:02:01:01" \
	    -_Stale                                  false \
	    -incrementBy                             "00:00:00:00:00:01" 

	set VLAN_R6 [$IP_R6 getLowerRelatedRange "VlanIdRange"]

	$VLAN_R6 config \
	    -incrementStep                           1 \
	    -innerIncrement                          1 \
	    -uniqueCount                             100 \
	    -firstId                                 2601 \
	    -tpid                                    "0x8100" \
	    -idIncrMode                              2 \
	    -enabled                                 true \
	    -innerFirstId                            1 \
	    -innerIncrementStep                      1 \
	    -priority                                1 \
	    -_Stale                                  false \
	    -increment                               1 \
	    -innerTpid                               "0x8100" \
	    -innerUniqueCount                        4094 \
	    -innerEnable                             false \
	    -innerPriority                           1 

	set IP_R7 [::IxLoad new ixNetIpV4V6Range]

	# ixNet objects need to be added in the list before they are configured.
	$IP_2 rangeList.appendItem -object $IP_R7



	$IP_R7 config \
	    -count                                   100 \
	    -enableGatewayArp                        true \
	    -randomizeSeed                           155196417 \
	    -generateStatistics                      false \
	    -autoIpTypeEnabled                       false \
	    -autoCountEnabled                        false \
	    -enabled                                 true \
	    -autoMacGeneration                       true \
	    -publishStats                            false \
	    -incrementBy                             "0.0.1.0" \
	    -prefix                                  24 \
	    -_Stale                                  false \
	    -gatewayIncrement                        "0.0.1.0" \
	    -gatewayIncrementMode                    "perSubnet" \
	    -mss                                     1460 \
	    -randomizeAddress                        false \
	    -gatewayAddress                          "12.1.1.100" \
	    -ipAddress                               "12.1.1.2" \
	    -ipType                                  "IPv4" 

	set MAC_R7 [$IP_R7 getLowerRelatedRange "MacRange"]

	$MAC_R7 config \
	    -count                                   100 \
	    -enabled                                 true \
	    -mtu                                     1500 \
	    -mac                                     "00:01:01:02:01:01" \
	    -_Stale                                  false \
	    -incrementBy                             "00:00:00:00:00:01" 

	set VLAN_R7 [$IP_R7 getLowerRelatedRange "VlanIdRange"]

	$VLAN_R7 config \
	    -incrementStep                           1 \
	    -innerIncrement                          1 \
	    -uniqueCount                             100 \
	    -firstId                                 2601 \
	    -tpid                                    "0x8100" \
	    -idIncrMode                              2 \
	    -enabled                                 true \
	    -innerFirstId                            1 \
	    -innerIncrementStep                      1 \
	    -priority                                1 \
	    -_Stale                                  false \
	    -increment                               1 \
	    -innerTpid                               "0x8100" \
	    -innerUniqueCount                        4094 \
	    -innerEnable                             false \
	    -innerPriority                           1 

	set IP_R8 [::IxLoad new ixNetIpV4V6Range]

	# ixNet objects need to be added in the list before they are configured.
	$IP_2 rangeList.appendItem -object $IP_R8



	$IP_R8 config \
	    -count                                   100 \
	    -enableGatewayArp                        true \
	    -randomizeSeed                           155196417 \
	    -generateStatistics                      false \
	    -autoIpTypeEnabled                       false \
	    -autoCountEnabled                        false \
	    -enabled                                 true \
	    -autoMacGeneration                       true \
	    -publishStats                            false \
	    -incrementBy                             "0.0.1.0" \
	    -prefix                                  24 \
	    -_Stale                                  false \
	    -gatewayIncrement                        "0.0.1.0" \
	    -gatewayIncrementMode                    "perSubnet" \
	    -mss                                     1460 \
	    -randomizeAddress                        false \
	    -gatewayAddress                          "13.1.1.100" \
	    -ipAddress                               "13.1.1.1" \
	    -ipType                                  "IPv4" 

	set MAC_R8 [$IP_R8 getLowerRelatedRange "MacRange"]

	$MAC_R8 config \
	    -count                                   100 \
	    -enabled                                 true \
	    -mtu                                     1500 \
	    -mac                                     "00:01:01:02:01:01" \
	    -_Stale                                  false \
	    -incrementBy                             "00:00:00:00:00:01" 

	set VLAN_R8 [$IP_R8 getLowerRelatedRange "VlanIdRange"]

	$VLAN_R8 config \
	    -incrementStep                           1 \
	    -innerIncrement                          1 \
	    -uniqueCount                             100 \
	    -firstId                                 2701 \
	    -tpid                                    "0x8100" \
	    -idIncrMode                              2 \
	    -enabled                                 true \
	    -innerFirstId                            1 \
	    -innerIncrementStep                      1 \
	    -priority                                1 \
	    -_Stale                                  false \
	    -increment                               1 \
	    -innerTpid                               "0x8100" \
	    -innerUniqueCount                        4094 \
	    -innerEnable                             false \
	    -innerPriority                           1 

	set IP_R9 [::IxLoad new ixNetIpV4V6Range]

	# ixNet objects need to be added in the list before they are configured.
	$IP_2 rangeList.appendItem -object $IP_R9



	$IP_R9 config \
	    -count                                   100 \
	    -enableGatewayArp                        true \
	    -randomizeSeed                           155196417 \
	    -generateStatistics                      false \
	    -autoIpTypeEnabled                       false \
	    -autoCountEnabled                        false \
	    -enabled                                 true \
	    -autoMacGeneration                       true \
	    -publishStats                            false \
	    -incrementBy                             "0.0.1.0" \
	    -prefix                                  24 \
	    -_Stale                                  false \
	    -gatewayIncrement                        "0.0.1.0" \
	    -gatewayIncrementMode                    "perSubnet" \
	    -mss                                     1460 \
	    -randomizeAddress                        false \
	    -gatewayAddress                          "13.1.1.100" \
	    -ipAddress                               "13.1.1.2" \
	    -ipType                                  "IPv4" 

	set MAC_R9 [$IP_R9 getLowerRelatedRange "MacRange"]

	$MAC_R9 config \
	    -count                                   100 \
	    -enabled                                 true \
	    -mtu                                     1500 \
	    -mac                                     "00:01:01:02:01:01" \
	    -_Stale                                  false \
	    -incrementBy                             "00:00:00:00:00:01" 

	set VLAN_R9 [$IP_R9 getLowerRelatedRange "VlanIdRange"]

	$VLAN_R9 config \
	    -incrementStep                           1 \
	    -innerIncrement                          1 \
	    -uniqueCount                             100 \
	    -firstId                                 2701 \
	    -tpid                                    "0x8100" \
	    -idIncrMode                              2 \
	    -enabled                                 true \
	    -innerFirstId                            1 \
	    -innerIncrementStep                      1 \
	    -priority                                1 \
	    -_Stale                                  false \
	    -increment                               1 \
	    -innerTpid                               "0x8100" \
	    -innerUniqueCount                        4094 \
	    -innerEnable                             false \
	    -innerPriority                           1 

	#################################################
	# Creating the IP Distribution Groups
	#################################################
	$IP_2 rangeGroups.clear



	set DistGroup2 [::IxLoad new ixNetRangeGroup]

	# ixNet objects need to be added in the list before they are configured!
	$IP_2 rangeGroups.appendItem -object $DistGroup2



	# ixNet objects need to be added in the list before they are configured.
	$DistGroup2 rangeList.appendItem -object $IP_R4



	# ixNet objects need to be added in the list before they are configured.
	$DistGroup2 rangeList.appendItem -object $IP_R5



	# ixNet objects need to be added in the list before they are configured.
	$DistGroup2 rangeList.appendItem -object $IP_R6



	# ixNet objects need to be added in the list before they are configured.
	$DistGroup2 rangeList.appendItem -object $IP_R7



	# ixNet objects need to be added in the list before they are configured.
	$DistGroup2 rangeList.appendItem -object $IP_R8



	# ixNet objects need to be added in the list before they are configured.
	$DistGroup2 rangeList.appendItem -object $IP_R9



	$DistGroup2 config \
	    -distribType                             0 \
	    -_Stale                                  false \
	    -name                                    "DistGroup1" 

	$SvrTraffic0_SvrNetwork_0 config \
	    -enable                                  true \
	    -tcpAccelerationAllowedFlag              true \
	    -network                                 $SvrNetwork_0 

	#################################################
	# Activity HTTPServer1 of NetTraffic SvrTraffic0@SvrNetwork_0
	#################################################
	set Activity_HTTPServer1 [$SvrTraffic0_SvrNetwork_0 activityList.appendItem -protocolAndType "HTTP Server"]

	set _Match_Longest_ [::IxLoad new ixMatchLongestTimeline]



	$Activity_HTTPServer1 config \
	    -enable                                  true \
	    -name                                    "HTTPServer1" \
	    -timeline                                $_Match_Longest_ 

	$Activity_HTTPServer1 agent.webPageList.clear

	set _200_OK [::IxLoad new ResponseHeader]

	$_200_OK responseList.clear

	$_200_OK config \
	    -mimeType                                "text/plain" \
	    -expirationMode                          0 \
	    -code                                    "200" \
	    -dateIncrementFor                        1 \
	    -name                                    "200_OK" \
	    -lastModifiedMode                        1 \
	    -lastModifiedIncrementEnable             false \
	    -enableCustomPutResponse                 false \
	    -dateIncrementEnable                     false \
	    -lastModifiedDateTimeValue               "2014/06/13 18:50:55" \
	    -lastModifiedIncrementFor                1 \
	    -expirationAfterLastModifiedValue        3600 \
	    -dateTimeValue                           "2014/06/13 18:50:55" \
	    -dateZone                                "GMT" \
	    -dateMode                                2 \
	    -expirationAfterRequestValue             3600 \
	    -dateIncrementBy                         5 \
	    -expirationDateTimeValue                 "2014/07/13 18:50:55" \
	    -lastModifiedIncrementBy                 5 \
	    -description                             "OK" 

	set my_PageObject [::IxLoad new PageObject]

	$my_PageObject config \
	    -chunkSize                               "1" \
	    -Md5Option                               3 \
	    -payloadSize                             "1-1" \
	    -customPayloadId                         -1 \
	    -payloadType                             "range" \
	    -payloadFile                             "<specify file>" \
	    -page                                    "/1b.html" \
	    -response                                $_200_OK 

	$Activity_HTTPServer1 agent.webPageList.appendItem -object $my_PageObject



	set my_PageObject1 [::IxLoad new PageObject]

	$my_PageObject1 config \
	    -chunkSize                               "512-1024" \
	    -Md5Option                               3 \
	    -payloadSize                             "4096-4096" \
	    -customPayloadId                         -1 \
	    -payloadType                             "range" \
	    -payloadFile                             "<specify file>" \
	    -page                                    "/4k.html" \
	    -response                                $_200_OK 

	$Activity_HTTPServer1 agent.webPageList.appendItem -object $my_PageObject1



	set my_PageObject2 [::IxLoad new PageObject]

	$my_PageObject2 config \
	    -chunkSize                               "512-1024" \
	    -Md5Option                               3 \
	    -payloadSize                             "8192-8291" \
	    -customPayloadId                         -1 \
	    -payloadType                             "range" \
	    -payloadFile                             "<specify file>" \
	    -page                                    "/8k.html" \
	    -response                                $_200_OK 

	$Activity_HTTPServer1 agent.webPageList.appendItem -object $my_PageObject2



	set my_PageObject3 [::IxLoad new PageObject]

	$my_PageObject3 config \
	    -chunkSize                               "512-1024" \
	    -Md5Option                               3 \
	    -payloadSize                             "16536-16536" \
	    -customPayloadId                         -1 \
	    -payloadType                             "range" \
	    -payloadFile                             "<specify file>" \
	    -page                                    "/16k.html" \
	    -response                                $_200_OK 

	$Activity_HTTPServer1 agent.webPageList.appendItem -object $my_PageObject3



	set my_PageObject4 [::IxLoad new PageObject]

	$my_PageObject4 config \
	    -chunkSize                               "512-1024" \
	    -Md5Option                               3 \
	    -payloadSize                             "32768" \
	    -customPayloadId                         -1 \
	    -payloadType                             "range" \
	    -payloadFile                             "<specify file>" \
	    -page                                    "/32k.html" \
	    -response                                $_200_OK 

	$Activity_HTTPServer1 agent.webPageList.appendItem -object $my_PageObject4



	set my_PageObject5 [::IxLoad new PageObject]

	$my_PageObject5 config \
	    -chunkSize                               "512-1024" \
	    -Md5Option                               3 \
	    -payloadSize                             "65536" \
	    -customPayloadId                         -1 \
	    -payloadType                             "range" \
	    -payloadFile                             "<specify file>" \
	    -page                                    "/64k.html" \
	    -response                                $_200_OK 

	$Activity_HTTPServer1 agent.webPageList.appendItem -object $my_PageObject5



	set my_PageObject6 [::IxLoad new PageObject]

	$my_PageObject6 config \
	    -chunkSize                               "512-1024" \
	    -Md5Option                               3 \
	    -payloadSize                             "131072" \
	    -customPayloadId                         -1 \
	    -payloadType                             "range" \
	    -payloadFile                             "<specify file>" \
	    -page                                    "/128k.html" \
	    -response                                $_200_OK 

	$Activity_HTTPServer1 agent.webPageList.appendItem -object $my_PageObject6



	set my_PageObject7 [::IxLoad new PageObject]

	$my_PageObject7 config \
	    -chunkSize                               "512-1024" \
	    -Md5Option                               3 \
	    -payloadSize                             "262144" \
	    -customPayloadId                         -1 \
	    -payloadType                             "range" \
	    -payloadFile                             "<specify file>" \
	    -page                                    "/256k.html" \
	    -response                                $_200_OK 

	$Activity_HTTPServer1 agent.webPageList.appendItem -object $my_PageObject7



	set my_PageObject8 [::IxLoad new PageObject]

	$my_PageObject8 config \
	    -chunkSize                               "512-1024" \
	    -Md5Option                               3 \
	    -payloadSize                             "524288" \
	    -customPayloadId                         -1 \
	    -payloadType                             "range" \
	    -payloadFile                             "<specify file>" \
	    -page                                    "/512k.html" \
	    -response                                $_200_OK 

	$Activity_HTTPServer1 agent.webPageList.appendItem -object $my_PageObject8



	set my_PageObject9 [::IxLoad new PageObject]

	$my_PageObject9 config \
	    -chunkSize                               "512-1024" \
	    -Md5Option                               3 \
	    -payloadSize                             "1048576" \
	    -customPayloadId                         -1 \
	    -payloadType                             "range" \
	    -payloadFile                             "<specify file>" \
	    -page                                    "/1024k.html" \
	    -response                                $_200_OK 

	$Activity_HTTPServer1 agent.webPageList.appendItem -object $my_PageObject9



	$Activity_HTTPServer1 agent.cookieList.clear

	set UserCookie [::IxLoad new CookieObject]

	$UserCookie cookieContentList.clear

	set firstName [::IxLoad new ixCookieContent]

	$firstName config \
	    -domain                                  "" \
	    -name                                    "firstName" \
	    -maxAge                                  "" \
	    -value                                   "Joe" \
	    -other                                   "" \
	    -path                                    "" 

	$UserCookie cookieContentList.appendItem -object $firstName



	set lastName [::IxLoad new ixCookieContent]

	$lastName config \
	    -domain                                  "" \
	    -name                                    "lastName" \
	    -maxAge                                  "" \
	    -value                                   "Smith" \
	    -other                                   "" \
	    -path                                    "" 

	$UserCookie cookieContentList.appendItem -object $lastName



	$UserCookie config \
	    -mode                                    3 \
	    -type                                    2 \
	    -name                                    "UserCookie" \
	    -description                             "Name of User" 

	$Activity_HTTPServer1 agent.cookieList.appendItem -object $UserCookie



	set LoginCookie [::IxLoad new CookieObject]

	$LoginCookie cookieContentList.clear

	set name [::IxLoad new ixCookieContent]

	$name config \
	    -domain                                  "" \
	    -name                                    "name" \
	    -maxAge                                  "" \
	    -value                                   "joesmith" \
	    -other                                   "" \
	    -path                                    "" 

	$LoginCookie cookieContentList.appendItem -object $name



	set password [::IxLoad new ixCookieContent]

	$password config \
	    -domain                                  "" \
	    -name                                    "password" \
	    -maxAge                                  "" \
	    -value                                   "foobar" \
	    -other                                   "" \
	    -path                                    "" 

	$LoginCookie cookieContentList.appendItem -object $password



	$LoginCookie config \
	    -mode                                    2 \
	    -type                                    2 \
	    -name                                    "LoginCookie" \
	    -description                             "Login name and password" 

	$Activity_HTTPServer1 agent.cookieList.appendItem -object $LoginCookie



	$Activity_HTTPServer1 agent.customPayloadList.clear

	set AsciiCustomPayload [::IxLoad new CustomPayloadObject]

	$AsciiCustomPayload config \
	    -repeat                                  false \
	    -name                                    "AsciiCustomPayload" \
	    -asciiPayloadValue                       "Ixia-Ixload-Http-Server-Custom-Payload" \
	    -payloadmode                             0 \
	    -offset                                  1 \
	    -hexPayloadValue                         "" \
	    -payloadPosition                         "Start With" \
	    -id                                      0 

	$Activity_HTTPServer1 agent.customPayloadList.appendItem -object $AsciiCustomPayload



	set HexCustomPayload [::IxLoad new CustomPayloadObject]

	$HexCustomPayload config \
	    -repeat                                  false \
	    -name                                    "HexCustomPayload" \
	    -asciiPayloadValue                       "" \
	    -payloadmode                             1 \
	    -offset                                  1 \
	    -hexPayloadValue                         "49 78 69 61 2d 49 78 6c 6f 61 64 2d 48 74 74 70 2d 53 65 72 76 65 72 2d 43 75 73 74 6f 6d 2d 50 61 79 6c 6f 61 64" \
	    -payloadPosition                         "Start With" \
	    -id                                      1 

	$Activity_HTTPServer1 agent.customPayloadList.appendItem -object $HexCustomPayload



	$Activity_HTTPServer1 agent.responseHeaderList.clear

	set _201 [::IxLoad new ResponseHeader]

	$_201 responseList.clear

	$_201 config \
	    -mimeType                                "text/plain" \
	    -expirationMode                          0 \
	    -code                                    "200" \
	    -dateIncrementFor                        1 \
	    -name                                    "200_OK" \
	    -lastModifiedMode                        1 \
	    -lastModifiedIncrementEnable             false \
	    -enableCustomPutResponse                 false \
	    -dateIncrementEnable                     false \
	    -lastModifiedDateTimeValue               "2014/06/13 18:50:55" \
	    -lastModifiedIncrementFor                1 \
	    -expirationAfterLastModifiedValue        3600 \
	    -dateTimeValue                           "2014/06/13 18:50:55" \
	    -dateZone                                "GMT" \
	    -dateMode                                2 \
	    -expirationAfterRequestValue             3600 \
	    -dateIncrementBy                         5 \
	    -expirationDateTimeValue                 "2014/07/13 18:50:55" \
	    -lastModifiedIncrementBy                 5 \
	    -description                             "OK" 

	$Activity_HTTPServer1 agent.responseHeaderList.appendItem -object $_201



	set _404_PageNotFound [::IxLoad new ResponseHeader]

	$_404_PageNotFound responseList.clear

	$_404_PageNotFound config \
	    -mimeType                                "text/plain" \
	    -expirationMode                          0 \
	    -code                                    404 \
	    -dateIncrementFor                        1 \
	    -name                                    "404_PageNotFound" \
	    -lastModifiedMode                        1 \
	    -lastModifiedIncrementEnable             false \
	    -enableCustomPutResponse                 false \
	    -dateIncrementEnable                     false \
	    -lastModifiedDateTimeValue               "2014/06/13 18:50:55" \
	    -lastModifiedIncrementFor                1 \
	    -expirationAfterLastModifiedValue        3600 \
	    -dateTimeValue                           "2014/06/13 18:50:55" \
	    -dateZone                                "GMT" \
	    -dateMode                                2 \
	    -expirationAfterRequestValue             3600 \
	    -dateIncrementBy                         5 \
	    -expirationDateTimeValue                 "2014/07/13 18:50:55" \
	    -lastModifiedIncrementBy                 5 \
	    -description                             "Page not found" 

	$Activity_HTTPServer1 agent.responseHeaderList.appendItem -object $_404_PageNotFound



	$Activity_HTTPServer1 agent.config \
	    -cmdListLoops                            0 \
	    -vlanPriority                            0 \
	    -validateCertificate                     false \
	    -maxResponseDelay                        "0" \
	    -docrootChunkSize                        "512-1024" \
	    -rstTimeout                              100 \
	    -enableChunkedRequest                    false \
	    -enableEsm                               false \
	    -enableHTTP2                             false \
	    -certificate                             "" \
	    -enableNewSslSupport                     false \
	    -tos                                     0 \
	    -enableSslSendCloseNotify                false \
	    -enableMD5Checksum                       false \
	    -httpPort                                "80" \
	    -httpsPort                               "443" \
	    -caCert                                  "" \
	    -esm                                     1460 \
	    -enableTos                               false \
	    -precedenceTOS                           0 \
	    -integrityCheckOption                    "Custom MD5" \
	    -flowPercentage                          100.0 \
	    -enableChunkEncoding                     false \
	    -privateKey                              "" \
	    -sslRecordSize                           "16384" \
	    -reliabilityTOS                          0 \
	    -delayTOS                                0 \
	    -privateKeyPassword                      "" \
	    -urlStatsCount                           10 \
	    -tcpCloseOption                          0 \
	    -enableVlanPriority                      false \
	    -enableIntegrityCheck                    false \
	    -docrootfile                             "" \
	    -enablesslRecordSize                     false \
	    -dhParams                                "" \
	    -throughputTOS                           0 \
	    -requestTimeout                          300 \
	    -dontExpectUpgrade                       false \
	    -ServerCiphers                           "DEFAULT" \
	    -enableDHsupport                         false \
	    -enablePerServerPerURLstat               false \
	    -urlPageSize                             1024 \
	    -acceptSslConnections                    false \
	    -minResponseDelay                        "0" 

	$SvrTraffic0_SvrNetwork_0 traffic.config -name "SvrTraffic0"

	$SvrTraffic0_SvrNetwork_0 setPortOperationModeAllowed $::ixPort(kOperationModeThroughputAcceleration) false

	$SvrTraffic0_SvrNetwork_0 setPortOperationModeAllowed $::ixPort(kOperationModeFCoEOffload) true

	$SvrTraffic0_SvrNetwork_0 setPortOperationModeAllowed $::ixPort(kOperationModeL23) true

	$SvrTraffic0_SvrNetwork_0 setTcpAccelerationAllowed $::ixAgent(kTcpAcceleration) true

	$Terminate elementList.appendItem -object $SvrTraffic0_SvrNetwork_0



	$Terminate config -name "Terminate"

	$Scenario1 columnList.appendItem -object $Terminate



	$Scenario1 appMixList.clear

	$Scenario1 links.clear

	$Scenario1 config -name "Scenario1"

	$Test1 config \
	    -comment                                 "" \
	    -csvInterval                             2 \
	    -networkFailureThreshold                 0 \
	    -name                                    "Test1" \
	    -downgradeAppLibFlowsToLatestValidVersion true \
	    -statsRequired                           true \
	    -enableResetPorts                        true \
	    -statViewThroughputUnits                 "Kbps" \
	    -isFrameSizeDistributionViewSupported    false \
	    -csvThroughputScalingFactor              1000 \
	    -enableForceOwnership                    true \
	    -enableReleaseConfigAfterRun             false \
	    -activitiesGroupedByObjective            false \
	    -enableNetworkDiagnostics                false \
	    -enableFrameSizeDistributionStats        false \
	    -allowMixedObjectiveTypes                false \
	    -currentUniqueIDForAgent                 4 \
	    -enableTcpAdvancedStats                  false \
	    -profileDirectory                        $profileDirectory \
	    -eventHandlerSettings                    $my_ixEventHandlerSettings \
	    -captureViewOptions                      $my_ixViewOptions 

	set my_ixDutConfigVirtual [::IxLoad new ixDutConfigVirtual]

	$my_ixDutConfigVirtual networkRangeList.clear

	set Network_Range_1_in_unknown_dut__1_1_1_100_100_ [::IxLoad new ixDutNetworkRange]

	$Network_Range_1_in_unknown_dut__1_1_1_100_100_ config \
	    -vlanUniqueCount                         4094 \
	    -firstIp                                 "1.1.1.100" \
	    -enable                                  true \
	    -name                                    "Network Range 1 in unknown dut (1.1.1.100+100)" \
	    -vlanEnable                              true \
	    -vlanId                                  1001 \
	    -innerVlanEnable                         false \
	    -ipIncrStep                              "0.0.1.0" \
	    -networkMask                             "255.255.255.0" \
	    -ipType                                  1 \
	    -vlanIncrStep                            1 \
	    -vlanCount                               100 \
	    -ipCount                                 100 

	$my_ixDutConfigVirtual networkRangeList.appendItem -object $Network_Range_1_in_unknown_dut__1_1_1_100_100_



	set Network_Range_2_in_unknown_dut__2_1_1_100_100_ [::IxLoad new ixDutNetworkRange]

	$Network_Range_2_in_unknown_dut__2_1_1_100_100_ config \
	    -vlanUniqueCount                         4094 \
	    -firstIp                                 "2.1.1.100" \
	    -enable                                  true \
	    -name                                    "Network Range 2 in unknown dut (2.1.1.100+100)" \
	    -vlanEnable                              true \
	    -vlanId                                  1101 \
	    -innerVlanEnable                         false \
	    -ipIncrStep                              "0.0.1.0" \
	    -networkMask                             "255.255.255.0" \
	    -ipType                                  1 \
	    -vlanIncrStep                            1 \
	    -vlanCount                               100 \
	    -ipCount                                 100 

	$my_ixDutConfigVirtual networkRangeList.appendItem -object $Network_Range_2_in_unknown_dut__2_1_1_100_100_



	set Network_Range_3_in_unknown_dut__3_1_1_100_100_ [::IxLoad new ixDutNetworkRange]

	$Network_Range_3_in_unknown_dut__3_1_1_100_100_ config \
	    -vlanUniqueCount                         4094 \
	    -firstIp                                 "3.1.1.100" \
	    -enable                                  true \
	    -name                                    "Network Range 3 in unknown dut (3.1.1.100+100)" \
	    -vlanEnable                              true \
	    -vlanId                                  1201 \
	    -innerVlanEnable                         false \
	    -ipIncrStep                              "0.0.1.0" \
	    -networkMask                             "255.255.255.0" \
	    -ipType                                  1 \
	    -vlanIncrStep                            1 \
	    -vlanCount                               100 \
	    -ipCount                                 100 

	$my_ixDutConfigVirtual networkRangeList.appendItem -object $Network_Range_3_in_unknown_dut__3_1_1_100_100_



	$my_ixDutConfigVirtual protocolPortRangeList.clear

	set DUT1 [$scenarioElementFactory create $::ixScenarioElementType(kDutBasic)]

	$DUT1 config \
	    -comment                                 "" \
	    -type                                    "VirtualDut" \
	    -name                                    "DUT1" \
	    -dutConfig                               $my_ixDutConfigVirtual 

	$DUT elementList.appendItem -object $DUT1



	#################################################
	# Destination  for HTTP_Client1_1
	#################################################
	set destination [$Traffic0_CltNetwork_0 getDestinationForActivity "HTTP_Client1_1" "DUT1:80"]

	$destination config -portMapPolicy "customMesh"

	set my_ixCustomPortMap [$destination cget -customPortMap]

	set Submap0 [$my_ixCustomPortMap submapsIPv4.getItem 0]

	$Submap0 config \
	    -name                                    "Submap0" \
	    -meshType                                "vlanRangePairs" 

	$Submap0 sourceRanges(0).config \
	    -destinationId                           "1001" \
	    -enable                                  true \
	    -vlanId                                  2001 

	$Submap0 sourceRanges(1).config \
	    -destinationId                           "1002" \
	    -enable                                  true \
	    -vlanId                                  2002 

	$Submap0 sourceRanges(2).config \
	    -destinationId                           "1003" \
	    -enable                                  true \
	    -vlanId                                  2003 

	$Submap0 sourceRanges(3).config \
	    -destinationId                           "1004" \
	    -enable                                  true \
	    -vlanId                                  2004 

	$Submap0 sourceRanges(4).config \
	    -destinationId                           "1005" \
	    -enable                                  true \
	    -vlanId                                  2005 

	$Submap0 sourceRanges(5).config \
	    -destinationId                           "1006" \
	    -enable                                  true \
	    -vlanId                                  2006 

	$Submap0 sourceRanges(6).config \
	    -destinationId                           "1007" \
	    -enable                                  true \
	    -vlanId                                  2007 

	$Submap0 sourceRanges(7).config \
	    -destinationId                           "1008" \
	    -enable                                  true \
	    -vlanId                                  2008 

	$Submap0 sourceRanges(8).config \
	    -destinationId                           "1009" \
	    -enable                                  true \
	    -vlanId                                  2009 

	$Submap0 sourceRanges(9).config \
	    -destinationId                           "1010" \
	    -enable                                  true \
	    -vlanId                                  2010 

	$Submap0 sourceRanges(10).config \
	    -destinationId                           "1011" \
	    -enable                                  true \
	    -vlanId                                  2011 

	$Submap0 sourceRanges(11).config \
	    -destinationId                           "1012" \
	    -enable                                  true \
	    -vlanId                                  2012 

	$Submap0 sourceRanges(12).config \
	    -destinationId                           "1013" \
	    -enable                                  true \
	    -vlanId                                  2013 

	$Submap0 sourceRanges(13).config \
	    -destinationId                           "1014" \
	    -enable                                  true \
	    -vlanId                                  2014 

	$Submap0 sourceRanges(14).config \
	    -destinationId                           "1015" \
	    -enable                                  true \
	    -vlanId                                  2015 

	$Submap0 sourceRanges(15).config \
	    -destinationId                           "1016" \
	    -enable                                  true \
	    -vlanId                                  2016 

	$Submap0 sourceRanges(16).config \
	    -destinationId                           "1017" \
	    -enable                                  true \
	    -vlanId                                  2017 

	$Submap0 sourceRanges(17).config \
	    -destinationId                           "1018" \
	    -enable                                  true \
	    -vlanId                                  2018 

	$Submap0 sourceRanges(18).config \
	    -destinationId                           "1019" \
	    -enable                                  true \
	    -vlanId                                  2019 

	$Submap0 sourceRanges(19).config \
	    -destinationId                           "1020" \
	    -enable                                  true \
	    -vlanId                                  2020 

	$Submap0 sourceRanges(20).config \
	    -destinationId                           "1021" \
	    -enable                                  true \
	    -vlanId                                  2021 

	$Submap0 sourceRanges(21).config \
	    -destinationId                           "1022" \
	    -enable                                  true \
	    -vlanId                                  2022 

	$Submap0 sourceRanges(22).config \
	    -destinationId                           "1023" \
	    -enable                                  true \
	    -vlanId                                  2023 

	$Submap0 sourceRanges(23).config \
	    -destinationId                           "1024" \
	    -enable                                  true \
	    -vlanId                                  2024 

	$Submap0 sourceRanges(24).config \
	    -destinationId                           "1025" \
	    -enable                                  true \
	    -vlanId                                  2025 

	$Submap0 sourceRanges(25).config \
	    -destinationId                           "1026" \
	    -enable                                  true \
	    -vlanId                                  2026 

	$Submap0 sourceRanges(26).config \
	    -destinationId                           "1027" \
	    -enable                                  true \
	    -vlanId                                  2027 

	$Submap0 sourceRanges(27).config \
	    -destinationId                           "1028" \
	    -enable                                  true \
	    -vlanId                                  2028 

	$Submap0 sourceRanges(28).config \
	    -destinationId                           "1029" \
	    -enable                                  true \
	    -vlanId                                  2029 

	$Submap0 sourceRanges(29).config \
	    -destinationId                           "1030" \
	    -enable                                  true \
	    -vlanId                                  2030 

	$Submap0 sourceRanges(30).config \
	    -destinationId                           "1031" \
	    -enable                                  true \
	    -vlanId                                  2031 

	$Submap0 sourceRanges(31).config \
	    -destinationId                           "1032" \
	    -enable                                  true \
	    -vlanId                                  2032 

	$Submap0 sourceRanges(32).config \
	    -destinationId                           "1033" \
	    -enable                                  true \
	    -vlanId                                  2033 

	$Submap0 sourceRanges(33).config \
	    -destinationId                           "1034" \
	    -enable                                  true \
	    -vlanId                                  2034 

	$Submap0 sourceRanges(34).config \
	    -destinationId                           "1035" \
	    -enable                                  true \
	    -vlanId                                  2035 

	$Submap0 sourceRanges(35).config \
	    -destinationId                           "1036" \
	    -enable                                  true \
	    -vlanId                                  2036 

	$Submap0 sourceRanges(36).config \
	    -destinationId                           "1037" \
	    -enable                                  true \
	    -vlanId                                  2037 

	$Submap0 sourceRanges(37).config \
	    -destinationId                           "1038" \
	    -enable                                  true \
	    -vlanId                                  2038 

	$Submap0 sourceRanges(38).config \
	    -destinationId                           "1039" \
	    -enable                                  true \
	    -vlanId                                  2039 

	$Submap0 sourceRanges(39).config \
	    -destinationId                           "1040" \
	    -enable                                  true \
	    -vlanId                                  2040 

	$Submap0 sourceRanges(40).config \
	    -destinationId                           "1041" \
	    -enable                                  true \
	    -vlanId                                  2041 

	$Submap0 sourceRanges(41).config \
	    -destinationId                           "1042" \
	    -enable                                  true \
	    -vlanId                                  2042 

	$Submap0 sourceRanges(42).config \
	    -destinationId                           "1043" \
	    -enable                                  true \
	    -vlanId                                  2043 

	$Submap0 sourceRanges(43).config \
	    -destinationId                           "1044" \
	    -enable                                  true \
	    -vlanId                                  2044 

	$Submap0 sourceRanges(44).config \
	    -destinationId                           "1045" \
	    -enable                                  true \
	    -vlanId                                  2045 

	$Submap0 sourceRanges(45).config \
	    -destinationId                           "1046" \
	    -enable                                  true \
	    -vlanId                                  2046 

	$Submap0 sourceRanges(46).config \
	    -destinationId                           "1047" \
	    -enable                                  true \
	    -vlanId                                  2047 

	$Submap0 sourceRanges(47).config \
	    -destinationId                           "1048" \
	    -enable                                  true \
	    -vlanId                                  2048 

	$Submap0 sourceRanges(48).config \
	    -destinationId                           "1049" \
	    -enable                                  true \
	    -vlanId                                  2049 

	$Submap0 sourceRanges(49).config \
	    -destinationId                           "1050" \
	    -enable                                  true \
	    -vlanId                                  2050 

	$Submap0 sourceRanges(50).config \
	    -destinationId                           "1051" \
	    -enable                                  true \
	    -vlanId                                  2051 

	$Submap0 sourceRanges(51).config \
	    -destinationId                           "1052" \
	    -enable                                  true \
	    -vlanId                                  2052 

	$Submap0 sourceRanges(52).config \
	    -destinationId                           "1053" \
	    -enable                                  true \
	    -vlanId                                  2053 

	$Submap0 sourceRanges(53).config \
	    -destinationId                           "1054" \
	    -enable                                  true \
	    -vlanId                                  2054 

	$Submap0 sourceRanges(54).config \
	    -destinationId                           "1055" \
	    -enable                                  true \
	    -vlanId                                  2055 

	$Submap0 sourceRanges(55).config \
	    -destinationId                           "1056" \
	    -enable                                  true \
	    -vlanId                                  2056 

	$Submap0 sourceRanges(56).config \
	    -destinationId                           "1057" \
	    -enable                                  true \
	    -vlanId                                  2057 

	$Submap0 sourceRanges(57).config \
	    -destinationId                           "1058" \
	    -enable                                  true \
	    -vlanId                                  2058 

	$Submap0 sourceRanges(58).config \
	    -destinationId                           "1059" \
	    -enable                                  true \
	    -vlanId                                  2059 

	$Submap0 sourceRanges(59).config \
	    -destinationId                           "1060" \
	    -enable                                  true \
	    -vlanId                                  2060 

	$Submap0 sourceRanges(60).config \
	    -destinationId                           "1061" \
	    -enable                                  true \
	    -vlanId                                  2061 

	$Submap0 sourceRanges(61).config \
	    -destinationId                           "1062" \
	    -enable                                  true \
	    -vlanId                                  2062 

	$Submap0 sourceRanges(62).config \
	    -destinationId                           "1063" \
	    -enable                                  true \
	    -vlanId                                  2063 

	$Submap0 sourceRanges(63).config \
	    -destinationId                           "1064" \
	    -enable                                  true \
	    -vlanId                                  2064 

	$Submap0 sourceRanges(64).config \
	    -destinationId                           "1065" \
	    -enable                                  true \
	    -vlanId                                  2065 

	$Submap0 sourceRanges(65).config \
	    -destinationId                           "1066" \
	    -enable                                  true \
	    -vlanId                                  2066 

	$Submap0 sourceRanges(66).config \
	    -destinationId                           "1067" \
	    -enable                                  true \
	    -vlanId                                  2067 

	$Submap0 sourceRanges(67).config \
	    -destinationId                           "1068" \
	    -enable                                  true \
	    -vlanId                                  2068 

	$Submap0 sourceRanges(68).config \
	    -destinationId                           "1069" \
	    -enable                                  true \
	    -vlanId                                  2069 

	$Submap0 sourceRanges(69).config \
	    -destinationId                           "1070" \
	    -enable                                  true \
	    -vlanId                                  2070 

	$Submap0 sourceRanges(70).config \
	    -destinationId                           "1071" \
	    -enable                                  true \
	    -vlanId                                  2071 

	$Submap0 sourceRanges(71).config \
	    -destinationId                           "1072" \
	    -enable                                  true \
	    -vlanId                                  2072 

	$Submap0 sourceRanges(72).config \
	    -destinationId                           "1073" \
	    -enable                                  true \
	    -vlanId                                  2073 

	$Submap0 sourceRanges(73).config \
	    -destinationId                           "1074" \
	    -enable                                  true \
	    -vlanId                                  2074 

	$Submap0 sourceRanges(74).config \
	    -destinationId                           "1075" \
	    -enable                                  true \
	    -vlanId                                  2075 

	$Submap0 sourceRanges(75).config \
	    -destinationId                           "1076" \
	    -enable                                  true \
	    -vlanId                                  2076 

	$Submap0 sourceRanges(76).config \
	    -destinationId                           "1077" \
	    -enable                                  true \
	    -vlanId                                  2077 

	$Submap0 sourceRanges(77).config \
	    -destinationId                           "1078" \
	    -enable                                  true \
	    -vlanId                                  2078 

	$Submap0 sourceRanges(78).config \
	    -destinationId                           "1079" \
	    -enable                                  true \
	    -vlanId                                  2079 

	$Submap0 sourceRanges(79).config \
	    -destinationId                           "1080" \
	    -enable                                  true \
	    -vlanId                                  2080 

	$Submap0 sourceRanges(80).config \
	    -destinationId                           "1081" \
	    -enable                                  true \
	    -vlanId                                  2081 

	$Submap0 sourceRanges(81).config \
	    -destinationId                           "1082" \
	    -enable                                  true \
	    -vlanId                                  2082 

	$Submap0 sourceRanges(82).config \
	    -destinationId                           "1083" \
	    -enable                                  true \
	    -vlanId                                  2083 

	$Submap0 sourceRanges(83).config \
	    -destinationId                           "1084" \
	    -enable                                  true \
	    -vlanId                                  2084 

	$Submap0 sourceRanges(84).config \
	    -destinationId                           "1085" \
	    -enable                                  true \
	    -vlanId                                  2085 

	$Submap0 sourceRanges(85).config \
	    -destinationId                           "1086" \
	    -enable                                  true \
	    -vlanId                                  2086 

	$Submap0 sourceRanges(86).config \
	    -destinationId                           "1087" \
	    -enable                                  true \
	    -vlanId                                  2087 

	$Submap0 sourceRanges(87).config \
	    -destinationId                           "1088" \
	    -enable                                  true \
	    -vlanId                                  2088 

	$Submap0 sourceRanges(88).config \
	    -destinationId                           "1089" \
	    -enable                                  true \
	    -vlanId                                  2089 

	$Submap0 sourceRanges(89).config \
	    -destinationId                           "1090" \
	    -enable                                  true \
	    -vlanId                                  2090 

	$Submap0 sourceRanges(90).config \
	    -destinationId                           "1091" \
	    -enable                                  true \
	    -vlanId                                  2091 

	$Submap0 sourceRanges(91).config \
	    -destinationId                           "1092" \
	    -enable                                  true \
	    -vlanId                                  2092 

	$Submap0 sourceRanges(92).config \
	    -destinationId                           "1093" \
	    -enable                                  true \
	    -vlanId                                  2093 

	$Submap0 sourceRanges(93).config \
	    -destinationId                           "1094" \
	    -enable                                  true \
	    -vlanId                                  2094 

	$Submap0 sourceRanges(94).config \
	    -destinationId                           "1095" \
	    -enable                                  true \
	    -vlanId                                  2095 

	$Submap0 sourceRanges(95).config \
	    -destinationId                           "1096" \
	    -enable                                  true \
	    -vlanId                                  2096 

	$Submap0 sourceRanges(96).config \
	    -destinationId                           "1097" \
	    -enable                                  true \
	    -vlanId                                  2097 

	$Submap0 sourceRanges(97).config \
	    -destinationId                           "1098" \
	    -enable                                  true \
	    -vlanId                                  2098 

	$Submap0 sourceRanges(98).config \
	    -destinationId                           "1099" \
	    -enable                                  true \
	    -vlanId                                  2099 

	$Submap0 sourceRanges(99).config \
	    -destinationId                           "1100" \
	    -enable                                  true \
	    -vlanId                                  2100 

	$Submap0 sourceRanges(100).config \
	    -destinationId                           "1101" \
	    -enable                                  true \
	    -vlanId                                  2101 

	$Submap0 sourceRanges(101).config \
	    -destinationId                           "1102" \
	    -enable                                  true \
	    -vlanId                                  2102 

	$Submap0 sourceRanges(102).config \
	    -destinationId                           "1103" \
	    -enable                                  true \
	    -vlanId                                  2103 

	$Submap0 sourceRanges(103).config \
	    -destinationId                           "1104" \
	    -enable                                  true \
	    -vlanId                                  2104 

	$Submap0 sourceRanges(104).config \
	    -destinationId                           "1105" \
	    -enable                                  true \
	    -vlanId                                  2105 

	$Submap0 sourceRanges(105).config \
	    -destinationId                           "1106" \
	    -enable                                  true \
	    -vlanId                                  2106 

	$Submap0 sourceRanges(106).config \
	    -destinationId                           "1107" \
	    -enable                                  true \
	    -vlanId                                  2107 

	$Submap0 sourceRanges(107).config \
	    -destinationId                           "1108" \
	    -enable                                  true \
	    -vlanId                                  2108 

	$Submap0 sourceRanges(108).config \
	    -destinationId                           "1109" \
	    -enable                                  true \
	    -vlanId                                  2109 

	$Submap0 sourceRanges(109).config \
	    -destinationId                           "1110" \
	    -enable                                  true \
	    -vlanId                                  2110 

	$Submap0 sourceRanges(110).config \
	    -destinationId                           "1111" \
	    -enable                                  true \
	    -vlanId                                  2111 

	$Submap0 sourceRanges(111).config \
	    -destinationId                           "1112" \
	    -enable                                  true \
	    -vlanId                                  2112 

	$Submap0 sourceRanges(112).config \
	    -destinationId                           "1113" \
	    -enable                                  true \
	    -vlanId                                  2113 

	$Submap0 sourceRanges(113).config \
	    -destinationId                           "1114" \
	    -enable                                  true \
	    -vlanId                                  2114 

	$Submap0 sourceRanges(114).config \
	    -destinationId                           "1115" \
	    -enable                                  true \
	    -vlanId                                  2115 

	$Submap0 sourceRanges(115).config \
	    -destinationId                           "1116" \
	    -enable                                  true \
	    -vlanId                                  2116 

	$Submap0 sourceRanges(116).config \
	    -destinationId                           "1117" \
	    -enable                                  true \
	    -vlanId                                  2117 

	$Submap0 sourceRanges(117).config \
	    -destinationId                           "1118" \
	    -enable                                  true \
	    -vlanId                                  2118 

	$Submap0 sourceRanges(118).config \
	    -destinationId                           "1119" \
	    -enable                                  true \
	    -vlanId                                  2119 

	$Submap0 sourceRanges(119).config \
	    -destinationId                           "1120" \
	    -enable                                  true \
	    -vlanId                                  2120 

	$Submap0 sourceRanges(120).config \
	    -destinationId                           "1121" \
	    -enable                                  true \
	    -vlanId                                  2121 

	$Submap0 sourceRanges(121).config \
	    -destinationId                           "1122" \
	    -enable                                  true \
	    -vlanId                                  2122 

	$Submap0 sourceRanges(122).config \
	    -destinationId                           "1123" \
	    -enable                                  true \
	    -vlanId                                  2123 

	$Submap0 sourceRanges(123).config \
	    -destinationId                           "1124" \
	    -enable                                  true \
	    -vlanId                                  2124 

	$Submap0 sourceRanges(124).config \
	    -destinationId                           "1125" \
	    -enable                                  true \
	    -vlanId                                  2125 

	$Submap0 sourceRanges(125).config \
	    -destinationId                           "1126" \
	    -enable                                  true \
	    -vlanId                                  2126 

	$Submap0 sourceRanges(126).config \
	    -destinationId                           "1127" \
	    -enable                                  true \
	    -vlanId                                  2127 

	$Submap0 sourceRanges(127).config \
	    -destinationId                           "1128" \
	    -enable                                  true \
	    -vlanId                                  2128 

	$Submap0 sourceRanges(128).config \
	    -destinationId                           "1129" \
	    -enable                                  true \
	    -vlanId                                  2129 

	$Submap0 sourceRanges(129).config \
	    -destinationId                           "1130" \
	    -enable                                  true \
	    -vlanId                                  2130 

	$Submap0 sourceRanges(130).config \
	    -destinationId                           "1131" \
	    -enable                                  true \
	    -vlanId                                  2131 

	$Submap0 sourceRanges(131).config \
	    -destinationId                           "1132" \
	    -enable                                  true \
	    -vlanId                                  2132 

	$Submap0 sourceRanges(132).config \
	    -destinationId                           "1133" \
	    -enable                                  true \
	    -vlanId                                  2133 

	$Submap0 sourceRanges(133).config \
	    -destinationId                           "1134" \
	    -enable                                  true \
	    -vlanId                                  2134 

	$Submap0 sourceRanges(134).config \
	    -destinationId                           "1135" \
	    -enable                                  true \
	    -vlanId                                  2135 

	$Submap0 sourceRanges(135).config \
	    -destinationId                           "1136" \
	    -enable                                  true \
	    -vlanId                                  2136 

	$Submap0 sourceRanges(136).config \
	    -destinationId                           "1137" \
	    -enable                                  true \
	    -vlanId                                  2137 

	$Submap0 sourceRanges(137).config \
	    -destinationId                           "1138" \
	    -enable                                  true \
	    -vlanId                                  2138 

	$Submap0 sourceRanges(138).config \
	    -destinationId                           "1139" \
	    -enable                                  true \
	    -vlanId                                  2139 

	$Submap0 sourceRanges(139).config \
	    -destinationId                           "1140" \
	    -enable                                  true \
	    -vlanId                                  2140 

	$Submap0 sourceRanges(140).config \
	    -destinationId                           "1141" \
	    -enable                                  true \
	    -vlanId                                  2141 

	$Submap0 sourceRanges(141).config \
	    -destinationId                           "1142" \
	    -enable                                  true \
	    -vlanId                                  2142 

	$Submap0 sourceRanges(142).config \
	    -destinationId                           "1143" \
	    -enable                                  true \
	    -vlanId                                  2143 

	$Submap0 sourceRanges(143).config \
	    -destinationId                           "1144" \
	    -enable                                  true \
	    -vlanId                                  2144 

	$Submap0 sourceRanges(144).config \
	    -destinationId                           "1145" \
	    -enable                                  true \
	    -vlanId                                  2145 

	$Submap0 sourceRanges(145).config \
	    -destinationId                           "1146" \
	    -enable                                  true \
	    -vlanId                                  2146 

	$Submap0 sourceRanges(146).config \
	    -destinationId                           "1147" \
	    -enable                                  true \
	    -vlanId                                  2147 

	$Submap0 sourceRanges(147).config \
	    -destinationId                           "1148" \
	    -enable                                  true \
	    -vlanId                                  2148 

	$Submap0 sourceRanges(148).config \
	    -destinationId                           "1149" \
	    -enable                                  true \
	    -vlanId                                  2149 

	$Submap0 sourceRanges(149).config \
	    -destinationId                           "1150" \
	    -enable                                  true \
	    -vlanId                                  2150 

	$Submap0 sourceRanges(150).config \
	    -destinationId                           "1151" \
	    -enable                                  true \
	    -vlanId                                  2151 

	$Submap0 sourceRanges(151).config \
	    -destinationId                           "1152" \
	    -enable                                  true \
	    -vlanId                                  2152 

	$Submap0 sourceRanges(152).config \
	    -destinationId                           "1153" \
	    -enable                                  true \
	    -vlanId                                  2153 

	$Submap0 sourceRanges(153).config \
	    -destinationId                           "1154" \
	    -enable                                  true \
	    -vlanId                                  2154 

	$Submap0 sourceRanges(154).config \
	    -destinationId                           "1155" \
	    -enable                                  true \
	    -vlanId                                  2155 

	$Submap0 sourceRanges(155).config \
	    -destinationId                           "1156" \
	    -enable                                  true \
	    -vlanId                                  2156 

	$Submap0 sourceRanges(156).config \
	    -destinationId                           "1157" \
	    -enable                                  true \
	    -vlanId                                  2157 

	$Submap0 sourceRanges(157).config \
	    -destinationId                           "1158" \
	    -enable                                  true \
	    -vlanId                                  2158 

	$Submap0 sourceRanges(158).config \
	    -destinationId                           "1159" \
	    -enable                                  true \
	    -vlanId                                  2159 

	$Submap0 sourceRanges(159).config \
	    -destinationId                           "1160" \
	    -enable                                  true \
	    -vlanId                                  2160 

	$Submap0 sourceRanges(160).config \
	    -destinationId                           "1161" \
	    -enable                                  true \
	    -vlanId                                  2161 

	$Submap0 sourceRanges(161).config \
	    -destinationId                           "1162" \
	    -enable                                  true \
	    -vlanId                                  2162 

	$Submap0 sourceRanges(162).config \
	    -destinationId                           "1163" \
	    -enable                                  true \
	    -vlanId                                  2163 

	$Submap0 sourceRanges(163).config \
	    -destinationId                           "1164" \
	    -enable                                  true \
	    -vlanId                                  2164 

	$Submap0 sourceRanges(164).config \
	    -destinationId                           "1165" \
	    -enable                                  true \
	    -vlanId                                  2165 

	$Submap0 sourceRanges(165).config \
	    -destinationId                           "1166" \
	    -enable                                  true \
	    -vlanId                                  2166 

	$Submap0 sourceRanges(166).config \
	    -destinationId                           "1167" \
	    -enable                                  true \
	    -vlanId                                  2167 

	$Submap0 sourceRanges(167).config \
	    -destinationId                           "1168" \
	    -enable                                  true \
	    -vlanId                                  2168 

	$Submap0 sourceRanges(168).config \
	    -destinationId                           "1169" \
	    -enable                                  true \
	    -vlanId                                  2169 

	$Submap0 sourceRanges(169).config \
	    -destinationId                           "1170" \
	    -enable                                  true \
	    -vlanId                                  2170 

	$Submap0 sourceRanges(170).config \
	    -destinationId                           "1171" \
	    -enable                                  true \
	    -vlanId                                  2171 

	$Submap0 sourceRanges(171).config \
	    -destinationId                           "1172" \
	    -enable                                  true \
	    -vlanId                                  2172 

	$Submap0 sourceRanges(172).config \
	    -destinationId                           "1173" \
	    -enable                                  true \
	    -vlanId                                  2173 

	$Submap0 sourceRanges(173).config \
	    -destinationId                           "1174" \
	    -enable                                  true \
	    -vlanId                                  2174 

	$Submap0 sourceRanges(174).config \
	    -destinationId                           "1175" \
	    -enable                                  true \
	    -vlanId                                  2175 

	$Submap0 sourceRanges(175).config \
	    -destinationId                           "1176" \
	    -enable                                  true \
	    -vlanId                                  2176 

	$Submap0 sourceRanges(176).config \
	    -destinationId                           "1177" \
	    -enable                                  true \
	    -vlanId                                  2177 

	$Submap0 sourceRanges(177).config \
	    -destinationId                           "1178" \
	    -enable                                  true \
	    -vlanId                                  2178 

	$Submap0 sourceRanges(178).config \
	    -destinationId                           "1179" \
	    -enable                                  true \
	    -vlanId                                  2179 

	$Submap0 sourceRanges(179).config \
	    -destinationId                           "1180" \
	    -enable                                  true \
	    -vlanId                                  2180 

	$Submap0 sourceRanges(180).config \
	    -destinationId                           "1181" \
	    -enable                                  true \
	    -vlanId                                  2181 

	$Submap0 sourceRanges(181).config \
	    -destinationId                           "1182" \
	    -enable                                  true \
	    -vlanId                                  2182 

	$Submap0 sourceRanges(182).config \
	    -destinationId                           "1183" \
	    -enable                                  true \
	    -vlanId                                  2183 

	$Submap0 sourceRanges(183).config \
	    -destinationId                           "1184" \
	    -enable                                  true \
	    -vlanId                                  2184 

	$Submap0 sourceRanges(184).config \
	    -destinationId                           "1185" \
	    -enable                                  true \
	    -vlanId                                  2185 

	$Submap0 sourceRanges(185).config \
	    -destinationId                           "1186" \
	    -enable                                  true \
	    -vlanId                                  2186 

	$Submap0 sourceRanges(186).config \
	    -destinationId                           "1187" \
	    -enable                                  true \
	    -vlanId                                  2187 

	$Submap0 sourceRanges(187).config \
	    -destinationId                           "1188" \
	    -enable                                  true \
	    -vlanId                                  2188 

	$Submap0 sourceRanges(188).config \
	    -destinationId                           "1189" \
	    -enable                                  true \
	    -vlanId                                  2189 

	$Submap0 sourceRanges(189).config \
	    -destinationId                           "1190" \
	    -enable                                  true \
	    -vlanId                                  2190 

	$Submap0 sourceRanges(190).config \
	    -destinationId                           "1191" \
	    -enable                                  true \
	    -vlanId                                  2191 

	$Submap0 sourceRanges(191).config \
	    -destinationId                           "1192" \
	    -enable                                  true \
	    -vlanId                                  2192 

	$Submap0 sourceRanges(192).config \
	    -destinationId                           "1193" \
	    -enable                                  true \
	    -vlanId                                  2193 

	$Submap0 sourceRanges(193).config \
	    -destinationId                           "1194" \
	    -enable                                  true \
	    -vlanId                                  2194 

	$Submap0 sourceRanges(194).config \
	    -destinationId                           "1195" \
	    -enable                                  true \
	    -vlanId                                  2195 

	$Submap0 sourceRanges(195).config \
	    -destinationId                           "1196" \
	    -enable                                  true \
	    -vlanId                                  2196 

	$Submap0 sourceRanges(196).config \
	    -destinationId                           "1197" \
	    -enable                                  true \
	    -vlanId                                  2197 

	$Submap0 sourceRanges(197).config \
	    -destinationId                           "1198" \
	    -enable                                  true \
	    -vlanId                                  2198 

	$Submap0 sourceRanges(198).config \
	    -destinationId                           "1199" \
	    -enable                                  true \
	    -vlanId                                  2199 

	$Submap0 sourceRanges(199).config \
	    -destinationId                           "1200" \
	    -enable                                  true \
	    -vlanId                                  2200 

	$Submap0 sourceRanges(200).config \
	    -destinationId                           "1201" \
	    -enable                                  true \
	    -vlanId                                  2201 

	$Submap0 sourceRanges(201).config \
	    -destinationId                           "1202" \
	    -enable                                  true \
	    -vlanId                                  2202 

	$Submap0 sourceRanges(202).config \
	    -destinationId                           "1203" \
	    -enable                                  true \
	    -vlanId                                  2203 

	$Submap0 sourceRanges(203).config \
	    -destinationId                           "1204" \
	    -enable                                  true \
	    -vlanId                                  2204 

	$Submap0 sourceRanges(204).config \
	    -destinationId                           "1205" \
	    -enable                                  true \
	    -vlanId                                  2205 

	$Submap0 sourceRanges(205).config \
	    -destinationId                           "1206" \
	    -enable                                  true \
	    -vlanId                                  2206 

	$Submap0 sourceRanges(206).config \
	    -destinationId                           "1207" \
	    -enable                                  true \
	    -vlanId                                  2207 

	$Submap0 sourceRanges(207).config \
	    -destinationId                           "1208" \
	    -enable                                  true \
	    -vlanId                                  2208 

	$Submap0 sourceRanges(208).config \
	    -destinationId                           "1209" \
	    -enable                                  true \
	    -vlanId                                  2209 

	$Submap0 sourceRanges(209).config \
	    -destinationId                           "1210" \
	    -enable                                  true \
	    -vlanId                                  2210 

	$Submap0 sourceRanges(210).config \
	    -destinationId                           "1211" \
	    -enable                                  true \
	    -vlanId                                  2211 

	$Submap0 sourceRanges(211).config \
	    -destinationId                           "1212" \
	    -enable                                  true \
	    -vlanId                                  2212 

	$Submap0 sourceRanges(212).config \
	    -destinationId                           "1213" \
	    -enable                                  true \
	    -vlanId                                  2213 

	$Submap0 sourceRanges(213).config \
	    -destinationId                           "1214" \
	    -enable                                  true \
	    -vlanId                                  2214 

	$Submap0 sourceRanges(214).config \
	    -destinationId                           "1215" \
	    -enable                                  true \
	    -vlanId                                  2215 

	$Submap0 sourceRanges(215).config \
	    -destinationId                           "1216" \
	    -enable                                  true \
	    -vlanId                                  2216 

	$Submap0 sourceRanges(216).config \
	    -destinationId                           "1217" \
	    -enable                                  true \
	    -vlanId                                  2217 

	$Submap0 sourceRanges(217).config \
	    -destinationId                           "1218" \
	    -enable                                  true \
	    -vlanId                                  2218 

	$Submap0 sourceRanges(218).config \
	    -destinationId                           "1219" \
	    -enable                                  true \
	    -vlanId                                  2219 

	$Submap0 sourceRanges(219).config \
	    -destinationId                           "1220" \
	    -enable                                  true \
	    -vlanId                                  2220 

	$Submap0 sourceRanges(220).config \
	    -destinationId                           "1221" \
	    -enable                                  true \
	    -vlanId                                  2221 

	$Submap0 sourceRanges(221).config \
	    -destinationId                           "1222" \
	    -enable                                  true \
	    -vlanId                                  2222 

	$Submap0 sourceRanges(222).config \
	    -destinationId                           "1223" \
	    -enable                                  true \
	    -vlanId                                  2223 

	$Submap0 sourceRanges(223).config \
	    -destinationId                           "1224" \
	    -enable                                  true \
	    -vlanId                                  2224 

	$Submap0 sourceRanges(224).config \
	    -destinationId                           "1225" \
	    -enable                                  true \
	    -vlanId                                  2225 

	$Submap0 sourceRanges(225).config \
	    -destinationId                           "1226" \
	    -enable                                  true \
	    -vlanId                                  2226 

	$Submap0 sourceRanges(226).config \
	    -destinationId                           "1227" \
	    -enable                                  true \
	    -vlanId                                  2227 

	$Submap0 sourceRanges(227).config \
	    -destinationId                           "1228" \
	    -enable                                  true \
	    -vlanId                                  2228 

	$Submap0 sourceRanges(228).config \
	    -destinationId                           "1229" \
	    -enable                                  true \
	    -vlanId                                  2229 

	$Submap0 sourceRanges(229).config \
	    -destinationId                           "1230" \
	    -enable                                  true \
	    -vlanId                                  2230 

	$Submap0 sourceRanges(230).config \
	    -destinationId                           "1231" \
	    -enable                                  true \
	    -vlanId                                  2231 

	$Submap0 sourceRanges(231).config \
	    -destinationId                           "1232" \
	    -enable                                  true \
	    -vlanId                                  2232 

	$Submap0 sourceRanges(232).config \
	    -destinationId                           "1233" \
	    -enable                                  true \
	    -vlanId                                  2233 

	$Submap0 sourceRanges(233).config \
	    -destinationId                           "1234" \
	    -enable                                  true \
	    -vlanId                                  2234 

	$Submap0 sourceRanges(234).config \
	    -destinationId                           "1235" \
	    -enable                                  true \
	    -vlanId                                  2235 

	$Submap0 sourceRanges(235).config \
	    -destinationId                           "1236" \
	    -enable                                  true \
	    -vlanId                                  2236 

	$Submap0 sourceRanges(236).config \
	    -destinationId                           "1237" \
	    -enable                                  true \
	    -vlanId                                  2237 

	$Submap0 sourceRanges(237).config \
	    -destinationId                           "1238" \
	    -enable                                  true \
	    -vlanId                                  2238 

	$Submap0 sourceRanges(238).config \
	    -destinationId                           "1239" \
	    -enable                                  true \
	    -vlanId                                  2239 

	$Submap0 sourceRanges(239).config \
	    -destinationId                           "1240" \
	    -enable                                  true \
	    -vlanId                                  2240 

	$Submap0 sourceRanges(240).config \
	    -destinationId                           "1241" \
	    -enable                                  true \
	    -vlanId                                  2241 

	$Submap0 sourceRanges(241).config \
	    -destinationId                           "1242" \
	    -enable                                  true \
	    -vlanId                                  2242 

	$Submap0 sourceRanges(242).config \
	    -destinationId                           "1243" \
	    -enable                                  true \
	    -vlanId                                  2243 

	$Submap0 sourceRanges(243).config \
	    -destinationId                           "1244" \
	    -enable                                  true \
	    -vlanId                                  2244 

	$Submap0 sourceRanges(244).config \
	    -destinationId                           "1245" \
	    -enable                                  true \
	    -vlanId                                  2245 

	$Submap0 sourceRanges(245).config \
	    -destinationId                           "1246" \
	    -enable                                  true \
	    -vlanId                                  2246 

	$Submap0 sourceRanges(246).config \
	    -destinationId                           "1247" \
	    -enable                                  true \
	    -vlanId                                  2247 

	$Submap0 sourceRanges(247).config \
	    -destinationId                           "1248" \
	    -enable                                  true \
	    -vlanId                                  2248 

	$Submap0 sourceRanges(248).config \
	    -destinationId                           "1249" \
	    -enable                                  true \
	    -vlanId                                  2249 

	$Submap0 sourceRanges(249).config \
	    -destinationId                           "1250" \
	    -enable                                  true \
	    -vlanId                                  2250 

	$Submap0 sourceRanges(250).config \
	    -destinationId                           "1251" \
	    -enable                                  true \
	    -vlanId                                  2251 

	$Submap0 sourceRanges(251).config \
	    -destinationId                           "1252" \
	    -enable                                  true \
	    -vlanId                                  2252 

	$Submap0 sourceRanges(252).config \
	    -destinationId                           "1253" \
	    -enable                                  true \
	    -vlanId                                  2253 

	$Submap0 sourceRanges(253).config \
	    -destinationId                           "1254" \
	    -enable                                  true \
	    -vlanId                                  2254 

	$Submap0 sourceRanges(254).config \
	    -destinationId                           "1255" \
	    -enable                                  true \
	    -vlanId                                  2255 

	$Submap0 sourceRanges(255).config \
	    -destinationId                           "1256" \
	    -enable                                  true \
	    -vlanId                                  2256 

	$Submap0 sourceRanges(256).config \
	    -destinationId                           "1257" \
	    -enable                                  true \
	    -vlanId                                  2257 

	$Submap0 sourceRanges(257).config \
	    -destinationId                           "1258" \
	    -enable                                  true \
	    -vlanId                                  2258 

	$Submap0 sourceRanges(258).config \
	    -destinationId                           "1259" \
	    -enable                                  true \
	    -vlanId                                  2259 

	$Submap0 sourceRanges(259).config \
	    -destinationId                           "1260" \
	    -enable                                  true \
	    -vlanId                                  2260 

	$Submap0 sourceRanges(260).config \
	    -destinationId                           "1261" \
	    -enable                                  true \
	    -vlanId                                  2261 

	$Submap0 sourceRanges(261).config \
	    -destinationId                           "1262" \
	    -enable                                  true \
	    -vlanId                                  2262 

	$Submap0 sourceRanges(262).config \
	    -destinationId                           "1263" \
	    -enable                                  true \
	    -vlanId                                  2263 

	$Submap0 sourceRanges(263).config \
	    -destinationId                           "1264" \
	    -enable                                  true \
	    -vlanId                                  2264 

	$Submap0 sourceRanges(264).config \
	    -destinationId                           "1265" \
	    -enable                                  true \
	    -vlanId                                  2265 

	$Submap0 sourceRanges(265).config \
	    -destinationId                           "1266" \
	    -enable                                  true \
	    -vlanId                                  2266 

	$Submap0 sourceRanges(266).config \
	    -destinationId                           "1267" \
	    -enable                                  true \
	    -vlanId                                  2267 

	$Submap0 sourceRanges(267).config \
	    -destinationId                           "1268" \
	    -enable                                  true \
	    -vlanId                                  2268 

	$Submap0 sourceRanges(268).config \
	    -destinationId                           "1269" \
	    -enable                                  true \
	    -vlanId                                  2269 

	$Submap0 sourceRanges(269).config \
	    -destinationId                           "1270" \
	    -enable                                  true \
	    -vlanId                                  2270 

	$Submap0 sourceRanges(270).config \
	    -destinationId                           "1271" \
	    -enable                                  true \
	    -vlanId                                  2271 

	$Submap0 sourceRanges(271).config \
	    -destinationId                           "1272" \
	    -enable                                  true \
	    -vlanId                                  2272 

	$Submap0 sourceRanges(272).config \
	    -destinationId                           "1273" \
	    -enable                                  true \
	    -vlanId                                  2273 

	$Submap0 sourceRanges(273).config \
	    -destinationId                           "1274" \
	    -enable                                  true \
	    -vlanId                                  2274 

	$Submap0 sourceRanges(274).config \
	    -destinationId                           "1275" \
	    -enable                                  true \
	    -vlanId                                  2275 

	$Submap0 sourceRanges(275).config \
	    -destinationId                           "1276" \
	    -enable                                  true \
	    -vlanId                                  2276 

	$Submap0 sourceRanges(276).config \
	    -destinationId                           "1277" \
	    -enable                                  true \
	    -vlanId                                  2277 

	$Submap0 sourceRanges(277).config \
	    -destinationId                           "1278" \
	    -enable                                  true \
	    -vlanId                                  2278 

	$Submap0 sourceRanges(278).config \
	    -destinationId                           "1279" \
	    -enable                                  true \
	    -vlanId                                  2279 

	$Submap0 sourceRanges(279).config \
	    -destinationId                           "1280" \
	    -enable                                  true \
	    -vlanId                                  2280 

	$Submap0 sourceRanges(280).config \
	    -destinationId                           "1281" \
	    -enable                                  true \
	    -vlanId                                  2281 

	$Submap0 sourceRanges(281).config \
	    -destinationId                           "1282" \
	    -enable                                  true \
	    -vlanId                                  2282 

	$Submap0 sourceRanges(282).config \
	    -destinationId                           "1283" \
	    -enable                                  true \
	    -vlanId                                  2283 

	$Submap0 sourceRanges(283).config \
	    -destinationId                           "1284" \
	    -enable                                  true \
	    -vlanId                                  2284 

	$Submap0 sourceRanges(284).config \
	    -destinationId                           "1285" \
	    -enable                                  true \
	    -vlanId                                  2285 

	$Submap0 sourceRanges(285).config \
	    -destinationId                           "1286" \
	    -enable                                  true \
	    -vlanId                                  2286 

	$Submap0 sourceRanges(286).config \
	    -destinationId                           "1287" \
	    -enable                                  true \
	    -vlanId                                  2287 

	$Submap0 sourceRanges(287).config \
	    -destinationId                           "1288" \
	    -enable                                  true \
	    -vlanId                                  2288 

	$Submap0 sourceRanges(288).config \
	    -destinationId                           "1289" \
	    -enable                                  true \
	    -vlanId                                  2289 

	$Submap0 sourceRanges(289).config \
	    -destinationId                           "1290" \
	    -enable                                  true \
	    -vlanId                                  2290 

	$Submap0 sourceRanges(290).config \
	    -destinationId                           "1291" \
	    -enable                                  true \
	    -vlanId                                  2291 

	$Submap0 sourceRanges(291).config \
	    -destinationId                           "1292" \
	    -enable                                  true \
	    -vlanId                                  2292 

	$Submap0 sourceRanges(292).config \
	    -destinationId                           "1293" \
	    -enable                                  true \
	    -vlanId                                  2293 

	$Submap0 sourceRanges(293).config \
	    -destinationId                           "1294" \
	    -enable                                  true \
	    -vlanId                                  2294 

	$Submap0 sourceRanges(294).config \
	    -destinationId                           "1295" \
	    -enable                                  true \
	    -vlanId                                  2295 

	$Submap0 sourceRanges(295).config \
	    -destinationId                           "1296" \
	    -enable                                  true \
	    -vlanId                                  2296 

	$Submap0 sourceRanges(296).config \
	    -destinationId                           "1297" \
	    -enable                                  true \
	    -vlanId                                  2297 

	$Submap0 sourceRanges(297).config \
	    -destinationId                           "1298" \
	    -enable                                  true \
	    -vlanId                                  2298 

	$Submap0 sourceRanges(298).config \
	    -destinationId                           "1299" \
	    -enable                                  true \
	    -vlanId                                  2299 

	$Submap0 sourceRanges(299).config \
	    -destinationId                           "1300" \
	    -enable                                  true \
	    -vlanId                                  2300 



	#################################################
	# Session Specific Settings
	#################################################
	set my_ixNetMacSessionData [$Test1 getSessionSpecificData "L2EthernetPlugin"]

	$my_ixNetMacSessionData config \
	    -_Stale                                  false \
	    -duplicateCheckingScope                  2 

	set my_ixNetIpSessionData [$Test1 getSessionSpecificData "IpV4V6Plugin"]

	$my_ixNetIpSessionData config \
	    -enableGatewayArp                        false \
	    -ignoreUnresolvedIPs                     false \
	    -individualARPTimeOut                    500 \
	    -maxOutstandingGatewayArpRequests        300 \
	    -_Stale                                  false \
	    -sendAllRequests                         true \
	    -gatewayArpRequestRate                   300 \
	    -duplicateCheckingScope                  2 

	#################################################
	# Create the test controller to run the test
	#################################################
	set testController [::IxLoad new ixTestController  -outputDir true]



	$testController setResultDir "RESULTS\\scriptgen_ixload"

	set NS statCollectorUtils

	set test_server_handle [$testController getTestServerHandle]
	${NS}::Initialize -testServerHandle $test_server_handle

	${NS}::ClearStats
	$Test1 clearGridStats

	set count 1

	foreach stat $::statList {
	    set caption [format "Watch_Stat_%s"  $count]
	    set statSourceType [lindex $stat 0]
	    set statName [lindex $stat 1]
	    set aggregationType [lindex $stat 2]
	    ${NS}::AddStat \
		-filterList                              {} \
		-caption                                 $caption \
		-statSourceType                          $statSourceType \
		-statName                                $statName \
		-aggregationType                         $aggregationType 
	    incr count
		
	    proc ::my_stat_collector_command {args} {
		puts "====================================="
		puts "INCOMING STAT RECORD >>> $args"
		puts "====================================="
	    }
	}
	

	${NS}::StartCollector -command IxL_StatCollectorCommand -interval 2
	set ::ixTestControllerMonitor ""

	$testController run $Test1

	IxL_EnterKeyToAbortTest 

	#vwait ::ixTestControllerMonitor
	#puts $::ixTestControllerMonitor

	${NS}::StopCollector

	#################################################
	# Cleanup
	#################################################
	# Release config is only strictly necessary if enableReleaseConfigAfterRun is 0.
	#$testController releaseConfig
	$testController releaseConfigWaitFinish

	#vwait ::ixTestControllerMonitor
	#puts $::ixTestControllerMonitor

	$Test1 clearDUTList

	$Traffic0_CltNetwork_0 removeAllPortsFromAnalyzer

	$SvrTraffic0_SvrNetwork_0 removeAllPortsFromAnalyzer

	::IxLoad delete $chassisChain

	::IxLoad delete $Test1

	::IxLoad delete $profileDirectory

	::IxLoad delete $my_ixEventHandlerSettings

	::IxLoad delete $my_ixViewOptions

	::IxLoad delete $Scenario1

	::IxLoad delete $Originate

	::IxLoad delete $Traffic0_CltNetwork_0

	::IxLoad delete $CltNetwork_0

	::IxLoad delete $Settings_2

	::IxLoad delete $Filter_1

	::IxLoad delete $GratARP_1

	::IxLoad delete $TCP_2

	::IxLoad delete $DNS_2

	::IxLoad delete $Meshing_1

	::IxLoad delete $Ethernet_1

	::IxLoad delete $my_ixNetDataCenterSettings

	::IxLoad delete $my_ixNetEthernetELMPlugin

	::IxLoad delete $my_ixNetDualPhyPlugin

	::IxLoad delete $MAC_VLAN_1

	::IxLoad delete $IP_1

	::IxLoad delete $IP_R1

	::IxLoad delete $MAC_R1

	::IxLoad delete $VLAN_R1

	::IxLoad delete $IP_R2

	::IxLoad delete $MAC_R2

	::IxLoad delete $VLAN_R2

	::IxLoad delete $IP_R3

	::IxLoad delete $MAC_R3

	::IxLoad delete $VLAN_R3

	::IxLoad delete $DistGroup1

	::IxLoad delete $Activity_HTTP_Client1_1

	::IxLoad delete $timeLine_0

	::IxLoad delete $my_ixHttpCommand

	::IxLoad delete $my_ixHttpHeaderString

	::IxLoad delete $my_ixHttpHeaderString1

	::IxLoad delete $my_ixHttpHeaderString2

	::IxLoad delete $my_ixHttpHeaderString3

	::IxLoad delete $DUT

	::IxLoad delete $Terminate

	::IxLoad delete $SvrTraffic0_SvrNetwork_0

	::IxLoad delete $SvrNetwork_0

	::IxLoad delete $Settings_4

	::IxLoad delete $Filter_2

	::IxLoad delete $GratARP_2

	::IxLoad delete $TCP_4

	::IxLoad delete $DNS_4

	::IxLoad delete $Meshing_2

	::IxLoad delete $Ethernet_2

	::IxLoad delete $my_ixNetDataCenterSettings1

	::IxLoad delete $my_ixNetEthernetELMPlugin1

	::IxLoad delete $my_ixNetDualPhyPlugin1

	::IxLoad delete $MAC_VLAN_2

	::IxLoad delete $IP_2

	::IxLoad delete $IP_R4

	::IxLoad delete $MAC_R4

	::IxLoad delete $VLAN_R4

	::IxLoad delete $IP_R5

	::IxLoad delete $MAC_R5

	::IxLoad delete $VLAN_R5

	::IxLoad delete $IP_R6

	::IxLoad delete $MAC_R6

	::IxLoad delete $VLAN_R6

	::IxLoad delete $IP_R7

	::IxLoad delete $MAC_R7

	::IxLoad delete $VLAN_R7

	::IxLoad delete $IP_R8

	::IxLoad delete $MAC_R8

	::IxLoad delete $VLAN_R8

	::IxLoad delete $IP_R9

	::IxLoad delete $MAC_R9

	::IxLoad delete $VLAN_R9

	::IxLoad delete $DistGroup2

	::IxLoad delete $Activity_HTTPServer1

	::IxLoad delete $_Match_Longest_

	::IxLoad delete $my_PageObject

	::IxLoad delete $_200_OK

	::IxLoad delete $my_PageObject1

	::IxLoad delete $my_PageObject2

	::IxLoad delete $my_PageObject3

	::IxLoad delete $my_PageObject4

	::IxLoad delete $my_PageObject5

	::IxLoad delete $my_PageObject6

	::IxLoad delete $my_PageObject7

	::IxLoad delete $my_PageObject8

	::IxLoad delete $my_PageObject9

	::IxLoad delete $UserCookie

	::IxLoad delete $firstName

	::IxLoad delete $lastName

	::IxLoad delete $LoginCookie

	::IxLoad delete $name

	::IxLoad delete $password

	::IxLoad delete $AsciiCustomPayload

	::IxLoad delete $HexCustomPayload

	::IxLoad delete $_201

	::IxLoad delete $_404_PageNotFound

	::IxLoad delete $DUT1

	::IxLoad delete $my_ixDutConfigVirtual

	::IxLoad delete $Network_Range_1_in_unknown_dut__1_1_1_100_100_

	::IxLoad delete $Network_Range_2_in_unknown_dut__2_1_1_100_100_

	::IxLoad delete $Network_Range_3_in_unknown_dut__3_1_1_100_100_

	::IxLoad delete $destination

	::IxLoad delete $my_ixCustomPortMap

	::IxLoad delete $my_ixNetMacSessionData

	::IxLoad delete $my_ixNetIpSessionData

	::IxLoad delete $testController


	#################################################
	# Disconnect / Release application lock
	#################################################
    } errorInfo] {
	$logger error $errorInfo
	puts $errorInfo
    }

    ::IxLoad disconnect
}


#Main
