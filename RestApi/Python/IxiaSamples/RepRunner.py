import Utils.IxLoadUtils as IxLoadUtils
import Utils.IxRestUtils as IxRestUtils
import Utils.IxLoadTestSettings as TestSettings
import inspect
import os


#### TEST CONFIG
testSettings = TestSettings.IxLoadTestSettings()
#testSettings.gatewayServer = "machine_ip_address"      # TODO - to be changed by user if he wants to run remote
#testSettings.apiVersion = "v1"                         # TODO - uncomment if you want to run on api/v1
testSettings.ixLoadVersion = ""                         # TODO - to be changed by user, by default will run on the latest installed version

location=inspect.getfile(inspect.currentframe())

# Run all repositories from kRxfFolderPath
kRxfFolderPath = r"C:\\Path\\to\\Folder\\With\\Repositories"  # TODO - to be changed by user

runOnDifferentSetup = False                             # TODO - to be changed by user if he wants to run on different setup
if runOnDifferentSetup:
    testSettings.chassisList = ["chassisIp"]            # TODO - to be changed by user
    testSettings.portListPerCommunity = {
                                         #  format: { community name : [ port list ] }
                                        "Traffic1@Network1" : [(1,1,1)],
                                        "Traffic2@Network2" : [(1,1,2)]
                                        }

# Create a connection to the gateway
connection = IxRestUtils.getConnection(
                        testSettings.gatewayServer,
                        testSettings.gatewayPort,
                        httpRedirect=testSettings.httpRedirect,
                        version=testSettings.apiVersion
                        )
connection.setApiKey(testSettings.apiKey)

sessionUrl = None

try:
    # Create a session
    IxLoadUtils.log("Creating a new session...")
    sessionUrl = IxLoadUtils.createNewSession(connection, testSettings.ixLoadVersion)
    IxLoadUtils.log("Session created.")

    kResourcesUrl = IxLoadUtils.getResourcesUrl(connection)
    kRxfFiles = [ '/'.join([kRxfFolderPath, f]) for f in os.listdir(kRxfFolderPath) if f.split(".")[1] == "rxf"]

    for kRxfFile in kRxfFiles:
        kRxfRelativeUploadPath = os.path.split(kRxfFile)[1]
        kRxfAbsoluteUploadPath = kRxfFile

        if not testSettings.isLocalHost():
            IxLoadUtils.log('Uploading file %s...' % kRxfFile)
            IxLoadUtils.uploadFile(connection, kResourcesUrl, kRxfFile, kRxfRelativeUploadPath)
            IxLoadUtils.log('Upload file finished.')
            kRxfAbsoluteUploadPath = '/'.join([IxLoadUtils.getSharedFolder(connection), kRxfRelativeUploadPath])

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

        IxLoadUtils.log("Enable ForcefullyTakeOwnership And ResetPorts...")
        IxLoadUtils.enableForcefullyTakeOwnershipAndResetPorts(connection, sessionUrl)
        IxLoadUtils.log("ForcefullyTakeOwnership And ResetPorts enabled")

        IxLoadUtils.log("Starting the test...")
        IxLoadUtils.runTest(connection, sessionUrl)
        IxLoadUtils.log("Test started.")

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



