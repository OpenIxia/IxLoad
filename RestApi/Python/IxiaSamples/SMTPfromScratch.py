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
                            "SMTPClient": ["SMTP Simulated Users", "SMTP Sessions Established","SMTP Mails Sent", "SMTP Total Attachments Sent","SMTP Messages Failed"],
                            "SMTPServer": ["SMTP Session Requests Successful","SMTP MAIL Received","SMTP Session Requests Failed"]
                        }

kCommunities = [
    # format: {option1: value1, option2: value2}
    {}, # default community with no options
    {"tcpAccelerationAllowedFlag": True}  # community with tcpAccelerationAllowedFlag set to True
]

kActivities = {
    # format: {communityName: [activityProtocolAndType1, activityProtocolAndType2]}
    'Traffic1@Network1': ['SMTP Client'],
    'Traffic2@Network2': ['SMTP Server']
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

    # Mail message types
    #mailMessageId:0-Simple-100 bytes plain text body
    #mailMessageId:1-SimpleLarge-4K bytes plain text body
    #mailMessageId:2-HTMLSmall-1K bytes HTML body
    #mailMessageId:3-HTMLRandom-Random 1K to 32K HTML body
    #mailMessageId:4-AttachmentSmall-100 bytes plain text body 1K plain text attachment
    #mailMessageId:5-AttachmentLarge-1K bytes HTML body 1 64K attachment
    #mailMessageId:6-RandomSmall-small random body random attachments
    #mailMessageId:7-RandomLarge-large random body random attachments

    # SEND command
    IxLoadUtils.log('Adding SEND command to SMTP client...')
    smtpCommandOptions = {'commandType': '{Send}','destination': 'Traffic2_SMTPServer1:25'}
    mailMesageType={'mailMessageId': '4'}
    IxLoadUtils.SMTPUtils.addSMTPCommand(connection, sessionUrl, 'Traffic1@Network1', 'SMTPClient1', smtpCommandOptions)
    IxLoadUtils.SMTPUtils.changeMailMesage(connection, sessionUrl, 'Traffic1@Network1', 'SMTPClient1','Send 1',mailMesageType)
    IxLoadUtils.log('Command SEND added to smtp client.')

    # MAIL command
    IxLoadUtils.log('Adding MAIL command to SMTP client...')
    smtpCommandOptions = {'commandType': 'MAIL','destination': ''}
    mailMesageType={'mailMessageId': '4'} #
    IxLoadUtils.SMTPUtils.addSMTPCommand(connection, sessionUrl, 'Traffic1@Network1', 'SMTPClient1', smtpCommandOptions)
    IxLoadUtils.SMTPUtils.changeMailMesage(connection, sessionUrl, 'Traffic1@Network1', 'SMTPClient1','Mail 2', mailMesageType)
    IxLoadUtils.log('Command MAIL added to smtp client.')

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
