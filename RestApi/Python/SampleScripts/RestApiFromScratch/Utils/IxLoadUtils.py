import json
import requests
import time


kActionStateFinished = 'finished'
kActionStatusSuccessful = 'Successful'
kActionStatusError = 'Error'
kTestStateUnconfigured = 'Unconfigured'


def log(message):
    currentTime = time.strftime("%H:%M:%S")
    print ("%s -> %s" % (currentTime, message))


def getResourcesUrl(connection):
    return connection.url + '/resources'


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

                    print (errorMsg)
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
            resp = requests.post(url, data=f, params=params, headers=headers, verify=False)
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

def waitForAllCaptureData(connection, sessionUrl):
    '''
        This method is used after a test ran, to wait until all the port capture data was received.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session on which the test was ran.
    '''
    waitForAllCaptureDataUrl = "%s/ixload/test/operations/waitForAllCaptureData" % (sessionUrl)
    data = {}

    performGenericOperation(connection, waitForAllCaptureDataUrl, data)

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
    communityListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl

    communityList = connection.httpGet(url=communityListUrl)

    for community in communityList:
        portListForCommunity = portListPerCommunity.get(community.name)

        portListUrl = "%s/%s/network/portList" % (communityListUrl, community.objectID)

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
    communityListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl

    communityList = connection.httpGet(url=communityListUrl)

    for community in communityList:
        stackUrl = "%s/%s/network/stack" % (communityListUrl, community.objectID)

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
    communityListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl
    communityList = connection.httpGet(url=communityListUrl)

    for community in communityList:
        activityListUrl = "%s/%s/activityList" % (communityListUrl, community.objectID)
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
    communityListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl
    communityList = connection.httpGet(url=communityListUrl)

    for community in communityList:
        activityListUrl = "%s/%s/activityList" % (communityListUrl, community.objectID)
        activityList = connection.httpGet(url=activityListUrl)

        for activity in activityList:
            if activity.name in activityOptionsToChange.keys():
                activityUrl = "%s/%s" % (activityListUrl, activity.objectID)
                performGenericPatch(connection, activityUrl, activityOptionsToChange[activity.name])


def addCommunities(connection, sessionUrl, communityOptionsList):
    communityListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl
    for communityOptionsDict in communityOptionsList:
        performGenericPost(connection, communityListUrl, communityOptionsDict)


def getItemByName(itemList, itemName):
    for item in itemList:
        if item.name == itemName:
            return item


def addActivities(connection, sessionUrl, activityListPerCommunity):
    communityListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl
    communityList = connection.httpGet(url=communityListUrl)

    for communityName, activityList in activityListPerCommunity.iteritems():
        community = getItemByName(communityList, communityName)

        if community is None:
            raise Exception('Community %s cannot be found.' % communityName)

        activityListUrl = "%s/%s/activityList" % (communityListUrl, community.objectID)
        for activityType in activityList:
            options = {}
            options.update({'protocolAndType': activityType})
            performGenericPost(connection, activityListUrl, options)


def deleteAllSessions(connection):
    connection.httpDelete('sessions')


# To be used for removing '/api/v0/' from a link
def normalizeLink(link):
    return link.href.replace('/api/v0/', '')


