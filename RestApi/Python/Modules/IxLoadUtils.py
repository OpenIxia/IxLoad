import json
import requests
import time


kActionStateFinished = 'finished'
kActionStatusSuccessful = 'Successful'
kActionStatusError = 'Error'
kTestStateUnconfigured = 'Unconfigured'


def log(message):
    currentTime = time.strftime("%H:%M:%S")
    print "%s -> %s" % (currentTime, message)


def stripApiAndVersionFromURL(url):
    #remove the slash (if any) at the beginning of the url
    if url[0] == '/':
        url = url[1:]

    urlElements = url.split('/')
    if 'api' in url:
        #strip the api/v0 part of the url
        urlElements = urlElements[2:]

    return '/'.join(urlElements)


def waitForActionToFinish(connection, replyObj, actionUrl):
    '''
        This method waits for an action to finish executing. after a POST request is sent in order to start an action,
        The HTTP reply will contain, in the header, a 'location' field, that contains an URL.
        The action URL contains the status of the action. we perform a GET on that URL every 0.5 seconds until the action finishes with a success.
        If the action fails, we will throw an error and print the action's error message.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - replyObj the reply object holding the location
        - actionUrl - the url pointing to the operation
    '''
    actionResultURL = replyObj.headers.get('location')
    if actionResultURL:
        actionResultURL = stripApiAndVersionFromURL(actionResultURL)
        actionFinished = False

        while not actionFinished:
            actionStatusObj = connection.httpGet(actionResultURL)

            if actionStatusObj.state == kActionStateFinished:
                if actionStatusObj.status == kActionStatusSuccessful:
                    actionFinished = True
                else:
                    errorMsg = "Error while executing action '%s'." % actionUrl

                    if actionStatusObj.status == kActionStatusError:
                        errorMsg += actionStatusObj.error

                    print errorMsg
                    raise Exception(errorMsg)
            else:
                time.sleep(0.1)


def performGenericOperation(connection, url, payloadDict):
    '''
        This will perform a generic operation on the given url, it will wait for it to finish.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - url is the address of where the operation will be performed
        - payloadDict is the python dict with the parameters for the operation
    '''
    data = json.dumps(payloadDict)
    reply = connection.httpPost(url=url, data=data)

    if not reply.ok:
        raise Exception(reply.text)

    waitForActionToFinish(connection, reply, url)

    return reply


def performGenericPost(connection, listUrl, payloadDict):
    '''
        This will perform a generic POST method on a given url

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - url is the address of where the operation will be performed
        - payloadDict is the python dict with the parameters for the operation
    '''
    data = json.dumps(payloadDict)

    reply = connection.httpPost(url=listUrl, data=data)

    if not reply.ok:
        raise Exception(reply.text)

    try:
        newObjPath = reply.headers['location']
    except:
        raise Exception("Location header is not present. Please check if the action was created successfully.")

    newObjID = newObjPath.split('/')[-1]
    return newObjID


def performGenericDelete(connection, listUrl, payloadDict):
    '''
        This will perform a generic DELETE method on a given url

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - url is the address of where the operation will be performed
        - payloadDict is the python dict with the parameters for the operation
    '''
    data = json.dumps(payloadDict)

    reply = connection.httpDelete(url=listUrl, data=data)

    if not reply.ok:
        raise Exception(reply.text)
    return reply


def performGenericPatch(connection, url, payloadDict):
    '''
        This will perform a generic PATCH method on a given url

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - url is the address of where the operation will be performed
        - payloadDict is the python dict with the parameters for the operation
    '''
    data = json.dumps(payloadDict)

    reply = connection.httpPatch(url=url, data=data)
    if not reply.ok:
        raise Exception(reply.text)
    return reply


def createSession(connection, ixLoadVersion):
    '''
        This method is used to create a new session. It will return the url of the newly created session

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - ixLoadVersion this is the actual IxLoad Version to start
    '''

    sessionsUrl = "sessions"
    data = {"ixLoadVersion": ixLoadVersion}

    sessionId = performGenericPost(connection, sessionsUrl, data)

    newSessionUrl = "%s/%s" % (sessionsUrl, sessionId)
    startSessionUrl = "%s/operations/start" % (newSessionUrl)

    #start the session
    performGenericOperation(connection, startSessionUrl, {})

    log("Created session no %s" % sessionId)

    return newSessionUrl


def deleteSession(connection, sessionUrl):
    '''
        This method is used to delete an existing session.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the seession to delete
    '''
    deleteParams = {}
    performGenericDelete(connection, sessionUrl, deleteParams)


