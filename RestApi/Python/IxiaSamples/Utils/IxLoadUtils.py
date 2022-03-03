from __future__ import print_function

import json
import requests
import time
import os
import re
from future.utils import iteritems

kActionStateFinished = 'finished'
kActionStatusSuccessful = 'Successful'
kActionStateSuccess = 'SUCCESS'
kActionStateError = 'EXCEPTION'
kActionStatusError = 'Error'
kTestStateUnconfigured = 'Unconfigured'
kGatewaySharedFolderL = '/mnt/ixload-share'


def getRxfName(connection, location):
    relativeFileNamePath = location
    activeConnection = connection
    fileName = os.path.split(relativeFileNamePath)[-1]
    fileNameWithoutExtension = fileName.split('.')[0]
    rxfName = "%s.rxf" % (fileNameWithoutExtension)
    rxfDirPath = getSharedFolder(activeConnection)
    return '/'.join([rxfDirPath, rxfName])


def log(message):
    currentTime = time.strftime("%H:%M:%S")
    print("%s -> %s" % (currentTime, message))


def getResourcesUrl(connection):
    return connection.url + '/resources'


def stripApiAndVersionFromURL(url):
    # remove the slash (if any) at the beginning of the url
    if url[0] == '/':
        url = url[1:]
    urlElements = url.split('/')
    if 'api' in url:
        # strip the api/v0 part of the url
        urlElements = urlElements[2:]

    return '/'.join(urlElements)


def getApiVersion(connection):
    return connection.url.split("/")[-1]


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

    actionStatusSuccess = {"v0": lambda x: x.state == kActionStateFinished and x.status == kActionStatusSuccessful,
                           "v1": lambda x: x.state == kActionStateSuccess}
    actionStatusError = {"v0": lambda x: x.status == kActionStatusError,
                         "v1": lambda x: x.state == kActionStateError}
    messageError = {"v0": lambda x: x.error,
                    "v1": lambda x: x.message}

    actionResultURL = replyObj.headers.get('location')
    apiVersion = getApiVersion(connection)
    if actionResultURL:
        actionResultURL = stripApiAndVersionFromURL(actionResultURL)
        actionFinished = False

        while not actionFinished:
            actionStatusObj = connection.httpGet(actionResultURL)
            if actionStatusSuccess[apiVersion](actionStatusObj):
                actionFinished = True
            elif actionStatusError[apiVersion](actionStatusObj):
                errorMsg = "Error while executing action '%s'." % actionResultURL
                errorMsg += messageError[apiVersion](actionStatusObj)
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
        This will perform a generic POST method on a given url.

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
        This will perform a generic DELETE method on a given url.

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
        This will perform a generic PATCH method on a given url.

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


def downloadResource(connection, downloadFolder, localPath, zipName=None, timeout=80):
    '''
        This method is used to download an entire folder as an archive or any type of file without changing it's format.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - downloadFolder is the folder were the archive/file will be saved
        - localPath is the local path on the machine that holds the IxLoad instance
        - zipName is the name that archive will take, this parameter is mandatory only for folders, if you want to download a file this parameter is not used.
    '''
    downloadResourceUrl = connection.url + "/downloadResource"
    downloadFolder = downloadFolder.replace("\\\\", "\\")
    localPath = localPath.replace("\\", "/")
    parameters = { "localPath": localPath, "zipName": zipName }

    downloadResourceReply = connection.httpRequest('GET', downloadResourceUrl, params= parameters, downloadStream=True, timeout =timeout)

    if not downloadResourceReply.ok:
        raise Exception("Error on executing GET request on url %s: %s" % (downloadResourceUrl, downloadResourceReply.text))

    if not zipName:
        zipName = localPath.split("/")[-1]
    elif zipName.split(".")[-1] != "zip":
        zipName  = zipName + ".zip"
    downloadFile = '/'.join([downloadFolder, zipName])
    log("Downloading resource to %s..." % (downloadFile))
    try:
        with open(downloadFile, 'wb') as fileHandle:
            for chunk in downloadResourceReply.iter_content(chunk_size=1024):
                fileHandle.write(chunk)
    except IOError as e:
        raise Exception("Download resource failed. Could not open or create file, please check path and/or permissions. Received IO error: %s" % str(e))
    except Exception as e:
        raise Exception('Download resource failed. Received the following error:\n %s' % str(e))
    else:
        log("Download resource finished.")


def createNewSession(connection, ixLoadVersion=''):
    if not ixLoadVersion:
        newSessionUrl = startNewSession(connection)
    else:
        newSessionUrl = createSession(connection, ixLoadVersion)

    return newSessionUrl


def startNewSession(connection):
    '''
        This method is used to create and start a new session. It will return the url of the newly created session.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
    '''
    sessionsUrl = "sessions"
    startNewSessionUrl = "%s/operations/startNewSession" % (sessionsUrl)
    startNewSessionReply = performGenericOperation(connection, startNewSessionUrl, {})
    sessionLocation = stripApiAndVersionFromURL(startNewSessionReply.headers['location'])
    resourceObj = connection.httpGet(sessionLocation)
    sessionId = resourceObj.sessionId

    log("Created session no %s." % (sessionId))
    newSessionUrl = "%s/%s" % (sessionsUrl, sessionId)

    return newSessionUrl


