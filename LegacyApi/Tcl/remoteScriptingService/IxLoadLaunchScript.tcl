#
#   remote scripting service
#
#   this script is run as a windows service to handle scripts running on remote machines
#

# Set up paths
package require registry
if { [ catch {
    set ::_IXLOAD_INSTALL_ROOT [registry get {HKEY_LOCAL_MACHINE\Software\Ixia Communications\IxLoad\8.01.99.14\InstallInfo} HOMEDIR] } result ]
} then {
    exit "IxLoad not installed on server $result"
}

if { [ catch {
    set ::_TCL_INSTALL_ROOT [registry get {HKEY_LOCAL_MACHINE\Software\Ixia Communications\Tcl\8.5.17.0\InstallInfo} HOMEDIR] } result ]
} then {
    exit "TCL not installed on server $result"
}

proc IxLoadLaunchScript {ipaddr port pkgName} {
    # find a log file to use
    set systemDrive [lindex [file split [pwd]] 0]
    for {set i 0} { 1 } { incr i } {
        set logFileName "$systemDrive/rss${i}.log"
        if { [catch { set logFile [open $logFileName "w"] } result] == 0 } {
            close $logFile
            break
        }
        if {$i >= 100} {
            error "Unable to open rss log file on ixLoad connect destination system"
        }
    }

    if {$pkgName == "IxLoad"} {
        set ::_IXLOAD_TCL_PATH [file join $::_TCL_INSTALL_ROOT bin tclsh.exe]
        set ::_IXLOAD_REMOTE_SCRIPTING_SERVICE_DIR [file join $::_IXLOAD_INSTALL_ROOT TclScripts remoteScriptingService ]
        # global variable used in IxLoadRemoteScript to determine how to terminate and what to load. Possible values: IxLoad/IxLoadCsv
        set ::packageName "IxLoad"
        cd $::_IXLOAD_REMOTE_SCRIPTING_SERVICE_DIR
        exec $::_IXLOAD_TCL_PATH IxLoadRemoteScript.tcl $ipaddr $port >& $logFileName &
    }
    
    if {$pkgName == "IxLoadCsv"} {
        #set TCL_LIBRARY path for TickleSharp init
        set ::env(TCL_LIBRARY) "$::_TCL_INSTALL_ROOT\\lib\\tcl8.5"
	    if { [catch {exec [file join $::_IXLOAD_INSTALL_ROOT IxLoad.exe] -tclip $ipaddr -tclport $port -visibility False >& $logFileName &} result] } {
            error "Failed to launch IxLoad: $result"
        }
    }
}



