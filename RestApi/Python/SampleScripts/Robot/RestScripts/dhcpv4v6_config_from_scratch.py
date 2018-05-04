import Utils.IxLoadUtils as IxLoadUtils
import Utils.IxRestUtils as IxRestUtils
import inspect, os

####TEST CONFIG

kGatewayServer = "127.0.0.1"
kGatewayPort = 8443
kIxLoadVersion = "8.40.0.168"#TODO - to be changed by user

kChassisList = ['chassisIpOrHostName']#TODO - to be changed by user

kPortListPerCommunityCommunity =    {
                                        "Traffic1@Network1" : [(1,1,11)],
                                        "Traffic2@Network2" : [(1,1,12)]
                                    }

kStatsToDisplayDict =   {
                            #format: { statSource : [stat name list] }
                            "HTTPClient": ["HTTP Simulated Users", "HTTP Concurrent Connections", "HTTP Requests Successful"],
                            "HTTPServer": ["HTTP Requests Received", "TCP Retries"]
                        }

kCommunities = [
    # format: {option1: value1, option2: value2}
    {},  # default community with no options
    {"tcpAccelerationAllowedFlag": True}  # community with tcpAccelerationAllowedFlag set to True
]

kActivities = {
    # format: {communityName: [activityProtocolAndType1, activityProtocolAndType2]}
    'Traffic1@Network1': ['HTTP Client'],
    'Traffic2@Network2': ['HTTP Server']
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
                                            "arguments"     : r"D:\important.txt", #TODO - to be changed by user
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
    # create a session
    IxLoadUtils.log("Creating a new session...")
    sessionUrl = IxLoadUtils.createSession(connection, kIxLoadVersion)
    IxLoadUtils.log("Session created.")

    # create nettraffics (communities)
    IxLoadUtils.log('Creating communities...')
    IxLoadUtils.addCommunities(connection, sessionUrl, kCommunities)
    IxLoadUtils.log('Communities created.')

    IxLoadUtils.log('Deleting IP plugins...')
    IxLoadUtils.NetworkUtils.deletePlugin(connection, sessionUrl, 'Traffic1@Network1', 'IP-1')
    IxLoadUtils.NetworkUtils.deletePlugin(connection, sessionUrl, 'Traffic2@Network2', 'IP-2')

    IxLoadUtils.log('Adding DHCP plugins...')
    IxLoadUtils.NetworkUtils.addPlugin(connection, sessionUrl, 'Traffic1@Network1', 'MAC/VLAN-1', {'itemType': 'DHCPPlugin'})
    IxLoadUtils.NetworkUtils.addPlugin(connection, sessionUrl, 'Traffic2@Network2', 'MAC/VLAN-2', {'itemType': 'DHCPServerPlugin'})

    IxLoadUtils.log('Adding DHCPv6 ranges...')
    IxLoadUtils.NetworkUtils.addRange(connection, sessionUrl, 'Traffic1@Network1', 'DHCP Client-1', 'rangeList', {'ipType': 'IPv6'})
    IxLoadUtils.NetworkUtils.addRange(connection, sessionUrl, 'Traffic2@Network2', 'DHCP Server-1', 'rangeList', {'ipType': 'IPv6'})

    dhcpRangeOptions = {
        'serverAddress': '::A0B:1',
        'serverAddressIncrement': '::1',
        'ipPrefix': 112,
        'serverPrefix': 112,
        'ipAddress': '::A0B:101',
    }

    IxLoadUtils.log('Changing DHCP range options for DHCP Server plugin...')
    IxLoadUtils.NetworkUtils.changeRangeOptions(connection, sessionUrl, 'Traffic2@Network2', 'DHCP Server-1', 'rangeList', 'DHCPServer-R2', dhcpRangeOptions)

    # Changing the DHCP-server range options in order to be able to alter the ipAddressIncrement
    IxLoadUtils.NetworkUtils.changeRangeOptions(connection, sessionUrl, 'Traffic2@Network2', 'DHCP Server-1', 'rangeList', 'DHCPServer-R2', {"dhcp6IaType": "IAPD"})
    IxLoadUtils.NetworkUtils.changeRangeOptions(connection, sessionUrl, 'Traffic2@Network2', 'DHCP Server-1', 'rangeList', 'DHCPServer-R2', {"ipAddressIncrement": "::1"})
    IxLoadUtils.NetworkUtils.changeRangeOptions(connection, sessionUrl, 'Traffic2@Network2', 'DHCP Server-1', 'rangeList', 'DHCPServer-R2', {"dhcp6IaType": "IANA"})

    # create activities
    IxLoadUtils.log('Creating activities...')
    IxLoadUtils.addActivities(connection, sessionUrl, kActivities)
    IxLoadUtils.log('Activities created.')

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