def createSession(connection, ixLoadVersion):
    '''
        This method is used to create a new session. It will return the url of the newly created session.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - ixLoadVersion this is the actual IxLoad Version to start
    '''
    sessionsUrl = "sessions"
    apiVersion = getApiVersion(connection)

    if apiVersion == "v1":
        data = {"applicationVersion": ixLoadVersion}
    else:
        data = {"ixLoadVersion": ixLoadVersion}

    sessionId = performGenericPost(connection, sessionsUrl, data)

    newSessionUrl = "%s/%s" % (sessionsUrl, sessionId)
    startSessionUrl = "%s/operations/start" % (newSessionUrl)

    # start the session
    performGenericOperation(connection, startSessionUrl, {})
    log("Created session no %s." % (sessionId))

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


def getSharedFolder(connection):
    '''
    This method gets the sharedLocation folder.

    Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
    '''
    resourceUrl = "resources"
    resourceObj = connection.httpGet(resourceUrl)

    return resourceObj.sharedLocation


def changeRunResultDir(connection, sessionUrl, runResultDirPath):
    '''
        This method is used to change the path where results are saved.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session on which the test was ran.
        - runResultDirPath is the new folder path
    '''
    testUrl = "%s/ixload/test" % sessionUrl
    payloadDict = {"outputDir": "true", "runResultDirFull": runResultDirPath}

    performGenericPatch(connection, testUrl, payloadDict)
    log("Changed the result directory to %s." % (runResultDirPath))


def uploadFile(connection, url, fileName, uploadPath, overwrite=True):
    '''
        This method is used to upload a file from the computer where the script runs, on the computer where the 
        IxLoad client is running.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - url is the address of the resource that uploads the file. E.g. http://ip:port/api/v0/resources
        - filename contains the name (or absolute path to the file, if the file is not in the same
            location as the executing script) of the file to be uploaded. This is the location on the
            computer where the script is running. E.g. "file.txt", r"D:/examples/file.txt".
        - uploadPath is the path where the file should be copied to on the computer on which the IxLoad client runs
        - overwrite specifies the required behavior if the file to be uploaded already exists on the remote computer
    '''
    headers = {'Content-Type': 'multipart/form-data'}
    params = {"overwrite": overwrite, "uploadPath": uploadPath}
    log('Uploading to %s...' % (uploadPath))
    result = {}
    try:
        with open(fileName, 'rb') as f:
            response = requests.post(url, data=f, params=params, headers=headers, verify=False)
            result["status"] = int(response.ok)
            if response.ok is not True:
                result["error"] = response.text
                raise Exception('POST operation failed with %s' % response.text)
    except requests.exceptions.ConnectionError as e:
        result["error"] = str(e)
        raise Exception(
            'Upload file failed. Received connection error. One common cause for this error is the size of the file to be uploaded.'
            ' The web server sets a limit of 1GB for the uploaded file size. Received the following error: %s' % str(e)
        )
    except IOError as e:
        result["error"] = str(e)
        raise Exception('Upload file failed. Received IO error: %s' % str(e))
    except Exception as e:
        result["error"] = str(e)
        raise Exception('Upload file failed. Received the following error:\n   %s' % str(e))
    else:
        result["error"] = ""
        log('Upload file finished.')
        log('Response status code %s' % (response.status_code))
        log('Response text %s' % (response.text))
    return result


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


def save(connection, sessionUrl):
    '''
        This method saves the currently loaded configuration file.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session to save the rxf for
    '''
    saveUrl = "%s/ixload/test/operations/save" % (sessionUrl)
    data = {}

    performGenericOperation(connection, saveUrl, data)


def saveRxf(connection, sessionUrl, rxfFilePath, overWrite=True):
    '''
        This method saves the current rxf to the disk of the machine on which the IxLoad instance is running.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session to save the rxf for
        - rxfFilePath is the location where to save the rxf on the machine that holds the IxLoad instance
    '''
    saveRxfUrl = "%s/ixload/test/operations/saveAs" % (sessionUrl)
    rxfFilePath = rxfFilePath.replace("\\", "\\\\")
    data = {"fullPath": rxfFilePath, "overWrite": overWrite}

    performGenericOperation(connection, saveRxfUrl, data)


def importConfig(connection, sessionUrl, srcFilePath, destRxfPath):
    '''
        This method will perform a POST request to load a repository.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session to save the rxf for
        - srcFilePath is the location for crf file on the machine that holds the IxLoad instance
        - destRxfPath is the location where to save the rxf on the machine that holds the IxLoad instance
    '''
    importConfigUrl = "%s/ixload/test/operations/importConfig" % (sessionUrl)
    srcFilePath = srcFilePath.replace("\\", "\\\\")
    data = {"srcFile": srcFilePath, "destRxf": destRxfPath}

    performGenericOperation(connection, importConfigUrl, data)


