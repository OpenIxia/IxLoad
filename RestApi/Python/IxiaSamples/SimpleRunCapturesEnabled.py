import Utils.IxLoadUtils as IxLoadUtils
import Utils.IxRestUtils as IxRestUtils
import Utils.IxLoadTestSettings as TestSettings
import inspect
import os


testSettings = TestSettings.IxLoadTestSettings()
# testSettings.gatewayServer = "machine_ip_address"     # TODO - to be changed by user if he wants to run remote
testSettings.ixLoadVersion = ""                         # TODO - to be changed by user, by default will run on the latest installed version
# testSettings.apiVersion = "v1"                        # TODO - to be changed by user, uncomment if you want to run on /api/v1
testSettings.httpRedirect = False                       # TODO - to be changed by user
kRxfPath = r"C:\\Path\\to\\config.rxf"                  # TODO - to be changed by user
diagsFile = "diags.zip"                                 # TODO - to be changed by user
gatewayDiagnosticsFile = "gatewaydiags.zip"             # TODO - to be changed by user

runOnDifferentSetup = False                             # TODO - to be changed by user
if runOnDifferentSetup:
    testSettings.chassisList = ["chassisIp"]            # TODO - to be changed by user
    testSettings.portListPerCommunity = {
                                         # format: { community name : [ port list ] }
                                        "Traffic1@Network1" : [(1,7,1)],
                                        "Traffic2@Network2" : [(1,7,5)]
                                        }

kCaptureFileRootPath = r"C:\\Path\\to\\Folder\\With\\Captures\\"    # TODO - to by changed by user, root directory for capture files
testSettings.analyzerTupleList = []                                 # TODO - to be changed by user, list of touples of community ids and port ids to apply Analyzer to
                                                                    # format -[(communityId, 'portId')]
                                                                    # [(0, '1.7.1'), (1, '1.7.5')]
location = inspect.getfile(inspect.currentframe())

gatewayDiagnosticsPath = '/'.join([os.path.dirname(kRxfPath), gatewayDiagnosticsFile])
diagsPath = '/'.join([os.path.dirname(kRxfPath), diagsFile])

kStatsToDisplayDict =   {
                            # format: { statSource : [stat name list] }
                            "DNSClient": ["DNS Total Queries Sent"],
                            "DNSServer": ["DNS Total Queries Received", "TCP Retries"]
                        }

# Create a connection to the gateway
connection = IxRestUtils.getConnection(testSettings.gatewayServer,
                                       testSettings.gatewayPort,
                                       httpRedirect=testSettings.httpRedirect,
                                       version=testSettings.apiVersion)
connection.setApiKey(testSettings.apiKey)

sessionUrl = None

try:
    # Create a session
    IxLoadUtils.log("Creating a new session...")
    sessionUrl = IxLoadUtils.createNewSession(connection, testSettings.ixLoadVersion)
    IxLoadUtils.log("Session created.")

    kRxfRelativeUploadPath = os.path.split(kRxfPath)[1]
    kRxfAbsoluteUploadPath = kRxfPath
    # Upload file to gateway server
    if not testSettings.isLocalHost():
        IxLoadUtils.log('Uploading file %s...' % kRxfPath)
        kResourcesUrl = IxLoadUtils.getResourcesUrl(connection)
        IxLoadUtils.uploadFile(connection, kResourcesUrl, kRxfPath, kRxfRelativeUploadPath)
        IxLoadUtils.log('Upload file finished.')
		kRxfAbsoluteUploadPath = '/'.join([IxLoadUtils.getSharedFolder(connection), kRxfRelativeUploadPath])

    # Load a repository
    IxLoadUtils.log("Loading repository %s..." % kRxfAbsoluteUploadPath)
    IxLoadUtils.loadRepository(connection, sessionUrl, kRxfAbsoluteUploadPath)
    IxLoadUtils.log("Repository loaded.")

    if runOnDifferentSetup:
        IxLoadUtils.log("Clearing chassis list...")
        IxLoadUtils.clearChassisList(connection, sessionUrl)
        IxLoadUtils.log("Chassis list cleared.")

        IxLoadUtils.log("Adding chassis %s..." % (testSettings.chassisList))
        IxLoadUtils.addChassisList(connection, sessionUrl, testSettings.chassisList)
        IxLoadUtils.log("Chassis added.")

        IxLoadUtils.log("Assigning new ports...")
        IxLoadUtils.assignPorts(connection, sessionUrl, testSettings.portListPerCommunity)
        IxLoadUtils.log("Ports assigned.")

        kRxfName = IxLoadUtils.getRxfName(connection, location).split(".")[0] + "-" + kRxfRelativeUploadPath
        IxLoadUtils.log("Saving repository %s..." % (kRxfName))
        IxLoadUtils.saveRxf(connection, sessionUrl, IxLoadUtils.getRxfName(connection, location))
        IxLoadUtils.log("Repository saved.")

    else:
        IxLoadUtils.log("Refresh all chassis...")
        IxLoadUtils.refreshAllChassis(connection, sessionUrl)
        IxLoadUtils.log("All chassis refreshed...")

    for analyzerTuple in testSettings.analyzerTupleList:
        IxLoadUtils.log("Applying analyzer to port [%s]..." % analyzerTuple[1])
        IxLoadUtils.enableAnalyzerOnPorts(connection, sessionUrl, analyzerTuple)
        IxLoadUtils.log("Finished applying analyzer to specified tuple")

    IxLoadUtils.log("Starting the test...")
    IxLoadUtils.runTest(connection, sessionUrl)
    IxLoadUtils.log("Test started.")

    IxLoadUtils.log("Waiting for capture data...")
    IxLoadUtils.waitForAllCaptureData(connection, sessionUrl)
    IxLoadUtils.log("Waiting done.")

    for analyzerTuple in testSettings.analyzerTupleList:
        communityID, portID = analyzerTuple
        IxLoadUtils.log("Retrieving capture for port %s..." % portID)
        captureFilePath = kCaptureFileRootPath + "Capture_%s_%s.cap" % (communityID, portID)
        IxLoadUtils.retrieveCaptureFileForPorts(connection, sessionUrl, analyzerTuple, captureFilePath)

    IxLoadUtils.log("Test finished.")

    IxLoadUtils.log("Checking test status...")
    testRunError = IxLoadUtils.getTestRunError(connection, sessionUrl)
    if testRunError:
        IxLoadUtils.log("The test exited with the following error: %s" % testRunError)

        IxLoadUtils.log("Waiting for gateway diagnostics collection...")
        IxLoadUtils.collectGatewayDiagnostics(connection, gatewayDiagnosticsPath)
        IxLoadUtils.log("Gateway diagnostics are saved in %s" % gatewayDiagnosticsPath)

        IxLoadUtils.log("Waiting for diagnostics collection...")
        IxLoadUtils.collectDiagnostics(connection, sessionUrl, diagsPath)
        IxLoadUtils.log("Diagnostics are saved in %s" % diagsPath)
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
