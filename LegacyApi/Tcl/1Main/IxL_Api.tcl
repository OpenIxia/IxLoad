# IxLoad APIs by: Hubert Gee
# Scripts that uses these APIs:
#    - IxL_multipleIpv4RangesHttp3.tcl

proc IxL_Connect { windowsClientIp } {
    puts "\nConnecting to $windowsClientIp..."
    # clientOpen: Error: couldn't open socket: host is unreachable
    if {[catch {::IxLoad connect $windowsClientIp} connectStatus]} {
	return 1
    }
    puts "\nSuccessfully connected to $windowsClientIp"
    return 0
}

proc IxL_AddPorts { args } {
    # -objHandle $Network1

    set params {}

    set argIndex 0
    while {$argIndex < [llength $args]} {
	set currentArg [lindex $args $argIndex]
	switch -exact -- $currentArg { 
	    -objHandle {
		set objHandle [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -chassisId {
		set chassisId [lindex $args [expr $argIndex + 1]]
		append params "-chassisId $chassisId "
		incr argIndex 2
	    }
	    -cardId {
		set cardId [lindex $args [expr $argIndex + 1]]
		append params "-cardId $cardId "
		incr argIndex 2
	    }
	    -portId {
		set portId [lindex $args [expr $argIndex + 1]]
		append params "-portId $portId "
		incr argIndex 2
	    }
	    default {
		puts "\nIxL_AddPorts Error: No such parameter: $currentArg"
		return 1
	    }
	}
    }

    #puts "\nIxL_AppendPortList $chassisId $cardId $portId"
    eval $objHandle portList.appendItem $params
}

proc IxL_EnableForceOwnership { object action } {
    # Ex: IxL_EnableForceOwnership $Test1 true
    # action = true or false
    $object config -enableForceOwnership $action
}

proc IxL_EnableResetPorts { object action } {
    # Ex: IxL_EnableResetPorts $Test1 true
    # action = true or false
    $object config -enableResetPorts $action
}


proc IxL_ConfigNetwork { objHandle args } {
    set paramList {} 
    
    set mandatoryParams {-ipAddress -gatewayAddress}
    
    set undiscoveredList {}
    foreach undiscoveredParam $mandatoryParams {
	if {[lsearch $args $undiscoveredParam] == -1} {
	    lappend undiscoveredList $undiscoveredParam
	}
    }
    
    if {$undiscoveredList != ""} {
	puts "\nIxL_ConfigNetwork Error: Requires mandatory params: $undiscoveredList"
	return 1
    }

    foreach {parameter value} { \
				    -enableGatewayArp   true \
				    -randomizeSeed      155196417 \
				    -generateStatistics false \
				    -autoIpTypeEnabled  false \
				    -autoCountEnabled   false \
				    -enabled            true \
				    -autoMacGeneration  true \
				    -publishStats       false \
				    -incrementBy        "0.0.1.0" \
				    -gatewayIncrement   "0.0.1.0" \
				    -gatewayIncrementMode "perSubnet" \
				    -mss                  1460 \
				    -randomizeAddress     false \
				    -ipAddress            "1.1.1.1" \
				    -gatewayAddress       "1.1.1.255" \
				    -ipType               "IPv4" \
				    -count                1 \
				    -prefix               24 \
				} {

    	if {[lsearch $args $parameter] == -1} {
	    # Defaults
	    if {[llength $value] > 1 || $value == ""} {
		set value \"$value\"
	    }
	    append paramList " $parameter $value"
	} else {
	    # User defined
	    set argIndex [lsearch $args $parameter]
	    set userValue [lindex $args [expr $argIndex + 1]]
	    if {[llength $userValue] > 1 || $value == ""} {
		set userValue \"$userValue\"
	    }
	    append paramList " $parameter $userValue"
	}
    }
    
    set newIpObject [::IxLoad new ixNetIpV4V6Range]

    # ixNet objects need to be added in the list before they are configured.
    $objHandle rangeList.appendItem -object $newIpObject
    
    puts "\nIxL_ConfigNetwork: $paramList"
    eval $newIpObject config $paramList
    return $newIpObject
}

proc IxL_ConfigMacAddress { objHandle args } {
    set paramList {} 

    foreach {parameter value} { \
				    -enabled true \
				    -mtu     1500 \
				    -_Stale  false \
				    -incrementBy "00:00:00:00:00:01" \
				    -count   1 \
				    -mac 00:00:00:00:00:01 \
				} {
	
	if {[lsearch $args $parameter] == -1} {
	    # Defaults
	    if {[llength $value] > 1 || $value == ""} {
		set value \"$value\"
	    }
	    append paramList " $parameter $value"
	} else {
	    # User defined
	    set argIndex [lsearch $args $parameter]
	    set userValue [lindex $args [expr $argIndex + 1]]
	    if {[llength $userValue] > 1 || $value == ""} {
		set userValue \"$userValue\"
	    }
	    append paramList " $parameter $userValue"
	}
    }

    set newMacObj [$objHandle getLowerRelatedRange "MacRange"]

    puts "\nIxL_ConfigMacAddress: $paramList"
    eval $newMacObj config $paramList
    return $newMacObj
}

proc IxL_ConfigVlanId { objHandle args } {
    set paramList {} 
    
    foreach {parameter value} { \
				    -incrementStep 1 \
				    -innerIncrement 1 \
				    -tpid           "0x8100" \
				    -idIncrMode     2 \
				    -enabled        true \
				    -innerFirstId   1 \
				    -innerIncrementStep 1 \
				    -_Stale             false \
				    -increment          1 \
				    -innerTpid          "0x8100" \
				    -innerUniqueCount   4094 \
				    -innerEnable        false \
				    -innerPriority      1 \
				    -uniqueCount        1 \
				    -firstId            1 \
				    -priority           1 \
				} {

	if {[lsearch $args $parameter] == -1} {
	    # Defaults
	    if {[llength $value] > 1 || $value == ""} {
		set value \"$value\"
	    }
	    append paramList " $parameter $value"
	} else {
	    # User defined
	    set argIndex [lsearch $args $parameter]
	    set userValue [lindex $args [expr $argIndex + 1]]
	    if {[llength $userValue] > 1 || $value == ""} {
		set userValue \"$userValue\"
	    }
	    append paramList " $parameter $userValue"
	}
    }
    
    set newVlanIdObj [$objHandle getLowerRelatedRange "VlanIdRange"]
    
    puts "\nIxL_ConfigVlanId: $paramList"
    eval $newVlanIdObj config $paramList
    return $newVlanIdObj
}

proc IxL_ConfigGratArp { objHandle args } {
    set paramList {} 

    foreach {parameter value} { \
				    -forwardGratArp false \
				    -enabled true \
				    -maxFramesPerSecond 0 \
				    -_Stale false \
				    -rateControlEnabled false \
				} {
	
	if {[lsearch $args $parameter] == -1} {
	    # Defaults
	    if {[llength $value] > 1 || $value == ""} {
		set value \"$value\"
	    }
	    append paramList " $parameter $value"
	} else {
	    # User defined
	    set argIndex [lsearch $args $parameter]
	    set userValue [lindex $args [expr $argIndex + 1]]
	    if {[llength $userValue] > 1 || $value == ""} {
		set userValue \"$userValue\"
	    }
	    append paramList " $parameter $userValue"
	}
    }
    
    set gratArpObj [::IxLoad new ixNetGratArpPlugin]
    
    puts "\nIxL_ConfigGratArp: $paramList"
    $objHandle globalPlugins.appendItem -object $gratArpObj

    puts "\nIxL_ConfigGratArp: $paramList"
    eval $gratArpObj config $paramList
    return $gratArpObj
}

proc IxL_ConfigArp { objHandle args } {
    set paramList {} 

    foreach {parameter value} { \
				    -_Stale false \
				    -duplicateCheckingScope 2 \
				    -enableGatewayArp true \
				    -ignoreUnresolvedIPs false \
				    -individualARPTimeOut 500 \
				    -maxOutstandingGatewayArpRequests 300 \
				    -sendAllRequests true \
				    -gatewayArpRequestRate 300 \
				} {

	if {[lsearch $args $parameter] == -1} {
	    # Defaults
	    if {[llength $value] > 1 || $value == ""} {
		set value \"$value\"
	    }
	    append paramList " $parameter $value"
	} else {
	    # User defined
	    set argIndex [lsearch $args $parameter]
	    set userValue [lindex $args [expr $argIndex + 1]]
	    if {[llength $userValue] > 1 || $value == ""} {
		set userValue \"$userValue\"
	    }
	    append paramList " $parameter $userValue"
	}
    }
    
    puts "\nIxL_ConfigArp: $paramList"
    set status [eval $objHandle config $paramList]
    return $status
}

proc IxL_ConfigTimeLine { args } {
    set paramList {} 

    foreach {parameter value} { \
				    -rampUpType   0 \
				    -offlineTime  0 \
				    -iterations   1 \
				    -timelineType  0 \
				    -name "Timeline1" \
				    -rampUpValue  1 \
				    -rampDownTime 20 \
				    -standbyTime  0 \
				    -rampDownValue 0 \
				    -rampUpInterval 1 \
				    -sustainTime   20 \
				} {

	if {[lsearch $args $parameter] == -1} {
	    # Defaults
	    if {[llength $value] > 1 || $value == ""} {
		set value \"$value\"
	    }
	    append paramList " $parameter $value"
	} else {
	    # User defined
	    set argIndex [lsearch $args $parameter]
	    set userValue [lindex $args [expr $argIndex + 1]]
	    if {[llength $userValue] > 1 || $value == ""} {
		set userValue \"$userValue\"
	    }
	    append paramList " $parameter $userValue"
	}
    }
    
    set timeLineObj [::IxLoad new ixTimeline]

    puts "\nIxL_ConfigTimeLine: $paramList"
    eval $timeLineObj config $paramList
    return $timeLineObj
}

proc IxL_ConfigTcp { objHandle args } {
    set paramList {}

    foreach {parameter value}  { \
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
				     -delayed_acks                            true \
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
				     -tcp_synack_retries                      5 \
				     -tcp_timestamps                          true \
				     -tcp_reordering                          3 \
				     -rps_needed                              false \
				     -tcp_sack                                true \
				     -tcp_bic_fast_convergence                1 \
				     -tcp_bic_low_window                      14 \
				 } {

	if {[lsearch $args $parameter] == -1} {
	    # Defaults
	    if {[llength $value] > 1 || $value == ""} {
		set value \"$value\"
	    }
	    append paramList " $parameter $value"
	} else {
	    # User defined
	    set argIndex [lsearch $args $parameter]
	    set userValue [lindex $args [expr $argIndex + 1]]
	    if {[llength $userValue] > 1 || $value == ""} {
		set userValue \"$userValue\"
	    }
	    append paramList " $parameter $userValue"
	}
    }
    
    set tcpObj [::IxLoad new ixNetTCPPlugin]
    
    # ixNet objects need to be added in the list before they are configured.
    $objHandle globalPlugins.appendItem -object $tcpObj
    
    puts "\nIxL_ConfigTcp: $paramList"
    eval $tcpObj config $paramList
    return $tcpObj
}

proc IxL_ConfigDutNetwork { args } {
    set paramList {} 
    set mandatoryParams {-firstIp}

    set undiscoveredList {}
    foreach undiscoveredParam $mandatoryParams {
	if {[lsearch $args $undiscoveredParam] == -1} {
	    lappend undiscoveredList $undiscoveredParam
	}
    }

    if {$undiscoveredList != ""} {
	puts "\nIxL_ConfigDutNetwork Error: Requires mandatory params: $undiscoveredList"
	return 1
    }

    foreach {parameter value} { \
				    -enable            true \
				    -firstIp           1.1.1.1 \
				    -ipCount           1 \
				    -networkMask       255.255.255.0 \
				    -ipType            1 \
				    -vlanIncrStep      1 \
				    -innerVlanEnable   false \
				    -ipIncrStep        "0.0.1.0" \
				    -vlanUniqueCount   4094 \
				    -vlanEnable        false \
				    -vlanId            1 \
				    -vlanCount         1 \
				    -name              "DUT Network Range" \
				} {
	
	if {[lsearch $args $parameter] == -1} {
	    # Defaults
	    if {[llength $value] > 1 || $value == ""} {
		set value \"$value\"
	    }
	    append paramList " $parameter $value"
	} else {
	    # User defined
	    set argIndex [lsearch $args $parameter]
	    set userValue [lindex $args [expr $argIndex + 1]]
	    if {[llength $userValue] > 1 || $value == ""} {
		set userValue \"$userValue\"
	    }
	    append paramList " $parameter $userValue"
	}
    }
    
    set dutNetworkRangeObj [::IxLoad new ixDutNetworkRange]
    
    puts "\nIxL_ConfigDutNetwork: $paramList\n"
    eval $dutNetworkRangeObj config $paramList
    return $dutNetworkRangeObj
}

proc IxL_MapVlanSrcDstPair { args } {
    # Users will have to create a list for srcVlanId and dstVlanId
    # using the utility like IxL_CreateVlanMapList,
    # because users can have all sort of vlanID patterns.
    # So, define the pattern list first.

    set argIndex 0
    while {$argIndex < [llength $args]} {
	set currentArg [lindex $args $argIndex]
	switch -exact -- $currentArg { 
	    -objHandle {
		set objHandle [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -srcVlanIdList {
		set srcVlanIdList [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -dstVlanIdList {
		set dstVlanIdList [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    default {
		puts "\nMapVlanPair error: No such parameter: $currentArg"
		return 1
	    }
	}
    }

    set index 0
    foreach srcVlanId $srcVlanIdList dstVlanId $dstVlanIdList {
	$objHandle sourceRanges($index).config \
	    -destinationId $dstVlanId \
	    -enable        true \
	    -vlanId        $srcVlanId

	incr index
    }
}

proc IxL_CreateVlanMapList { args } {
    # A utility for creating srcVlanId/dstVlanId mapping:
    # This utility will only incrementing in steps of "1".
    # No other patterns.  If you need a different pattern,
    # create a different utility Proc.
    #
    #    -start = The starting VlanId number.
    #    -total = The total amount of number to create.

    set argIndex 0
    while {$argIndex < [llength $args]} {
	set currentArg [lindex $args $argIndex]
	switch -exact -- $currentArg { 
	    -start {
		set start [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -total {
		set total [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    default {
		puts "\nIxL_CreateVlanMapList: Error: No such parameter: $currentArg"
		return 1
	    }
	}
    }
	
    set mapList {}
    for {set number $start} {$number < [expr $start + $total]} {incr number} {
	lappend mapList $number 
    }
    return $mapList
}

proc IxL_ConfigHttpClientSettings { objHandle args } {
    set paramList {} 
    
    foreach {parameter value} { \
				    -enable true \
				    -userIpMapping "1:1" \
				    -enableConstraint true \
				    -constraintType "SimulatedUserConstraint" \
				    -userObjectiveType "throughputMbps" \
				    -destinationIpMapping "Consecutive" \
				    -name "HTTPClient1" \
				    -constraintValue 100 \
				    -userObjectiveValue 3 \
				} {
	
	if {[lsearch $args $parameter] == -1} {
	    # Defaults
	    if {[llength $value] > 1 || $value == ""} {
		set value \"$value\"
	    }
	    append paramList " $parameter $value"
	} else {
	    # User defined
	    set argIndex [lsearch $args $parameter]
	    set userValue [lindex $args [expr $argIndex + 1]]
	    if {[llength $userValue] > 1 || $value == ""} {
		set userValue \"$userValue\"
	    }
	    append paramList " $parameter $userValue"
	}
    }

    puts "\nIxL_ConfigHttpClientSettings: $paramList"
    eval $objHandle config $paramList
}

proc IxL_ConfigHttpCommands { objHandle args } {
    set paramList {}

    foreach {parameter value}  { \
				     -profile -1 \
				     -enableDi 0 \
				     -namevalueargs "" \
				     -sendMD5ChkSumHeader 0 \
				     -cmdName "Get 1" \
				     -abort "None" \
				     -arguments "" \
				     -sendingChunkSize "None" \
				     -destination "DUT1:80" \
				     -commandType "GET" \
				     -pageObject "/32k.html" \
				 } {
	
    	if {[lsearch $args $parameter] == -1} {
	    # Defaults
	    if {[llength $value] > 1 || $value == ""} {
		set value \"$value\"
	    }
	    append paramList " $parameter $value"
	} else {
	    # User defined
	    set argIndex [lsearch $args $parameter]
	    set userValue [lindex $args [expr $argIndex + 1]]
	    if {[llength $userValue] > 1 || $value == ""} {
		set userValue \"$userValue\"
	    }
	    append paramList " $parameter $userValue"
	}
    }
    				  
    puts "\nIxL_ConfigHttpCommands: $paramList"
    eval $objHandle config $paramList
}

proc IxL_ConfigHttpAgents { objHandle args } {
    set paramList {}

    foreach {parameter value} { \
				    -cmdListLoops                            0 \
				    -vlanPriority                            0 \
				    -validateCertificate                     0 \
				    -enableDecompressSupport                 0 \
				    -exactTransactions                       0 \
				    -enableHttpsProxy                        0 \
				    -perHeaderPercentDist                    0 \
				    -enablePerConnCookieSupport              0 \
				    -cookieRejectProbability                 0.0 \
				    -enableUnidirectionalClose               0 \
				    -httpsTunnel                             "0.0.0.0" \
				    -piggybackAck                            1 \
				    -maxPersistentRequests                   100 \
				    -enableEsm                               0 \
				    -certificate                             "" \
				    -sequentialSessionReuse                  0 \
				    -browserEmulationName                    "Custom1" \
				    -enableSslSendCloseNotify                0 \
				    -maxPipeline                             1 \
				    -contentLengthDeviationTolerance         0 \
				    -caCert                                  "" \
				    -enableHttpProxy                         0 \
				    -disableDnsResolutionCache               0 \
				    -enableTos                               0 \
				    -precedenceTOS                           0 \
				    -ipPreference                            2 \
				    -maxHeaderLen                            1024 \
				    -flowPercentage                          100.0 \
				    -cookieJarSize                           10 \
				    -reliabilityTOS                          0 \
				    -sslRecordSize                           "16384" \
				    -privateKey                              "" \
				    -commandTimeout                          600 \
				    -enablemetaRedirectSupport               0 \
				    -delayTOS                                0 \
				    -enableIntegrityCheckSupport             0 \
				    -commandTimeout_ms                       0 \
				    -privateKeyPassword                      "" \
				    -urlStatsCount                           10 \
				    -followHttpRedirects                     0 \
				    -tcpCloseOption                          0 \
				    -enableVlanPriority                      0 \
				    -esm                                     1460 \
				    -enablesslRecordSize                     0 \
				    -enableHttpsTunnel                       0 \
				    -enableLargeHeader                       0 \
				    -throughputTOS                           0 \
				    -enableCookieSupport                     0 \
				    -enableConsecutiveIpsPerSession          0 \
				    -clientCiphers                           "DEFAULT" \
				    -enableAchieveCCFirst                    0 \
				    -tos                                     0 \
				    -httpProxy                               "0.0.0.0" \
				    -keepAlive                               false \
				    -enableCRCCheckSupport                   0 \
				    -httpsProxy                              "0.0.0.0" \
				    -maxSessions                             3 \
				    -httpVersion                             1 \
				    -enableSsl                               false \
				} {
	
    	if {[lsearch $args $parameter] == -1} {
	    # Defaults
	    if {[llength $value] > 1 || $value == ""} {
		set value \"$value\"
	    }
	    append paramList " $parameter $value"
	} else {
	    # User defined
	    set argIndex [lsearch $args $parameter]
	    set userValue [lindex $args [expr $argIndex + 1]]
	    if {[llength $userValue] > 1 || $value == ""} {
		set userValue \"$userValue\"
	    }
	    append paramList " $parameter $userValue"
	}
    }

    puts "\nIxL_ConfigHttpAgents: $paramList"
    eval $objHandle agent.config $paramList
}

proc IxL_ConfigHttpResponseHeader { objHandle args } {
    set paramList {}

    # Set these as defaults if user did not define any of these parameters.
    foreach {parameter value} { \
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
				    -description                             "OK" \
				} {
	
	if {[lsearch $args $parameter] == -1} {
	    # Defaults
	    if {[llength $value] > 1 || $value == ""} {
		set value \"$value\"
	    }
	    append paramList " $parameter $value"
	} else {
	    # User defined
	    set argIndex [lsearch $args $parameter]
	    set userValue [lindex $args [expr $argIndex + 1]]
	    if {[llength $userValue] > 1 || $value == ""} {
		set userValue \"$userValue\"
	    }
	    append paramList " $parameter $userValue"
	}
    }
    
    puts "\nIxL_ConfigHttpResponseHeader: $paramList"
    eval $objHandle config $paramList
}

proc IxL_SetResultDirectory { testControllerObj resultDirectory } {
    puts "\nIxL_SetResultDirectory: $resultDirectory"
    $testControllerObj setResultDir $resultDirectory
}

proc IxL_InitializeStatCollector { trafficStatName testServerHandle } {
    puts "\nIxL_InitializeStatCollector: $trafficStatName"
    ${trafficStatName}::Initialize -testServerHandle $testServerHandle
}

proc IxL_ClearStats { trafficStatName } {
    puts "\nIxL_ClearStats: $trafficStatName"
    ${trafficStatName}::ClearStats
}

proc IxL_AddStat { args } {
    # Define the stats we would like to collect
    set params {}
    set argIndex 0
    while {$argIndex < [llength $args]} {
	set currentArg [lindex $args $argIndex]
	switch -exact -- $currentArg { 
	    -trafficStatName {
		set trafficStatName [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -caption {
		set caption [lindex $args [expr $argIndex + 1]]
		append params "-caption $caption "
		incr argIndex 2
	    }
	    -statSourceType {
		set statSourceType [lindex $args [expr $argIndex + 1]]
		if {[llength $statSourceType] > 1} {
		    set statSourceType "\"$statSourceType\""
		}
		append params "-statSourceType $statSourceType "
		incr argIndex 2
	    }
	    -statName {
		set statName [lindex $args [expr $argIndex + 1]]
		if {[llength $statName] > 1} {
		    set statName "\"$statName\""
		}
		append params "-statName $statName "
		incr argIndex 2
	    }
	    -aggregationType {
		set aggregationType [lindex $args [expr $argIndex + 1]]
		append params "-aggregationType $aggregationType "
		incr argIndex 2
	    }
	    -filterList {
		set filterList [lindex $args [expr $argIndex + 1]]
		if {$filterList == ""} {
		    set filterList [list [list]]
		}
		append params "-filterList $filterList "
		incr argIndex 2
	    }
	    default {
		puts "\nError: No such parameter: $currentArg"
		return 1
	    }
	}
    }

    puts "\nIxL_AddStats: $trafficStatName: $params"
    eval ${trafficStatName}::AddStat $params
    return 0
}

proc IxL_GetStats {args} {
    # Start the collector (runs in the tcl event loop)
    puts "====================================="
    puts "INCOMING STAT RECORD >>> $args"
    puts "Len = [llength $args]"
    puts  [lindex $args 0]
    puts  [lindex $args 1]
    puts "====================================="
}

proc IxL_StartStatCollector { trafficStatName } {
    puts "\nIxL_StartStatCollector: $trafficStatName"
    #${trafficStatName}::StartCollector -command ::my_stat_collector_command
    ${trafficStatName}::StartCollector -command IxL_GetStats
}

proc IxL_RunTest { testControllerObj testObj {rxfFileName ""} } {
    # rxfFileName = The name of the IxLoad config file to be saved as.
    #               Useful to save the scripts config and then load the 
    #               sved .rxf file in the IxLoad gui to verify the 
    #               script's configurations.
    #        
    #               The saved configuration is stored at the $resultDirectory

    if {$rxfFileName != ""} {
	puts "\nIxL_RunTest: $testControllerObj : Saving configuration as $rxfFileName"
	$testControllerObj run $testObj -autorepository $rxfFileName
    } else {
	$testControllerObj run $testObj
    }
}

proc IxL_StopStatCollector { trafficStatName } {
    puts "\nIxL_StopStatCollector: $trafficStatName"
    ${trafficStatName}::StopCollector
}

proc IxL_ReleaseConfigWaitFinish { testControllerObj } {
    $testControllerObj releaseConfigWaitFinish
}

proc IxL_GetCsvStatFiles { statList fromWindowsDir } {
    foreach statFile $statList {
	set localStatFile ixLoad_[string map {" " ""} [string map {- _} $statFile]]
	puts "IxL_GetCsvStatFiles:  $statFile ..."
	catch {::IxLoad retrieveFileCopy $resultDirectoryOnWindows\\$statFile $localStatFile} errMsg
	if {$errMsg != ""} {
	    puts "\nError: Copying csv stat file from Windows PC: $statFile\n"
	}
    }
}

proc IxL_StartTest { args } {
    set argIndex 0
    while {$argIndex < [llength $args]} {
	set currentArg [lindex $args $argIndex]
	switch -exact -- $currentArg { 
	    -testControllerObj {
		set testControllerObj [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -testObj {
		set testObj [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -saveConfigFileName {
		set saveConfigFileName [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    default {
		puts "\nIxL_StartTest Error: No such parameter: $currentArg"
		return 1
	    }
	}
    }

    if {[info exists saveConfigFileName]} {
	puts "\nIxL_StartTest: Saving configuration to filename: $saveConfigFileName ...\n"
	eval $testControllerObj run $testObj -autorepository $saveConfigFileName
    } else {
	puts "\nIxL_StartTest ...\n"
	eval $testControllerObj run $testObj
    }
}

proc IxL_StopTest { testControllerObj } {
    puts "\nIxL_StopTest ...\n"
    $testControllerObj stopRun
}

proc IxL_EnterKeyToAbortTest {} {
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

proc IxL_CopyFileFromWindows {sourcePathAndFile localPath} {
    # sourcePathAndFile: c:\\Results\\fileToget.csv
    puts "\nIxL_CopyFileFromWindows: $sourcePathAndFile -> $localPath"
    catch {::IxLoad retrieveFileCopy $sourcePathAndFile $localPath} errMsg
}

proc IxL_ConvertScriptToRxf { testObject chassisChain rxfName } {
    # Create a .rxf file out of a TCL script.        
    #                                                                
    # If you want to just create the .rxf file without running traffic, do
    # a word search in your script for "testController run" and comment out
    # the following lines in your script: 
    #    $testController run $Test1
    #    vwait ::ixTestControllerMonitor
    #    puts $::ixTestControllerMonitor
    #    $testController releaseConfig
    #    vwait ::ixTestControllerMonitor
    #    puts $::ixTestControllerMonitor
    # 
    # Parameters:
    #    testObject = $Test1
    #    chassisChain = $chassisChain   
    #    rxfName = Path + file name
    # 
    # Example on the conversion:
    #   Example: $repository write -destination {"c:\\Results\\convertedScriptgen.rxf"} -overwrite 1

    puts "\nConverting scriptgen to .rxf ..."
    set repository [::IxLoad new ixRepository]
    $repository testList.appendItem -object $testObject
    $repository config -activeTest [$testObject cget -name] -chassisChain $chassisChain
    $repository write -destination $rxfName -overwrite 1
}

proc IxVmConnectToVChassisIp { vChassisIp } {
    # In order to add, modify or view vChassis and vLM, must 
    # create a chassis builder object handle and connect to the vChassis IP.

    set chassisBuilder [::IxLoad new ixChassisBuilder]
    $chassisBuilder connectToChassis -chassisName $vChassisIp
    return $chassisBuilder
}

proc IxVmGetLicenseServer { chassisBuilder } {
    # Get the current license server IP on the vChassis controller
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp
    set chassisSettings [$chassisBuilder getChassisSettings]
    return [$chassisSettings cget -LicenseServer]
}

proc IxVmGetEnableLicenseCheck { chassisBuilder } {
    # Returns the value of EnableLicenseCheck on the vChassis controller.

    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp
    #
    # Returns 0 if disabled.
    # Returns 1 if enabled.

    set chassisSettings [$chassisBuilder getChassisSettings]
    return [$chassisSettings cget -EnableLicenseCheck]
}

proc IxVmGetNtpServer { chassisBuilder } {
    # Returns the value of NTP Server on the vChassis controller.

    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp
    #
    set chassisSettings [$chassisBuilder getChassisSettings]
    return [$chassisSettings cget -NtpServer]
}

proc IxVmGetTxDelay { chassisBuilder } {
    # Returns the value of TxDelay on the vChassis controller.

    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp
    #
    set chassisSettings [$chassisBuilder getChassisSettings]
    return [$chassisSettings cget -TxDelay]
}

proc IxVmSetLicenseServer { chassisBuilder licenseServerIp } {
    # This API will set the license server IP address on the vChassis controller
    # and verifies the setting.
    #
    # Return 0 if success
    # Return 1 if failed
    #
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp

    puts "IxVmSetLicenseServer: Configure license server to $licenseServerIp"
    set chassisSettings [$chassisBuilder getChassisSettings]
    $chassisSettings cset -LicenseServer $licenseServerIp

    # When done with chassis settings, make them permanent:
    if {[catch {$chassisBuilder setChassisSettings -chassisSettings $chassisSettings} errMsg]} {
	puts "\nIxVmSetLicenseCheck failed: $errMsg"
	return 1
    }

    set currentLicenseServer [$chassisSettings cget -LicenseServer]
    if {$currentLicenseServer == $licenseServerIp} {
	puts "IxVmSetLicenseServer: Successfully set license server."
	return 0
    } else {
	puts "IxVmSetLicenseServer: Failed to set license server on vChassis"
	return 1
    }
}

proc IxVmSetLicenseCheck { chassisBuilder {enable 1} } {
    # This API will enable or disable license checking on the vChassis controller
    # and verifies the setting.
    #
    # Return 0 if success
    # Return 1 if failed
    #
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp

    puts "IxVmSetLicenseServer: Configure license check to: $enable"
    set chassisSettings [$chassisBuilder getChassisSettings]
    $chassisSettings cset -EnableLicenseCheck $enable

    # When done with chassis settings, make them permanent:
    if {[catch {$chassisBuilder setChassisSettings -chassisSettings $chassisSettings} errMsg]} {
	puts "\nIxVmSetLicenseCheck failed: $errMsg"
	return 1
    } 

    set currentLicenseCheck [$chassisSettings cget -EnableLicenseCheck]

    if {$currentLicenseCheck == $enable} {
	puts "IxVmSetLicenseServer: Successfully set license check to: $enable."
	return 0
    } else {
	puts "IxVmSetLicenseServer: Failed to set license check on vChassis to: $enable"
	return 1
    }
}

proc IxVmSetNtpServer { chassisBuilder ntpServerIp } {
    # This API will set the NTP server IP address on the vChassis controller
    # and verifies the setting.
    #
    # Return 0 if success
    # Return 1 if failed
    #
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp

    puts "IxVmSetNtpServer: Configure NTP server to $ntpServerIp"
    set chassisSettings [$chassisBuilder getChassisSettings]
    $chassisSettings cset -NtpServer $ntpServerIp

    # When done with chassis settings, make them permanent:
    if {[catch {$chassisBuilder setChassisSettings -chassisSettings $chassisSettings} errMsg]} {
	puts "\nIxVmSetNtpServer failed: $errMsg"
	return 1
    }

    set currentNtpServer [$chassisSettings cget -NtpServer]
    if {$currentNtpServer == $ntpServerIp} {
	puts "IxVmSetNtpServer: Successfully set ntp server to $ntpServerIp."
	return 0
    } else {
	puts "IxVmSetNtpServer: Failed to set NTP server $ntpServerIp on vChassis."
	return 1
    }
}

proc IxVmSetTxDelay { chassisBuilder txDelay } {
    # This API will set the Tx Delay on the vChassis controller
    # and verifies the setting.
    #
    # Return 0 if success
    # Return 1 if failed
    #
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp

    puts "IxVmSetTxDelay: Configure Tx Delay to $txDelay"
    set chassisSettings [$chassisBuilder getChassisSettings]
    $chassisSettings cset -TxDelay $txDelay

    # When done with chassis settings, make them permanent:
    if {[catch {$chassisBuilder setChassisSettings -chassisSettings $chassisSettings} errMsg]} {
	puts "\nIxVmSetTxDelay failed: $errMsg"
	return 1
    }

    set currentTxDelay [$chassisSettings cget -TxDelay]
    if {$currentTxDelay == $txDelay} {
	puts "IxVmSetTxDelay: Successfully set Tx Delay to $txDelay."
	return 0
    } else {
	puts "IxVmSetTxDelay: Failed to set Tx Delay $txDelay on vChassis."
	return 1
    }
}

proc IxVmAddCardPort { chassisBuilder cardIp int speed mtu promiscuousMode } {
    # This API assumes that you have successfully:
    #    - Installed vChassis and virtual load modules.
    #    - Configured vChassis mgmt IP address.
    #    - Configured all vLM mgmt IP addresses.
    #
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp
    #
    # Example:
    #    IxVmAddCardPort $chassisBuilder 192.168.70.130 eth1 1000 1500 False
    #    IxVmAddCardPort $chassisBuilder 192.168.70.131 eth1 1000 1500 False

    $chassisBuilder addCard -managementIp $cardIp -keepAliveTimeout 300
    set cardId [$chassisBuilder getIxVMCardByIP -managementIp $cardIp]

    puts "Adding port to CardId: $cardId"
    $chassisBuilder addPort -cardId $cardId -portId 1 -interfaceName $int \
	-promiscuousMode $promiscuousMode -lineSpeed $speed -mtu $mtu

    $chassisBuilder connectCard -cardId $cardId    
}

proc IxVmDisconnectCardId { chassisBuilder cardId } {
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp
    puts "IxVmDisconnectCardId: $cardId"
    $chassisBuilder disconnectCard -cardId $cardId
}

proc IxVmConnectToDisconnectCardId { chassisBuilder cardId } {
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp
    puts "IxVmDisconnectCardId: $cardId"
    $chassisBuilder connectCard -cardId $cardId
}

proc IxVmRebootCardIds { chassisBuilder cardIdList } {
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp
    puts "IxVmRebootCardIds: $cardIdList"
    $chassisBuilder hwRebootCardByIDs [list $cardIdList]
}

proc IxVmRebootChassis { chassisBuilder } {
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp
    puts "IxVmRebootChassis"
    $chassisBuilder hardChassisReboot
}

proc IxVmClearOwnership { chassisBuilder cardId } {
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp
    puts "IxVmClearOwnership: cardId $cardId"
    $chassisBuilder clearOwnership -cardId $cardId
}

proc IxVmRemoveCardId { chassisBuilder cardId } {
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp
    puts "IxVmRemoveCardId: $cardId"
    $chassisBuilder deleteCard -cardId $cardId
}

proc IxVmRemovePortId { chassisBuilder cardId portId } {
    # To use this API, you must create a chassisBuilder object and pass it in:
    #     set chassisBuilder [::IxLoad new ixChassisBuilder]
    #     $chassisBuilder connectToChassis -chassisName $vChassisIp
    puts "IxVmRemovePortId: $cardId/$portId"
    $chassisBuilder removePortById -cardId $cardId -portId $portId
}

proc IxVmRemoveAllCardIds { {vChassisIp None} {chassisBuilderObj None}  } {
    # This API will discover the total amount of IxVM cards created and delete them.
    # 
    # Optional Parameters:
    #    chassisBuilderObj: The chassis builder object. If none is provided, a 
    #                       chassisBuilder object will be instantiated.
    #    ixChassisIp:       The virtual chassis IP address.  This is only required 
    #                       if the chassisBuilderObj is provided.
    #
    # Requirements:
    #    Prior to calling this API, you must have called ::IxLoad conenct $ixLoadServer

    if {$chassisBuilderObj == "None"} {
	if {$vChassisIp == "None"} {
	    puts "\nError: Please provide your virtual chassis IP address"
	    return 1
	}
	puts "IxVmRemoveAllCardIds: Creating ixChassisBuilder object"
	set chassisBuilderObj [::IxLoad new ixChassisBuilder]
	puts "IxVmRemoveAllCardIds: Connecting to vChassis $vChassisIp" 
	$chassisBuilderObj connectToChassis -chassisName $vChassisIp
    }

    puts "IxVmRemoveAllCardId: Starting getChassisTopology API"
    set topologies [$chassisBuilderObj getChassisTopology]
    set count      [$topologies indexCount]
    puts "Total card IDs discovered: $count"
    
    if {$count != 0} {
	for {set index 0} {$index < $count} {incr index} {
	    set topology     [$topologies getItem $index]
	    puts "topology: $topology"
	    set CardServerId     [$topology cget -CardServerId]
	    puts "Removing cardServerId: $CardServerId"
	    $chassisBuilderObj deleteCard -cardId $CardServerId
	}
    }
}