def exportConfig(connection, sessionUrl, destFilePath):
    '''
        This method saves the current configuration as crf file to the disk of the machine on which the IxLoad instance is running.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session to save the rxf for
        - destFilePath is the location where to save the crf on the machine that holds the IxLoad instance
    '''
    exportConfigUrl =  "%s/ixload/test/operations/exportConfig" % (sessionUrl)
    destFile = destFilePath.replace("\\", "\\\\")
    data = {"destFile": destFile}

    performGenericOperation(connection, exportConfigUrl, data)


def applyConfiguration(connection, sessionUrl):
    '''
        This method is used to apply the currently loaded test. After starting the 'Apply Config' action, wait for the action to complete.

        Args:
            - connection is the connection object that manages the HTTP data transfers between the client and the REST API
            - sessionUrl is the address of the session that should run the test.
    '''

    applyConfigurationUrl = "%s/ixload/test/operations/applyConfiguration" %(sessionUrl)
    data = {}

    performGenericOperation(connection, applyConfigurationUrl, data)


def releaseConfiguration(connection, sessionUrl):
    '''
    This method is used to release the currently loaded test. After starting the 'Release Config' action, wait for the action to complete.
        Args:
            - connection is the connection object that manages the HTTP data transfers between the client and the REST API
            - sessionUrl is the address of the session that should run the test.
    '''

    releaseConfigUrl = "%s/ixload/test/operations/abortAndReleaseConfigWaitFinish"  %(sessionUrl)
    data = {}

    performGenericOperation(connection, releaseConfigUrl, data)


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


def enableForcefullyTakeOwnershipAndResetPorts(connection, sessionUrl):
    '''
        This method is used to take forcefully the ownership of the ports.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session on which the test was ran.
    '''
    activeTestUrl = "%s/ixload/test/activeTest" % (sessionUrl)
    data =  {'enableForceOwnership': 'true','enableResetPorts': 'true'}

    performGenericPatch(connection, activeTestUrl, data)


def getPortObjectId(connection, sessionUrl, communityPortIdTuple):
    '''
        This method is used to get the objectID of a port from a communityList.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - communityPortIdTuple is a tuple composed of (communityID and portName)
            - communityID is the id of the community list for which captures should be retrieved.
            - portName is the name of the port for which the objectID will be retrieved ( in the following format:'1.5.1')
        - sessionUrl is the address of the session on which the test was ran.
    '''
    communityObjectID, portID = communityPortIdTuple
    communityUrl = sessionUrl + ("/ixload/test/activeTest/communityList/%s/network/portList" % communityObjectID)
    portList = connection.httpRequest('GET', communityUrl).json()

    objectID = None
    for port in portList:
        if port['id'] == portID:
            objectID = port["objectID"]
            break

    if objectID is None:
        raise Exception("Could not find port with id '%s' on community with id '%s'" % (portID, communityObjectID))

    return objectID


def enableAnalyzerOnPorts(connection, sessionUrl, communityPortIdTuple):
    '''
        This method is used to enable Analyzer for a specific port on a specific community.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - communityPortIdTuple is a tuple composed of (communityID and portName)
            - communityID is the id of the community list for which captures should be retrieved.
            - portName is the name of the port for which capture will be enabled (in format '1.5.1', not 'Port 1.5.1')
        - sessionUrl is the address of the session on which the test was ran.
    '''
    communityObjectID, portID = communityPortIdTuple
    portObjectID = getPortObjectId(connection, sessionUrl, communityPortIdTuple)
    if portObjectID is None:
        raise Exception("Port objectID could not be found for the port with ID: %s" % portID)

    patchUrl = sessionUrl + "/ixload/test/activeTest/communityList/%s/network/portList/%s" % (communityObjectID, portObjectID)
    payloadDict = {'enableCapture': "true"}

    performGenericPatch(connection, patchUrl, payloadDict)


def enableAnalyzerOnAssignedPorts(connection, sessionUrl):
    '''
        This method is used to enable Analyzer for all assigned ports.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session on which the test was ran.
    '''
    communityListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl
    communityList = connection.httpGet(communityListUrl)

    for community in communityList:
        portListUrl = "%s/%s/network/portList" % (communityListUrl, community.objectID)
        portList = connection.httpGet(portListUrl)
        payloadDict = {"enableCapture" : "true"}

        performGenericPatch(connection, portListUrl, payloadDict)


def setEnableL23RestStatViews(connection, sessionUrl, value=True):
    '''
        This method is used to set the value for the 'enableL23RestStatsViews' option.
        that handles the creation of L23 statistics:
            - L2-3 Stats for Client Ports
            - L2-3 Stats for Server Ports
            - L2-3 Throughput Stats

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session on which the test was ran.
        - value is True to enable and False to disable the L23 statistics.
    '''
    preferencesUrl = "%s/ixload/preferences" % sessionUrl
    payloadDict = {"enableL23RestStatViews": value}

    performGenericPatch(connection, preferencesUrl, payloadDict)


