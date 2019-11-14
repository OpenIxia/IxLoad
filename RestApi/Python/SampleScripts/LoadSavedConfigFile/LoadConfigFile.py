

# Description
#   A sample Python REST API script on loading a saved configuration,
#   run traffic and getting stats.
#
#   Supports both Windows and Linux gateway Server. If connecting to a 
#   Linux server, a license server running on Windows PC is still required unless it is 
#   installed in the chassis.
#   This script will configure the license server IP and license model on the Linux server.
#
#   If the saved config file is located locally, you could upload it to the gateway.
#   Otherwise, the saved config file must be already in the Windows filesystem.
#
#   This sample script also has SSH capabilities to retrieve all the statistic csv result
#   files to anywhere on your local file system and optionally, you could also delete them in the Gateway
#   server as clean up.

#   If you want to retrieve results from a Windows Gateway server, you must install and enable
#   OpenSSH so the script could connect to it. SSH is enabled by default if using a Linux Gateway server.
#   Here is a link on how to install and set up OpenSSH for Windows.
#       http://openixia.com/tutorials?subject=Windows&page=sshOnWindows.html
#
#   - Load a saved config .rxf file
#   - Run traffic
#   - Get stats
#
# Requirements
#    Python2.7 and Python3
#    IxL_RestApi.py 
#    Optional: sshAssistant.py

import os, sys, time, signal, traceback

sys.path.insert(0, (os.path.dirname(os.path.abspath(__file__).replace('SampleScripts/LoadSavedConfigFile', 'Modules'))))
from IxL_RestApi import *

# Choices: linux or windows 
serverOs = 'linux'

# Prior to 9.0, it is mandatory to include the exact IxLoad version.
# To view all the installed versions, go on a web browser and enter: 
#    http://<server ip>:8080/api/v0/applicationTypes
ixLoadVersion = '8.50.115.333'
ixLoadVersion = '9.00.0.347'

# Do you want to delete the session at the end of the test or if the test failed?
deleteSession = False
forceTakePortOwnership = True

if serverOs == 'windows':
    apiServerIp = '192.168.70.3'

    # Where to store all of the csv result files in Windows
    resultsDir = 'c:\\Results'

    # Where to upload the config file or where to find it if you're not uploading it.
    rxfFileOnServer = 'C:\\Results\\IxL_Http_Ipv4Ftp_vm_8.20.rxf'

    # Optional: For SSH only. To copy results off of Windows gateway server to local filesystem.
    sshUsername = 'hgee'
    sshPassword = os.environ['windowsPasswd']
    #sshPasswordFile = '/mnt/hgfs/Utilities/vault' ;# Alternative password retreival


if serverOs == 'linux':
    apiServerIp = '192.168.70.129'
    sshUsername = 'ixload'
    sshPassword = 'ixia123' 

    # Leave as defaults. For your reference only.
    resultsDir = '/mnt/ixload-share/Results'

    # Must be in the path /mnt/ixload-share
    rxfFileOnServer = '/mnt/ixload-share/IxL_Http_Ipv4Ftp_vm_8.20.rxf'


# Do you need to upload your saved config file to the server?
# If not, a saved config must be already in the Windows filesystem.
upLoadFile = True
localConfigFileToUpload = '/home/hgee/OpenIxiaGit/IxLoad/RestApi/Python/SampleScripts/LoadSavedConfigFile/IxL_Http_Ipv4Ftp_vm_8.20.rxf'

scpRetrieveResults = True
scpDestPath = '/home/hgee/OpenIxiaGit/IxLoad/RestApi/Python/SampleScripts/LoadSavedConfigFile'

apiServerIpPort = 8443 ;# http=8080.  https=8443 (https is supported starting 8.50)

licenseServerIp = '192.168.70.3'
# licenseModel choices: 'Subscription Mode' or 'Perpetual Mode'
licenseModel = 'Subscription Mode'

class getCsvStats:
    '''
    CSV stat polling is mainly for Windows because it doesn't have OpenSSH installed.  
    '''
    # Set to True if you want to save results to CSV files.
    # Mainly used when using a Windows gateway server because Windows don't come with SSH
    # to SCP CSV result files.
    saveStatsToCsvFile = True

    # Enable timestamp to avoid overwriting the previous csv result files: True or False
    csvEnableFileTimestamp = False

    # To add a custom name to the beginning of the CSV file
    csvFilePrependName = None
    pollStatInterval = 2


# To assign ports for testing.  Format = (cardId,portId)
# Traffic1@Network1 are activity names.
# To get the Activity names, got to: /ixload/test/activeTest/communityList
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

    restObj.connect(ixLoadVersion, sessionId=None, timeout=120)

    restObj.configLicensePreferences(licenseServerIp=licenseServerIp, licenseModel=licenseModel)
    restObj.setResultDir(resultsDir, createTimestampFolder=True)

    if upLoadFile == True:
        restObj.uploadFile(localConfigFileToUpload, rxfFileOnServer)

    restObj.loadConfigFile(rxfFileOnServer)
    restObj.assignChassisAndPorts([communityPortList1, communityPortList2])

    if forceTakePortOwnership:
        restObj.enableForceOwnership()

    # Optional: Modify the sustain time
    restObj.configTimeline(name='Timeline1', sustainTime=12)

    runTestOperationsId = restObj.runTraffic()

    restObj.pollStats(statsDict,
                      csvFile=getCsvStats.saveStatsToCsvFile,
                      pollStatInterval=getCsvStats.pollStatInterval,
                      csvEnableFileTimestamp=getCsvStats.csvEnableFileTimestamp,
                      csvFilePrependName=getCsvStats.csvFilePrependName)

    restObj.waitForActiveTestToUnconfigure()

    if scpRetrieveResults:
        # SSH to the server to retrieve the csv stat results and delete them in the server.
        # SSH is enabled on a Linux Gateway, but if you're connecting a Windows gateway, more than likely,
        # you don't have OpenSSH enabled or installed in your Windows.  In this case, you need to install OpenSSH.
        if 'sshPasswordFile' in locals():
            sshPassword = restObj.readFile(sshPasswordFile)

        restObj.sshSetCredentials(sshUsername, sshPassword, port=22)
        restObj.scpFiles(sourceFilePath=restObj.getResultPath(), destFilePath=scpDestPath, typeOfScp='download')
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
 
