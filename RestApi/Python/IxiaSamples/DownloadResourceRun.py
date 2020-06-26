import Utils.IxLoadUtils as IxLoadUtils
import Utils.IxRestUtils as IxRestUtils
import Utils.IxLoadTestSettings as TestSettings
import inspect
import os


####TEST CONFIG
testSettings = TestSettings.IxLoadTestSettings()
# testSettings.gatewayServer = "machine_ip_address"  #TODO - to be changed by user if he wants to run remote
testSettings.ixLoadVersion = "" # TODO - to be changed by user, by default will run on the latest installed version
# testSettings.apiVersion = "v1" #TODO -to be changed by user, uncomment if you want to run on /api/v1
kRxfPath = r"C:\\Path\\to\\config.rxf"  # TODO - to be changed by user
diagsFile = "diags.zip"    # TODO - to be changed by user
gatewayDiagnosticsFile = "gatewaydiags.zip"    # TODO - to be changed by user
downloadFolder =  "C:\\Path\\to\\Download\\Folder"# TODO - to be changed by user- where you want to save the archive
localPath = r"C:\\Path\\to\\Downloaded\\Folder\\or\\File" #TODO - to be changed by user folder from your computer with size
zipName = "bug.zip"   #TODO - to be changed by user - used only if you download folders NOT files

 # TODO - to be changed by user
runOnDifferentSetup = False
if runOnDifferentSetup:
    testSettings.chassisList = ["chassisIP"] #TODO - to be changed by user
    testSettings.portListPerCommunity = {
                                         #  format: { community name : [ port list ] }
                                        "Traffic1@Network1" : [(1,2,1)],
                                        "Traffic2@Network2" : [(1,2,5)]
                                        }


location=inspect.getfile(inspect.currentframe())
gatewayDiagnosticsPath = '/'.join([os.path.dirname(kRxfPath), gatewayDiagnosticsFile])
diagsPath = '/'.join([os.path.dirname(kRxfPath), diagsFile])

kStatsToDisplayDict =   {
                            #format: { statSource : [stat name list] }
                            "HTTPClient": ["HTTP Simulated Users"],
                            "HTTPServer": ["HTTP Requests Received"]
                        }
################

#create a connection to the gateway
connection = IxRestUtils.getConnection(
                        testSettings.gatewayServer,
                        testSettings.gatewayPort,
                        httpRedirect=testSettings.httpRedirect,
                        version=testSettings.apiVersion
                        )
connection.setApiKey(testSettings.apiKey)

sessionUrl = None
#create a session
try:
    IxLoadUtils.log("Creating a new session...")
    sessionUrl = IxLoadUtils.createNewSession(connection, testSettings.ixLoadVersion)
    IxLoadUtils.log("Session created.")

    kRxfAbsoluteUploadPath = kRxfPath
    # upload file to gateway server
    kRxfRelativeUploadPath = os.path.split(kRxfPath)[1]
    if not testSettings .isLocalHost():
        IxLoadUtils.log('Uploading file %s...' % kRxfPath)
        kResourcesUrl = IxLoadUtils.getResourcesUrl(connection)
        IxLoadUtils.uploadFile(connection, kResourcesUrl, kRxfPath, kRxfRelativeUploadPath)
        IxLoadUtils.log('Upload file finished.')
        kRxfAbsoluteUploadPath = '/'.join([IxLoadUtils.getSharedFolder(connection), kRxfRelativeUploadPath])

    # load a repository

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

        kRxfName = IxLoadUtils.getRxfName(connection, location).split(".")[0]+"-"+ kRxfRelativeUploadPath
        IxLoadUtils.log("Saving repository %s..." % (kRxfName))
        IxLoadUtils.saveRxf(connection, sessionUrl, kRxfName)
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

    IxLoadUtils.log("Downloading resources...")
    #zipName is provided only when you download folders
    #timeout to be increased if you download big files or slow connection
    IxLoadUtils.downloadResource(connection, downloadFolder, localPath, zipName,timeout=200)
    IxLoadUtils.log("Resources  downloaded...")

finally:
    if sessionUrl is not None:
        IxLoadUtils.log("Closing IxLoad session...")
        IxLoadUtils.deleteSession(connection, sessionUrl)
        IxLoadUtils.log("IxLoad session closed.")