def setEnableRestStatViewsCsvLogging(connection, sessionUrl, value=True):
    '''
        This method is used to set the value for the 'enableRestStatViewsCsvLogging' option
        that handles the saving in CSV format of the stat views.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session on which the test was ran.
        - value is True to enable and False to disable the CSV logging.
    '''
    preferencesUrl = "%s/ixload/preferences" % sessionUrl
    payloadDict = {"enableRestStatViewsCsvLogging": value}

    performGenericPatch(connection, preferencesUrl, payloadDict)


def setEnableRestReportingPreferences(connection, sessionUrl, value=True):
    '''
        This method is used to set the values for the 'enableL23RestStatViews', 'enableRestStatViewsCsvLogging' and
        'saveDataModelSnapshot' options needed to generate a report from REST API.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session on which the test was ran.
        - value is True to enable and False to disable the REST reporting preferences.
    '''
    preferencesUrl = "%s/ixload/preferences" % sessionUrl
    payloadDict = {
        "enableL23RestStatViews" : value,
        "saveDataModelSnapshot" : value,
        "enableRestStatViewsCsvLogging" : value
    }

    performGenericPatch(connection, preferencesUrl, payloadDict)


def retrieveCaptureFileForPorts(connection, sessionUrl, communityPortIdTuple, captureFile):
    '''
        This method is used to retrieve capture files from a rest session which had portCapture set to True.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - communityPortIdTuple is a tuple composed of (communityID and portName)
            - communityID is the id of the community list for which captures should be retrieved.
            - portName is the name of the port for which ('1.5.1', not 'Port 1.5.1')
        - sessionUrl is the address of the session on which the test was ran.
        - captureFile is the save path for the capture file

        Error Codes:
        - 0 No error
        - 1 Invalid portId
        - 2 Cannot create/open captureFile

    '''
    communityObjectID, portID = communityPortIdTuple
    portObjectID = getPortObjectId(connection, sessionUrl, communityPortIdTuple)
    if portObjectID is None:
        log("Error: Port objectID could not be found for port with ID: %s" % (portID))
        return 1

    captureFile = captureFile.replace("\\\\", "\\")

    portUrl = sessionUrl + ("/ixload/test/activeTest/communityList/%s/network/portList" % communityObjectID)
    captureUrl = portUrl + "/%s/restCaptureFile" % portObjectID
    capturePayload = connection.httpRequest('GET', captureUrl, downloadStream=True)

    log("Saving capture file %s..." % (captureFile))
    try:
        with open(captureFile, 'wb') as fileHandle:
            for chunk in capturePayload.iter_content(chunk_size=1024):
                fileHandle.write(chunk)
    except IOError as e:
        log("Error: Saving capture failed. Could not open or create file, please check path and/or permissions. Received IO error: %s" % (str(e)))
        return 2
    except Exception as e:
        log("Error: Saving capture failed. Received the following error:\n %s" % (str(e)))
        return 2
    else:
        log("Saving capture finished.")
    
    return 0


def retrieveCaptureFileForAssignedPorts(connection, sessionUrl, captureFolder):
    '''
        This method is used to retrieve capture files from a rest session which had portCapture set to True.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session on which the test was ran.
        - captureFolder is the folder where the capture file will be saved

    '''
    communityListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl
    communityList = connection.httpGet(communityListUrl)
    captureFolder = captureFolder.replace("\\\\", "\\")

    for community in communityList:
        portListUrl = "%s/%s/network/portList" % (communityListUrl, community.objectID)
        portList = connection.httpGet(portListUrl)
        for port in portList:
            captureUrl = portListUrl + "/%s/restCaptureFile" % port.objectID
            capturePayload = connection.httpRequest('GET', captureUrl, downloadStream=True)
            captureName = "Capture_%s_%s.cap" % (community.objectID, port.id)
            captureFile = '/'.join([captureFolder, captureName])
            log("Saving capture file %s..." % (captureFile))
            try:
                with open(captureFile, 'wb') as fileHandle:
                    for chunk in capturePayload.iter_content(chunk_size=1024):
                        fileHandle.write(chunk)
            except IOError as e:
                raise Exception("Error: Saving capture failed. Could not open or create file, please check path and/or permissions. Received IO error: %s" % str(e))
            except Exception as e:
                raise Exception("Error: Saving capture failed. Received the following error:\n %s" % str(e))
            else:
                log("Saving capture finished.")


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


def getSessionIsActive(connection, sessionUrl):
    sessionObj = connection.httpGet(sessionUrl)
    return sessionObj.isActive


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


def getRemotePid(connection, sessionUrl):
    '''
    This method returns the process identifier of the IxLoad instance running for this session.
    Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test.
    '''
    sessionData = connection.httpGet(sessionUrl)
    return sessionData.remotePid


