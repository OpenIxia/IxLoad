#
# Setup script for python sample tests.
#
# This file is imported by all IxLoad sample python test scripts,
# and provides a convenient central place to change the
# chassis, port, and card that the tests will run on.
#
# Users should also avoid names beginning with Ix or ix.
#


# set remoteServer to IP address of IxLoad client machine running
# the remoteScriptingService script or daemon. The value is ignored
# when running a script locally on a 
remoteServer = "1.2.3.4"

# set chassis and ports
# both clientPort and serverPort are assumed to be on a single chassis
chassisName  = "400-amit"
clientPort1   = "1.7.1"
serverPort1   = "1.7.2"
clientPort2   = "1.7.3"
serverPort2   = "1.7.4"


