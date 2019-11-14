

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
#       http://openixia.com/tutorials?subject=Windows&page=sshOnWindows.html
#
#
#   What the script will do:
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

sys.path.insert(0, (os.path.dirname(os.path.abspath(__file__).replace('SampleScripts/LoadSavedConfigFile/VoIP', 'Modules'))))
from IxL_RestApi import *

# Choices: linux or windows 
serverOs = 'linux'

# Prior to 9.0, it is mandatory to include the exact IxLoad version.
# To view all the installed versions, go on a web browser and enter: 
#    http://<server ip>:8080/api/v0/applicationTypes
#ixLoadVersion = '8.50.115.333'
ixLoadVersion = '9.00.0.347'

# Do you want to delete the session at the end of the test or if the test failed?
deleteSession = False
forceTakePortOwnership = True

if serverOs == 'windows':
    apiServerIp = '192.168.70.3'

    # Where to store the results on the Windows filesystem
    resultsDir = 'c:\\Results'

    # For SSH only, to copy results off of Windows to local filesystem.
    sshUsername = 'hgee'
    sshPassword = os.environ['windowsPasswd']
    #sshPasswordFile = '/mnt/hgfs/Utilities/vault' ;# Alternative password retreiving method
    
    # Where to put or get the .crf file in the Windows filesystem
    crfFileOnServer = 'c:\\VoIP\\voipSip.crf'

if serverOs == 'linux':
    apiServerIp = '192.168.70.129'
    sshUsername = 'ixload'  
    sshPassword = 'ixia123'

    # Leave as defaults. For your reference only.
    resultsDir = '/mnt/ixload-share/Results' 

    # Where to put the config file in the Linux Gateway server. Always begin with /mnt/ixload-share 
    crfFileOnServer = '/mnt/ixload-share/VoIP/voipSip.crf'

# Where is the VoIP .crf file located on your local filesystem to be uploaded to the IxLoad Gateway server
localConfigFileToUpload = '/home/hgee/OpenIxiaGit/IxLoad/RestApi/Python/SampleScripts/LoadSavedConfigFile/VoIP/voipSip.crf'

scpRetrieveResults = True

# Where to put SCP the csv results on your local system
scpResultsDestPath = '/home/hgee/OpenIxiaGit/IxLoad/RestApi/Python/SampleScripts/LoadSavedConfigFile/VoIP'

apiServerIpPort = 8443 ;# http=8080.  https=8443 (https is supported starting 8.50)

licenseServerIp = '192.168.70.3'
# licenseModel choices: 'Subscription Mode' or 'Perpetual Mode'
licenseModel = 'Subscription Mode'

class getCsvStats:
    '''                                                                                                                                                                       
    CSV stat polling is mainly for Windows because it doesn't have OpenSSH installed                                                                                          
    for SCP to retrieve results.                                                                                                                                              
    '''
    # Set to True if you want to save results to CSV files.
    # Mainly used when using a Windows gateway server because Windows don't come with SSH
    # to SCP CSV result files.
    saveStatsToCsvFile = True

    # Enable timestamp to prevent overwriting the previous csv file
    csvEnableFileTimestamp = False

    # To add a custom name to the beginning of the CSV file
    csvFilePrependName = None
    pollStatInterval = 2


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
                      csvFile=getCsvStats.saveStatsToCsvFile, 
                      pollStatInterval=getCsvStats.pollStatInterval, 
                      csvEnableFileTimestamp=getCsvStats.csvEnableFileTimestamp,
                      csvFilePrependName=getCsvStats.csvFilePrependName)

    # Wait if your configuration has port capturing enabled
    restObj.waitForAllCapturedData()
    restObj.waitForActiveTestToUnconfigure()

    if scpRetrieveResults:
        # SSH to the server to retrieve the csv stat results and delete them in the server.                                                                                   
        # SSH is enabled on a Linux Gateway, but if you're connecting a Windows gateway, more than likely,                                                                    
        # you don't have OpenSSH enabled or installed in your Windows.  In this case, you need to install OpenSSH.                                                            
        if 'sshPasswordFile' in locals():
            sshPassword = restObj.readFile(sshPasswordFile)

        restObj.sshSetCredentials(sshUsername, sshPassword, port=22)
        restObj.scpFiles(sourceFilePath=restObj.getResultPath(), destFilePath=scpResultsDestPath, typeOfScp='download')
        restObj.deleteFolder(filePath=restObj.getResultPath())

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
 
