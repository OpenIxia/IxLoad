use strict;
use warnings;

use lib '..';
use lib '../lib';
use lib '../../lib';
use setup_simple;
use IxLoad;

my $numArgs = $#ARGV + 1;
my $repositoryName;

if ($numArgs==1) {
    $repositoryName = $ARGV[0];
}
else {
    print "Enter full path of rxf file to run:";
    $repositoryName=<STDIN>;
    chomp($repositoryName);
}

print "Running all tests in repository $repositoryName\n";

#
# setup path and load IxLoad package
#

#
# Initialize IxLoad
#

# IxLoad connect should always be called, even for local scripts
IxLoadConnect->connect(remoteServer);

# once we've connected, make sure we disconnect, even if there's a problem
eval {

    #
    # setup logger
    #
    my $logtag = "IxLoad-api";
    my $logName = "reprun";
    my $logger = IxLoad->new('ixLogger', $logtag, 1);
    my $logEngine = $logger->getEngine();
    $logEngine->setLevels($IxLoad::Info::ixLogger{kLevelDebug}, $IxLoad::Info::ixLogger{kLevelInfo});
    $logEngine->setFile($logName,2,256,1);

    #-----------------------------------------------------------------------
    # Create a test controller bound to the previosuly allocated
    # chassis chain. This will eventually run the test we created earlier.
    #-----------------------------------------------------------------------
    my $testController = IxLoad->new("ixTestController", {
            outputDir => 1
        });

    $testController->setResultDir("RESULTS//$logName");
    
    #
    # Load the repository
    #
    my $repository = IxLoad->new("ixRepository", {
            name => $repositoryName
        });

    #
    # Loop through the tests, running them
    #

    my $numTests = $repository->testList->indexCount();
    for my $testNo (0 .. $numTests-1) {
        
        my $testName = $repository->testList->getItem($testNo)->cget("name");
        my $test = $repository->testList->getItem($testName);

        # Start the test
        eval {
            $testController->run($test);

            my $wait_result = IxLoad::TestControllerWait();
            print $wait_result."\n";
        };
    }

    #-----------------------------------------------------------------------
    # Cleanup
    #-----------------------------------------------------------------------

    $testController->releaseConfigWaitFinish(); 

    IxLoad->delete($repository);
    IxLoad->delete($testController);
    IxLoad->delete($logger);
    IxLoad->delete($logEngine);
};
if ($@) {
    print "Error: $@\n";}

#-----------------------------------------------------------------------
# Disconnect
#-----------------------------------------------------------------------

IxLoad->disconnect();
exit(0);