def collectDiagnostics(connection, sessionUrl, zipFilePath, clientOnly=False):
    '''
         This method will perform a POST request to collect log files and packages them into a ZIP file.

         Args:
         - connection is the connection object that manages the HTTP data transfers between the client and the REST API
         - sessionUrl is the address of the session to collect diagnostics for
         - zipFilePath is the local zip path on the machine that holds the IxLoad instance
    '''
    collectDiagnosticsUrl = "%s/ixload/test/activeTest/operations/collectDiagnostics" % (sessionUrl)
    data = {"zipFileLocation": zipFilePath, "clientOnly": clientOnly}

    performGenericOperation(connection, collectDiagnosticsUrl, data)


def collectGatewayDiagnostics(connection, zipFilePath):
    '''
        This method will perform a POST request to collect gateway log files and packages them into a ZIP file.

         Args:
         - connection is the connection object that manages the HTTP data transfers between the client and the REST API
         - zipFilePath is the local zip path on the machine that holds the IxLoad instance. This needs to be the absolute path (ex: /mnt/ixload-share/diags.zip)
    '''
    collectGatewayDiagnosticsUrl = "logs/operations/collectDiagnostics"
    data = {"zipFileLocation": zipFilePath}

    performGenericOperation(connection, collectGatewayDiagnosticsUrl, data)


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


def extractLastElementFromLink(link):
    lastElement = str(link).split("/")[-1]

    return lastElement


def checkStatSource(statSource):
    validStatSource = ["peer", "client", "server", "sip"]
    foundStat = False
    if re.findall('|'.join(validStatSource), statSource):
        foundStat = True

    return foundStat


def extractStatList(connection, sessionUrl):
    statUrl = "%s/ixload/stats" % (sessionUrl)
    statList = []
    statSourceList = connection.httpGet(statUrl).links
    for statSource in statSourceList:
        statResource = extractLastElementFromLink(statSource.href)
        if checkStatSource(statResource.lower()):
            statList.append(statResource)

    return statList


def extractStatName(connection, sessionUrl, statList):
    statDir = {}

    for statSource in statList[:]:
        statSourceUrl = "%s/ixload/stats/%s/availableStats" % (sessionUrl, statSource)
        availableStatsList = connection.httpGet(statSourceUrl)
        if hasattr(availableStatsList, "error"):
            log("Warning - Stat source '%s' does not exist. Will ignore it." % (statSource))
            statList.remove(statSource)
            continue
        statDir[statSource] = [str(availableStat.statName) for availableStat in availableStatsList]

    return statDir


def pollStats(connection, sessionUrl, watchedStatsDict, pollingInterval=4):
    '''
        This method is used to poll the stats. Polling stats is per request but this method does a continuous poll.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
        - watchedStatsDict these are the stats that are being monitored
        - pollingInterval the polling interval is 4 by default but can be overridden.

    '''
    statSourceList = list(watchedStatsDict)

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
            newTimestamps = [int(timestamp) for timestamp in list(valuesDict) if timestamp not in collectedTimestamps.get(statSource, [])]
            newTimestamps.sort()

            for timestamp in newTimestamps:
                timeStampStr = str(timestamp)

                collectedTimestamps.setdefault(statSource, []).append(timeStampStr)

                timestampDict = statsDict.setdefault(statSource, {}).setdefault(timestamp, {})

                # save the values for the current timestamp, and later print them
                for caption, value in iteritems(valuesDict[timeStampStr].getOptions()):
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


def refreshAllChassis(connection, sessionUrl):
    '''
        This method is used to refresh all chassis.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
    '''
    chassisListUrl = "%s/ixload/chassisChain/chassisList" % (sessionUrl)
    chassisList = connection.httpGet(chassisListUrl)
    for chassisObj in chassisList:
        chassisId = chassisObj.objectID
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
    communityNameList = [community.name for community in communityList]

    for communityName in portListPerCommunity:
        if communityName not in communityNameList:
            errorMsg = "Error while executing assignPorts operation. Invalid NetTraffic name: %s. This NetTraffic is not defined in the loaded rxf." % communityName
            raise Exception(errorMsg)

    for community in communityList:
        if portListPerCommunity.get(community.name):
            portListForCommunity = portListPerCommunity.get(community.name)
            portListUrl = "%s/%s/network/portList" % (communityListUrl, community.objectID)
            for portTuple in portListForCommunity:
                chassisId, cardId, portId = portTuple
                paramDict = {"chassisId": chassisId, "cardId": cardId, "portId": portId}

                performGenericPost(connection, portListUrl, paramDict)
        else:
            errorMsg = "Error while executing assignPorts operation. For community: %s you dont't have ports assigned." % community.name
            raise Exception(errorMsg)


def changeCardsInterfaceMode(connection, chassisChainUrl, chassisIp, cardIdList, mode):
    '''
        This method is used to change the interface mode on a list of cards from a chassis. 
        In order to call this method, the desired chassis must be already  added and connected.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - chassisChainUrl is the address of the chassisChain resource
        - chassisIp is the IP or hostname of the chassis that contains the card(s)
        - cardIdList is a list of card IDs
        - mode is the interface mode that will be set on the cards. Possible options are (depending on card type): 1G, 10G, 40G, 100G
    '''
    changeCardsInterfaceModeOperationUrl = "%s/operations/changeCardsInterfaceMode" % chassisChainUrl
    cardIdStr = ",".join([str(cardId) for cardId in cardIdList])
    data = {"chassisIp": chassisIp, "cardIdList": cardIdStr, "mode": mode}

    performGenericOperation(connection, changeCardsInterfaceModeOperationUrl, data)


