#
#   remote scripting service
#
#   this script is run as a windows service to handle scripts running on remote machines
#

#! /usr/local/bin/tclsh
if { $::argc != 2 } \
{
    error "IxLoadRemoteScript must be called with 2 parameters (ipaddr port)"
} \
else \
{
    set ipaddr [lindex $::argv 0]
    set port [lindex $::argv 1]
}
set ::isGUIStarted 0
if { [info exists packageName] && $packageName == "IxLoadCsv"} {
    set ::isGUIStarted 1
    set ::done 0

}

catch {
    
# Set up paths

set ::_IXLOAD_VERSION 8.01.99.14

if {[string first "." $::_IXLOAD_VERSION] == -1} {
    # if no '.' found in _IXLOAD_VERSION, then we are running from 
    # the dev environment. Set IXLOAD_TCLAPI_REV from env or default
    # to something obviously wrong.
    if {[info exists ::env(IXLOAD_TCLAPI_REV)]} {
        # use dummy development version
        set ::_IXLOAD_VERSION $::env(IXLOAD_TCLAPI_REV)
    } else {
	error "IxLoad Version not defined. Set IXLOAD_TCLAPI_REV environment var to required version."
    }
}

package require registry 1
set ::_TCL_INSTALL_ROOT [registry get {HKEY_LOCAL_MACHINE\Software\Ixia Communications\Tcl\8.5.17.0\InstallInfo} HOMEDIR]
set ::_IXLOAD_INSTALL_ROOT [registry get "HKEY_LOCAL_MACHINE\\Software\\Ixia Communications\\IxLoad\\$::_IXLOAD_VERSION\\InstallInfo" HOMEDIR]
set ::_IXLOAD_PKG_DIR [file join $::_IXLOAD_INSTALL_ROOT TclScripts lib IxLoad]
lappend ::auto_path $::_IXLOAD_PKG_DIR

lappend ::auto_path [file join $::_TCL_INSTALL_ROOT lib/tcl8.5]
lappend ::auto_path [file join $::_TCL_INSTALL_ROOT lib]
lappend ::auto_path [file join $::_TCL_INSTALL_ROOT lib/tcllib1.9]
lappend ::auto_path [file join $::_IXLOAD_INSTALL_ROOT TclSCripts/lib/comm]
package require -exact comm 4.2.1
#
#   Load up IxLoad packages
#
puts "Loading IxLoad"
package require IxLoad
puts "Loading statCollectorUtils"
package require statCollectorUtils

namespace eval ::IxLoadPrivate {
    variable currentClient -1
}

set ::log [teepee new ixLogger "remoteScriptingService" 1]
set ::tc [teepee new ixTestController]

#################################################################################################
#
# redefine ::IxLoad eval to execute its command and args remotely. This causes
# the test controller tcl callback and stat callbacks to be executed remotely.
#
#################################################################################################

puts "Hooking IxLoad"

# old IxLoad command. We don't check before we wedge because this is a script and not a package.
rename ::IxLoad ::IxLoadPrivate::IxLoadPrior

# see Client/tclext/teepee/stage/pkgIndex.tcl for the original definition (syntax is preserved)
proc ::IxLoad {cmd args} {
    switch $cmd {
        eval {
            if { $::IxLoadPrivate::currentClient == -1} {
                # evaluate locally in case there are side affects required by the test controller
                error "RemoteScriptingHost: Remote client not connected. Cannot remotely evaluate command: $cmd $args"
            } else {
                puts "Remotely evaluating: $args"
                return [::comm::comm send $::IxLoadPrivate::currentClient [lindex $args 0]]
            }
        }
        unhexAndSendFile {
            if { [llength $args]!=2} {
                error "Usage: ::IxLoad sendFile contents"
            }
            set fileName [lindex $args 0]
            # Retrieve original fileName - un-hex
            set fileName [binary format H* $fileName]
            set contents [lindex $args 1]
            # Retrieve original data - un-hex
            set contents [binary format H* $contents]
            set fileId [open $fileName w]
            fconfigure $fileId -translation binary
            puts -nonewline $fileId $contents
            close $fileId
            return
        }
        default {
            ::IxLoadPrivate::IxLoadPrior $cmd $args
        }
    }
}

puts "Installing lost connection hook"

# handle connection lost (end of session)
::comm::comm hook lost {
    puts "Connection to $::IxLoadPrivate::currentClient closed"
    if { !$::isGUIStarted} {
        ::comm::comm destroy
        # make aborting a remote unix behave the same as aborting a local script
        # just terminate the process without attempting a cleanup
        exit
    } else {
        global ::done
        set ::done 1
        ::comm::comm destroy
    }
}

#puts "Installing eval hook"
#
# evaluate commands in slave intepreter
#::comm::comm hook eval {
#    return [uplevel #0 [lindex $buffer 0]]
#}
#
#    connect to originating client Unix session
#
::comm::comm configure -local 0
set ::IxLoadPrivate::currentClient "$port $ipaddr"
puts "connecting to $::IxLoadPrivate::currentClient"
set mySock [::comm::comm connect $::IxLoadPrivate::currentClient]
puts "connected"
set myPort [::comm::comm configure -port]
set myChannel "$myPort [lindex [fconfigure $mySock -sockname] 0]"
set remoteCommand [format "set ::IxLoadPrivate::ChannelId {%s}" $myChannel]
::comm::comm send  $::IxLoadPrivate::currentClient $remoteCommand
if { !$::isGUIStarted} {
    vwait ::done
    puts "Cleaning up session"
    puts "Shutting down test controller"
    if { [catch {$tc shutDown} shutDownResult] } {
        $::log debug $shutDownResult
    }
}
proc checkDone {} {
    after 50 set timeout 1
    vwait timeout
    #puts "Are we done? $::done"
    return $::done

}

} result

puts "Result = $result"
puts "Done"
if {$::isGUIStarted && $result!=""} {
    set ::done 1
}

# This shouldn't be necessary, but somehow it keeps TCL Server happy
# Without it, we would sometimes get a pop-up claiming that we'd crashed
if { !$::isGUIStarted} {
    exit
}