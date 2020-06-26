

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
    sys.path.insert(0, (currentDir).replace('SampleScripts\\LoadSavedConfigFile\\VoIP', 'Modules')))
else:
    sys.path.insert(0, (currentDir.replace('SampleScripts/LoadSavedConfigFile/VoIP', 'Modules')))

from IxL_RestApi import *

# Choices of IxLoad Gateway server OS: linux or windows 
serverOs = 'windows'

# Which IxLoad version are you using for your test?
# To view all the installed versions, go on a web browser and enter: 
#    http://<server ip>:8080/api/v0/applicationTypes
#ixLoadVersion = '8.50.115.333'
ixLoadVersion = '9.00.0.347'

# Do you want to delete the session at the end of the test or if the test failed?
deleteSession = True
forceTakePortOwnership = True

if serverOs == 'windows':
    apiServerIp = '192.168.70.3'

    # Where to store the results on the Windows filesystem
    resultsDir = 'c:\\Results'

    # Where to put or get the .crf file in the Windows filesystem
    crfFileOnServer = 'c:\\VoIP\\voipSip.crf'

if serverOs == 'linux':
    apiServerIp = '192.168.70.129'

    # Leave as defaults. For your reference only.
    resultsDir = '/mnt/ixload-share/Results' 

    # Where to put the config file in the Linux Gateway server. Always begin with /mnt/ixload-share 
    crfFileOnServer = '/mnt/ixload-share/VoIP/voipSip.crf'


# Where is the VoIP .crf file located on your local filesystem to be uploaded to the IxLoad Gateway server
# In this example, get it from the current folder.
localConfigFileToUpload = '{}/{}'.format(currentDir, 'voipSip.crf')

# For IxLoad versions prior to 8.50 that doesn't have the rest api to download results.
# Set to True if you want to save realtime results to CSV files.
saveStatsToCsvFile = False

# Where to put the csv results on your local system. This example puts it in the current directory.
scpResultsDestPath = currentDir

apiServerIpPort = 8443 ;# http=8080.  https=8443 (https is supported starting 8.50)

# licenseModel choices: 'Subscription Mode' or 'Perpetual Mode'
licenseModel = 'Subscription Mode'
licenseServerIp = '192.168.70.3'

# Assign ports for testing.  Format = (cardId,portId)
# 'Traffic1@Network1' are activity names.
# To get the Activity names, go to: /ixload/test/activeTest/communityList
communityPortList1 = {
    'chassisIp': '192.168.70.128',
    'Traffic1@Network1': [(1,1)],
}

communityPortList2 = {
    'chassisIp': '192.168.70.128',
    'Traffic2@Network2': [(2,1)],
}

# Stat names to display at run time.
# To see how to get the stat names, go to the link below for step-by-step guidance:
#     https://www.openixia.com/tutorials?subject=ixLoad/getStatName&page=fromApiBrowserForRestApi.html
statsDict = {
    'SIP(VoIPSip)':       ['SIP Requests Parsed', 'SIP Requests Matched'],
    'RTP(VoIPSip)':       ['Successful Records', 'Successful Playbacks'],
    'Signaling(VoIPSip)': ['Received Calls', 'Answered Calls']
}

try:
    restObj = Main(apiServerIp=apiServerIp,
                   apiServerIpPort=apiServerIpPort,
                   osPlatform=serverOs,
                   deleteSession=deleteSession,
                   generateRestLogFile=True)

    restObj.connect(ixLoadVersion, sessionId=None, timeout=120)
    restObj.configLicensePreferences(licenseServerIp=licenseServerIp, licenseModel=licenseModel)
    restObj.setResultDir(resultsDir, createTimestampFolder=True)
    restObj.deleteLogsOnSessionClose()
    restObj.importCrfFile(crfFileOnServer, localConfigFileToUpload)
    restObj.assignChassisAndPorts([communityPortList1, communityPortList2])

    if forceTakePortOwnership:
        restObj.enableForceOwnership()

    # Modify the sustain time
    restObj.configTimeline(name='Timeline1', sustainTime=12)

    runTestOperationsId = restObj.runTraffic()

    restObj.pollStats(statsDict,
                      csvFile=saveStatsToCsvFile, 
                      pollStatInterval=2, 
                      csvEnableFileTimestamp=True,
                      csvFilePrependName=None)

    # Wait if your configuration has port capturing enabled
    restObj.waitForAllCapturedData()
    restObj.waitForActiveTestToUnconfigure()

    restObj.downloadResults()

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
 
