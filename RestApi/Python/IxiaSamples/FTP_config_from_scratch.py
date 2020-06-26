import Utils.IxLoadUtils as IxLoadUtils
import Utils.IxRestUtils as IxRestUtils
import Utils.IxLoadTestSettings as TestSettings
import inspect


#### TEST CONFIG
testSettings = TestSettings.IxLoadTestSettings()
# testSettings.gatewayServer = "machine_ip_address"     # TODO - to be changed by user if he wants to run remote
testSettings.ixLoadVersion = ""                         # TODO - to be changed by user, by default will run on the latest installed version
testSettings.chassisList = ['chassisIpOrHostName']      # TODO - to be changed by user

testSettings.portListPerCommunity =    {
                                        "Traffic1@Network1" : [(1,1,1)],
                                        "Traffic2@Network2" : [(1,1,2)]
                                    }

kStatsToDisplayDict =   {
                            # format: { statSource : [stat name list] }
                            "FTPClient": ["FTP Simulated Users", "FTP Connections","FTP Data Conn Established","FTP File Uploads Successful","FTP File Uploads Failed"],
                            "FTPServer": ["FTP Control Bytes Sent","FTP Data Bytes Sent","FTP Data Bytes Received","FTP File Downloads Successful","FTP File Downloads Failed"]
                        }

location = inspect.getfile(inspect.currentframe())

forcefullyTakeOwnership = False

kCommunities = [
    # format: {option1: value1, option2: value2}
    {},  # default community with no options
    {"tcpAccelerationAllowedFlag": True}  # community with tcpAccelerationAllowedFlag set to True
]

kActivities = {
    # format: {communityName: [activityProtocolAndType1, activityProtocolAndType2]}
    'Traffic1@Network1': ['FTP Client'],
    'Traffic2@Network2': ['FTP Server']
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

    serverIPaddress=IxLoadUtils.NetworkUtils.getIPRange(connection, sessionUrl, 'Traffic2@Network2','IP-2','rangeList','IP-R2')
    clientIPaddress=IxLoadUtils.NetworkUtils.getIPRange(connection, sessionUrl, 'Traffic1@Network1','IP-1','rangeList','IP-R1')

    IxLoadUtils.log('Adding Login command to FTP client...')
    ftpCommandOptions = {'commandType': 'LOGIN', 'destination': '%s:21' %serverIPaddress}
    IxLoadUtils.FtpUtils.addFtpCommand(connection, sessionUrl, 'Traffic1@Network1', 'FTPClient1', ftpCommandOptions)
    IxLoadUtils.log('Command added to FTP client.')

    IxLoadUtils.log('Adding Get command to FTP client...')
    ftpCommandOptions = {'commandType': '{Get}', 'destination': 'Traffic2_FTPServer1:21'}
    IxLoadUtils.FtpUtils.addFtpCommand(connection, sessionUrl, 'Traffic1@Network1', 'FTPClient1', ftpCommandOptions)
    IxLoadUtils.log('Command added to FTP client.')

    IxLoadUtils.log('Adding MKD command to FTP client...')
    ftpCommandOptions = {'commandType': 'MKD', 'destination': 'Traffic2_FTPServer1:21','arguments': 'New'}
    IxLoadUtils.FtpUtils.addFtpCommand(connection, sessionUrl, 'Traffic1@Network1', 'FTPClient1', ftpCommandOptions)
    IxLoadUtils.log('Command added to FTP client.')

    IxLoadUtils.log('Adding Put command to FTP client...')
    ftpCommandOptions = {'commandType': '{Put}', 'destination': 'Traffic2_FTPServer1:21','arguments': '/#262144'}
    IxLoadUtils.FtpUtils.addFtpCommand(connection, sessionUrl, 'Traffic1@Network1', 'FTPClient1', ftpCommandOptions)
    IxLoadUtils.log('Command added to FTP client.')

    IxLoadUtils.log('Change FTP client objective...')
    optionsToChange = { "userObjectiveType": "concurrentSessions", "userObjectiveValue": 200}
    IxLoadUtils.changeActivityOptions(connection, sessionUrl, {'FTPClient1': optionsToChange})
    IxLoadUtils.log('FTP client objective changed.')

    IxLoadUtils.log("Clearing chassis list...")
    IxLoadUtils.clearChassisList(connection, sessionUrl)
    IxLoadUtils.log("Chassis list cleared.")

    IxLoadUtils.log("Adding chassis %s..." % (testSettings.chassisList))
    IxLoadUtils.addChassisList(connection, sessionUrl, testSettings.chassisList)
    IxLoadUtils.log("Chassis added.")

    IxLoadUtils.log("Assigning new ports...")
    IxLoadUtils.assignPorts(connection, sessionUrl, testSettings.portListPerCommunity)
    IxLoadUtils.log("Ports assigned.")

    IxLoadUtils.log("Saving repository %s..." % (IxLoadUtils.getRxfName(connection, location)))
    IxLoadUtils.saveRxf(connection, sessionUrl, IxLoadUtils.getRxfName(connection, location))
    IxLoadUtils.log("Repository saved.")

    if forcefullyTakeOwnership:
        IxLoadUtils.log("Enable ForcefullyTakeOwnership And ResetPorts...")
        IxLoadUtils.enableForcefullyTakeOwnershipAndResetPorts(connection, sessionUrl)
        IxLoadUtils.log("ForcefullyTakeOwnership And ResetPorts enabled")

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