class ActivityUtils(object):

    @staticmethod
    def changeAgentOptions(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = ActivityUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        agentUrl = '%s/%s/agent' % (activityListUrl, activity.objectID)
        performGenericPatch(connection, agentUrl, optionsDict)

    @staticmethod
    def getActivityByName(connection, sessionUrl, communityName, activityName):
        communityListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl
        communityList = connection.httpGet(url=communityListUrl)

        community = getItemByName(communityList, communityName)
        if community is None:
            raise Exception('Community %s cannot be found.' % communityName)

        activityListUrl = "%s/%s/activityList" % (communityListUrl, community.objectID)
        activityList = connection.httpGet(url=activityListUrl)

        activity = getItemByName(activityList, activityName)
        if activity is None:
            raise Exception('Community %s does not have an activity named %s.' % (communityName, activityName))

        return (activityListUrl, activity)


class NetworkUtils(object):

    @staticmethod
    def getStackUrlByCommunityName(connection, sessionUrl, communityName):
        communityListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl
        communityList = connection.httpGet(url=communityListUrl)

        community = getItemByName(communityList, communityName)
        if community is None:
            raise Exception('Community %s cannot be found.' % communityName)

        stackUrl = "%s/%s/network/stack" % (communityListUrl, community.objectID)
        return stackUrl

    @staticmethod
    def _getRangeListUrl(connection, nodes, pluginName, rangeListType):
        for node in nodes:
            if node.name == pluginName:
                for link in node.links:
                    if link.rel == rangeListType:
                        return link.href.replace('/api/v0/', '')
                else:
                    raise Exception('Plugin %s does not have a rangeList with rangeListType %s' % (pluginName, rangeListType))
            else:
                childrenNodesUrl = None
                for link in node.links:
                    if link.rel == 'childrenList':
                        childrenNodesUrl = normalizeLink(link)
                        break
                if childrenNodesUrl is None:
                    return
                childrenNodes = connection.httpGet(url=childrenNodesUrl)
                return NetworkUtils._getRangeListUrl(connection, childrenNodes, pluginName, rangeListType)

    @staticmethod
    def _getPluginUrl(connection, nodes, pluginName):
        for node in nodes:
            if node.name == pluginName:
                return node._url_
            else:
                childrenNodesUrl = None
                for link in node.links:
                    if link.rel == 'childrenList':
                        childrenNodesUrl = normalizeLink(link)
                        break
                if childrenNodesUrl is None:
                    return
                childrenNodes = connection.httpGet(url=childrenNodesUrl)
                return NetworkUtils._getPluginUrl(connection, childrenNodes, pluginName)

    @staticmethod
    def getParentPluginChildrenUrl(connection, nodes, parentPluginName):
        for node in nodes:
            if node.name == parentPluginName:
                for link in node.links:
                    if link.rel == 'childrenList':
                        return normalizeLink(link)
                else:
                    raise Exception('Plugin %s does not have the childrenList option.' % parentPluginName)
            else:
                childrenNodesUrl = None
                for link in node.links:
                    if link.rel == 'childrenList':
                        childrenNodesUrl = normalizeLink(link)
                        break
                if childrenNodesUrl is None:
                    return
                childrenNodes = connection.httpGet(url=childrenNodesUrl)
                return NetworkUtils.getParentPluginChildrenUrl(connection, childrenNodes, parentPluginName)

    @staticmethod
    def getRangeListUrl(connection, sessionUrl, communityName, pluginName, rangeListType):
        stackUrl = NetworkUtils.getStackUrlByCommunityName(connection, sessionUrl, communityName)
        stack = connection.httpGet(url=stackUrl)
        nodes = [stack]
        rangeListUrl = NetworkUtils._getRangeListUrl(connection, nodes, pluginName, rangeListType)
        if rangeListUrl is None:
            raise Exception('Plugin %s under community %s does not have a rangeList of type %s.' % (pluginName, communityName, rangeListType))
        return rangeListUrl

    @staticmethod
    def getRangeUrl(connection, sessionUrl, communityName, pluginName, rangeListType, rangeName):
        rangeListUrl = NetworkUtils.getRangeListUrl(connection, sessionUrl, communityName, pluginName, rangeListType)
        rangeList = connection.httpGet(url=rangeListUrl)

        r = getItemByName(rangeList, rangeName)
        if r is None:
            raise Exception('Community %s, plugin %s does not have a range named %s.' % (communityName, pluginName, rangeName))
        return '%s/%s' % (rangeListUrl, r.objectID)

    @staticmethod
    def getPluginUrl(connection, sessionUrl, communityName, pluginName):
        stackUrl = NetworkUtils.getStackUrlByCommunityName(connection, sessionUrl, communityName)
        stack = connection.httpGet(url=stackUrl)
        nodes = [stack]
        pluginUrl = NetworkUtils._getPluginUrl(connection, nodes, pluginName)
        if pluginUrl is None:
            raise Exception('Community %s does not have a plugin with the name %s.' % (communityName, pluginName))
        return pluginUrl

    @staticmethod
    def addRange(connection, sessionUrl, communityName, pluginName, rangeListType, rangeOptions):
        rangeListUrl = NetworkUtils.getRangeListUrl(connection, sessionUrl, communityName, pluginName, rangeListType)
        performGenericPost(connection, rangeListUrl, rangeOptions)

    @staticmethod
    def changeRangeOptions(connection, sessionUrl, communityName, pluginName, rangeListType, rangeName, rangeOptions):
        rangeUrl = NetworkUtils.getRangeUrl(connection, sessionUrl, communityName, pluginName, rangeListType, rangeName)
        if rangeUrl is None:
            raise Exception('Invalid range name %s for community %s, plugin %s and rangeListType %s' % (rangeName, communityName, pluginName, rangeListType))
        performGenericPatch(connection, rangeUrl, rangeOptions)

    @staticmethod
    def addPlugin(connection, sessionUrl, communityName, parentPluginName, pluginOptions):
        stackUrl = NetworkUtils.getStackUrlByCommunityName(connection, sessionUrl, communityName)
        stack = connection.httpGet(url=stackUrl)
        nodes = [stack]
        parentPluginChildrenUrl = NetworkUtils.getParentPluginChildrenUrl(connection, nodes, parentPluginName)

        if parentPluginChildrenUrl is None:
            raise Exception('Invalid parent plugin name %s under community %' % (parentPluginName, communityName))
        performGenericPost(connection, parentPluginChildrenUrl, pluginOptions)

    @staticmethod
    def changePluginOptions(connection, sessionUrl, communityName, pluginName, pluginOptions):
        pluginUrl = NetworkUtils.getPluginUrl(connection, sessionUrl, communityName, pluginName)
        performGenericPatch(connection, pluginUrl, pluginOptions)

    @staticmethod
    def deletePlugin(connection, sessionUrl, communityName, pluginName):
        pluginUrl = NetworkUtils.getPluginUrl(connection, sessionUrl, communityName, pluginName)
        performGenericDelete(connection, pluginUrl, {})

    @staticmethod
    def addIpRange(connection, sessionUrl, communityName, pluginName, rangeOptions):
        NetworkUtils.addRange(connection, sessionUrl, communityName, pluginName, 'rangeList', rangeOptions)

    @staticmethod
    def addIpsecPlugin(connection, sessionUrl, communityName, parentPluginName):
        NetworkUtils.addPlugin(connection, sessionUrl, communityName, parentPluginName, {'itemType': 'IPSecPlugin'})


class ActivityNetworkMixinUtils(ActivityUtils, NetworkUtils):
    pass


class HttpUtils(ActivityNetworkMixinUtils):

    @staticmethod
    def enableSSLOnClient(connection, sessionUrl, communityName, activityName):
        options = {"enableSsl": True}
        HttpUtils.changeAgentOptions(connection, sessionUrl, communityName, activityName, options)

    @staticmethod
    def enableSSLOnServer(connection, sessionUrl, communityName, activityName):
        options = {"acceptSslConnections": True}
        HttpUtils.changeAgentOptions(connection, sessionUrl, communityName, activityName, options)


class ImapUtils(ActivityNetworkMixinUtils):

    @staticmethod
    def addImapCommand(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = ImapUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        imapCommandsUrl = '%s/%s/agent/pm/imapCommands' % (activityListUrl, activity.objectID)
        performGenericPost(connection, imapCommandsUrl, optionsDict)

    @staticmethod
    def addImapServerConfigMail(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = ImapUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        imapMailsUrl = '%s/%s/agent/pm/imapServerConfig/mails' % (activityListUrl, activity.objectID)
        performGenericPost(connection, imapMailsUrl, optionsDict)


class IpsecUtils(ActivityNetworkMixinUtils):

    @staticmethod
    def changePortGroupDataOptions(connection, sessionUrl, communityName, pluginName, portGroupDataOptions):
        pluginUrl = IpsecUtils.getPluginUrl(connection, sessionUrl, communityName, pluginName)
        portGroupDataUrl = '%s/%s' % (pluginUrl, 'PortGroupData')
        performGenericPatch(connection, portGroupDataUrl, portGroupDataOptions)

    @staticmethod
    def changeIpsecTunnelSetupOptions(connection, sessionUrl, communityName, pluginName, ipsecTunnelSetupOptions):
        pluginUrl = IpsecUtils.getPluginUrl(connection, sessionUrl, communityName, pluginName)
        ipsecTunnelSetupUrl = '%s/%s' % (pluginUrl, 'SessionData/ipsecTunnelSetup')
        performGenericPatch(connection, ipsecTunnelSetupUrl, ipsecTunnelSetupOptions)


class FtpUtils(ActivityNetworkMixinUtils):

    @staticmethod
    def addFtpCommand(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = FtpUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        ftpCommandsUrl = '%s/%s/agent/actionList' % (activityListUrl, activity.objectID)
        performGenericPost(connection, ftpCommandsUrl, optionsDict)


class DnsUtils(ActivityNetworkMixinUtils):

    @staticmethod
    def addDnsCommand(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = DnsUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        dnsCommandsUrl = '%s/%s/agent/pm/dnsConfig/dnsQueries' % (activityListUrl, activity.objectID)
        performGenericPost(connection, dnsCommandsUrl, optionsDict)


class TftpUtils(ActivityNetworkMixinUtils):

    @staticmethod
    def addTftpCommand(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = TftpUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        tftpCommandsUrl = '%s/%s/agent/pm/cmdList' % (activityListUrl, activity.objectID)
        performGenericPost(connection, tftpCommandsUrl, optionsDict)


class RtspUtils(ActivityNetworkMixinUtils):

    @staticmethod
    def changeRtspCommand(connection, sessionUrl, communityName, activityName, commandName, optionsDict):
        activityListUrl, activity = RtspUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        rtspCommandsUrl = '%s/%s/agent/commandList' % (activityListUrl, activity.objectID)
        rtspCommands = connection.httpGet(rtspCommandsUrl)

        for rtspCommand in rtspCommands:
            if rtspCommand.cmdName == commandName:
                rtspCommandUrl = '%s/%s' % (rtspCommandsUrl, rtspCommand.objectID)
                performGenericPatch(connection, rtspCommandUrl, optionsDict)
                break
        else:
            raise Exception('Community %s, activity %s does not have a command named %s' % (communityName, activityName, commandName))


class VoipPeerUtils(ActivityNetworkMixinUtils):

    @staticmethod
    def changeScenarioSettings(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = VoipPeerUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        scenarioSettingsUrl = '%s/%s/agent/pm/scenarioSettings' % (activityListUrl, activity.objectID)
        performGenericPatch(connection, scenarioSettingsUrl, optionsDict)
