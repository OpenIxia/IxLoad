import Utils.IxLoadUtils as IxLoadUtils
import Utils.IxRestUtils as IxRestUtils
import time, inspect, os

####TEST CONFIG

kGatewayServer = "127.0.0.1"
kGatewayPort = 8443
kIxLoadVersion = "8.00.0.44"#TODO - to be changed by user

kRxfPath = r"C:\\Path\\to\\config.rxf"#TODO - to be changed by user
kChassisList = ['chassisIpOrHostName']#TODO - to be changed by user

kPortListPerCommunityCommunity =    {
                                        "Traffic1@Network1" : [(1,2,1)],
                                        "Traffic2@Network2" : [(1,2,2)]
                                    }

kStatsToDisplayDict =   {
                            #format: { statSource : [stat name list] }
                            "HTTPClient": ["HTTP Simulated Users", "HTTP Concurrent Connections", "HTTP Requests Successful"],
                            "HTTPServer": ["HTTP Requests Received", "TCP Retries"]
                        }


kNewCommands =  {
                    #format: { agent name : [ { field : value } ] }
                    "HTTPClient1" : [
                                        {
                                            "commandType"   : "GET",
                                            "destination"   : "Traffic2_HTTPServer1:80",
                                            "pageObject"    : "/32k.html",
                                        },
                                        {
                                            "commandType"   : "POST",
                                            "destination"   : "Traffic2_HTTPServer1:80",
                                            "pageObject"    : "/8k.html",
                                            "arguments"     : r"C:\\Path\\to\\file.txt", #TODO - to be changed by user
                                        }
                                    ]
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
connection = IxRestUtils.getConnection(kGatewayServer, kGatewayPort)

sessionUrl = None

try:
    #create a session
    IxLoadUtils.log("Creating a new session...")
    sessionUrl = IxLoadUtils.createSession(connection, kIxLoadVersion)
    IxLoadUtils.log("Session created.")

    #load a repository
    IxLoadUtils.log("Loading reposiory %s..." % kRxfPath)
    IxLoadUtils.loadRepository(connection, sessionUrl, kRxfPath)
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

    IxLoadUtils.log("Clearing command lists for agents %s..." % (kNewCommands.keys()))
    IxLoadUtils.clearAgentsCommandList(connection, sessionUrl, kNewCommands.keys())
    IxLoadUtils.log("Command lists cleared.")

    IxLoadUtils.log("Adding new commands for agents %s..." % (kNewCommands.keys()))
    IxLoadUtils.addCommands(connection, sessionUrl, kNewCommands)
    IxLoadUtils.log("Commands added.")

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
