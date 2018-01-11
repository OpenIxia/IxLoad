from IxLoad import IxLoad, StatCollectorUtils
from setup_simple import *

#
# Initialize IxLoad
#

IxLoad = IxLoad()

# IxLoad connect should always be called, even for local scripts
IxLoad.connect(remoteServer)

# once we've connected, make sure we disconnect, even if there's a problem
try:
    #
    # Loads plugins for specific protocols configured in this test
    #  
    IxLoad.loadAppPlugin("HTTP")

    #
    # setup logger
    #
    logtag = "IxLoad-python-api"
    logName = "HTTP"
    logger  = IxLoad.new("ixLogger", logtag, 1)
    logEngine = logger.getEngine()
    logEngine.setLevels(IxLoad.ixLogger.kLevelDebug, IxLoad.ixLogger.kLevelWarning)
    logEngine.setFile(logName, 2, 256, 1)

    #-----------------------------------------------------------------------
    # Initialize stat collection utilities
    #-----------------------------------------------------------------------
    StatUtils = StatCollectorUtils()

    #-----------------------------------------------------------------------
    # Build Chassis Chain
    #-----------------------------------------------------------------------
    chassisChain  = IxLoad.new("ixChassisChain")
    chassisChain.addChassis(chassisName)

    #-----------------------------------------------------------------------
    # Build client and server Network
    #-----------------------------------------------------------------------
    clnt_network  = IxLoad.new("ixNetworkGroup", chassisChain, name="clnt_network")
    
    clnt_network.networkRangeList.appendItem(name        = "clnt_range",
                                             enable      = 1,
                                             firstIp     = "198.18.2.1",
                                             ipIncrStep  = IxLoad.ixNetworkRange.kIpIncrOctetForth,
                                             ipCount     = 100,
                                             networkMask = "255.255.0.0",
                                             gateway     = "0.0.0.0", \
                                             firstMac    = "00:C6:12:02:01:00",
                                             macIncrStep = IxLoad.ixNetworkRange.kMacIncrOctetSixth,
                                             vlanEnable  = 0,
                                             vlanId      = 1,
                                             mssEnable   = 0,
                                             mss         = 100)

    clnt_network.arpSettings.config(gratuitousArp=0)

    (chId, cId, pId) = clientPort1.split(".")
    clnt_network.portList.appendItem(chassisId=chId, cardId=cId, portId=pId)

    svr_network = IxLoad.new("ixNetworkGroup", chassisChain, name="svr_network")
    
    svr_network.networkRangeList.appendItem(name        = "svr_range",
                                            enable      = 1,
                                            firstIp     = "198.18.200.1", \
                                            ipIncrStep  = IxLoad.ixNetworkRange.kIpIncrOctetForth,
                                            ipCount     = 100,
                                            networkMask = "255.255.0.0",
                                            gateway     = "0.0.0.0",
                                            firstMac    = "00:C6:12:02:02:00",
                                            macIncrStep = IxLoad.ixNetworkRange.kMacIncrOctetSixth,
                                            vlanEnable  = 0,
                                            vlanId      = 1,
                                            mssEnable   = 0,
                                            mss         = 100)

    svr_network.arpSettings.config(gratuitousArp=0)

    (chId, cId, pId) = serverPort1.split(".")
    svr_network.portList.appendItem(chassisId = chId,
                                    cardId    = cId,
                                    portId    = pId)


    #-----------------------------------------------------------------------
    # Construct Client Traffic
    # The ActivityModel acts as a factory for creating agents which actually
    # generate the test traffic
    #-----------------------------------------------------------------------
    clnt_traffic = IxLoad.new("ixClientTraffic", name="client_traffic")
    clnt_traffic.agentList.appendItem(name                  = "my_http_client",
                                      protocol              = "HTTP",
                                      type                  = "Client",
                                      maxSessions           = 3,
                                      httpVersion           = "1.0",
                                      keepAlive             = 0,
                                      maxPersistentRequests = 3,
                                      followHttpRedirects   = 0,
                                      enableCookieSupport   = 0,
                                      enableHttpProxy       = 0,
                                      enableHttpsProxy      = 0,
                                      browserEmulation      = 1,
                                      enableSsl             = 0)

    #
    # Add actions to this client agent
    #
    for (page, dest) in [("/4k.htm", "svr_traffic_my_http_server"), ("/8k.htm", "svr_traffic_my_http_server")]:
        clnt_traffic.agentList[0].actionList.appendItem(command     = "GET",
                                                        destination = dest,
                                                        pageObject  = page)

    #-----------------------------------------------------------------------
    # Construct Server Traffic
    #-----------------------------------------------------------------------
    svr_traffic      = IxLoad.new("ixServerTraffic", name="svr_traffic")
    svr_traffic.agentList.appendItem(name        = "my_http_server",
                                     protocol    = "HTTP",
                                     type        = "Server",
                                     httpPort    = 80)

    for idx in range(0, int(svr_traffic.agentList[0].responseHeaderList.indexCount())):
        response = svr_traffic.agentList[0].responseHeaderList.getItem(idx)
        if response.cget("name") == "200_OK":
            response200ok = response
        if response.cget("name") == "404_PageNotFound":
            response404_PageNotFound = response


    #
    # Clear pre-defined web pages, add new web pages 
    #
    svr_traffic.agentList[0].webPageList.clear()
    svr_traffic.agentList[0].webPageList.appendItem(page        = "/4k.html",
                                                    payloadType = "range",
                                                    payloadSize = "4096-4096",
                                                    response    =  response200ok)

    svr_traffic.agentList[0].webPageList.appendItem(page        = "/8k.html",
                                                    payloadType = "range",
                                                    payloadSize = "8192-8192",
                                                    response    =  response404_PageNotFound)

    svr_traffic.agentList[0].webPageList.appendItem(page        = "/128k.html",
                                                    payloadType = "range",
                                                    payloadSize = "131072",
                                                    response    =  response200ok)

    #-----------------------------------------------------------------------
    # Create a client and server mapping and bind into the
    # network and traffic that they will be employing
    #-----------------------------------------------------------------------
    clnt_t_n_mapping = IxLoad.new("ixClientTrafficNetworkMapping",
                                  network         = clnt_network,
                                  traffic         = clnt_traffic,
                                  objectiveType   = "simulatedUsers",
                                  objectiveValue  = 20,
                                  rampUpValue     = 5,
                                  sustainTime     = 20,
                                  rampDownTime    = 20)

    #
    # Set objective type, value and port map for client activity
    #
    clnt_t_n_mapping.setObjectiveTypeForActivity("my_http_client", "connectionRate")
    clnt_t_n_mapping.setObjectiveValueForActivity ("my_http_client", 200)
    clnt_t_n_mapping.setPortMapForActivity("my_http_client", "portMesh")

    svr_t_n_mapping  = IxLoad.new("ixServerTrafficNetworkMapping",
                                  network               = svr_network,
                                  traffic               = svr_traffic,
                                  matchClientTotalTime  = 1)

    #-----------------------------------------------------------------------
    # Create a test controller bound to the previosuly allocated
    # chassis chain. This will eventually run the test we created earlier.
    #-----------------------------------------------------------------------
    test = IxLoad.new("ixTest",
                      name              = "my_test",
                      statsRequired     = 1,
                      enableResetPorts  = 1)
                      
    test.clientCommunityList.appendItem(object=clnt_t_n_mapping)
    test.serverCommunityList.appendItem(object=svr_t_n_mapping)
    testController=IxLoad.new("ixTestController",
                              outputDir=1)
    testController.setResultDir("RESULTS/%s" % logName)

    #-----------------------------------------------------------------------
    # Set up stat Collection
    #-----------------------------------------------------------------------
    test_server_handle=testController.getTestServerHandle()
    StatUtils.Initialize(test_server_handle)

    #
    # Clear any stats that may have been registered previously
    #
    StatUtils.ClearStats()

    #
    # Define the stats we would like to collect
    #
    StatUtils.AddStat(caption           = "Watch_Stat_1",
                      statSourceType    = "HTTP Client",
                      statName          = "HTTP Bytes Sent",
                      aggregationType   = "kSum",
                      filterList        = {})

    StatUtils.AddStat(caption           = "Watch_Stat_2",
                      statSourceType    = "HTTP Client",
                      statName          = "HTTP Bytes Received",
                      aggregationType   = "kSum",
                      filterList        = {})

    StatUtils.AddStat(caption           = "Watch_Stat_3",
                      statSourceType    = "HTTP Client",
                      statName          = "HTTP Bytes Sent",
                      aggregationType   = "kRate",
                      filterList        = {})

    StatUtils.AddStat(caption           = "Watch_Stat_4",
                      statSourceType    = "HTTP Client",
                      statName          = "HTTP Bytes Received",
                      aggregationType   = "kRate",
                      filterList        = {})

    #
    # Start the collector (runs in the tcl event loop)
    #
    def my_stat_collector_python_command(*args):
        print "====================================="
        print "INCOMING STAT RECORD >>> %s" % (args, )
        print "Len = %s" % len(args)
        print args[0]
        print args[1]
        print "====================================="

    StatUtils.StartCollector(my_stat_collector_python_command)
    
    testController.run(test)

    #
    # have the script wait until the test is over
    #
    IxLoad.waitForTestFinish()
    
    #
    # Stop the collector (running in the tcl event loop)
    #
    StatUtils.StopCollector()

    #-----------------------------------------------------------------------
    # Cleanup
    #-----------------------------------------------------------------------

    testController.generateReport(detailedReport=1, format="PDF;HTML")
    testController.releaseConfigWaitFinish()

    IxLoad.delete(chassisChain)
    IxLoad.delete(clnt_network)
    IxLoad.delete(clnt_traffic)
    IxLoad.delete(clnt_t_n_mapping)
    IxLoad.delete(svr_network)
    IxLoad.delete(svr_traffic)
    IxLoad.delete(svr_t_n_mapping)
    IxLoad.delete(test)
    IxLoad.delete(testController)
    IxLoad.delete(logger)
    IxLoad.delete(logEngine)

except Exception, e:
    print str(e)

#-----------------------------------------------------------------------
# Disconnect
#-----------------------------------------------------------------------

IxLoad.disconnect()
