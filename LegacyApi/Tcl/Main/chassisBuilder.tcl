#!/bin/tclsh

# APIs by: Hubert Gee

# All the APIs to creating/removing/modifying IxVM chassis builder.
# Below all the APIs are callables examples.

package req IxLoadCsv

set ixChassisIp 192.168.70.10
set ixLoadTclServer 192.168.70.127

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

# Connect to IxLoad Server
::IxLoad connect $ixLoadTclServer

# Connect to IxVM vChassis IP
set chassisBuilder [IxVmConnectToVChassisIp $ixChassisIp]

#---------------------------------------------------
# To view/modify vChassis settings
# Options: LicenseServer, EnableLicenseCheck, NtpServer, TxDelay

if 0 {
puts "license server: [IxVmGetLicenseServer $chassisBuilder]"
IxVmSetLicenseServer $chassisBuilder 192.168.70.127

puts "enable license check: [IxVmGetEnableLicenseCheck $chassisBuilder]"
IxVmSetLicenseCheck $chassisBuilder 1

puts "NTP server: [IxVmGetNtpServer $chassisBuilder]"
IxVmSetNtpServer $chassisBuilder $ixChassisIp

puts "txDelay: [IxVmGetTxDelay $chassisBuilder]"
IxVmSetTxDelay $chassisBuilder 1
}

#---------------------------------------------------

# Getting chassis topology

# getItem:0
#currentLicenseServer: 192.168.70.127
#count: 2
#cardServerId: 1
#interfaceName: eth1
#ipAddress: 192.168.70.130
#portServerId: 1
#promiscuousMode: 0

# getItem:1
#currentLicenseServer: 192.168.70.127
#count: 2
#cardServerId: 2
#interfaceName: eth1
#ipAddress: 192.168.70.131
#portServerId: 1
#promiscuousMode: 0

# Get what is already created
if 0 {
set topologies [$chassisBuilder getChassisTopology]
set count [$topologies indexCount]
set topology [$topologies getItem 1]
set cardServerId [$topology cget -CardServerId]
puts "cardServerId: $cardServerId"
set interfaceName [$topology cget -InterfaceName]
puts "interfaceName: $interfaceName"
set ipAddress [$topology cget -IPAddress]
puts "ipAddress: $ipAddress"
set portServerId [$topology cget -PortServerId]
puts "portServerId: $portServerId"
set promiscuousMode [$topology cget -PromiscMode]
puts "promiscuousMode: $promiscuousMode"

#-----------------------------------------------------
# Discover Virtual Machines

#Discovered: 2 virtual machines
#applianceName: port1
#interface: ::tp::_Obja ::tp::_Objb
#managementIp: 192.168.70.130
#type: VMware
#interfaceNumber: 2

set discoveredVirtualMachines [$chassisBuilder getDiscoveredMachines]
set count [$discoveredVirtualMachines indexCount]
puts "Discovered: $count virtual machines"
set vm1Obj [$discoveredVirtualMachines getItem 0]

set applianceName [$vm1Obj cget -ApplianceName]
puts "applianceName: $applianceName"
set interface [$vm1Obj cget -Interfaces]
puts "interface: $interface"
set managementIp [$vm1Obj cget -ManagementIp]
puts "managementIp: $managementIp"
set type [$vm1Obj cget -Type]
puts "type: $type"
set interfaceNumber [$vm1Obj cget -InterfaceNumber]
puts "interfaceNumber: $interfaceNumber"
}

#----------------------------------------------------
# Add a card and a port example

#IxVmAddCardPort $chassisBuilder 192.168.70.130 eth1 1000 1500 False
#IxVmAddCardPort $chassisBuilder 192.168.70.131 eth1 1000 1500 False

#----------------------------------------------------

IxVmRemoveAllCardIds $ixChassisIp
#IxVmRemoveCardId $chassisBuilder 2
#IxVmRemovePortId $chassisBuilder 2 1
#$chassisBuilder rediscoverAppliances

::IxLoad disconnect
