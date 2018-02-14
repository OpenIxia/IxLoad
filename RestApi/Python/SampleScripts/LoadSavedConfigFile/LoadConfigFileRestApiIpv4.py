

# Description
#   A sample Python REST API script to demonstrate loading a saved configuration,
#   run traffic and getting stats.
#
#   This sample script supports both Windows and Linux Server. If connecting to a 
#   Linux server, a license server running on Windows PC is still required.
#   This script will configure the license server IP and license model on the Linux server.
#
#   - Load a saved config .rxf file
#   - Run traffic
#   - Get statss
#
# Requirements
#    Python2.7 minimum. (Supports Python2 and 3)
#    IxL_RestApi.py API file.

import os, sys, time, signal, traceback
from IxL_RestApi import *

# Choices: linux or windows 
serverOs = 'linux'
#
# It is mandatory to include the exact IxLoad version.
ixLoadVersion = '8.40.0.277'

# Do you want to delete the session if the test failed and at the end of the test? True|False
deleteSession = True

if serverOs == 'windows':
    # Windows settings
    apiServerIp = '192.168.70.3'
    apiServerIpPort = '8080'
    #rxfFile = 'C:\\Results\\IxL_Http_Ipv4Ftp_vm_8.30.rxf'
    rxfFile = 'C:\\Results\\IxL_Http_Ipv4Ftp_vm_8.20.rxf'

if serverOs == 'linux':
    # Linux settings.  Comment out these variables if you are using Windows.
    apiServerIp = '192.168.70.111'
    apiServerIpPort = '8080'
    localRxfFileToUpload = '/OpenIxiaGit/IxLoad/RestApi/Python/SampleScripts/LoadSavedConfigFile/IxL_Http_Ipv4Ftp_vm_8.20.rxf'
    rxfFile = '/mnt/ixload-share/IxL_Http_Ipv4Ftp_vm_8.30.rxf'

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


# To reassign ports, uncomment this and replace chassis and port values
# Format = (cardId,portId)
# To get the Activity names: http://<ip>:8080/api/v0/sessions/<id>/ixload/test/activeTest/communityList
communityPortList = {
    'chassisIp': '192.168.70.11',
    'Traffic1@Network1': [(1,1)],
    'Traffic2@Network2': [(2,1)]
}

# Set the stats to get and display at real time testing.
# To get the exact statistic names, go to IxLoad GUI and do a scriptgen on your configuration.
# To get the stat keyName (HTTPClient): http://192.168.70.127:8080/api/v0/sessions/63/ixLoad/stats/HTTPClient/availableStats
# Then open up the scriptgen file and do a keyword search for "statlist". Copy and paste the names here.
# HTTPCLIENT and HTTPServer must be exact also.
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
               ],
    #'FTPClient': ['FTP Concurrent Sessions', 
    #              'FTP Transactions'],
    #'FTPServer': ['FTP Control Conn Established']
}

try:
    restObj = Main(apiServerIp=apiServerIp, apiServerIpPort=apiServerIpPort, deleteSession=deleteSession)
    restObj.connect(ixLoadVersion)
    restObj.configLicensePreferences(licenseServerIp=licenseServerIp, licenseModel=licenseModel)

    # If connecting to Linux server, must upload the config file to the server first.
    if serverOs == 'linux':
        restObj.uploadFile(localRxfFileToUpload, rxfFile)

    restObj.loadConfigFile(rxfFile)

    if 'communityPortList' in locals():
        restObj.assignChassisAndPorts(communityPortList)

    restObj.enableForceOwnership()
    restObj.getStatNames()
    runTestOperationsId = restObj.runTrafficAndVerifySuccess()
    restObj.pollStats(statsDict, pollStatInterval=pollStatInterval, csvFile=csvStatFile,
                      csvEnableFileTimestamp=csvEnableFileTimestamp, csvFilePrependName=csvFilePrependName)
    restObj.waitForActiveTestToUnconfigure()
    restObj.deleteSessionId()

except (IxLoadRestApiException, Exception) as errMsg:
    print('\n%s' % traceback.format_exc())
    restObj.abortActiveTest()
    #restObj.deleteSessionId()
    sys.exit(errMsg)

except KeyboardInterrupt:
    print('\nCTRL-C detected.')
    restObj.abortActiveTest()
    restObj.deleteSessionId()
 
