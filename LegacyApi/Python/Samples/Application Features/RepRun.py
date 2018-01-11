#
# A simple script to run all the tests in a repository.
#

from IxLoad import IxLoad, StatCollectorUtils
from setup_simple import *
import sys

if len(sys.argv) == 2:
    repositoryName = sys.argv[1]
else:
    repositoryName = raw_input("Enter full path of rxf file to run: ")

print "Running all tests in repository %s" % repositoryName

#
# setup path and load IxLoad package
#

#
# Initialize IxLoad
#

IxLoad = IxLoad()

# IxLoad connect should always be called, even for local scripts
IxLoad.connect(remoteServer)

# once we've connected, make sure we disconnect, even if there's a problem
try:

    #
    # setup logger
    #
    logtag = "IxLoad-api"
    logName = "reprun"
    logger  = IxLoad.new("ixLogger", logtag, 1)
    logEngine = logger.getEngine()
    logEngine.setLevels(IxLoad.ixLogger.kLevelDebug, IxLoad.ixLogger.kLevelInfo)
    logEngine.setFile(logName, 2, 256, 1)

    #-----------------------------------------------------------------------
    # Create a test controller bound to the previosuly allocated
    # chassis chain. This will eventually run the test we created earlier.
    #-----------------------------------------------------------------------
    testController=IxLoad.new("ixTestController",
                              outputDir=1)
    testController.setResultDir("RESULTS/%s" % logName)

    #
    # Load the repository
    #
    repository = IxLoad.new("ixRepository", 
                            name = repositoryName)

    #
    # Loop through the tests, running them
    #
    numTests = int(repository.testList.indexCount())
    for testNo in range(0, numTests):

        testName = repository.testList[testNo].cget("name")

        test = repository.testList.getItem(testName)

        # Start the test
        testController.run(test)

        IxLoad.waitForTestFinish()


    #-----------------------------------------------------------------------
    # Cleanup
    #-----------------------------------------------------------------------

    testController.releaseConfigWaitFinish()

    IxLoad.delete(repository)
    IxLoad.delete(testController)
    IxLoad.delete(logger)
    IxLoad.delete(logEngine)

except Exception, e:
    print str(e)

#-----------------------------------------------------------------------
# Disconnect
#-----------------------------------------------------------------------

IxLoad.disconnect()













