#
# Setup script for Perl sample tests.
#
# This file is imported by all IxLoad sample Perl test scripts,
# and provides a convenient central place to change the
# chassis, port, and card that the tests will run on.
#
# Users should also avoid names beginning with Ix or ix.
#

package setup_simple;

use warnings;
use strict;
use base qw(Exporter);

our @EXPORT = qw(remoteServer chassisName clientPort1 serverPort1);



# set remoteServer to IP address of IxLoad client machine running
# the remoteScriptingService script or daemon. The value is ignored
# when running a script locally on a 

use constant remoteServer => '1.2.3.4';

# set chassis and ports
# both clientPort and serverPort are assumed to be on a single chassis

use constant chassisName => '400-amit';
use constant clientPort1 => '1.7.1';
use constant serverPort1 => '1.7.2';

1

