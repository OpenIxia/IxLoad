from __future__ import absolute_import, print_function
import requests
import json
import sys
import pprint
import time
import subprocess
import os
import re

# 200 (OK)
# 201 (OK. Server processed the connection)
# 202 (Accepted)
# 204 (Delete OK). Server successfully processed the request, but is not returning 
#                  any content
# 401 unauthorized
# 403 Forbidden. Authentication failure
# 404 Bad Request (Malformed syntax)
# 405 Not allowed
# 501 and 502 Errors

class IxLoadRestApiException(Exception):pass

class Main():
    def __init__(self, apiServerIp, apiServerIpPort, deleteSession=True):
        self.apiServerIp = apiServerIp
        #self.licenseServerIp = licenseServerIp
        #self.licenseModel = licenseModel
        self.deleteSession = deleteSession
        self.httpHeader = 'http://{0}:{1}'.format(apiServerIp, apiServerIpPort)
        self.jsonHeader = {'content-type': 'application/json'}

        from requests.exceptions import ConnectionError
        from requests.packages.urllib3.connection import HTTPConnection

    def get(self, restApi, data={}, silentMode=False, ignoreError=False):
        """
        Description
           A HTTP GET function to send REST APIs.
        
        Parameters
           restApi: The REST API URL.
           data: The data payload for the URL.
           silentMode: True or False.  To display URL, data and header info.
           ignoreError: True or False.  If False, the response will be returned.
        """
        if silentMode is False:
            print('\nGET:', restApi)
            print('HEADERS:', self.jsonHeader)

        try:
            response = requests.get(restApi, headers=self.jsonHeader)
            if silentMode is False:
                print('STATUS CODE:', response.status_code)
            if not re.match('2[0-9][0-9]', str(response.status_code)):
                if ignoreError == False:
                    raise IxLoadRestApiException('http GET error:{0}\n'.format(response.text))
            return response

        except requests.exceptions.RequestException as errMsg:
            raise IxLoadRestApiException('http GET error: {0}\n'.format(errMsg))

    def post(self, restApi, data={}, headers=None, silentMode=False, ignoreError=False):
        """
        Description
           A HTTP POST function to mainly used to create or start operations.
        
        Parameters
           restApi: The REST API URL.
           data: The data payload for the URL.
           headers: The special header to use for the URL.
           silentMode: True or False.  To display URL, data and header info.
           noDataJsonDumps: True or False. If True, use json dumps. Else, accept the data as-is. 
           ignoreError: True or False.  If False, the response will be returned. No exception will be raised.
        """

        if headers != None:
            originalJsonHeader = self.jsonHeader
            self.jsonHeader = headers

        data = json.dumps(data)

        print('\nPOST:', restApi)
        if silentMode == False:
            print('DATA:', data)
            print('HEADERS:', self.jsonHeader)

        try:
            response = requests.post(restApi, data=data, headers=self.jsonHeader)
            # 200 or 201
            if silentMode == False:
                print('STATUS CODE:', response.status_code)
            if not re.match('2[0-9][0-9]', str(response.status_code)):
                if ignoreError == False:
                    self.showErrorMessage()
                    raise IxLoadRestApiException('http POST error: {0}\n'.format(response.text))

            # Change it back to the original json header
            if headers != None:
                self.jsonHeader = originalJsonHeader

            return response
        except requests.exceptions.RequestException as errMsg:
            raise IxLoadRestApiException('http POST error: {0}\n'.format(errMsg))

    def patch(self, restApi, data={}, silentMode=False):
        """
        Description
           A HTTP PATCH function to modify configurations.
        
        Parameters
           restApi: The REST API URL.
           data: The data payload for the URL.
           silentMode: True or False.  To display URL, data and header info.
        """

        if silentMode == False:
            print('\nPATCH:', restApi)
            print('DATA:', data)
            print('HEADERS:', self.jsonHeader)
        try:
            response = requests.patch(restApi, data=json.dumps(data), headers=self.jsonHeader)
            if silentMode == False:
                print('STATUS CODE:', response.status_code)
            if not re.match('2[0-9][0-9]', str(response.status_code)):
                print('\nPatch error:')
                self.showErrorMessage()
                raise IxLoadRestApiException('http PATCH error: {0}\n'.format(response.text))
            return response
        except requests.exceptions.RequestException as errMsg:
            raise IxLoadRestApiException('http PATCH error: {0}\n'.format(errMsg))

    def delete(self, restApi, data={}, headers=None):
        """
        Description
           A HTTP DELETE function to delete the session.
           For Linux API server only.
        
        Parameters
           restApi: The REST API URL.
           data: The data payload for the URL.
           headers: The header to use for the URL.
        """

        if headers != None:
            self.jsonHeader = headers

        print('\nDELETE:', restApi)
        print('DATA:', data)
        print('HEADERS:', self.jsonHeader)
        try:
            response = requests.delete(restApi, data=json.dumps(data), headers=self.jsonHeader)
            print('STATUS CODE:', response.status_code)
            if not re.match('2[0-9][0-9]', str(response.status_code)):
                self.showErrorMessage()
                raise IxLoadRestApiException('http DELETE error: {0}\n'.format(response.text))
            return response
        except requests.exceptions.RequestException as errMsg:
            raise IxLoadRestApiException('http DELETE error: {0}\n'.format(errMsg))

    def showErrorMessage(self):
        pass

    # CONNECT
    def connect(self, ixLoadVersion):
        # http://10.219.x.x:8080/api/v0/sessions
        response = self.post(self.httpHeader+'/api/v0/sessions', data=({'ixLoadVersion': ixLoadVersion}))
        response = requests.get(self.httpHeader+'/api/v0/sessions')

        pprint.pprint(response.json()[-1])
        sessionId = response.json()[-1]['sessionId']
        self.sessionId = str(sessionId)
        self.sessionIdUrl = self.httpHeader+'/api/v0/sessions/'+self.sessionId+'/'
        response = self.startOperations()
        self.verifyStartOperations(response)

    # START OPERATIONS
    def startOperations(self):
        operationsStartUrl = self.sessionIdUrl+'operations/start'
        response = self.post(operationsStartUrl)
        time.sleep(1)
        return response

    # VERIFY OPERATION START
    def verifyStatus(self, subject, url, statusName, expectedStatus, timeout=90):
        timeout = timeout
        for counter in range(1,timeout+1):
            response = self.get(url)
            print('\nverifyStatus %s: %s\n' % (subject, url))
            for key, value in response.json().items():
                print('%s: %s' % (key, value))

            if response.status_code is 200:
                if counter < timeout and response.json()[statusName] != expectedStatus:
                    print('\t%s: Expecting %s = %s: %s/%d sec' % (subject, statusName, expectedStatus, counter, timeout))
                    time.sleep(1)
                    continue            
                if counter < timeout and response.json()[statusName] == expectedStatus:
                    print('\t%s %s=%s' % (subject, statusName, expectedStatus))
                if counter is timeout and response.json()[statusName] != expectedStatus:
                    raise IxLoadRestApiException('Error: Verify operation start failed')

    # VERIFY STATUS
    def verifyStartOperations(self, response): 
        # deleteSessionId = You could set this to False for debugging.
        
        if response.status_code is 202:
            status = self.verifyStatus('startOperations', self.sessionIdUrl, statusName='isActive', expectedStatus=True)
            if status == 1:
                if self.deleteSession == True: self.deleteSessionId()
                serverId = self.sessionIdUrl.split('/api')[0]
                totalOpenedSessions = self.getTotalOpenedSessions(serverId)
                print('\nFailed: Probable cause:  The REST API Server has %d active opened sessions.' % totalOpenedSessions)
                print('Check your server preference for maximumInstances allowed. Default is 2 maximum allowed.')
                raise IxNetRestApiException('\nFailed. Session ID %s failed to activate' % (self.sessionId))
        else:
            if self.deleteSession == True:
                self.deleteSessionId()
                raise IxLoadRestApiException('\nFailed: operations/start. Status code: %s' % response.status_code)

    # LOAD CONFIG FILE
    def loadConfigFile(self, rxfFile):
        loadTestUrl = self.sessionIdUrl + 'ixLoad/test/operations/loadTest/'
        response = self.post(loadTestUrl, data={'fullPath': rxfFile})
        # http://10.219.117.103:8080/api/v0/sessions/42/ixLoad/test/operations/loadTest/0
        operationsId = response.headers['Location']
        status = self.verifyStatus('loadConfig', self.httpHeader+operationsId, statusName='status', expectedStatus='Successful')
        if status == 1:
            self.deleteSessionId()
            raise IxLoadRestApiException('Error: Load config file failed')

    def configLicensePreferences(self, licenseServerIp, licenseModel='Subscription Mode'):
        """
        licenseModel = 'Subscription Mode' or 'Perpetual Mode'
        """
        self.patch(self.sessionIdUrl+'/ixLoad/preferences',
                   data = {'licenseServer': licenseServerIp, 'licenseModel': licenseModel})

    def refreshConnection(self, objectId):
        url = self.sessionIdUrl+'ixload/chassischain/chassisList/'+str(objectId)+'/operations/refreshConnection'
        self.post(url)

    def addNewChassis(self, chassisIp):
        # Verify if chassisIp exists. If exists, no need to add new chassis.
        url = self.sessionIdUrl+'ixLoad/chassisChain/chassisList'
        response = self.get(url)

        for eachChassisIp in response.json():
            if eachChassisIp['name'] == chassisIp:
                print('\nChassis Ip exists in config. No need to add new chassis')
                objectId = eachChassisIp['objectID']
                return eachChassisIp['id'],objectId

        print('\nChassis IP does not exists')
        print('Adding new chassisIP: %s:\nURL: %s' % (chassisIp, url))
        print('Server synchronous blocking state. Please wait a few seconds ...')
        response = self.post(url, data = {"name": chassisIp})
        objectId = response.headers['Location'].split('/')[-1]
        url = self.sessionIdUrl+'ixload/chassischain/chassislist/'+str(objectId)
        print('\nAdded new chassisIp Object to chainList:', url)
        response = self.get(url)
        pprint.pprint(response.json())
        newChassisId = response.json()['id']
        print('New Chassis ID:', newChassisId)
        self.refreshConnection(objectId=objectId)
        self.waitForChassisIpToConnect(objectId)
        return newChassisId,objectId

    def isChassisIpConnected(self, objectId):
        # Returns True or False
        url = self.sessionIdUrl+'ixload/chassischain/chassisList/'+str(objectId)
        response = self.get(url)
        return response.json()['isConnected']

    def waitForChassisIpToConnect(self, chassisObjectId):
        for counter in range(1,31):
            status = self.isChassisIpConnected(chassisObjectId)
            print('waitForChassisIpToConnect: chassisObjectID:%s : Status is: %s' % (chassisObjectId, status))
            if status == False or status == None:
                print('Wait %s/30 secs' % counter)
                time.sleep(1)
            if status == True:
                print('Chassis objectID %s is connected' % chassisObjectId)
                break
            if counter == 30:
                if status == False or status == None:
                    self.deleteSessionId()
                    raise IxLoadRestApiException("Chassis failed to get connected")

    def assignPorts(self, communityPortListDict):
        '''
        Usage:

        chassisId = Pass in the chassis ID. 
                    If you reassign chassis ID, you must pass in
                    the new chassis ID number.

        communityPortListDict should be passed in as a dictionary
        with Community Names mapping to ports in a tuplie list.
        communityPortListDict = {
           'Traffic0@CltNetwork_0': [(chassisId,1,1)],
           'SvrTraffic0@SvrNetwork_0': [(chassisId,2,1)]
           }
        '''

        communityListUrl = self.sessionIdUrl+'ixLoad/test/activeTest/communityList/'
        communityList = self.get(communityListUrl)

        failedToAddList = []
        communityNameNotFoundList = []
        for eachCommunity in communityList.json():
            # eachCommunity are client side or server side
            currentCommunityObjectId = str(eachCommunity['objectID'])
            currentCommunityName = eachCommunity['name']
            if currentCommunityName not in communityPortListDict:
                print('\nNo such community name found:', currentCommunityName)
                print('\tYour stated communityPortList are:', communityPortListDict)
                communityNameNotFoundList.append(currentCommunityName)
                return 1

            for eachTuplePort in communityPortListDict[currentCommunityName]:
                cardId,portId = eachTuplePort
                params = {'chassisId':chassisId, 'cardId':cardId, 'portId':portId}
                print('\nAssignPorts: {0}: {1}'.format(eachTuplePort, params))
                url = communityListUrl+str(currentCommunityObjectId)+'/network/portList'
                response = self.post(url, data=params, ignoreError=True)
                if response.status_code != 201:
                    failedToAddList.append((chassisId,cardId,portId))

        if failedToAddList == []:
            return 0
        else:
            raise IxLoadRestApiException('\nFailed to add ports:', failedToAddList)
            

    def assignChassisAndPorts(self, communityPortListDict):
        '''
        Usage:

        chassisId = Pass in the chassis ID. 
                    If you reassign chassis ID, you must pass in
                    the new chassis ID number.

        communityPortListDict should be passed in as a dictionary
        with Community Names mapping to ports in a tuplie list.
        communityPortListDict = {
           'Traffic0@CltNetwork_0': [(chassisId,1,1)],
           'SvrTraffic0@SvrNetwork_0': [(chassisId,2,1)]
           }
        '''

        # Assign Chassis
        chassisIp = communityPortListDict['chassisIp']
        newChassisId, newChassisObject = self. addNewChassis(chassisIp)
        print('New Chassis objectID:', newChassisObject)

        # Assign Ports
        communityListUrl = self.sessionIdUrl+'ixLoad/test/activeTest/communityList/'
        communityList = self.get(communityListUrl)

        self.refreshConnection(newChassisObject)
        time.sleep(1)
        self.waitForChassisIpToConnect(newChassisObject)

        failedToAddList = []
        communityNameNotFoundList = []
        for eachCommunity in communityList.json():
            currentCommunityObjectId = str(eachCommunity['objectID'])
            currentCommunityName = eachCommunity['name']
            if currentCommunityName not in communityPortListDict:
                print('\nNo such community name found in your stated list:', currentCommunityName)
                print('\tYour stated list:', communityPortListDict)
                communityNameNotFoundList.append(currentCommunityName)
                print('\nassignChassisAndPorts failed: communityNameNotFound:', currentCommunityName)

            if communityNameNotFoundList == []:
                for eachTuplePort in communityPortListDict[currentCommunityName]:
                    # Going to ignore user input chassisId. When calling addNewChassis(),
                    # it will verify for chassisIp exists. If exists, it will return the
                    # right chassisID.
                    cardId,portId = eachTuplePort
                    params = {"chassisId":int(newChassisId), "cardId":cardId, "portId":portId}
                    url = communityListUrl+str(currentCommunityObjectId)+'/network/portList'
                    print('assignChassisAndPorts URL:', url)
                    print('assignChassisAndPorts Params:', json.dumps(params))
                    response = self.post(url, data=params, ignoreError=True)
                    if response.status_code != 201:
                        portAlreadyConnectedMatch = re.search('.*has already been assigned.*', response.json()['error'])
                        if portAlreadyConnectedMatch:
                            print('%s/%s is already assigned' % (cardId,portId))
                        else:
                            failedToAddList.append((newChassisId,cardId,portId))
                            print('\nassignChassisAndPorts failed', response.text)

        if communityNameNotFoundList != []:
            raise IxLoadRestApiException
        if failedToAddList != []:
            if self.deleteSession:
                self.abortActiveTest()
            raise IxLoadRestApiException('\nFailed to add ports to chassisIp %s: %s:' % (chassisIp, failedToAddList))

    # ENABLE FORCE OWNERSHIP
    def enableForceOwnership(self):
        url = self.sessionIdUrl+'ixLoad/test/activeTest'
        response = self.patch(url, data={'enableForceOwnership': True})

    # GET STAT NAMES
    def getStatNames(self):
        statsUrl = self.sessionIdUrl+'ixLoad/stats'
        print('\ngetStatNames: %s\n' % statsUrl)
        response = self.get(statsUrl)
        for eachStatName in response.json()['links']:
            print('\t', eachStatName['href'])
        return response.json()

    # DISABLE ALL STATS
    def disableAllStats(self, configuredStats):
        configuredStats = self.sessionIdUrl + configuredStats
        response = self.patch(configuredStats, data={"enabled":False})
                              
    # ENABLE CERTAIN STATS
    def enableConfiguredStats(self, configuredStats, statNameList):
        '''
        Notes: Filter queries
        .../configuredStats will re-enable all stats 
        .../configuredStats/15 will only enable the stat with object id = 15 
        .../configuredStats?filter="objectID le 10" will only enable stats with object id s lower or equal to 10 
        .../configuredStats?filter="caption eq FTP" will only enable stats that contain FTP in their caption name
        '''
        for eachStatName in statNameList:
            configuredStats = configuredStats + '?filter="caption eq %s"' % eachStatName
            print('\nEnableConfiguredStats:', configuredStats)
            response = self.patch(configuredStats, data={"enabled": True})

    def showTestLogs(self):
        testLogUrl = self.sessionIdUrl+'/ixLoad/test/logs'
        currentObjectId = 0
        while True:
            response = self.get(testLogUrl)
            for eachLogEntry in response.json():
                if currentObjectId != eachLogEntry['objectID']:
                    currentObjectId = eachLogEntry['objectID']
                    print('\t{time}: Severity:{severity} ModuleName:{2} {3}'.format(eachLogEntry['timeStamp'],
                                                                                    eachLogEntry['severity'],
                                                                                    eachLogEntry['moduleName'],
                                                                                    eachLogEntry['message']))

    # RUN TRAFFIC
    def runTraffic(self):
        runTestUrl = self.sessionIdUrl+'ixLoad/test/operations/runTest'
        response = self.post(runTestUrl)
        operationsId = response.headers['Location']
        return operationsId.split('/')[-1] ;# Return the number only

    def runTrafficAndVerifySuccess(self):
        runTestOperationsId = self.runTraffic()
        if runTestOperationsId == 'failed':
            self.deleteSessionId()
            raise IxLoadRestApiException('\nError: Traffic failed to run')
        self.waitForTestStatusToRunSuccessfully(runTestOperationsId)
        return runTestOperationsId

    # GET TEST STATUS
    def getTestStatus(self, operationsId):
        '''
        status = "Not Started|In Progress|successful"
        state  = "executing|finished"
        '''
        testStatusUrl = self.sessionIdUrl+'ixLoad/test/operations/runTest/'+str(operationsId)
        response = self.get(testStatusUrl)
        return response

    def getActiveTestCurrentState(self, silentMode=False):
        # currentState: Configuring, Starting Run, Running, Stopping Run, Cleaning, Unconfigured 
        url = self.sessionIdUrl+'ixLoad/test/activeTest'
        response = self.get(url, silentMode=silentMode)
        if response.status_code == 200:
            return response.json()['currentState']

    # GET STATS
    def getStats(self, statUrl):
        response = self.get(statUrl, silentMode=True)
        return response

    def pollStats(self, statsDict, pollStatInterval=2, csvFile=False, csvEnableFileTimestamp=False, csvFilePrependName=None):
        '''
        sessionIdUrl = http://192.168.70.127:8080/api/v0/sessions/20

        statsDict = 
            This API will poll stats based on the dictionary statsDict that you passed in.
            Example how statsDict should look like:

            statsDict = {
                'HTTPClient': ['TCP Connections Established',
                               'HTTP Simulated Users',
                               'HTTP Concurrent Connections',
                               'HTTP Connections',
                               'HTTP Transactions',
                               'HTTP Connection Attempts'
                           ],
                'HTTPServer': ['TCP Connections Established',
                               'TCP Connection Requests Failed'
                           ]
            }
 
            The exact name of the above stats could be found on REST API or by doing a ScriptGen on the GUI.
            If doing by ScriptGen, do a wordsearch for "statlist".  Copy and Paste the stats that you want.

        RETURN 1 if there is an error.

        csvFile: To enable or disable recording stats on csv file: True or False

        csvEnableFileTimestamp: To append a timestamp on the csv file so they don't overwrite each other: True or False

        csvFilePrependName: To prepend a name of your choice to the csv file for visual identification and if you need 
                            to restart the test, a new csv file will be created. Prepending a name will group the csv files.
        '''

        if csvFile:
            import csv
            csvFilesDict = {}
            for key in statsDict.keys():
                fileName = key
                if csvFilePrependName:
                    fileName = csvFilePrependName+'_'+fileName
                csvFilesDict[key] = {}

                if csvEnableFileTimestamp:
                    import datetime
                    timestamp = datetime.datetime.now().strftime('%H%M%S')
                    fileName = fileName+'_'+timestamp

                fileName = fileName+'.csv'
                csvFilesDict[key]['filename'] = fileName
                csvFilesDict[key]['columnNameList'] = []
                csvFilesDict[key]['fileObj'] = open(fileName, 'w')
                csvFilesDict[key]['csvObj'] = csv.writer(csvFilesDict[key]['fileObj'])

            # Create the csv top row column name list
            for key,values in statsDict.items():        
                for columnNames in values:
                    csvFilesDict[key]['columnNameList'].append(columnNames)
                csvFilesDict[key]['csvObj'].writerow(csvFilesDict[key]['columnNameList'])

        waitForRunningStatusCounter = 0
        waitForRunningStatusCounterExit = 20
        while True:
            currentState = self.getActiveTestCurrentState(silentMode=True)
            print('\nActiveTest current status:', currentState)
            if currentState == 'Running':
                # statType:  HTTPClient or HTTPServer (Just a example using HTTP.)
                # statNameList: transaction success, transaction failures, ...
                for statType,statNameList in statsDict.items():
                    print('\n%s:' % statType)
                    statUrl = self.sessionIdUrl+'/ixLoad/stats/'+statType+'/values'
                    response = self.getStats(statUrl)
                    highestTimestamp = 0
                    # Each timestamp & statnames: values                
                    for eachTimestamp,valueList in response.json().items():
                        if eachTimestamp == 'error':
                            raise IxLoadRestApiException('\npollStats error: Probable cause: Misconfigured stat names to retrieve.')

                        if int(eachTimestamp) > highestTimestamp:
                            highestTimestamp = int(eachTimestamp)
                    if highestTimestamp == 0:
                        time.sleep(3)
                        continue

                    if csvFile:
                        csvFilesDict[statType]['rowValueList'] = []

                    # Get the interested stat names only
                    for statName in statNameList:
                        if statName in response.json()[str(highestTimestamp)]:
                            statValue = response.json()[str(highestTimestamp)][statName]
                            print('\t%s: %s' % (statName, statValue))
                            if csvFile:
                                csvFilesDict[statType]['rowValueList'].append(statValue)
                        else:
                            print('\tStat name not found. Check spelling and case sensitivity:', statName)

                    if csvFile:
                        if csvFilesDict[statType]['rowValueList'] != []:
                            csvFilesDict[statType]['csvObj'].writerow(csvFilesDict[statType]['rowValueList']) 

                time.sleep(pollStatInterval)
            elif currentState == "Unconfigured":
                break
            else:
                # If currentState is "Stopping Run" or Cleaning
                if waitForRunningStatusCounter < waitForRunningStatusCounterExit:
                    waitForRunningStatusCounter += 1
                    print('\tWaiting {0}/{1} seconds'.format(waitForRunningStatusCounter, waitForRunningStatusCounterExit))
                    time.sleep(1)
                    continue
                if waitForRunningStatusCounter == waitForRunningStatusCounterExit:
                    return 1

        if csvFile:
            for key in statsDict.keys():
                csvFilesDict[key]['fileObj'].close()

    def waitForTestStatusToRunSuccessfully(self, runTestOperationsId):
        timer = 180
        for counter in range(1,timer+1):
            response = self.getTestStatus(runTestOperationsId)
            currentStatus = response.json()['status']
            print('waitForTestStatusToRunSuccessfully %s/%s secs:\n\tCurrentTestStatus: %s\n\tExpecting: Successful' % (
                counter, str(timer), currentStatus))
            if currentStatus == 'Error':
                return 1
            if currentStatus != 'Successful' and counter < timer:
                time.sleep(1)
                continue
            if currentStatus == 'Successful' and counter < timer:
                return 0
            if currentStatus != 'Successful' and counter == timer:
                raise IxLoadRestApiException('\nTest status failed to run')


    def waitForActiveTestToUnconfigure(self):
        ''' Wait for the active test state to be Unconfigured '''
        print()
        for counter in range(1,31):
            currentState = self.getActiveTestCurrentState()
            print('waitForActiveTestToUnconfigure current state:', currentState)
            if counter < 30 and currentState != 'Unconfigured':
                print('ActiveTest current state = %s\nWaiting for state = Unconfigued: Wait %s/30' % (currentState, counter))
                time.sleep(1)
            if counter < 30 and currentState == 'Unconfigured':
                print('\nActiveTest is Unconfigured')
                return 0
            if counter == 30 and currentState != 'Unconfigured':
                raise IxLoadRestApiException('\nActiveTest is stuck at:', currentState)

    def applyConfiguration(self):
        # Apply the configuration.
        # If applying configuration failed, you have the option to keep the 
        # sessionId alive for debugging or delete it.

        url = self.sessionIdUrl+'ixLoad/test/operations/applyconfiguration'
        response = self.post(url, ignoreError=True)
        if response.status_code != 202:
            if self.deleteSession:
                self.deleteSessionId()
                raise IxLoadRestApiException('\napplyConfiguration failed')

        operationsId = response.headers['Location']
        operationsId = operationsId.split('/')[-1] ;# Return the number only
        url = url+'/'+str(operationsId)

        for counter in range(1,31):
            response = self.get(url)
            currentState = response.json()['status']
            print('\nApplyConfiguration current state:', currentState)
            if counter < 30 and currentState != 'Successful':
                print('\tWaiting for state = Successful: Wait %s/30' % (counter))
                time.sleep(1)
                continue
            if counter < 30 and currentState == 'Successful':
                print('\nApplyConfiguation = success')
                return 0
            if counter == 30 and currentState != 'Successful':
                raise IxLoadRestApiException('\nApplyConfiguration is stuck at:', currentState)

    def saveConfiguration(self):
        url = self.sessionIdUrl+'ixLoad/test/operations/save'
        print('\nsaveConfiguration:', url)
        response = self.post(url)

    def abortActiveTest(self):
        url = self.sessionIdUrl+'ixLoad/test/operations/abortAndReleaseConfigWaitFinish'
        response = self.post(url, ignoreError=True)
        if response.status_code != 202:
            self.deleteSessionId()
            raise IxLoadRestApiException('abortActiveTest Warning failed')
        else:
            # Verify until success
            objectId = response.headers['Location']
            objectId = objectId.split('/')[-1]
            for counter in range(1,11):
                response = self.get(url+'/'+str(objectId))
                # status=Successful state=finished
                status = response.json()['status']
                state = response.json()['state']
                if counter < 30 and status != 'Successful':
                    print('Aborting activeTest status: %s. Wait %s/30' % (status, counter))
                    time.sleep(1)
                if counter < 30 and status == 'Successful':
                    print('Successfully aborted active test')
                    break
                if counter == 30 and status != 'Successful':
                    raise IxLoadRestApiException('Aborting test is stuck unsuccessfully')
                time.sleep(1)

    def deleteSessionId(self):
        response = self.delete(self.sessionIdUrl)

    def getMaximumInstances(self):
        response = self.get(self.sessionIdUrl+'/ixLoad/preferences')
        maxInstances = response.json()['maximumInstances']
        print('\ngetMaximumInstances:', maxInstances)
        return int(maxInstances)

    def getTotalOpenedSessions(self, serverId):
        # serverId: 'http://192.168.70.127:8080'
        # Returns: Total number of opened active and non-active sessions.

        response = self.get(serverId+'/api/v0/sessions')
        counter = 1
        activeSessionCounter = 0
        print()
        for eachOpenedSession in response.json():
            print('\t%d: Opened sessionId: %s' % (counter, serverId+eachOpenedSession['links'][0]['href']))
            print('\t      isActive:', eachOpenedSession['isActive'])
            print('\t      activeTime:', eachOpenedSession['activeTime'])
            counter += 1
            if eachOpenedSession['isActive'] == True:
                activeSessionCounter += 1

        return activeSessionCounter

    def uploadFile(self, localPathAndFilename, ixLoadSvrPathAndFilename, overwrite=True):
        """
        Description
           For Linux server only.  You need to upload the config file into the Linux
           server location first: /mnt/ixload-share 

        Parameters
           localPathAndFilename:     The config file on the local PC path to be uploaded.
           ixLoadSvrPathandFilename: Default path on the Linux REST API server is '/mnt/ixload-share'
                                     Ex: '/mnt/ixload-share/IxL_Http_Ipv4Ftp_vm_8.20.rxf'

        """
        url = self.httpHeader+'/api/v0/resources'
        headers = {'Content-Type': 'multipart/form-data'}
        params = {'overwrite': overwrite, 'uploadPath': ixLoadSvrPathAndFilename}
        #filename = ixLoadSvrPathAndFilename.split('/')[-1]

        print('\nUploadFile: {0} file to {1}...'.format(localPathAndFilename, ixLoadSvrPathAndFilename))
        try:
            with open(localPathAndFilename, 'rb') as f:
                response = requests.post(url, data=f, params=params, headers=headers)
                if response.status_code != 200:
                    raise IxLoadRestApiException('\nuploadFile failed', response.json()['text'])
        except requests.exceptions.ConnectionError as e:
            raise IxLoadRestApiException(
                'Upload file failed. Received connection error. One common cause for this error is the size of the file to be uploaded.'
                ' The web server sets a limit of 1GB for the uploaded file size. Received the following error: %s' % str(e)
            )
        except IOError as e:
            raise IxLoadRestApiException('Upload file failed. Received IO error: %s' % str(e))
        except Exception:
            raise IxLoadRestApiException('Upload file failed. Received the following error: %s' % str(e))
        else:
            print('Upload file finished.')
            print('Response status code %s' % response.status_code)
            print('Response text %s' % response.text)

