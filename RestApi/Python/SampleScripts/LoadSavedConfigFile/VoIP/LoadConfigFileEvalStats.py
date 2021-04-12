

# Description
#   Load a saved VoIP .crf config file.
#
#   In the IxLoad GUI, "export" the VoIP config to a .crf file
#   This script will use the rest api /operations/importConfig to load the .crf file.
#   Which will decompress the .crf file and comes with the .rxf and .tst files.
#
#   What the script will do:
#     - Import the .crf config file. 
#     - Reassign ports 
#     - Run traffic
#     - Get stats
#     - Download csv result stats
#
# Requirements
#    - IxL_RestApi.py libary file.
#    - A saved VoIP .crf config file
#    - For Windows: The VoIP folder must exists in the c:\VoIP.
#

import os, sys, time, signal, traceback, platform

# Insert the Modules path to the system's memory in order to import IxL_RestApi.py
currentDir = os.path.abspath(os.path.dirname(__file__))

if platform.system() == 'Windows':
    sys.path.insert(0, (currentDir.replace('SampleScripts\\LoadSavedConfigFile\\VoIP', 'Modules')))
else:
    sys.path.insert(0, (currentDir.replace('SampleScripts/LoadSavedConfigFile/VoIP', 'Modules')))

from IxL_RestApi import *

# Choices of IxLoad Gateway server OS: linux or windows 
serverOs = 'linux'

# Which IxLoad version are you using for your test?
# To view all the installed versions, go on a web browser and enter: 
#    http://<server ip>:8080/api/v0/applicationTypes
ixLoadVersion = '9.10.115.43'

# Do you want to delete the session at the end of the test or if the test failed?
deleteSession = True
forceTakePortOwnership = True

crfFile = 'voipSip.crf'

# API-Key: Use your user API-Key if you want added security
apiKey = None

if serverOs == 'windows':
    apiServerIp = '192.168.129.6'

    # Where to store the results on the Windows filesystem
    resultsDir = 'c:\\Results'

    # Where to put the crf file or where to tell IxLoad the location in the Windows filesystem
    crfFileOnServer = 'c:\\VoIP\\{}'.format(crfFile)

if serverOs == 'linux':
    apiServerIp = '192.168.129.24'

    # Leave as defaults. For your reference only.
    resultsDir = '/mnt/ixload-share/Results' 

    # Leave as default
    crfFileOnServer = '/mnt/ixload-share/VoIP/{}'.format(crfFile)

# Where to put the downloaded saved csv results
saveResultsInPath = currentDir

# Where is the VoIP .crf file located on your local filesystem to be uploaded to the IxLoad Gateway server
# In this example, get it from the current folder.
localConfigFileToUpload = '{}/{}'.format(currentDir, crfFile)

# For IxLoad versions prior to 8.50 that doesn't have the rest api to download results.
# Set to True if you want to save realtime results to CSV files.
saveStatsToCsvFile = False

# Where to put the csv results on your local system. This example puts it in the current directory.
scpResultsDestPath = currentDir

apiServerIpPort = 8443 ;# http=8080.  https=8443 (https is supported starting 8.50)

# licenseModel choices: 'Subscription Mode' or 'Perpetual Mode'
licenseModel = 'Subscription Mode'
licenseServerIp = '192.168.129.6'

# Assign ports for testing.  Format = (cardId,portId)
# 'Traffic1@Network1' are activity names.
# To get the Activity names, go to: /ixload/test/activeTest/communityList
communityPortList1 = {
    'chassisIp': '192.168.129.15',
    'Traffic1@Network1': [(1,1)],
}

communityPortList2 = {
    'chassisIp': '192.168.129.15',
    'Traffic2@Network2': [(1,2)],
}

# Stat names to display at run time.
# To see how to get the stat names, go to the link below for step-by-step guidance:
#     https://www.openixia.com/tutorials?subject=ixLoad/getStatName&page=fromApiBrowserForRestApi.html
#
# What this does: 
#    Get run time stats and evaluate the stats with an operator and the expected value.
#    Due to stats going through ramp up and ramp down, stats will fluctuate.
#    Once the stat hits and maintains the expected threshold value, the stat is marked as passed.
#    
#    If evaluating stats at run time is not what you need, use PollStats() instead shown
#    in sample script LoadConfigFile.py
#
# operator options:  None, >, <, <=, >=
statsDict = {
    'SIP(VoIPSip)': [{'caption': 'SIP Requests Parsed',  'operator': '>=', 'expect': 1},
                     {'caption': 'SIP Requests Matched', 'operator': '>=', 'expect': 1},
                    ],
    'RTP(VoIPSip)': [{'caption': 'Successful Records',   'operator': '>=', 'expect': 1},
                     {'caption': 'Successful Playbacks', 'operator': '>=', 'expect': 1}
                    ],
    'Signaling(VoIPSip)': [{'caption': 'Received Calls', 'operator': '>=', 'expect': 1},
                           {'caption': 'Answered Calls', 'operator': '>', 'expect': 1}
                          ]
}

try:
    restObj = Main(apiServerIp=apiServerIp,
                   apiServerIpPort=apiServerIpPort,
                   osPlatform=serverOs,
                   deleteSession=deleteSession,
                   pollStatusInterval=1,
                   apiKey=apiKey,
                   generateRestLogFile=True)

    restObj.connect(ixLoadVersion, sessionId=None, timeout=120)
    restObj.configLicensePreferences(licenseServerIp=licenseServerIp, licenseModel=licenseModel)
    restObj.setResultDir(resultsDir, createTimestampFolder=True)
    restObj.deleteLogsOnSessionClose()
    restObj.importCrfFile(crfFileOnServer, localConfigFileToUpload)
    restObj.assignChassisAndPorts([communityPortList1, communityPortList2])

    if forceTakePortOwnership:
        restObj.enableForceOwnership()

    # Optional: Modify the sustain time
    restObj.configTimeline(name='Timeline1', sustainTime=12)

    runTestOperationsId = restObj.runTraffic()

    restObj.pollStatsAndCheckStatResults(statsDict,
                                         csvFile=saveStatsToCsvFile,
                                         csvFilePrependName=None,
                                         pollStatInterval=2,
                                         exitAfterPollingIteration=None)
    
    testResult = restObj.getTestResults()

    # Wait if your configuration has port capturing enabled
    restObj.waitForAllCapturedData()
    restObj.waitForActiveTestToUnconfigure()

    restObj.downloadResults(targetPath=saveResultsInPath)

    if deleteSession:
        restObj.deleteSessionId()

    if testResult['result'] == 'Failed':
        sys.exit(1)
        
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
 
