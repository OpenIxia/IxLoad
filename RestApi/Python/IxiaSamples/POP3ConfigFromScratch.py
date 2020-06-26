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
                                        "Traffic1@Network1" : [(1,7,1)],
                                        "Traffic2@Network2" : [(1,7,5)]
                                    }

kStatsToDisplayDict =   {
                            # format: { statSource : [stat name list] }
                            "POP3Client": ["POP3 Simulated Users", "POP3 Sessions Established", "POP3 Sessions Failed","POP3 Mails Received","POP3 RETR Failed","POP3 RETR Sent"],
                            "POP3Server": ["POP3 Session Requests Successful", "POP3 Session Requests Failed","POP3 Total Mails Sent", "POP3 Total Attachments Sent","POP3 Total Mails With Attachments Sent","POP3 RETR Cmds Received"]
                        }

kCommunities = [
    # format: {option1: value1, option2: value2}
    {}, # default community with no options
    {"tcpAccelerationAllowedFlag": True}  # community with tcpAccelerationAllowedFlag set to True
]

kActivities = {
    # format: {communityName: [activityProtocolAndType1, activityProtocolAndType2]}
    'Traffic1@Network1': ['POP3 Client'],
    'Traffic2@Network2': ['POP3 Server']
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

    IxLoadUtils.log('Adding Get command to POP3 client...')
    POP3CommandOptions = {'commandType': '{Get}', 'arguments': 'Traffic2_POP3Server1:110', 'enableDataIntegrity': 'true'}
    IxLoadUtils.POP3Utils.addPOP3Command(connection, sessionUrl, 'Traffic1@Network1', 'POP3Client1', POP3CommandOptions)
    IxLoadUtils.log('Get Command added to POP3 client.')

    IxLoadUtils.log('Adding RETR command to POP3 client...')
    POP3CommandOptions = {'commandType': 'RETR','enableDataIntegrity': 'true'}
    IxLoadUtils.POP3Utils.addPOP3Command(connection, sessionUrl, 'Traffic1@Network1', 'POP3Client1', POP3CommandOptions)
    IxLoadUtils.log('RETR Command added to POP3 client.')

    for i in range(1,8):
        IxLoadUtils.log('Adding mail message to mailbox---POP3 server...')
        POP3ServerConfigMailOptions = {'count':'20'}
        MailMessageType={'mailMessageId':'%s' %i}
        IxLoadUtils.POP3Utils.addMailMessage(connection, sessionUrl, 'Traffic2@Network2', 'POP3Server1', POP3ServerConfigMailOptions)
        IxLoadUtils.POP3Utils.changeMailMessageType(connection, sessionUrl, 'Traffic2@Network2', 'POP3Server1',i,MailMessageType)
        IxLoadUtils.log('Mail message added to POP3 server.')

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
    IxLoadUtils.saveRxf(connection, sessionUrl, IxLoadUtils.getRxfName(connection,location))
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
