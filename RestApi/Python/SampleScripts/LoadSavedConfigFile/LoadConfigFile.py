

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
#       http://openixia.amzn.keysight.com/tutorials?subject=Windows&page=sshOnWindows.html
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

baseDir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, baseDir.replace('SampleScripts', 'Modules'))

from IxL_RestApi import *

# Choices: linux or windows 
serverOs = 'linux'

# Versions prior to 9.0 is mandatory to include the exact IxLoad version.
# You could view all of your installed versions by entering on a web browser: 
#    http://<server ip>:8080/api/v0/applicationTypes
ixLoadVersion = '8.50.115.333'
ixLoadVersion = '9.00.0.347'

# Do you want to delete the session at the end of the test or if the test failed?
deleteSession = True
forceTakePortOwnership = True

# CLI parameter input:  windows|linux
if len(sys.argv) > 1:
    serverOs = sys.argv[1]

if serverOs == 'windows':
    apiServerIp = '192.168.70.3'

    # Where to store all of the csv result files in Windows
    resultsDir = 'c:\\Results'

    # Where to upload the config file or where to find it if you're not uploading it.
    rxfFileOnServer = 'C:\\Results\\IxL_Http_Ipv4Ftp_vm_8.20.rxf'

    # Optional: For SSH only. To copy results off of Windows gateway server to local filesystem.
    sshUsername = 'hgee'

    # Set sshPasswordFile to None if you don't want to SSH the results.
    sshPasswordFile = '/mnt/hgfs/Utilities/vault'

    if sshPasswordFile:
        with open (sshPasswordFile, 'r') as pwdFile:
            sshPassword = pwdFile.read().strip()


if serverOs == 'linux':
    apiServerIp = '192.168.70.129'
    sshUsername = 'ixload'  ;# Leave as default if you did not change it
    sshPassword = 'ixia123' ;# Leave as default if you did not change it
    resultsDir = '/mnt/ixload-share/Results' ;# Default

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
    # If your Windows have OpenSSH installed, set csvStatFile = True
    # If your Windows don't have OpenSSH installed, set csvStatFile = False
    csvStatFile = False

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

# Stat names to display at run time:
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
    restObj = Main(apiServerIp=apiServerIp, apiServerIpPort=apiServerIpPort, osPlatform=serverOs,
                   deleteSession=deleteSession, generateRestLogFile=True)

    restObj.connect(ixLoadVersion, sessionId=None, timeout=120)

    restObj.configLicensePreferences(licenseServerIp=licenseServerIp, licenseModel=licenseModel)
    restObj.setResultDir(resultsDir, createTimestampFolder=True)

    if upLoadFile == True:
        restObj.uploadFile(localConfigFileToUpload, rxfFileOnServer)

    restObj.loadConfigFile(rxfFileOnServer)
    restObj.assignChassisAndPorts([communityPortList1, communityPortList2])

    if forceTakePortOwnership:
        restObj.enableForceOwnership()

    # Modify the sustain time
    restObj.configTimeline(name='Timeline1', sustainTime=12)

    runTestOperationsId = restObj.runTraffic()

    restObj.pollStats(statsDict, pollStatInterval=getCsvStats.pollStatInterval, csvFile=getCsvStats.csvStatFile,
                      csvEnableFileTimestamp=getCsvStats.csvEnableFileTimestamp, csvFilePrependName=getCsvStats.csvFilePrependName)

    restObj.waitForActiveTestToUnconfigure()

    if scpRetrieveResults:
        # SSH to the server to retrieve the csv stat results and delete them in the server.
        # SSH is enabled on a Linux Gateway, but if you're connecting a Windows gateway, more than likely,
        # you don't have OpenSSH enabled or installed in your Windows.  In this case, you need to install OpenSSH.
        resultPath = restObj.getResultPath()
        restObj.sshSetCredentials(sshUsername, sshPassword, sshPasswordFile=None,  port=22)
        restObj.scpFiles(sourceFilePath=resultPath, destFilePath=scpDestPath, typeOfScp='download')
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
 
