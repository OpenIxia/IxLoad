import Utils.IxLoadUtils as IxLoadUtils
import Utils.IxRestUtils as IxRestUtils
import Utils.IxLoadTestSettings as TestSettings
import inspect


#### TEST CONFIG
testSettings = TestSettings.IxLoadTestSettings()
# testSettings.gatewayServer = "machine_ip_address"     # TODO - to be changed by user if he wants to run remote
testSettings.ixLoadVersion = ""                         # TODO - to be changed by user, by default will run on the latest installed version
testSettings.chassisList = ['chassisIpOrHostName']      # TODO - to be changed by user

location=inspect.getfile(inspect.currentframe())

testSettings.portListPerCommunity = {
                                        "Traffic1@Network1" : [(1,11,1)],
                                        "Traffic2@Network2" : [(1,11,5)]
                                    }
kStatsToDisplayDict =   {
                            # format: { statSource : [stat name list] }
                            "CIFSClient": ["CIFS Active Connections", "CIFS Total Connections Succeeded","CIFS Total Connections Failed", "CIFSv2 Total WriteRequest Succeeded","CIFSv2 Total WriteRequest Failed (Error)","CIFSv2 Total SessionSetup Succeeded""CIFSv2 Total SessionSetup failed (Error)","CIFSv2 Total ReadRequest Succeeded","CIFSv2 Total ReadRequest Failed (Error)"],
                            "cifsServer": ["CIFSv2 SessionSetup Succeeded", "CIFSv2 SessionSetup Failed"]
                        }

kCommunities = [
    # format: {option1: value1, option2: value2}
    {},  # default community with no options
    {"tcpAccelerationAllowedFlag": True}  # community with tcpAccelerationAllowedFlag set to True
]

kActivities = {
    # format: {communityName: [activityProtocolAndType1, activityProtocolAndType2]}
    'Traffic1@Network1': ['cifs Client'],
    'Traffic2@Network2': ['cifs Server']
}

# Create a connection to the gateway
connection = IxRestUtils.getConnection(
                        testSettings.gatewayServer,
                        testSettings.gatewayPort,
                        httpRedirect=testSettings.httpRedirect,
                        version=testSettings.apiVersion
                        )

sessionUrl = None

try:
    # Create a session
    IxLoadUtils.log("Creating a new session...")
    sessionUrl = IxLoadUtils.createNewSession(connection, testSettings.ixLoadVersion)
    IxLoadUtils.log("Session created.")

    # Create nettraffics (communities)
    IxLoadUtils.log('Creating communities...')
    IxLoadUtils.addCommunities(connection, sessionUrl, kCommunities)
    IxLoadUtils.log('Communities created.')

    # Create activities
    IxLoadUtils.log('Creating activities...')
    IxLoadUtils.addActivities(connection, sessionUrl, kActivities)
    IxLoadUtils.log('Activities created.')

    IxLoadUtils.log('Adding CIFS ScanAll command to CIFS client...')
    cifsCommandOptions = {'commandType': 'ScanAllCommand', 'serverIP': 'Traffic2_CIFSServer1:445'}
    IxLoadUtils.cifsUtils.addCifsCommand(connection, sessionUrl, 'Traffic1@Network1', 'CIFSClient1', cifsCommandOptions)
    IxLoadUtils.log('Command added to CIFS client.')

    IxLoadUtils.log('Adding CIFS Session Setup command to CIFS client...')
    cifsCommandOptions = {'commandType': 'SessionSetupCommand', 'serverIP': 'Traffic2_CIFSServer1','userName': 'ixia-user','passWord': 'password'}
    IxLoadUtils.cifsUtils.addCifsCommand(connection, sessionUrl, 'Traffic1@Network1', 'CIFSClient1', cifsCommandOptions)
    IxLoadUtils.log('Command added to CIFS client.')

    IxLoadUtils.log('Adding CIFS ReadFromFile command to CIFS client...')
    cifsCommandOptions = {'commandType': 'ReadFromFileCommand','source': '\\root1\\file3','isReadEntireFile': 'true'}
    IxLoadUtils.cifsUtils.addCifsCommand(connection, sessionUrl, 'Traffic1@Network1', 'CIFSClient1', cifsCommandOptions)
    IxLoadUtils.log('Command ReadFromFile added to CIFS client.')

    IxLoadUtils.log('Adding CIFS WriteToFile command to CIFS client...')
    cifsCommandOptions = {"payloadType": "2", "dataLength": "1024","commandType": "WriteToFileCommand","target": "\\root1\\folder2\\file4"}
    IxLoadUtils.cifsUtils.addCifsCommand(connection, sessionUrl, 'Traffic1@Network1', 'CIFSClient1', cifsCommandOptions)
    IxLoadUtils.log('Command WriteToFile added to CIFS client.')

    IxLoadUtils.log('Adding new file to CIFS server...')
    cifsFileOptions = { "nodeType": "0","dataLength_unit": "1","payloadType": "2" ,"dataLength": "10","parentId": "2","name": "file4" }
    IxLoadUtils.cifsUtils.addFileToCifsServer(connection, sessionUrl, 'Traffic2@Network2', 'CIFSServer1', cifsFileOptions)
    IxLoadUtils.log('Command added to CIFS server.')

    IxLoadUtils.log("Clearing chassis list...")
    IxLoadUtils.clearChassisList(connection, sessionUrl)
    IxLoadUtils.log("Chassis list cleared.")

    IxLoadUtils.log("Adding chassis %s..." % (testSettings.chassisList))
    IxLoadUtils.addChassisList(connection, sessionUrl, testSettings.chassisList)
    IxLoadUtils.log("Chassis added.")

    IxLoadUtils.log("Assigning new ports...")
    IxLoadUtils.assignPorts(connection, sessionUrl,testSettings.portListPerCommunity)
    IxLoadUtils.log("Ports assigned.")

    IxLoadUtils.log("Saving repository %s..." % (IxLoadUtils.getRxfName(connection, location)))
    IxLoadUtils.saveRxf(connection, sessionUrl, IxLoadUtils.getRxfName(connection, location))
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
