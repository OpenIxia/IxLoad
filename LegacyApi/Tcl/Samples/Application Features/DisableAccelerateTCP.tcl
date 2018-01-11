
if {$::argc == 2} {
    set repositoryName [lindex $::argv 0]
    set newRepositoryName [lindex $::argv 1]
} else {
    puts "Enter the full path of rxf file to be loaded:"
    gets stdin repositoryName
    flush stdout
    puts "Enter the full path of the new rxf file:"
    gets stdin newRepositoryName
    flush stdout
}

source "../setup_simple.tcl"
package require IxLoad

::IxLoad connect $::IxLoadPrivate::SimpleSettings::remoteServer

if [catch {

# Setup logger
set logtag "IxLoad-api"
set logName "DisableAccelerateTCP"
set logger [::IxLoad new ixLogger $logtag 1]
set logEngine [$logger getEngine]
$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
$logEngine setFile $logName 2 256 1

set repository [::IxLoad new ixRepository -name $repositoryName]

set numTests [$repository testList.indexCount ]

for {set testNo 0} {$testNo < $numTests} {incr testNo} {

    set testName [$repository testList($testNo).cget -name]
    set test [$repository testList.getItem $testName]
    set numScenarios [$test scenarioList.indexCount ]
    
    for {set scenarioNo 0 } {$scenarioNo < $numScenarios} {incr scenarioNo} {
    
    	set scenario [$test scenarioList.getItem $scenarioNo ]
    	set numColumns [$scenario columnList.indexCount ]
    
    	for {set columnNo 0 } {$columnNo < $numColumns} {incr columnNo} {
 		
    	    set column [$scenario columnList.getItem $columnNo ]    		    		
    	    set numNetTraffics [$column elementList.indexCount ]
    		
            for {set netTrafficNo 0 } {$netTrafficNo < $numNetTraffics} {incr netTrafficNo} {
    		
    	        set netTraffic [$column elementList.getItem $netTrafficNo]
    		set elementType [$netTraffic cget -scenarioElementType]
    		
    		if { $elementType == $::ixScenarioElementType(kNetTraffic) || $elementType == $::ixScenarioElementType(kSubscriberNetTraffic) } {
    		    $netTraffic setTcpAccelerationAllowed $::ixAgent(kTcpAcceleration) false    			
    	        }
    	    }
    	}
    }
}
   
$repository write -destination $newRepositoryName -overwrite 1

::IxLoad delete $repository

}] {
puts $errorInfo
}
::IxLoad disconnect
    