def uploadFile(connection, url, fileName, uploadPath, overwrite=True):
    headers = {'Content-Type': 'multipart/form-data'}
    params = {'overwrite': overwrite, 'uploadPath': uploadPath}

    log('Uploading to %s...' % uploadPath)
    try:
        with open(fileName, 'rb') as f:
            resp = requests.post(url, data=f, params=params, headers=headers)
    except requests.exceptions.ConnectionError as e:
        raise Exception(
            'Upload file failed. Received connection error. One common cause for this error is the size of the file to be uploaded.'
            ' The web server sets a limit of 1GB for the uploaded file size. Received the following error: %s' % str(e)
        )
    except IOError as e:
        raise Exception('Upload file failed. Received IO error: %s' % str(e))
    except Exception:
        raise Exception('Upload file failed. Received the following error: %s' % str(e))
    else:
        log('Upload file finished.')
        log('Response status code %s' % resp.status_code)
        log('Response text %s' % resp.text)


def loadRepository(connection, sessionUrl, rxfFilePath):
    '''
        This method will perform a POST request to load a repository.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session to load the rxf for
        - rxfFilePath is the local rxf path on the machine that holds the IxLoad instance
    '''
    loadTestUrl = "%s/ixload/test/operations/loadTest" % (sessionUrl)
    data = {"fullPath": rxfFilePath}

    performGenericOperation(connection, loadTestUrl, data)


def saveRxf(connection, sessionUrl, rxfFilePath):
    '''
        This method saves the current rxf to the disk of the machine on which the IxLoad instance is running.
        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session to save the rxf for
        - rxfFilePath is the location where to save the rxf on the machine that holds the IxLoad instance
    '''
    saveRxfUrl = "%s/ixload/test/operations/saveAs" % (sessionUrl)
    rxfFilePath = rxfFilePath.replace("\\", "\\\\")
    data = {"fullPath": rxfFilePath, "overWrite": 1}

    performGenericOperation(connection, saveRxfUrl, data)


def runTest(connection, sessionUrl):
    '''
        This method is used to start the currently loaded test. After starting the 'Start Test' action, wait for the action to complete.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test.
    '''
    startRunUrl = "%s/ixload/test/operations/runTest" % (sessionUrl)
    data = {}

    performGenericOperation(connection, startRunUrl, data)


def getTestCurrentState(connection, sessionUrl):
    '''
    This method gets the test current state. (for example - running, unconfigured, ..)
    Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test.
    '''
    activeTestUrl = "%s/ixload/test/activeTest" % (sessionUrl)
    testObj = connection.httpGet(activeTestUrl)

    return testObj.currentState


def getTestRunError(connection, sessionUrl):
    '''
    This method gets the error that appeared during the last test run.
    If no error appeared (the test ran successfully), the return value will be 'None'.
    Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test.
    '''
    activeTestUrl = "%s/ixload/test/activeTest" % (sessionUrl)
    testObj = connection.httpGet(activeTestUrl)

    return testObj.testRunError


def waitForTestToReachUnconfiguredState(connection, sessionUrl):
    '''
    This method waits for the current test to reach the 'Unconfigured' state.
    This is required in order to make sure that the test, after finishing the run, completes the Clean Up process before the IxLoad session is closed.
    Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test.
    '''
    while getTestCurrentState(connection, sessionUrl) != kTestStateUnconfigured:
        time.sleep(0.1)


def pollStats(connection, sessionUrl, watchedStatsDict, pollingInterval=4):
    '''
        This method is used to poll the stats. Polling stats is per request but this method does a continuous poll.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
        - watchedStatsDict these are the stats that are being monitored
        - pollingInterval the polling interval is 4 by default but can be overridden.

    '''
    statSourceList = watchedStatsDict.keys()

    # retrieve stats for a given stat dict
    # all the stats will be saved in the dictionary below

    #statsDict format:
    # {
    #   statSourceName: {
    #                       timestamp:  {
    #                                       statCaption : value
    #                                   }
    #                   }
    # }
    statsDict = {}

    # remember the timstamps that were already collected - will be ignored in future
    collectedTimestamps = {}  # format { statSource : [2000, 4000, ...] }
    testIsRunning = True

    # check stat sources
    for statSource in statSourceList[:]:
        statSourceUrl = "%s/ixload/stats/%s/values" % (sessionUrl, statSource)
        statSourceReply = connection.httpRequest("GET", statSourceUrl)
        if statSourceReply.status_code != 200:
            log("Warning - Stat source '%s' does not exist. Will ignore it." % (statSource))
            statSourceList.remove(statSource)

    # check the test state, and poll stats while the test is still running
    while testIsRunning:

        # the polling interval is configurable. by default, it's set to 4 seconds
        time.sleep(pollingInterval)

        for statSource in statSourceList:
            valuesUrl = "%s/ixload/stats/%s/values" % (sessionUrl, statSource)

            valuesObj = connection.httpGet(valuesUrl)
            valuesDict = valuesObj.getOptions()

            # get just the new timestamps - that were not previously retrieved in another stats polling iteration
            newTimestamps = [int(timestamp) for timestamp in valuesDict.keys() if timestamp not in collectedTimestamps.get(statSource, [])]
            newTimestamps.sort()

            for timestamp in newTimestamps:
                timeStampStr = str(timestamp)

                collectedTimestamps.setdefault(statSource, []).append(timeStampStr)

                timestampDict = statsDict.setdefault(statSource, {}).setdefault(timestamp, {})

                # save the values for the current timestamp, and later print them
                for caption, value in valuesDict[timeStampStr].getOptions().items():
                    if caption in watchedStatsDict[statSource]:
                        log("Timestamp %s - %s -> %s" % (timeStampStr, caption, value))
                        timestampDict[caption] = value

        testIsRunning = getTestCurrentState(connection, sessionUrl) == "Running"

    log("Stopped receiving stats.")


