import Utils.IxLoadUtils as IxLoadUtils
import Utils.IxRestUtils as IxRestUtils
import Utils.IxLoadTestSettings as TestSettings
import os
import json


#### TEST CONFIG
testSettings = TestSettings.IxLoadTestSettings()
# testSettings.gatewayServer = "machine_ip_address"     # TODO - to be changed by user if he wants to run remote
testSettings.ixLoadVersion = ""                         # TODO - to be changed by user
# testSettings.apiVersion = "v1"                        # TODO - to be changed by user

kRxfPath = r"C:\\Path\\to\\config.rxf"                  # TODO - to be changed by user
kStatFile = "Stats.txt"                                 # TODO - to be changed by user
kStatSourceList = []                                    # TODO - to be changed by user if he wants statsName only for specific statSources

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

    kRxfRelativeUploadPath = os.path.split(kRxfPath)[1]
    # Upload file to gateway server
    if not testSettings .isLocalHost():
        IxLoadUtils.log('Uploading file %s...' % kRxfPath)
        kResourcesUrl = IxLoadUtils.getResourcesUrl(connection)
        IxLoadUtils.uploadFile(connection, kResourcesUrl, kRxfPath, kRxfRelativeUploadPath)
        IxLoadUtils.log('Upload file finished.')

    # Load a repository
    kRxfAbsoluteUploadPath = '/'.join([IxLoadUtils.getSharedFolder(connection), kRxfRelativeUploadPath])
    IxLoadUtils.log("Loading repository %s..." % kRxfAbsoluteUploadPath)
    IxLoadUtils.loadRepository(connection, sessionUrl, kRxfAbsoluteUploadPath)
    IxLoadUtils.log("Repository loaded.")

    if not kStatSourceList:
        IxLoadUtils.log("Extract StatList...")
        kStatSourceList = IxLoadUtils.extractStatList(connection, sessionUrl)
        IxLoadUtils.log("StatList extracted...")

    IxLoadUtils.log("Extract StatName...")
    statsName = IxLoadUtils.extractStatName(connection, sessionUrl, kStatSourceList)
    IxLoadUtils.log("StatName extracted...")

    kStatNamePath = '/'.join([os.path.split(kRxfPath)[0], kStatFile])
    with open(kStatNamePath, 'w') as outFile:
        outFile.write(json.dumps(statsName))

finally:
    if sessionUrl is not None:
        IxLoadUtils.log("Closing IxLoad session...")
        IxLoadUtils.deleteSession(connection, sessionUrl)
        IxLoadUtils.log("IxLoad session closed.")

