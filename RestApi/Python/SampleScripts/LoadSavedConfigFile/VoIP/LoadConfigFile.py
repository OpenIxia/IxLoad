

# Description
#   Load a saved VoIP .crf config file.
#
#   In the IxLoad GUI, "export" the VoIP config to a .crf file
#   This script will use the rest api /operations/importConfig to load the .crf file.
#   Which will decompress the .crf file and comes with the .rxf and .tst files.
#   
#   This sample script also has SSH capabilities to retrieve all the statistic csv result
#   files to anywhere on your local file system and optionally, you could also delete them in the Gateway
#   server as clean up.
#
#   If you want to retrieve results from a Windows Gateway server, you must install and enable
#   OpenSSH so the script could connect to it.
#   Here is a link on how to install and set up OpenSSH for Windows.
#       http://openixia.amzn.keysight.com/tutorials?subject=Windows&page=sshOnWindows.html
#
#
#   This will will:
#     - Import the .crf config file. 
#     - Reassign ports 
#     - Run traffic
#     - Get stats
#     - Optinal: Retrieves the results folder to your local Linux filesystem.
#
# Requirements
#    - IxL_RestApi.py libary file.
#    - sshAssistant.py
#    - .crf config file
#    - For Windows: The VoIP folder must exists in the c:\VoIP.
#   

import os, sys, time, signal, traceback

baseDir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, baseDir.replace('SampleScripts/LoadSavedConfigFile', 'Modules'))

from IxL_RestApi import *

# Choices: linux or windows 
serverOs = 'windows'

# CLI parameter input:  windows|linux
if len(sys.argv) > 1:
    serverOs = sys.argv[1]

# It is mandatory to include the exact IxLoad version.
#ixLoadVersion = '8.50.115.124'
ixLoadVersion = '8.50.115.333'

# Do you want to delete the session at the end of the test or if the test failed?
deleteSession = True

if serverOs == 'windows':
    apiServerIp = '192.168.70.3'
    resultsDir = 'c:\\Results'

    # For SSH only, to copy results off of Windows to local filesystem.
    sshUsername = 'hgee'
    sshPasswordFile = '/mnt/hgfs/Utilities/vault'
    
    with open (sshPasswordFile, 'r') as pwdFile:
        sshPassword = pwdFile.read().strip()
            
    # IMPORTANT NOTE: For Windows: The c:\\VoIP folder must exist in the IxLoad Gateway server.
    #                 The folder could be anywhere in your c:. Doesn't have to be c:\\VoIP
    localCrfFileToUpload = 'voipSip.crf'
    crfFileOnServer = 'c:\\VoIP\\voipSip.crf'

if serverOs == 'linux':
    apiServerIp = '192.168.70.129'
    sshUsername = 'ixload'  ;# Leave as default if you did not change it
    sshPassword = 'ixia123' ;# Leave as default if you did not change it
    resultsDir = '/mnt/ixload-share/Results' ;# Default
    localCrfFileToUpload = 'voipSip.crf' ;# The .crf config file to import

    # Where to put it in the Linux Gateway server. Always begin with /mnt/ixload-share 
    crfFileOnServer = '/mnt/ixload-share/VoIP/voipSip.crf'

apiServerIpPort = 8443 ;# http=8080.  https=8443 (https is supported starting 8.50)
licenseServerIp = '192.168.70.3'
# licenseModel choices: 'Subscription Mode' or 'Perpetual Mode'
licenseModel = 'Subscription Mode'

# To record stats to CSV file: True or False
csvStatFile = False

# Enable timestamp to not overwrite the previous csv file: True or False
csvEnableFileTimestamp = False

# To add a custom ID name to the beginning of the CSV file: string format
csvFilePrependName = None
pollStatInterval = 2

# Assign ports for testing.
# Format = (cardId,portId)
# 'Traffic1@Network1' are activity names.
# To get the Activity names: /ixload/test/activeTest/communityList
communityPortList1 = {
    'chassisIp': '192.168.70.128',
    'Traffic1@Network1': [(1,1)],
}

communityPortList2 = {
    'chassisIp': '192.168.70.128',
    'Traffic2@Network2': [(2,1)],
}


# Stat names to display at run time:
#     https://www.openixia.com/tutorials?subject=ixLoad/getStatName&page=fromApiBrowserForRestApi.html
statsDict = {
    'SIP(VoIPSip)': ['SIP Requests Parsed', 'SIP Requests Matched'],
    'RTP(VoIPSip)': ['Successful Records', 'Successful Playbacks'],
    'Signaling(VoIPSip)': ['Received Calls', 'Answered Calls']
}

try:
    restObj = Main(apiServerIp=apiServerIp, apiServerIpPort=apiServerIpPort, osPlatform=serverOs,
                   deleteSession=deleteSession, generateRestLogFile=True)

    restObj.connect(ixLoadVersion, timeout=120)
    restObj.configLicensePreferences(licenseServerIp=licenseServerIp, licenseModel=licenseModel)
    restObj.setResultDir(resultsDir, createTimestampFolder=True)
    restObj.deleteLogsOnSessionClose()
    restObj.importCrfFile(crfFileOnServer, localCrfFileToUpload)

    #if 'communityPortList' in locals():
    #    restObj.assignChassisAndPorts([communityPortList1, communityPortList2])
    restObj.assignChassisAndPorts([communityPortList1, communityPortList2])

    restObj.enableForceOwnership()

    # Modify the sustain time
    restObj.configTimeline(name='Timeline1', sustainTime=12)

    restObj.getStatNames()
    runTestOperationsId = restObj.runTraffic()
    restObj.pollStats(statsDict, pollStatInterval=pollStatInterval, csvFile=csvStatFile,
                      csvEnableFileTimestamp=csvEnableFileTimestamp, csvFilePrependName=csvFilePrependName)

    # Wait if your configuration has port capturing enabled
    restObj.waitForAllCapturedData()
    restObj.waitForActiveTestToUnconfigure()
    resultPath = restObj.getResultPath()

    if serverOs == 'linux':
        # SSH to the Gateway to retrieve the csv stat results and delete them in the server.
        # SSH is enabled on a Linux Gateway, but more than likely, you don't have OpenSSH enabled on your Windows.
        # You could modify this condition to include Windows if you have SSH enabled.
        restObj.sshSetCredentials(sshUsername, sshPassword, sshPasswordFile=None,  port=22)
        restObj.scpFiles(sourceFilePath=resultPath, destFilePath='.', typeOfScp='download')
        restObj.deleteFolder(filePath=resultPath)

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
 