def clearChassisList(connection, sessionUrl):
    '''
        This method is used to clear the chassis list. After execution no chassis should be available in the chassisList.
        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
    '''
    chassisListUrl = "%s/ixload/chassischain/chassisList" % sessionUrl
    deleteParams = {}
    performGenericDelete(connection, chassisListUrl, deleteParams)


def addChassisList(connection, sessionUrl, chassisList):
    '''
        This method is used to add one or more chassis to the chassis list.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
        - chassisList is the list of chassis that will be added to the chassis chain.
    '''
    chassisListUrl = "%s/ixload/chassisChain/chassisList" % (sessionUrl)

    for chassisName in chassisList:
        data = {"name": chassisName}
        chassisId = performGenericPost(connection, chassisListUrl, data)

        #refresh the chassis
        refreshConnectionUrl = "%s/%s/operations/refreshConnection" % (chassisListUrl, chassisId)
        performGenericOperation(connection, refreshConnectionUrl, {})


def assignPorts(connection, sessionUrl, portListPerCommunity):
    '''
        This method is used to assign ports from a connected chassis to the required NetTraffics.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
        - portListPerCommunity is the dictionary mapping NetTraffics to ports (format -> { community name : [ port list ] })
    '''
    communtiyListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl

    communityList = connection.httpGet(url=communtiyListUrl)

    for community in communityList:
        portListForCommunity = portListPerCommunity.get(community.name)

        portListUrl = "%s/%s/network/portList" % (communtiyListUrl, community.objectID)

        if portListForCommunity:
            for portTuple in portListForCommunity:
                chassisId, cardId, portId = portTuple
                paramDict = {"chassisId": chassisId, "cardId": cardId, "portId": portId}

                performGenericPost(connection, portListUrl, paramDict)

def changeCardsInterfaceMode(connection, chassisChainUrl, chassisIp, cardIdList, mode):
    '''
        This method is used to change the interface mode on a list of cards from a chassis. In order to call this method, the desired chassis must be already  added and connected.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - chassisChainUrl is the address of the chassisChain resource
        - chassisIp is the IP or hostname of the chassis that contains the card(s)
        - cardIdList is a list of card IDs
        - mode is the interface mode that will be set on the cards. Possible options are (depending on card type): 1G, 10G, 40G, 100G
    '''
    changeCardsInterfaceModeOperationUrl = "%s/operations/changeCardsInterfaceMode" % chassisChainUrl
    cardIdStr = ",".join([str(cardId) for cardId in cardIdList])
    
    data = {"chassisIp":chassisIp, "cardIdList":cardIdStr, "mode":mode}

    performGenericOperation(connection, changeCardsInterfaceModeOperationUrl, data)

def setCardsAggregationMode(connection, chassisChainUrl, chassisIp, cardIdList, mode):
    '''
        This method is used to change the aggregation mode on a list of cards from a chassis. In order to call this method, the desired chassis must be already  added and connected.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - chassisChainUrl is the address of the chassisChain resource
        - chassisIp is the IP or hostname of the chassis that contains the card(s)
        - cardIdList is a list of card IDs
        - mode is the aggregation mode that will be set on the cards. Possible options are (depending on card type): NA (Non Aggregated), 1G, 10G, 40G
    '''
    setCardsAggregationModeOperationUrl = "%s/operations/setCardsAggregationMode" % chassisChainUrl
    cardIdStr = ",".join([str(cardId) for cardId in cardIdList])
    
    data = {"chassisIp":chassisIp, "cardIdList":cardIdStr, "mode":mode}

    performGenericOperation(connection, setCardsAggregationModeOperationUrl, data)

    