def setCardsAggregationMode(connection, chassisChainUrl, chassisIp, cardIdList, mode):
    '''
        This method is used to change the aggregation mode on a list of cards from a chassis. 
        In order to call this method, the desired chassis must be already  added and connected.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - chassisChainUrl is the address of the chassisChain resource
        - chassisIp is the IP or hostname of the chassis that contains the card(s)
        - cardIdList is a list of card IDs
        - mode is the aggregation mode that will be set on the cards. Possible options are (depending on card type): NA (Non Aggregated), 1G, 10G, 40G
    '''
    setCardsAggregationModeOperationUrl = "%s/operations/setCardsAggregationMode" % chassisChainUrl
    cardIdStr = ",".join([str(cardId) for cardId in cardIdList])
    data = {"chassisIp": chassisIp, "cardIdList": cardIdStr, "mode": mode}

    performGenericOperation(connection, setCardsAggregationModeOperationUrl, data)


def getIPRangeListUrlForNetworkObj(connection, networkUrl):
    '''
        This method will return the IP Ranges associated with an IxLoad Network component.
        WARNING: this method was replaced with the more generic getRangeListUrlForNetworkObj, we recommend to stop using it

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - networkUrl is the REST address of the network object for which the network ranges will be provided.
    '''
    return getRangeListUrlForNetworkObj(connection, networkUrl, rangeListType='rangeList')


def getRangeListUrlForNetworkObj(connection, networkUrl, rangeListType):
    '''
        This method will return the ranges associated with an IxLoad Network component.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - networkUrl is the REST address of the network object for which the network ranges will be provided.
        - rangeListType is the type of the range list; it is one of the following: 'rangeList'/'macRangeList'/'vlanRangeList'
        - the 'rangeList' type does the same thing as the getIPRangeListUrlForNetworkObj method
    '''
    networkObj = connection.httpGet(networkUrl)

    if isinstance(networkObj, list):
        for obj in networkObj:
            url = "%s/%s" % (networkUrl, obj.objectID)
            rangeListUrl = getRangeListUrlForNetworkObj(connection, url, rangeListType)
            if rangeListUrl:
                return rangeListUrl
    else:
        for link in networkObj.links:
            if link.rel == rangeListType:
                rangeListUrl = normalizeLink(link.href)
                return rangeListUrl

        for link in networkObj.links:
            if link.rel == 'childrenList':
                #remove the 'api/v0' elements of the url, since they are not needed for connection http get

                childrenListUrl = normalizeLink(link.href)

                return getRangeListUrlForNetworkObj(connection, childrenListUrl, rangeListType)

    return None


def changeIpRangesParams(connection, sessionUrl, ipOptionsToChangeDict):
    '''
        This method is used to change certain properties on an IP Range.
        WARNING: this method was replaced with the more generic changeRangesParams, we recommend to stop using it.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
        - ipOptionsToChangeDict is the Python dict holding the items in the IP range that will be changed.
            (ipOptionsToChangeDict format -> { IP Range name : { optionName : optionValue } })
    '''
    return changeRangesParams(connection, sessionUrl, rangeListType='rangeList', optionsToChangeDict=ipOptionsToChangeDict)


def changeRangesParams(connection, sessionUrl, rangeListType, optionsToChangeDict):
    '''
        This method is used to change certain properties on a range.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that should run the test
        - rangeListType is the type of the range list; it is one of the following 'rangeList'/'macRangeList'/'vlanRangeList'
        - optionsToChangeDict is the Python dict holding the items in the range that will be changed.
            (optionsToChangeDict format -> { range name : { optionName : optionValue } })
        - the 'rangeList' type does the same thing as the changeIpRangesParams method
    '''
    communityListUrl = "%s/ixload/test/activeTest/communityList" % sessionUrl
    communityList = connection.httpGet(url=communityListUrl)

    for community in communityList:
        stackUrl = "%s/%s/network/stack" % (communityListUrl, community.objectID)

        rangeListUrl = getRangeListUrlForNetworkObj(connection, stackUrl, rangeListType)
        rangeList = connection.httpGet(rangeListUrl)

        for rangeObj in rangeList:
            if rangeObj.name in list(optionsToChangeDict):
                rangeObjUrl = "%s/%s" % (rangeListUrl, rangeObj.objectID)
                paramDict = optionsToChangeDict[rangeObj.name]

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
                        commandListUrl = normalizeLink(link.href)
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
    for agentName in list(commandDict):
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
            if activity.name in list(activityOptionsToChange):
                activityUrl = "%s/%s" % (activityListUrl, activity.objectID)
                performGenericPatch(connection, activityUrl, activityOptionsToChange[activity.name])


