# Description
#   A sample Python REST API script to:
#      - Load a saved configuration file
#      - Enable port analyzer
#      - Run traffic
#      - Get stats to local folder.
#      - Retrieve port capture files to local folder.
#
#   Supports both Windows and Linux gateway Server. If connecting to a 
#
#   If the saved config file is located on a remote pc, this script could upload it to the gateway.
#   Otherwise, the saved config file must be already in the IxLoad API gateway server.
#
# Requirements
#    Python2.7 or Python3
#    IxL_RestApi.py 

import os, sys, time, signal, traceback, platform

# Insert the Modules path to env in order to import IxL_RestApi.py
currentDir = os.path.abspath(os.path.dirname(__file__))

if platform.system() == 'Windows':
    sys.path.insert(0, (currentDir.replace('SampleScripts\\LoadSavedConfigFile', 'Modules')))
else:
    sys.path.insert(0, (currentDir.replace('SampleScripts/LoadSavedConfigFile', 'Modules')))

from IxL_RestApi import *

# Choices of IxLoad Gateway server OS: linux or windows 
serverOs = 'linux'

# Which IxLoad version are you using for your test?
# To view all the installed versions, go on a web browser and enter: 
#    http://<server ip>:8080/api/v0/applicationTypes
ixLoadVersion = '8.50.115.333'
ixLoadVersion = '9.00.0.347'   ;# EA
ixLoadVersion = '9.00.115.204' ;# Update-2
ixLoadVersion = '9.10.0.311'   ;# EA

# Do you want to delete the session at the end of the test or if the test failed?
deleteSession = True
forceTakePortOwnership = True

# The saved config file to load
rxfFile = 'IxL_Http_Ipv4Ftp_vm_8.20.rxf'

if serverOs == 'windows':
    apiServerIp = '192.168.70.3'

    # Where to store all of the csv result files in Windows
    resultsDir = 'c:\\Results'

    # Where to upload the rxf config file or where to IxLoad the location if you're not uploading it.
    rxfFileOnServer = 'C:\\Results\\{}'.format(rxfFile)

if serverOs == 'linux':
    apiServerIp = '192.168.70.129'

    # Leave as defaults. For your reference only.
    resultsDir = '/mnt/ixload-share/Results'

    # Leave as default
    rxfFileOnServer = '/mnt/ixload-share/{}'.format(rxfFile)

# Where to put the downloaded csv results
saveResultsInPath = currentDir

# Do you need to upload your saved config file to the server?
# If not, a saved config must be already in the IxLoad gateway server filesystem.
upLoadFile = True

# The path to the saved config file. In this example, get it from the current folder
localConfigFileToUpload = '{}/{}'.format(currentDir, rxfFile)

# The path where you want to download the csv result files to.  This is mostly used if using a Linux Gateway server.
# If you're using IxLoad in Windows, SSH must be installed.  Otherwise, this variable will be ignored.
scpDestPath = currentDir

# For IxLoad versions prior to 8.50 that doesn't have the rest api to download results.
# Set to True if you want to save run time stat results to CSV files.
saveStatsToCsvFile = True

apiServerIpPort = 8443 ;# http=8080.  https=8443 (https is supported starting 8.50)

licenseServerIp = '192.168.70.3'
# licenseModel choices: 'Subscription Mode' or 'Perpetual Mode'
licenseModel = 'Subscription Mode'

# To assign ports for testing.  Format = (cardId,portId)
#    Traffic1@Network1 are activity names.
#    To get the Activity names, go to: /ixload/test/activeTest/communityList
communityPortList1 = {
    'chassisIp': '192.168.70.15',
    'Traffic1@Network1': [(1,1)],
}

communityPortList2 = {
    'chassisIp': '192.168.70.15',
    'Traffic2@Network2': [(1,2)],
}

# Stat names to display at run time.
# To see how to get the stat names, go to the link below for step-by-step guidance:
#     https://www.openixia.com/tutorials?subject=ixLoad/getStatName&page=fromApiBrowserForRestApi.html
statsDict = {
    'HTTPClient': ['TCP Connections Established',
                   'HTTP Simulated Users',
                   'HTTP Connections',
                   'HTTP Transactions',
                   'HTTP Connection Attempts'
               ],
    'HTTPServer': ['TCP Connections Established',
                   'TCP Connection Requests Failed'
               ]
}

try:
    restObj = Main(apiServerIp=apiServerIp,
                   apiServerIpPort=apiServerIpPort,
                   osPlatform=serverOs,
                   deleteSession=deleteSession,
                   generateRestLogFile=True)
        
    # sessionId is an opened existing session that you like to connect to instead of starting a new session.
    restObj.connect(ixLoadVersion, sessionId=None, timeout=120)
    
    restObj.configLicensePreferences(licenseServerIp=licenseServerIp, licenseModel=licenseModel)
    restObj.setResultDir(resultsDir, createTimestampFolder=True)

    if upLoadFile == True:
        restObj.uploadFile(localConfigFileToUpload, rxfFileOnServer)

    restObj.loadConfigFile(rxfFileOnServer)
    restObj.assignChassisAndPorts([communityPortList1, communityPortList2])

    if forceTakePortOwnership:
        restObj.enableForceOwnership()

    restObj.enableAnalyzerOnAssignedPorts()

    # Optional: Modify the sustain time
    restObj.configTimeline(name='Timeline1', sustainTime=12)

    # Example on how to use the configActivityAttribute function to modify
    # some of its attributes.  Pass in the names of community and activity from your configuration.
    restObj.configActivityAttributes(communityName='Traffic1@Network1',
                                     activityName='HTTPClient1',
                                     attributes={'userObjectiveValue': 100})
    
    runTestOperationsId = restObj.runTraffic()
        
    restObj.pollStats(statsDict,
                      csvFile=saveStatsToCsvFile,
                      csvFilePrependName=None,
                      pollStatInterval=2,
                      exitAfterPollingIteration=None)
    
    restObj.waitForActiveTestToUnconfigure()
    restObj.downloadResults(targetPath=saveResultsInPath)
    restObj.retrievePortCaptureFileForAssignedPorts(os.getcwd())

    if deleteSession:
        restObj.deleteSessionId()
        
except (IxLoadRestApiException, Exception) as errMsg:
    print('\n%s' % traceback.format_exc())
    if deleteSession:
        restObj.abortActiveTest()
        restObj.deleteSessionId()
        
    sys.exit(errMsg)

except KeyboardInterrupt:
    print('\nCTRL-C detected.')
    if deleteSession:
        restObj.abortActiveTest()
        restObj.deleteSessionId()
 