def getIPRangeListUrlForNetworkObj(connection, networkUrl):
    '''
        This method will return the IP Ranges associated with an IxLoad Network component.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - networkUrl is the REST address of the network object for which the network ranges will be provided.
    '''
    networkObj = connection.httpGet(networkUrl)

    if isinstance(networkObj, list):
        for obj in networkObj:
            url = "%s/%s" % (networkUrl, obj.objectID)
            rangeListUrl = getIPRangeListUrlForNetworkObj(connection, url)
            if rangeListUrl:
                return rangeListUrl
    else:
        for link in networkObj.links:
            if link.rel == 'rangeList':
                rangeListUrl = link.href.replace("/api/v0/", "")
                return rangeListUrl

        for link in networkObj.links:
            if link.rel == 'childrenList':
                #remove the 'api/v0' elements of the url, since they are not needed for connection http get
                childrenListUrl = link.href.replace("/api/v0/", "")

                return getIPRangeListUrlForNetworkObj(connection, childrenListUrl)

    return None


def changeIpRangesParams(connection, sessionUrl, ipOptionsToChangeDict):
    '''
        This method is used to change certain properties on an IP Range.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
        - ipOptionsToChangeDict is the Python dict holding the items in the IP range that will be changed.
            (ipOptionsToChangeDict format -> { IP Range name : { optionName : optionValue } })
    '''
    communtiyListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl

    communityList = connection.httpGet(url=communtiyListUrl)

    for community in communityList:
        stackUrl = "%s/%s/network/stack" % (communtiyListUrl, community.objectID)

        rangeListUrl = getIPRangeListUrlForNetworkObj(connection, stackUrl)
        rangeList = connection.httpGet(rangeListUrl)

        for rangeObj in rangeList:
            if rangeObj.name in ipOptionsToChangeDict.keys():
                rangeObjUrl = "%s/%s" % (rangeListUrl, rangeObj.objectID)
                paramDict = ipOptionsToChangeDict[rangeObj.name]

                performGenericPatch(connection, rangeObjUrl, paramDict)


def getCommandListUrlForAgentName(connection, sessionUrl, agentName):
    '''
        This method is used to get the commandList url for a provided agent name.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
        - agentName is the agent name for which the commandList address is provided
    '''
    communtiyListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl
    communityList = connection.httpGet(url=communtiyListUrl)

    for community in communityList:
        activityListUrl = "%s/%s/activityList" % (communtiyListUrl, community.objectID)
        activityList = connection.httpGet(url=activityListUrl)

        for activity in activityList:
            if activity.name == agentName:
                #agentActionListUrl = "%s/%s/agent/actionList" % (activityListUrl, activity.objectID)
                agentUrl = "%s/%s/agent" % (activityListUrl, activity.objectID)
                agent = connection.httpGet(agentUrl)

                for link in agent.links:
                    if link.rel in ['actionList', 'commandList']:
                        commandListUrl = link.href.replace("/api/v0/", "")
                        return commandListUrl


def clearAgentsCommandList(connection, sessionUrl, agentNameList):
    '''
        This method clears all commands from the command list of the agent names provided.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
        - agentNameList the list of agent names for which the command list will be cleared.
    '''
    deleteParams = {}
    for agentName in agentNameList:
        commandListUrl = getCommandListUrlForAgentName(connection, sessionUrl, agentName)

        if commandListUrl:
            performGenericDelete(connection, commandListUrl, deleteParams)


def addCommands(connection, sessionUrl, commandDict):
    '''
        This method is used to add commands to a certain list of provided agents.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
        - commandDict is the Python dict that holds the mapping between agent name and specific commands. (commandDict format -> { agent name : [ { field : value } ] })
    '''
    for agentName in commandDict.keys():
        commandListUrl = getCommandListUrlForAgentName(connection, sessionUrl, agentName)

        if commandListUrl:
            for commandParamDict in commandDict[agentName]:
                performGenericPost(connection, commandListUrl, commandParamDict)


def changeActivityOptions(connection, sessionUrl, activityOptionsToChange):
    '''
        This method will change certain properties for the provided activities.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
        - activityOptionsToChange is the Python dict that holds the mapping between agent name and specific properties (activityOptionsToChange format: { activityName : { option : value } })
    '''
    communtiyListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl
    communityList = connection.httpGet(url=communtiyListUrl)

    for community in communityList:
        activityListUrl = "%s/%s/activityList" % (communtiyListUrl, community.objectID)
        activityList = connection.httpGet(url=activityListUrl)

        for activity in activityList:
            if activity.name in activityOptionsToChange.keys():
                activityUrl = "%s/%s" % (activityListUrl, activity.objectID)
                performGenericPatch(connection, activityUrl, activityOptionsToChange[activity.name])


# To use the upload Method
#url = 'http://192.168.70.151:8080/api/v0/resources'
#uploadFile('192.168.70.151', url, 'IxL_Http_Ipv4Ftp_vm_8.20.rxf', '/mnt/ixload-share/IxL_Http_Ipv4Ftp_vm_8.20.rxf')