def addDUT(connection, sessionUrl, dutDict=None):
    '''
        This method is used to add a DUT resource to the active test on the given session
        Returns the id of the newly added DUT

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - dutListUrl is the address that contains the list of DUTs
        - dutDict contains a comment, the name or the type of the DUT (or all three)
        DUT types::
            Firewall
            ExternalServer
            PacketSwitch
            ServerLoadBalancer
            VirtualDut
        By default, when posting using dutDict=None, dutType will be SLB
    '''
    dutListUrl = "%s/ixload/test/activeTest/dutList" % (sessionUrl)
    return performGenericPost(connection, dutListUrl, dutDict)


def editDutProperties(connection, sessionUrl, dutId, newInfoDict=None):
    '''
        This method is used to modify the DUT's: name, comment, type.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - dutUrl is the address of the dut that needs to be changed/modified
        - newInfoDict is a dictionary that contains the updated DUT information
    '''

    dutUrl = "%s/ixload/test/activeTest/dutList/%s" % (sessionUrl, dutId)
    performGenericPatch(connection, dutUrl, newInfoDict)


def editDutConfig(connection, dutUrl, configDict):
    '''
        This method is used to modify the settings found in the dutConfig page and its subpages
        Returns a dictionary with either the reply from the server for patch/delete and the objectId for post actions as value,
        and the corresponding networkDict as a key

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - dutUrl is the address of the dut that needs to be changed/modified
        - configDict is a list that contains the actions needed to be performed on the target DUT, and dictionaries with the information required for every action

        Example dictionary:
        {
            "post":
            {
                "originateNetwork.<arbitraryIdentifier1>": {}
                "originateNetwork.<arbitraryIdentifier2>":
                {
                    "ipCount": "200",
                    "firstIp": "10.10.10.10"
                }
            }
            "patch":
            {
                "terminateNetwork.<validObjectId1>":
                {
                    "ipCount": "500"
                }
            }
        }

        Format for network/protocol names:
            - Server Load Balancer: slb.<identifier>
            - Packet Switch: originateNetwork.<id>, terminateNetwork.<id>, terminateProtocolPort.<id>, originateProtocolPort.<id>
            - Virtual DUT: network.<id>, protocolPort.<id>
    '''

    actionDict = {
        "post": performGenericPost,
        "patch": performGenericPatch,
        "delete": performGenericDelete
    }
#   We hard code the order in which we want the actions to be performed
    actionOrder = ["post", "patch", "delete"]


    noRangeListDuts = ["Firewall", "ExternalServer"]
    rangeListDuts = ["PacketSwitch", "ServerLoadBalancer", "VirtualDut"]
    dutType = connection.httpGet(dutUrl).type
    dutRangesInfo = {}
    if dutType in noRangeListDuts:
        dutConfigUrl = "%s/dutConfig" % (dutUrl)
        performGenericPatch(connection, dutConfigUrl, configDict)
    elif dutType in rangeListDuts:
        for action in actionOrder:
            if action in configDict:
                for networkInfo in configDict[action]:
                    networkInfoList = networkInfo.split('.')
                    if action == "post":
                        dutListUrl = "%s/dutConfig/%sRangeList" % (dutUrl, networkInfoList[0])
                    else:
                        dutListUrl = "%s/dutConfig/%sRangeList/%s" % (dutUrl, networkInfoList[0], networkInfoList[1])
                    dutRangesInfo[networkInfo] = actionDict[action](connection, dutListUrl, configDict[action][networkInfo])

    return dutRangesInfo


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

    for communityName, activityList in iteritems(activityListPerCommunity):
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


def deleteSessionLogs (connection, sessionUrl):
    '''
        This method is used to delete the logs of a session. (client logs of the IxLoad process + IxLoadRest log)

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that will have its logs deleted
    '''
    performGenericPatch(connection, sessionUrl, {'deleteLogsOnSessionClose': True})


def deleteVersionLogs(connection, version):
    '''
        This method is used to delete all logs of an IxLoad version. (all client logs for that version + all IxLoadRest logs for sessions that used that version)

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - version is the version number of the IxLoad that will have its logs deleted (e.g. 8.50.0.1)
    '''
    data = {'appVersion': version}
    performGenericOperation(connection, 'logs/operations/deleteVersionLogs', data)


def deleteAllLogs(connection):
    '''
        This method is used to delete all logs of all IxLoad versions used to create sessions.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
    '''
    performGenericOperation(connection, 'logs/operations/deleteAllLogs', {})


def generateReport(connection, sessionUrl, reportName):
    '''
        This method is used to genererate a PDF report when running from REST API.

        Args:
        - connection is the connection object that manages the HTTP data transfers between the client and the REST API
        - sessionUrl is the address of the session that will have its logs deleted
        - reportName is the full name of the report file to be generated (in .pdf format)
    '''
    generateReportUrl = "%s/ixload/test/operations/generateRestReport"  % (sessionUrl)
    data = {"reportFile": reportName}

    performGenericOperation(connection, generateReportUrl, data)


