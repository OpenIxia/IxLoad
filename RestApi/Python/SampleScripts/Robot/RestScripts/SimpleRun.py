import Utils.IxLoadUtils as IxLoadUtils
import Utils.IxRestUtils as IxRestUtils
import inspect
import os

####TEST CONFIG

kGatewayServer = "127.0.0.1"
kGatewayPort = 8443  # TODO - to be changed by user depending on whether HTTP redirect is used or not
# TODO - to be changed by user in order to use HTTP requests instead of HTTPS requests (the HTTP requests will be redirected as HTTPS requests)
kHttpRedirect = False
kIxLoadVersion = "8.40.0.168"  # TODO - to be changed by user
kRxfPath = r"C:\\Path\\to\\config.rxf"  # TODO - to be changed by user
kGatewaySharedFolder = 'C:\\ProgramData\\Ixia\\IxLoadGateway'  # TODO - to be changed by user depending on the gateway OS
kRxfRelativeUploadPath = 'uploads/%s' % os.path.split(kRxfPath)[1]  # TODO - to be changed by user
kRxfAbsoluteUploadPath = os.path.join(kGatewaySharedFolder, kRxfRelativeUploadPath)
kChassisList = ['chassisIpOrHostName']  # TODO - to be changed by user
kApiKey = '' # TODO - to be changed by user

kPortListPerCommunityCommunity =    {
                                        #  format: { community name : [ port list ] }
                                        "Traffic1@Network1" : [(1,2,7), (1,2,12)],
                                        "Traffic2@Network2" : [(1,2,9), (1,2,10)]
                                    }

kStatsToDisplayDict =   {
                            #format: { statSource : [stat name list] }
                            "HTTPClient": ["HTTP Simulated Users", "HTTP Concurrent Connections", "HTTP Requests Successful"],
                            "HTTPServer": ["HTTP Requests Received", "TCP Retries"]
                        }


def getRxfName():
    relativeFileNamePath = inspect.getfile(inspect.currentframe())
    fileName = os.path.split(relativeFileNamePath)[-1]
    fileNameWithoutExtension = fileName.split('.')[0]
    rxfName = "%s.rxf" % (fileNameWithoutExtension)

    rxfDirPath = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))

    return os.path.join(rxfDirPath, rxfName)
################


#create a connection to the gateway
connection = IxRestUtils.getConnection(kGatewayServer, kGatewayPort, httpRedirect=kHttpRedirect)
connection.setApiKey(kApiKey)

sessionUrl = None
#create a session
try:
    IxLoadUtils.log("Creating a new session...")
    sessionUrl = IxLoadUtils.createSession(connection, kIxLoadVersion)
    IxLoadUtils.log("Session created.")

    # upload file to gateway server
    IxLoadUtils.log('Uploading file %s...' % kRxfPath)
    kResourcesUrl = IxLoadUtils.getResourcesUrl(connection)
    IxLoadUtils.uploadFile(connection, kResourcesUrl, kRxfPath, kRxfRelativeUploadPath)
    IxLoadUtils.log('Upload file finished.')

    # load a repository
    IxLoadUtils.log("Loading repository %s..." % kRxfAbsoluteUploadPath)
    IxLoadUtils.loadRepository(connection, sessionUrl, kRxfAbsoluteUploadPath)
    IxLoadUtils.log("Repository loaded.")

    IxLoadUtils.log("Clearing chassis list...")
    IxLoadUtils.clearChassisList(connection, sessionUrl)
    IxLoadUtils.log("Chassis list cleared.")

    IxLoadUtils.log("Adding chassis %s..." % (kChassisList))
    IxLoadUtils.addChassisList(connection, sessionUrl, kChassisList)
    IxLoadUtils.log("Chassis added.")

    IxLoadUtils.log("Assigning new ports...")
    IxLoadUtils.assignPorts(connection, sessionUrl, kPortListPerCommunityCommunity)
    IxLoadUtils.log("Ports assigned.")

    IxLoadUtils.log("Saving repository %s..." % (getRxfName()))
    IxLoadUtils.saveRxf(connection, sessionUrl, getRxfName())
    IxLoadUtils.log("Repository saved.")

    IxLoadUtils.log("Starting the test...")
    IxLoadUtils.runTest(connection, sessionUrl)
    IxLoadUtils.log("Test started.")

    IxLoadUtils.log("Polling values for stats %s..." % (kStatsToDisplayDict))
    IxLoadUtils.pollStats(connection, sessionUrl, kStatsToDisplayDict)

    IxLoadUtils.log("Test finished.")

    IxLoadUtils.log("Checking test status...")
    testRunError = IxLoadUtils.getTestRunError(connection, sessionUrl)
    if testRunError:
        IxLoadUtils.log("The test exited with the following error: %s" % testRunError)
    else:
        IxLoadUtils.log("The test completed successfully.")

    IxLoadUtils.log("Waiting for test to clean up and reach 'Unconfigured' state...")
    IxLoadUtils.waitForTestToReachUnconfiguredState(connection, sessionUrl)
    IxLoadUtils.log("Test is back in 'Unconfigured' state.")
finally:
    if sessionUrl is not None:
        IxLoadUtils.log("Closing IxLoad session...")
        IxLoadUtils.deleteSession(connection, sessionUrl)
        IxLoadUtils.log("IxLoad session closed.")
