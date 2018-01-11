#
# Setup script for simple*.tcl tests.
#
# This file is sourced by all IxLoad sample tcl test scripts,
# and provides a convenient central place to change the
# chassis, port, and card that the tests will run on.
#

#
# Set up paths to IxLoad tcl code relative to sample directory.
# (ignored for non-windows machines)
#
source ../setup_ixload_paths.tcl

#
# Define the main IxLoad command
#
package require IxLoad

# IxLoad's reservered namespace
# Users should also avoid names beginning with Ix or ix.
namespace eval ::IxLoadPrivate {}

# A namespace for settings defined in this file  
# and used by all simple*.tcl example scripts.
namespace eval ::IxLoadPrivate::SimpleSettings {}

# set remoteServer to IP address of IxLoad client machine running
# the remoteScriptingService script or daemon. The value is ignored
# when running a script locally on a 
variable ::IxLoadPrivate::SimpleSettings::remoteServer 192.168.4.137

# both clientPort and serverPort are assumed to be on a single chassis
variable ::IxLoadPrivate::SimpleSettings::chassisName 400-amit

array set ::IxLoadPrivate::SimpleSettings::clientPort {
    CARD_ID     "3"
    PORT_ID     "1"
}

array set ::IxLoadPrivate::SimpleSettings::serverPort {
    CARD_ID     "3"
    PORT_ID     "2"
}

# most tests require 2 ports, but some can use up to 6
# Change numPorts to run tests that require more
set ::IxLoadPrivate::SimpleSettings::numPorts 2

array set ::IxLoadPrivate::SimpleSettings::port3 {
    CARD_ID     "2"
    PORT_ID     "7"
}

array set ::IxLoadPrivate::SimpleSettings::port4 {
    CARD_ID     "2"
    PORT_ID     "8"
}

array set ::IxLoadPrivate::SimpleSettings::port5 {
    CARD_ID     "2"
    PORT_ID     "2"
}

array set ::IxLoadPrivate::SimpleSettings::port6 {
    CARD_ID     "2"
    PORT_ID     "3"
}