# To be used for removing '/api/v0/' from a link
def normalizeLink(link):
    pattern = re.search(r'/api/v[01]/', link)
    if pattern:
        return link.replace(pattern.group(), '')


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
                        return normalizeLink(link.href)
                else:
                    raise Exception('Plugin %s does not have a rangeList with rangeListType %s' % (pluginName, rangeListType))
            else:
                childrenNodesUrl = None
                for link in node.links:
                    if link.rel == 'childrenList':
                        childrenNodesUrl = normalizeLink(link.href)
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
                        childrenNodesUrl = normalizeLink(link.href)
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
                        return normalizeLink(link.href)
                else:
                    raise Exception('Plugin %s does not have the childrenList option.' % parentPluginName)
            else:
                childrenNodesUrl = None
                for link in node.links:
                    if link.rel == 'childrenList':
                        childrenNodesUrl = normalizeLink(link.href)
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
    def getIPRange(connection, sessionUrl, communityName, pluginName, rangeListType, rangeName):
        rangeUrl=NetworkUtils.getRangeUrl(connection, sessionUrl, communityName, pluginName, rangeListType, rangeName)
        range=connection.httpGet(url=rangeUrl)
        return range.ipAddress

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


class POP3Utils(ActivityNetworkMixinUtils):

    @staticmethod
    def addPOP3Command(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = POP3Utils.getActivityByName(connection, sessionUrl, communityName, activityName)
        POP3CommandsUrl = '%s/%s/agent/commandList' % (activityListUrl, activity.objectID)
        performGenericPost(connection, POP3CommandsUrl, optionsDict)

    @staticmethod
    def addMailMessage(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = POP3Utils.getActivityByName(connection, sessionUrl, communityName, activityName)
        POP3MailsUrl = '%s/%s/agent/mailBox' % (activityListUrl, activity.objectID)
        performGenericPost(connection, POP3MailsUrl, optionsDict)

    @staticmethod
    def changeMailMessageType(connection, sessionUrl, communityName, activityName, commandNumber,optionsDict):
        activityListUrl, activity = POP3Utils.getActivityByName(connection, sessionUrl, communityName, activityName)
        POP3MailBoxUrl = '%s/%s/agent/mailBox' % (activityListUrl, activity.objectID)
        POP3Commands = connection.httpGet(url=POP3MailBoxUrl)
        for POP3Command in POP3Commands:
            if POP3Command.objectID == commandNumber:
                POP3CommandUrl = '%s/%s' % (POP3MailBoxUrl, POP3Command.objectID)
                performGenericPatch(connection,POP3CommandUrl, optionsDict)
                break
        else:
            raise Exception('Community %s, activity %s does not have a command with the number %s' % (communityName, activityName, commandNumber))


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


class cifsUtils(ActivityNetworkMixinUtils):

    @staticmethod
    def addCifsCommand(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = cifsUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        cifsCommandsUrl = '%s/%s/agent/pm/commands' % (activityListUrl, activity.objectID)
        performGenericPost(connection, cifsCommandsUrl, optionsDict)

    @staticmethod
    def addFileToCifsServer(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = cifsUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        cifsCommandsUrl = '%s/%s/agent/pm/sharedPool' % (activityListUrl, activity.objectID)
        performGenericPost(connection, cifsCommandsUrl, optionsDict)


class StatelessPeerUtils(ActivityNetworkMixinUtils):

    @staticmethod
    def addStatelessPeerCommand(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = StatelessPeerUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        StatelessPeerCommandsUrl = '%s/%s/agent/pm/protocolFlows' % (activityListUrl, activity.objectID)
        performGenericPost(connection, StatelessPeerCommandsUrl, optionsDict)


class SMTPUtils(ActivityNetworkMixinUtils):

    @staticmethod
    def addSMTPCommand(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = SMTPUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        SMTPCommandsUrl = '%s/%s/agent/commandList' % (activityListUrl, activity.objectID)
        performGenericPost(connection, SMTPCommandsUrl, optionsDict)

    @staticmethod
    def changeMailMesage(connection, sessionUrl, communityName, activityName,commandName, optionsDict):
        activityListUrl, activity = SMTPUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        smtpCommandsListUrl = '%s/%s/agent/commandList/' % (activityListUrl, activity.objectID)
        smtpCommands = connection.httpGet(url=smtpCommandsListUrl)
        for smtpCommand in smtpCommands:
            if smtpCommand.cmdName == commandName:
                smtpCommandUrl = '%s/%s' % (smtpCommandsListUrl, smtpCommand.objectID)
                performGenericPatch(connection, smtpCommandUrl, optionsDict)
                break
        else:
            raise Exception('Community %s, activity %s does not have a command named %s' % (communityName, activityName, commandName))


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


class IPTVUtils(ActivityNetworkMixinUtils):

    @staticmethod
    def addIPTVCommand(connection, sessionUrl, communityName, activityName, optionsDict):
        activityListUrl, activity = IPTVUtils.getActivityByName(connection, sessionUrl, communityName, activityName)
        iptvCommandsUrl = '%s/%s/agent/pm/commands' % (activityListUrl, activity.objectID)
        performGenericPost(connection, iptvCommandsUrl, optionsDict)
