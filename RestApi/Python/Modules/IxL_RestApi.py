"""
By Hubert Gee


"""

from __future__ import absolute_import, print_function
import requests
import json
import sys
import pprint
import time
import subprocess
import os
import re
import datetime

class IxLoadRestApiException(Exception):
    def __init__(self, msg=None):
        showErrorMsg = '\nIxLoadRestApiException error: {0}\n\n'.format(msg)
        print(showErrorMsg)
        if Main.enableDebugLogFile:
            with open(Main.debugLogFile, 'a') as restLogFile:
                restLogFile.write(showErrorMsg)


class Main():
    debugLogFile = None
    enableDebugLogFile = False

    def __init__(self, apiServerIp, apiServerIpPort, useHttps=False, apiKey=None, verifySsl=False, deleteSession=True,
                 osPlatform='windows', generateRestLogFile='ixLoadRestApiLog.txt', robotFrameworkStdout=False):
        """
        Description
           Initialize the class variables
        
        Parameters
           apiServerIp: <str>: The IP address of the IxLoad API server.
           apiServerIpPort: <str>: The API server port. Default = 8080.
           apiKey: <str>: The apiKey to use for authentication. You only need this if you
                          enabled "enabled authentication on IxLoadGateway" during installation.
                          Then, get the apiKey from IxLoad GUI, Preferences, General, API-Key.
           osPlatform: <str>: windows or linux
           deleteSession: <bool>: True = Delete the session after test is done.
           generateRestLogFile: <bool>: True = generate a complete log file.
                                Filename = ixLoadRestApiLog.txt
           robotFrameworkStdout: <bool>: True = Display print statements on stdout.
        """
        from requests.exceptions import ConnectionError
        from requests.packages.urllib3.connection import HTTPConnection

        # Disable SSL warnings
        requests.packages.urllib3.disable_warnings()

        # Disable non http connections.
        from requests.packages.urllib3.exceptions import InsecureRequestWarning
        requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

        self.osPlatform = osPlatform

        if apiServerIpPort == 8443:
            httpHead = 'https'
        else:
            httpHead = 'http'

        self.apiServerIp = apiServerIp
        self.deleteSession = deleteSession
        self.httpHeader = '{0}://{1}:{2}'.format(httpHead, apiServerIp, apiServerIpPort)
        self.jsonHeader = {'content-type': 'application/json'}
        self.verifySsl = verifySsl
        self.generateRestLogFile = generateRestLogFile
        self.robotFrameworkStdout = robotFrameworkStdout
        Main.debugLogFile = self.generateRestLogFile
        Main.enableDebugLogFile = self.generateRestLogFile

        if apiKey:
            self.apiKey = apiKey
            self.jsonHeader.update({'X-Api-Key': self.apiKey})

        if self.robotFrameworkStdout:
            from robot.libraries.BuiltIn import _Misc
            self.robotLogger = _Misc()

        # GenerateRestLogFile could be a filename or boolean
        # If True, create default log file name: restApiLog.txt
        if generateRestLogFile:
            if type(generateRestLogFile) == bool and generateRestLogFile == True:
                # Default the log file name since user didn't provide a log file name.
                self.restLogFile = 'ixLoadRestApiLog'
                Main.debugLogFile = self.restLogFile

            # User provided a log file name.
            if type(generateRestLogFile) != bool:
                self.restLogFile = generateRestLogFile

            # Instantiate a new log file here.
            with open(self.restLogFile, 'w') as restLogFile:
                restLogFile.write('')

    # CONNECT
    def connect(self, ixLoadVersion=None, sessionId=None, timeout=90):
        """
        For new session, provide the ixLoadVersion.
        If connecting to an existing session, provide the sessionId
        """
        self.ixLoadVersion = ixLoadVersion

        # http://10.219.x.x:8080/api/v0/sessions
        if sessionId is None:
            response = self.post(self.httpHeader+'/api/v0/sessions', data=({'ixLoadVersion': ixLoadVersion}))
            response = requests.get(self.httpHeader+'/api/v0/sessions', verify=self.verifySsl)

            try:
                sessionId = response.json()[-1]['sessionId']
            except:
                raise IxLoadRestApiException('connect failed. No sessionId created')

        self.sessionId = str(sessionId)
        self.sessionIdUrl = self.httpHeader+'/api/v0/sessions/'+self.sessionId

        # Start operations
        if ixLoadVersion is not None:
            response = self.post(self.sessionIdUrl+'/operations/start')

            self.logInfo('\n\n', timestamp=False)
            for counter in range(1, timeout+1):
                response = self.get(self.sessionIdUrl)
                currentStatus = response.json()['isActive']

                self.logInfo('\tCurrentStatus: {0}'.format(currentStatus), timestamp=False)
                if counter < timeout and currentStatus != True:
                    self.logInfo('\tWait {0}/{1} seconds'.format(counter, timeout), timestamp=False)
                    time.sleep(1)
                    continue

                if counter < timeout and currentStatus == True:
                    break

                if counter == timeout and currentStatus != True:
                    raise IxLoadRestApiException('New session ID failed to become active')

    def logInfo(self, msg, end='\n', timestamp=True):
        """
        Description
           An internal function to print info to stdout
        
        Parameters
           msg: (str): The message to print.
        """
        currentTime = self.getTime()

        if timestamp:
            msg = '\n' + currentTime + ': ' + msg
        else:
            # No timestamp and no newline are mainly for verifying states and status
            msg = msg

        print('{0}'.format(msg), end=end)
        if self.generateRestLogFile != False:
            with open(self.restLogFile, 'a') as restLogFile:
                restLogFile.write(msg+end)

        if self.robotFrameworkStdout:
            self.robotLogger.log_to_console(msg)

    def getTime(self):
        """
        Returns: 13:31:44.083426
        """
        dateAndTime = str(datetime.datetime.now()).split(' ')
        return dateAndTime[1]

    def logError(self, msg, end='\n', timestamp=True):
        """
        Description
           An internal function to print error to stdout.
        
        Parameter
           msg: (str): The message to print.
        """
        currentTime = self.getTime()

        if timestamp:
            msg = '\n{0}: Error: {1}'.format(currentTime, msg)
        else:
            # No timestamp and no newline are mainly for verifying states and status
            msg = '\nError: {0}'.format(msg)

        print('{0}'.format(msg), end=end)
        if self.generateRestLogFile:
            with open(self.restLogFile, 'a') as restLogFile:
                restLogFile.write('Error: '+msg+end)

        if self.robotFrameworkStdout:
            self.robotStdout.log_to_console(msg)

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
            self.logInfo('\n\tGET: {0}\n\tHEADERS: {1}'.format(restApi, self.jsonHeader))

        try:
            
            response = requests.get(restApi, headers=self.jsonHeader, verify=self.verifySsl)
            if silentMode is False:
                self.logInfo('\tSTATUS CODE: %s' % response.status_code, timestamp=False)

            if not str(response.status_code).startswith('2'):
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

        if silentMode == False:
            self.logInfo('\n\tPOST: {0}\n\tDATA: {1}\n\tHEADERS: {2}'.format(restApi, data, self.jsonHeader))

        try:
            response = requests.post(restApi, data=data, headers=self.jsonHeader, verify=self.verifySsl)
            # 200 or 201
            if silentMode == False:
                self.logInfo('\tSTATUS CODE: %s' % response.status_code, timestamp=False)

            if not str(response.status_code).startswith('2'):
                if ignoreError == False:
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
            self.logInfo('\n\tPATCH: {0}\n\tDATA: {1}\n\tHEADERS: {2}'.format(restApi, data, self.jsonHeader))

        try:
            response = requests.patch(restApi, data=json.dumps(data), headers=self.jsonHeader, verify=self.verifySsl)
            if silentMode == False:
                self.logInfo('\tSTATUS CODE: %s' % response.status_code, timestamp=False)

            if not str(response.status_code).startswith('2'):
                self.logError('Patch error:')
                raise IxLoadRestApiException('http PATCH error: {0}\n'.format(response.text))
            return response
        except requests.exceptions.RequestException as errMsg:
            raise IxLoadRestApiException('http PATCH error: {0}\n'.format(errMsg))

    def delete(self, restApi, data={}, headers=None, silentMode=False):
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

        if silentMode == False:
            self.logInfo('\n\tDELETE: {0}\n\tDATA: {1}\n\tHEADERS: {2}'.format(restApi, data, self.jsonHeader))

        try:
            response = requests.delete(restApi, data=json.dumps(data), headers=self.jsonHeader, verify=self.verifySsl)
            self.logInfo('\tSTATUS CODE: %s' % response.status_code, timestamp=False)

            if not str(response.status_code).startswith('2'):
                raise IxLoadRestApiException('http DELETE error: {0}\n'.format(response.text))
            return response
        except requests.exceptions.RequestException as errMsg:
            raise IxLoadRestApiException('http DELETE error: {0}\n'.format(errMsg))


    # VERIFY OPERATION START
    def verifyStatus(self, url, timeout=120):
        timeout = timeout
        for counter in range(1,timeout+1):
            response = self.get(url)

            #print('\n\tverifyStatus:', response.json())
            if 'status' in response.json():
                currentStatus = response.json()['status']
            elif 'state' in response.json():
                currentStatus = response.json()['state']
                if currentStatus == 'Error':
                    errorMessage = 'Operation failed'
                    if 'message' in response.json():
                        errorMessage = response.json()['message']
                        raise IxLoadRestApiException('verifyStatus failed: {}'.format(errorMessage))
            else:
                raise IxLoadRestApiException('verifyStatus failed: No status and no state in json response')

            if currentStatus == 'Error' and 'error' in response.json():
                errorMessage = response.json()['error']
                raise IxLoadRestApiException('Operation failed: {0}'.format(errorMessage))

            if counter < timeout and currentStatus not in ['Successful']:
                self.logInfo('\tCurrent status: {0}. Wait {1}/{2} seconds...'.format(currentStatus, counter, timeout),
                             timestamp=False)
                time.sleep(1)
                continue
 
            if counter < timeout and currentStatus in ['Successful']:
                return

            if counter == timeout and currentStatus not in ['Successful']:
                raise IxLoadRestApiException('Operation failed: {0}'.format(url))

    # LOAD CONFIG FILE
    def loadConfigFile(self, rxfFile):
        loadTestUrl = self.sessionIdUrl + '/ixLoad/test/operations/loadTest/'
        response = self.post(loadTestUrl, data={'fullPath': rxfFile})
        # http://10.219.117.103:8080/api/v0/sessions/42/ixLoad/test/operations/loadTest/0
        operationsId = response.headers['Location']
        status = self.verifyStatus(self.httpHeader+operationsId)

    def importCrfFile(self, crfFile, localCrfFileToUpload=None):
        """
        1> Upload the local crfFile to the gateway server.
        2> Import the .crf config file, which will decompress the .rxf and .tst file.

        Parameters
           crfFile: The crfFile path either on the gateway server already or the path to put on the gateway server.
                    If path is c:\\VoIP\\config.crf, then this method will add a timestamp folder in
                    c:\\VoIP -> c:\\VoIP\\12-14-36-944630\\config.crf

           localCrfFileToUpload: If the .crf file is located in a remote Linux, provide the path.
                    Example: /home/hgee/config.crf
        """
        timestampFolder = str(self.getTime()).replace(':', '-').replace('.', '-')

        if self.osPlatform == 'windows':
            filename = crfFile.split('\\')[-1]
            pathOnServer = crfFile.split('\\')[:-1]

        if self.osPlatform == 'linux':
            filename = crfFile.split('/')[-1]
            pathOnServer = crfFile.split('/')[:-1]
            pathOnServer = [x for x in pathOnServer if x != '']

        pathOnServer.append(timestampFolder) ;# [c:, VoIP, 13-08-28-041835]
        self.importConfigPath = pathOnServer

        # To delete these timestamp folders after the test is done.
        if self.osPlatform == 'linux':
            self.importConfigPath = '/'.join(self.importConfigPath)

        if self.osPlatform == 'windows':
            self.importConfigPath = '\\'.join(self.importConfigPath)

        pathOnServer.append(filename) ;# [c:, VoIP, 13-08-28-041835, VoLTE_S1S11_1UE_2APNs_8.50.crf]

        if self.osPlatform == 'windows':
            pathOnServer = '\\'.join(pathOnServer) ;# c:\\VoIP\\13-08-28-041835\\VoLTE_S1S11_1UE_2APNs_8.50.crf
            srcFile = pathOnServer

        if self.osPlatform == 'linux':
            pathOnServer = '/'.join(pathOnServer) ;# /mnt/ixload-share/13-08-28-041835/VoLTE_S1S11_1UE_2APNs_8.50.crf
            pathOnServer = '/'+pathOnServer
            srcFile = pathOnServer

        self.uploadFile(localCrfFileToUpload, pathOnServer)
        destRxf = srcFile.replace('crf', 'rxf')
        loadTestUrl = self.sessionIdUrl + '/ixLoad/test/operations/importConfig/'    
        self.logInfo('\nimportConfig: srcFile: {}   destRxf: {}'.format(srcFile, destRxf))
        response = self.post(loadTestUrl, data={'srcFile': srcFile, 'destRxf': destRxf})
        operationsId = response.headers['Location']
        status = self.verifyStatus(self.httpHeader+operationsId)

    def deleteImportConfigFolder(self):
        try:
            sshClient = ConnectSSH(host, username, password)
            sshClient.ssh()
            stdout = sshClient.enterCommand('rm -rf /mnt/ixload-share/Results/17-12-20-089862')
            print(stdout)
            
        except paramiko.ssh_exception.NoValidConnectionsError as errMsg:
            print('\nSSH connection failed: {}'.format(errMsg))

    def configLicensePreferences(self, licenseServerIp, licenseModel='Subscription Mode'):
        """
        licenseModel = 'Subscription Mode' or 'Perpetual Mode'
        """
        self.patch(self.sessionIdUrl+'/ixLoad/preferences',
                   data = {'licenseServer': licenseServerIp, 'licenseModel': licenseModel})

    def refreshConnection(self, locationUrl):
        url = self.httpHeader+locationUrl+'/operations/refreshConnection'
        response = self.post(url)
        self.verifyStatus(self.httpHeader + response.headers['location'])

    def addNewChassis(self, chassisIpList):
        """
        Add a chassis to connect to.  If you have multiple chassis's, put them
        in a list.

        Parameter
           chassisIp: <list>:  One or more chassis IP addresses in a list.
        """
        if type(chassisIpList) == str:
            chassisIpList = chassisIpList.split(' ')

        self.logInfo('addNewChassis: {}'.format(chassisIpList))
        for chassisIp in chassisIpList:
            # Verify if chassisIp exists. If exists, no need to add new chassis.
            url = self.sessionIdUrl+'/ixLoad/chassisChain/chassisList'
            response = self.get(url)

            for eachChassisIp in response.json():
                if eachChassisIp['name'] == chassisIp:
                    self.logInfo('\naddNewChassis: Chassis Ip exists in config. No need to add new chassis')
                    objectId = eachChassisIp['objectID']
                    # /api/v0/sessions/10/ixLoad/chassisChain/chassisList/1/docs
                    return eachChassisIp['id'], eachChassisIp['links'][0]['href'].replace('/docs', '')

            self.logInfo('addNewChassis: Chassis IP does not exists')
            self.logInfo('addNewChassis: Adding new chassisIP: %s:\nURL: %s' % (chassisIp, url))
            self.logInfo('addNewChassis: Server synchronous blocking state. Please wait a few seconds ...')
            response = self.post(url, data = {"name": chassisIp})
            objectId = response.headers['Location'].split('/')[-1]

            # /api/v0/sessions/2/ixLoad/chassisChain/chassisList/0
            locationUrl = response.headers['Location']

            self.logInfo('\nAddNewChassis: locationUrl: %s' % locationUrl)
            url = self.httpHeader+locationUrl
            self.logInfo('\nAdded new chassisIp Object to chainList: %s' % url)
            response = self.get(url)
            newChassisId = response.json()['id']
            self.logInfo('\naddNewChassis: New Chassis ID: %s' % newChassisId)
            self.refreshConnection(locationUrl=locationUrl)
            self.waitForChassisIpToConnect(locationUrl=locationUrl)

            return newChassisId,locationUrl

    def waitForChassisIpToConnect(self, locationUrl):
        timeout = 60
        for counter in range(1,timeout+1):
            response = self.get(self.httpHeader+locationUrl, ignoreError=True)
            self.logInfo('waitForChassisIpToConnect response: {}'.format(response.json()))
            if 'status' in response.json() and 'Request made on a locked resource' in response.json()['status']:
                self.logInfo('API server response: Request made on a locked resource. Retrying %s/%d secs' % (counter, timeout))
                time.sleep(1)
                continue

            status = response.json()['isConnected']
            self.logInfo('waitForChassisIpToConnect: Status: %s' % (status), timestamp=False)
            if status == False or status == None:
                self.logInfo('Wait %s/%d secs' % (counter, timeout), timestamp=False)
                time.sleep(1)

            if status == True:
                self.logInfo('Chassis is connected', timestamp=False)
                break

            if counter == timeout:
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
        communityListUrl = self.sessionIdUrl+'/ixLoad/test/activeTest/communityList/'
        communityList = self.get(communityListUrl)

        failedToAddList = []
        communityNameNotFoundList = []
        for eachCommunity in communityList.json():
            # eachCommunity are client side or server side
            currentCommunityObjectId = str(eachCommunity['objectID'])
            currentCommunityName = eachCommunity['name']
            if currentCommunityName not in communityPortListDict:
                self.logInfo('\nNo such community name found: %s' % currentCommunityName)
                self.logInfo('\tYour stated communityPortList are: %s' % communityPortListDict, timestamp=False)
                communityNameNotFoundList.append(currentCommunityName)
                return 1

            for eachTuplePort in communityPortListDict[currentCommunityName]:
                chassisId,cardId,portId = eachTuplePort
                params = {'chassisId':chassisId, 'cardId':cardId, 'portId':portId}
                self.logInfo('\nAssignPorts: {0}: {1}'.format(eachTuplePort, params))
                url = communityListUrl+str(currentCommunityObjectId)+'/network/portList'
                response = self.post(url, data=params, ignoreError=True)
                if response.status_code != 201:
                    failedToAddList.append((chassisId,cardId,portId))

        if failedToAddList == []:
            return 0
        else:
            raise IxLoadRestApiException('Failed to add ports:', failedToAddList)

    def assignChassisAndPorts(self, communityPortListDict):
        """
        Assign ports.

        Parameter
           communityPortListDict: <list>: A list of community ports.  Example shown below.

        Usage:
            NOTE: Traffic#@Network# are the names from your configuration.
                  You must know what they are.

            If all the ports are in the same chassis:

                communityPortList = {
                   'chassisIp': '192.168.70.128',
                   'Traffic1@Network1': [(1,1)],
                   'Traffic2@Network2': [(2,1)]
                }

                restObj.assignChassisAndPorts([communityPortList])


            If ports are on different chassis, create two dicts.

                communityPortList1 = {
                   'chassisIp': '192.168.70.128',
                   'Traffic1@Network1': [(1,1)]
                }

                communityPortList2 = {
                   'chassisIp': '192.168.70.129',
                   'Traffic2@Network2': [(1,1),
                }

                restObj.assignChassisAndPorts([communityPortList1, communityPortList2])
        """
        if type(communityPortListDict) == dict:
            # Make this updated API backward compatible by passing in one dict versus a list.
            communityPortListDict = [communityPortListDict]

        for communityPorts in communityPortListDict:
            # Assign Chassis
            chassisIp = communityPorts['chassisIp']
            newChassisId, locationUrl = self. addNewChassis(chassisIp)
            self.logInfo('assignChassisAndPorts: To new chassis: %s' % locationUrl, timestamp=False)

            # Assign Ports
            communityListUrl = self.sessionIdUrl+'/ixLoad/test/activeTest/communityList/'
            communityList = self.get(communityListUrl)

            self.refreshConnection(locationUrl=locationUrl)
            self.waitForChassisIpToConnect(locationUrl=locationUrl)

            failedToAddList = []
            communityNameNotFoundList = []
            for eachCommunity in communityList.json():
                currentCommunityObjectId = str(eachCommunity['objectID'])
                currentCommunityName = eachCommunity['name']

                if currentCommunityName not in communityPorts:
                    continue

                if communityNameNotFoundList == []:
                    for eachTuplePort in communityPorts[currentCommunityName]:
                        # Going to ignore user input chassisId. When calling addNewChassis(),
                        # it will verify for chassisIp exists. If exists, it will return the
                        # right chassisID.
                        cardId,portId = eachTuplePort
                        params = {"chassisId":int(newChassisId), "cardId":cardId, "portId":portId}
                        url = communityListUrl+str(currentCommunityObjectId)+'/network/portList'
                        self.logInfo('assignChassisAndPorts URL: %s' % url, timestamp=False)
                        self.logInfo('assignChassisAndPorts Params: %s' % json.dumps(params), timestamp=False)
                        response = self.post(url, data=params, ignoreError=True)
                        if response.status_code != 201:
                            portAlreadyConnectedMatch = re.search('.*has already been assigned.*', response.json()['error'])
                            if portAlreadyConnectedMatch:
                                self.logInfo('%s/%s is already assigned' % (cardId,portId), timestamp=False)
                            else:
                                failedToAddList.append((newChassisId,cardId,portId))
                                self.logInfo('\nassignChassisAndPorts failed: %s' % response.text)

            if communityNameNotFoundList != []:
                raise IxLoadRestApiException

            if failedToAddList != []:
                if self.deleteSession:
                    self.abortActiveTest()
                raise IxLoadRestApiException('Failed to add ports to chassisIp %s: %s:' % (chassisIp, failedToAddList))


    def enableForceOwnership(self):
        url = self.sessionIdUrl+'/ixLoad/test/activeTest'
        response = self.patch(url, data={'enableForceOwnership': True})

    def getStatNames(self):
        statsUrl = self.sessionIdUrl+'/ixLoad/stats'
        self.logInfo('\ngetStatNames: %s\n' % statsUrl)
        response = self.get(statsUrl)
        for eachStatName in response.json()['links']:
            self.logInfo('\t%s' % eachStatName['href'], timestamp=False)
        return response.json()

    def disableAllStats(self, configuredStats):
        configuredStats = self.sessionIdUrl + '/' +configuredStats
        response = self.patch(configuredStats, data={"enabled":False})
                              
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
            self.logInfo('\nEnableConfiguredStats: %s' % configuredStats)
            response = self.patch(configuredStats, data={"enabled": True})

    def showTestLogs(self):
        testLogUrl = self.sessionIdUrl+'/ixLoad/test/logs'
        currentObjectId = 0
        while True:
            response = self.get(testLogUrl)
            for eachLogEntry in response.json():
                if currentObjectId != eachLogEntry['objectID']:
                    currentObjectId = eachLogEntry['objectID']
                    self.logInfo('\t{time}: Severity:{severity} ModuleName:{2} {3}'.format(eachLogEntry['timeStamp'],
                                                                                    eachLogEntry['severity'],
                                                                                    eachLogEntry['moduleName'],
                                                                                           eachLogEntry['message']), 
                                 timestamp=False)

    def runTraffic(self):
        runTestUrl = self.sessionIdUrl+'/ixLoad/test/operations/runTest'
        response = self.post(runTestUrl)
        operationsId = response.headers['Location']
        self.verifyStatus(self.httpHeader+operationsId, timeout=300)
        #return operationsId.split('/')[-1] ;# Return the number only

    def getTestStatus(self, operationsId):
        '''
        status = "Not Started|In Progress|successful"
        state  = "executing|finished"
        '''
        testStatusUrl = self.sessionIdUrl+'/ixLoad/test/operations/runTest/'+str(operationsId)
        response = self.get(testStatusUrl)
        return response

    def getActiveTestCurrentState(self, silentMode=False):
        # currentState: Configuring, Starting Run, Running, Stopping Run, Cleaning, Unconfigured 
        url = self.sessionIdUrl+'/ixLoad/test/activeTest'
        response = self.get(url, silentMode=silentMode)
        if response.status_code == 200:
            return response.json()['currentState']

    def getStats(self, statUrl):
        response = self.get(statUrl, silentMode=True)
        return response

    def pollStats(self, statsDict=None, pollStatInterval=2, csvFile=False,
                  csvEnableFileTimestamp=True, csvFilePrependName=None):
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
        versionMatch = re.match('([0-9]+\.[0-9]+)', self.ixLoadVersion)
        if float(versionMatch.group(1)) < float(8.5):
            # If ixLoad version is < 8.50, there is no rest api to download stats.
            # Default to creating csv stats from real time stats.
            csvFile = True

        if csvFile:
            import csv
            csvFilesDict = {}
            for key in statsDict.keys():
                fileName = key
                fileName = fileName.replace("(", '_')
                fileName = fileName.replace(")", '_')
                if csvFilePrependName:
                    fileName = csvFilePrependName+'_'+fileName

                csvFilesDict[key] = {}

                if csvEnableFileTimestamp:
                    import datetime
                    timestamp = datetime.datetime.now().strftime('%H%M%S')
                    fileName = timestamp+'_'+fileName

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
        waitForRunningStatusCounterExit = 30
        while True:
            currentState = self.getActiveTestCurrentState(silentMode=True)
            self.logInfo('ActiveTest current status: %s' % currentState)
            if currentState == 'Running':
                if statsDict == None:
                    time.sleep(1)
                    continue
                    
                # statType:  HTTPClient or HTTPServer (Just a example using HTTP.)
                # statNameList: transaction success, transaction failures, ...
                for statType,statNameList in statsDict.items():
                    self.logInfo('\n%s:' % statType, timestamp=False)
                    statUrl = self.sessionIdUrl+'/ixLoad/stats/'+statType+'/values'
                    response = self.getStats(statUrl)
                    highestTimestamp = 0
                    # Each timestamp & statnames: values                
                    for eachTimestamp,valueList in response.json().items():
                        if eachTimestamp == 'error':
                            raise IxLoadRestApiException('pollStats error: Probable cause: Misconfigured stat names to retrieve.')

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
                            self.logInfo('\t%s: %s' % (statName, statValue), timestamp=False)
                            if csvFile:
                                csvFilesDict[statType]['rowValueList'].append(statValue)
                        else:
                            self.logError('\tStat name not found. Check spelling and case sensitivity: %s' % statName)

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
                    self.logInfo('\tWaiting {0}/{1} seconds'.format(waitForRunningStatusCounter, waitForRunningStatusCounterExit), timestamp=False)
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
            self.logInfo('waitForTestStatusToRunSuccessfully %s/%s secs:\n\tCurrentTestStatus: %s\n\tExpecting: Successful' % (
                counter, str(timer), currentStatus))
            if currentStatus == 'Error':
                return 1
            if currentStatus != 'Successful' and counter < timer:
                time.sleep(1)
                continue
            if currentStatus == 'Successful' and counter < timer:
                return 0
            if currentStatus != 'Successful' and counter == timer:
                raise IxLoadRestApiException('Test status failed to run')

    def waitForActiveTestToUnconfigure(self):
        ''' Wait for the active test state to be Unconfigured '''
        self.logInfo('\n')
        for counter in range(1,31):
            currentState = self.getActiveTestCurrentState()
            self.logInfo('waitForActiveTestToUnconfigure current state:', currentState)
            if counter < 30 and currentState != 'Unconfigured':
                self.logInfo('ActiveTest current state = %s\nWaiting for state = Unconfigured: Wait %s/30' % (currentState, counter), timestamp=False)
                time.sleep(1)
            if counter < 30 and currentState == 'Unconfigured':
                self.logInfo('\nActiveTest is Unconfigured')
                return 0
            if counter == 30 and currentState != 'Unconfigured':
                raise IxLoadRestApiException('ActiveTest is stuck at: {0}'.format(currentState))

    def applyConfiguration(self):
        # Apply the configuration.
        # If applying configuration failed, you have the option to keep the 
        # sessionId alive for debugging or delete it.

        url = self.sessionIdUrl+'/ixLoad/test/operations/applyconfiguration'
        response = self.post(url, ignoreError=True)
        if response.status_code != 202:
            if self.deleteSession:
                self.deleteSessionId()
                raise IxLoadRestApiException('applyConfiguration failed')

        operationsId = response.headers['Location']
        operationsId = operationsId.split('/')[-1] ;# Return the number only
        url = url+'/'+str(operationsId)
        self.verifyStatus(response.headers['Location'])

    def saveConfiguration(self):
        url = self.sessionIdUrl+'/ixLoad/test/operations/save'
        self.logInfo('\nsaveConfiguration: %s' % url, timestamp=False)
        response = self.post(url)

    def abortActiveTest(self):
        url = self.sessionIdUrl+'/ixLoad/test/operations/abortAndReleaseConfigWaitFinish'
        response = self.post(url, ignoreError=True)
        if response.status_code != 202:
            self.deleteSessionId()
            raise IxLoadRestApiException('abortActiveTest Warning failed')

        self.verifyStatus(self.httpHeader+response.headers['Location'])

    def deleteSessionId(self):
        response = self.delete(self.sessionIdUrl)
        
    def getMaximumInstances(self):
        response = self.get(self.sessionIdUrl+'/ixLoad/preferences')
        maxInstances = response.json()['maximumInstances']
        self.logInfo('\ngetMaximumInstances:%s' % maxInstances)
        return int(maxInstances)

    def getTotalOpenedSessions(self, serverId):
        # serverId: 'http://192.168.70.127:8080'
        # Returns: Total number of opened active and non-active sessions.

        response = self.get(serverId+'/api/v0/sessions')
        counter = 1
        activeSessionCounter = 0
        self.logInfo()
        for eachOpenedSession in response.json():
            self.logInfo('\t%d: Opened sessionId: %s' % (counter, serverId+eachOpenedSession['links'][0]['href']), timestamp=False)
            self.logInfo('\t      isActive: %s' % eachOpenedSession['isActive'], timestamp=False)
            self.logInfo('\t      activeTime: %s' % eachOpenedSession['activeTime'], timestamp=False)
            counter += 1
            if eachOpenedSession['isActive'] == True:
                activeSessionCounter += 1

        return activeSessionCounter

    def getResultPath(self):
        url = self.sessionIdUrl+'/ixLoad/test'
        response = self.get(url)
        self.resultPath = response.json()['runResultDirFull']
        self.resultPath = self.resultPath.replace('\\', '\\\\')
        return self.resultPath

    def uploadFile(self, localPathAndFilename, ixLoadSvrPathAndFilename, overwrite=True):
        """
        Description
           For Linux server only.  You need to upload the config file into the Linux
           server location first: /mnt/ixload-share 

        Parameters
           localPathAndFilename:     The config file on the local PC path to be uploaded.
           ixLoadSvrPathandFilename: Default path on the Linux REST API server is '/mnt/ixload-share'
                                     Ex: '/mnt/ixload-share/IxL_Http_Ipv4Ftp_vm_8.20.rxf'

        Notes
           To log into IxLoad Linux gateway API server, password:ixia123
           To view or set the IP address, open a terminal and enter: ip address 
        """
        url = self.httpHeader+'/api/v0/resources'
        headers = {'Content-Type': 'multipart/form-data'}
        params = {'overwrite': overwrite, 'uploadPath': ixLoadSvrPathAndFilename}

        self.logInfo('\nUploadFile: {0} file to {1}...'.format(localPathAndFilename, ixLoadSvrPathAndFilename))
        self.logInfo('\n\tPOST: {0}\n\tDATA: {1}\n\tHEADERS: {2}'.format(url, params, self.jsonHeader))
        try:
            with open(localPathAndFilename, 'rb') as f:
                response = requests.post(url, data=f, params=params, headers=headers, verify=self.verifySsl)
                if response.status_code != 200:
                    raise IxLoadRestApiException('uploadFile failed', response.json()['text'])

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
            self.logInfo('Upload file finished.')
            self.logInfo('Response status code %s' % response.status_code)
            self.logInfo('Response text %s' % response.text)

    def configTimeline(self, **kwargs):
        """
        Modify the timeline.
        Requires the name of the timeline in the Timeline configuration

        Parameters
           name
           sustainTime
           rampDownTime
           rampUpTime
           rampUpInterval
           standbyTime

        Return
           True: Success
           Exeption: Failed
        """
        self.logInfo('configTimeLine')
        url = self.sessionIdUrl+'/ixLoad/test/activeTest/timelineList'
        response = self.get(url)
        for timelineObj in response.json():
            if timelineObj['name'] == kwargs['name']:
                objectId = timelineObj['objectID']
                url = url+'/'+str(objectId)
                self.patch(url, data=kwargs)
                return True
                
        raise IxLoadRestApiException('No such name found: {}'.format(kwargs['name']))

    def setResultDir(self, resultDirPath, createTimestampFolder=False):
        """
        Set the results directory path.

        resultDirPath: For Windows gateway server, provide the c: drive and path.
                       For Linux, must begin with path /mnt/ixload-share
        """
        timestampFolder = str(self.getTime()).replace(':', '-').replace('.', '-')
        if createTimestampFolder:
            if self.osPlatform == 'windows':
                resultDirPath = resultDirPath+'\\'+timestampFolder
            if self.osPlatform == 'linux':
                resultDirPath = resultDirPath+'/'+timestampFolder

        url = self.sessionIdUrl+'/ixLoad/test'
        data = {'outputDir': True, 'runResultDirFull': resultDirPath}
        self.patch(url, data=data)

    def deleteResultDir(self):
        """
        Delete a directory in the API gateway server
        """
        url = self.sessionIdUrl+'/ixLoad/test/operations/deleteTestResultDirectory'

        # This is supported starting with 8.50 update 2. 8.50.115.333
        if self.ixLoadVersion == '8.50.115.333' or int(self.ixLoadVersion.split('.')[0]) >= 9:
            self.logInfo('deleteResultDir')
            response = self.post(url.replace('v0', 'v1'))
            operationsId = response.headers['Location']
            status = self.verifyStatus(self.httpHeader+operationsId)
        else:
            self.logError('\nFailed: Your IxLoadVersion does not support deleteTestResultDirectory')

    def deleteLogsOnSessionClose(self):
        """
        Delete the logs in the IxLoad default results directory in the API gateway server.
        """
        self.logInfo('deleteLogsOnSessionClose')
        url = self.sessionIdUrl
        response = self.patch(url, data={'deleteLogsOnSessionClose': True})

    def waitForAllCapturedData(self):
        url = self.sessionIdUrl+'/ixLoad/test/operations/waitForAllCaptureData'
        response = self.post(url)
        operationsId = response.headers['Location']
        status = self.verifyStatus(self.httpHeader+operationsId)

    def configIp(self, searchName, **data):
        """
        Modify the existing network IP.

        Parameters
           searchName:  The name of the rangeList to modify.
           **date: <kwargs>: View below options

        Path
           /ixLoad/test/activeTest/communityList/<index>/network/stack/childrenList/<index>/childrenList/<index>/rangeList'

        Options:
           ipType = 'IPv4'
           ipAddress = '1.1.1.1'
           gatewayAddress = '1.1.1.2'
           gatewayIncrement = '0.0.0.0'
           incrementBy = '0.0.0.1'
           prefix = 24
           count = 100
           enableGatewayArp = <bool>
           name = The name of the network range to modify

        Usage:
            restObj.configIp(searchName='IP-R1', ipAddress='10.10.10.1', gatewayAddress='10.10.10.101')

        """
        searchNameExists = False
        url = self.sessionIdUrl+'/ixLoad/test/activeTest/communityList'
        response = self.get(url)
        for communityList in response.json():
            for link in communityList['links']:
                if link['rel'] == 'network':
                    # Get: /api/v0/sessions/15/ixLoad/test/activeTest/communityList/0/network
                    networkHref = link['href']
                    url = self.httpHeader + networkHref + '/stack/childrenList'
                    response = self.get(url)

                    for childrenList in response.json():
                        for childrenListLink in childrenList['links']:
                            if childrenListLink['rel'] == 'childrenList':
                                childrenListHref = childrenListLink['href']
                                url = self.httpHeader + childrenListHref
           
                                response = self.get(url)
                                # GET: /ixLoad/test/activeTest/communityList/1/network/stack/childrenList/5/childrenList/6/rangeList
                                for childrenList2 in response.json():
                                    for childrenListLink2 in childrenList2['links']:
                                        if childrenListLink2['rel'] == 'rangeList':
                                            rangeListHref = childrenListLink2['href']
                                            url = self.httpHeader + rangeListHref

                                            response = self.get(url)
                                            for ipRange in response.json():
                                                if response.json()[0]['name'] == searchName:
                                                    self.logInfo('configIp: {}'.format(data))
                                                    self.patch(url, data=(data))
                                                    searchNameExists = True

        if searchNameExists == False:
            self.logError('configIp: No name found: {}'.format(searchName))


    def sshSetCredentials(self, username='ixload', password='ixia123', sshPasswordFile=None, port=22, pkeyFile=None):
        """
        For scpFiles and deleteFolder.
        
        Parameters
           username: The username to log into the IxLoad Gateway server.
           password: The password. The Linux default password is ixia123.
           sshPasswordFile: The file that contains the password.
           port: The SSH port to use.
           pkeyFile: The PKEY file to use 
        
        """
        self.sshUsername = username
        self.sshPassword = password
        self.sshPort = port
        self.sshPkeyFile = pkeyFile

        if sshPasswordFile:
            # with open (sshPasswordFile, 'r') as pwdFile:
            #     self.sshPassword = pwdFile.read().strip()
            self.sshPassword = self.readFile(sshPasswordFile)
        
    def readFile(self, theFile):
        with open (theFile, 'r') as fileObj:
            fileContents = fileObj.read().strip()

        return fileContents

    def scpFiles(self, sourceFilePath=None, destFilePath='.', typeOfScp='download'):
        """
        This method is for running scripts from a Linux machine only and retreiving files off an
        IxLoad Linux Gateway server. Does not get from Windows unless you installed SSH server.

        As of 8.50, there is no Rest API to retrieve result folders off the IxLoad Gateway server
        when the test is done.  This method will get your specified result folder out of
        the IxLoad Gateway Server by using SCP.

        Requirements:
            Install sshpass on your local Linux.

            If your IxLoad Gateway is Windows, you need to download and install OpenSSH.  The link below shows the steps:
               https://www.openixia.com/tutorials?subject=Windows&page=sshOnWindows.html

        NOTE:
            - If you get an error message: host key verification failed, this means your
              local host doesn't have the ssh key of the ssh host that you're connecting to.
              To create the host key, enter:

              ssh-keyscan <server ip> >> ~/.ssh/known_hosts

        Parameters
           sourceFilePath: From where.
           destFilePath:   To where. Defaults to the location where the script was executed.
           typeOfScp:      download|upload

        Usage
            # Download Windows folder to local Linux
            restObj.scpFiles('C:\\Results', '/home/hgee', typeOfScp='download')

            # Download Linux to local Linux
            restObj.scpFiles('/mnt/ixload-share/file', '/home/hgee', typeOfScp='download')

            # Upload Linux to Windows
            restObj.scpFiles('/home/hgee/file.txt', 'C:\\Results', typeOfScp='upload')

        -v = Show debugs.
        -rp = recursive and persistent files.
        -p  = An estimate time.
        -P  = Specify a port
        -C  = Compress files on the go. Decompress on the destination to regular size.
        """
        if typeOfScp == 'download':
            cmd = 'sshpass -p {} scp -o "StrictHostKeyChecking no" -P {} -rp -C {}@{}:{} {}'.format(self.sshPassword, self.sshPort, self.sshUsername,
                                                                      self.apiServerIp, sourceFilePath, destFilePath)
        
        if typeOfScp == 'upload':
            cmd = 'sshpass -p {} scp -P {} -rp -C {} {}@{}:{}'.format(self.sshPassword, self.sshPort, sourceFilePath,
                                                                      self.sshUsername, self.apiServerIp, destFilePath)

        self.logInfo('SCP Files: {} -> {}'.format(sourceFilePath, destFilePath))
        output = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)

        while True:
            output.poll()
            line = output.stdout.readline()
            if line:
                self.logInfo('scpFiles: {}'.format(line))
            else:
                break

    def deleteFolder(self, filePath=None):
        """
        Deletes a folder on the IxLoad gateway server.
        """
        import sshAssistant

        try:
            sshClient = sshAssistant.Connect(self.apiServerIp, self.sshUsername, self.sshPassword,
                                            pkeyFile=self.sshPkeyFile, port=self.sshPort)
        except:
            self.logError('\ndeleteFolder failed to ssh: {}. This is not a test failure.'.format(self.apiServerIp))
            return

        if self.osPlatform == 'linux':
            stdout,stderr = sshClient.enterCommand('rm -rf {}'.format(filePath))

        if self.osPlatform == 'windows':
            sshClient.enterCommand('rmdir {} /s /q'.format(filePath))

    def downloadResults(self):
        """
        Get the test results path and download all the CSV results to the local system.

        Syntax:
            https://ip:8443/api/v1/downloadResource?localPath=/mnt/ixload-share/<Folder>&zipName=results.zip
        """
        versionMatch = re.match('([0-9]+\.[0-9]+)', self.ixLoadVersion)
        if float((versionMatch.group(1))) < float(8.5):
            self.logInfo('Your IxLoad version {} does not have the rest api to download csv stats. However, real time stats are saved in csv files in your local system'.format(self.ixLoadVersion))
            return

        resultsPath = self.getResultPath()
        if '/' in resultsPath:
            # Linux path 
            destinationZipFileName = resultsPath.split('/')[-1]
        else:
            # Windows path
            destinationZipFileName = resultsPath.split('\\')[-1]

        zipFile = 'ixLoadResults_{}.zip'.format(destinationZipFileName)

        self.logInfo('downloadResults: {}'.format(resultsPath))
        url = '{}/api/v1/downloadResource?localPath={}&zipName={}'.format(self.httpHeader, resultsPath, zipFile)

        response = requests.get(url, verify=self.verifySsl)
        open(zipFile, 'wb').write(response.content)
