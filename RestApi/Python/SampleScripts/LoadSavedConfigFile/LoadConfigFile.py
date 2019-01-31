

# Description
#   A sample Python REST API script to demonstrate loading a saved configuration,
#   run traffic and getting stats.
#
#   Supports both Windows and Linux gateway Server. If connecting to a 
#   Linux server, a license server running on Windows PC is still required unless it is 
#   installed in the chassis.
#   This script will configure the license server IP and license model on the Linux server.
#
#   - If the saved config file is located locally, you could upload it to the gateway.
#     Otherwise, the saved config file must be already in the Windows filesystem.
#   - Load a saved config .rxf file
#   - Run traffic
#   - Get stats
#
# Requirements
#    Python2.7 minimum. (Supports Python2 and 3)
#    IxL_RestApi.py API file.

import os, sys, time, signal, traceback

from IxL_RestApi import *

# Choices: linux or windows 
serverOs = 'windows'
#
# It is mandatory to include the exact IxLoad version.
ixLoadVersion = '8.50.115.124'

# Do you want to delete the session at the end of the test or if the test failed?
deleteSession = True

# CLI parameter input:  windows|linux
if len(sys.argv) > 1:
    serverOs = sys.argv[1]

if serverOs == 'windows':
    apiServerIp = '192.168.70.3'
    apiServerIpPort = 8443 ;# https: Starting with version 8.50
    #apiServerIpPort =  8080 ;# http

    # If your API gateway is a Windows and you're running this script remotely such as on Linux, you 
    # could upload the saved config file to the api gateway and set uploadFile = True. Otherwise, the 
    # saved config must be already in the Windows filesystem.
    #localFilePath = 'IxL_Http_Ipv4Ftp_vm_8.20.rxf'
    upLoadFile = False

    rxfFileOnServer = 'C:\\Results\\IxL_Http_Ipv4Ftp_vm_8.20.rxf'

if serverOs == 'linux':
    apiServerIp = '192.168.70.140'
    apiServerIpPort = 8080 ;# http
    #apiServerIpPort = 8443 ;# https: Starting with version 8.50
    localRxfFileToUpload = 'IxL_Http_Ipv4Ftp_vm_8.20.rxf'
    rxfFileOnServer = '/mnt/ixload-share/IxL_Http_Ipv4Ftp_vm_8.20.rxf'

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
    'chassisIp': '192.168.70.128',
    'Traffic1@Network1': [(1,1)],
    'Traffic2@Network2': [(1,2)]
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


if apiServerIpPort == 8443:
    useHttps = True
else:
    useHttps = False

try:
    restObj = Main(apiServerIp=apiServerIp, apiServerIpPort=apiServerIpPort, useHttps=useHttps,
                   deleteSession=deleteSession, generateRestLogFile=True)

    restObj.connect(ixLoadVersion)
    restObj.configLicensePreferences(licenseServerIp=licenseServerIp, licenseModel=licenseModel)

    # If connecting to Linux server, must upload the config file to the server first.
    if serverOs == 'linux':
        restObj.uploadFile(localRxfFileToUpload, rxfFileOnServer)

    if serverOs == 'windows' and upLoadFile == True:
        restObj.uploadFile(localFilePath, rxfFileOnServer)

    restObj.loadConfigFile(rxfFileOnServer)

    if 'communityPortList' in locals():
        restObj.assignChassisAndPorts(communityPortList)

    restObj.enableForceOwnership()
    restObj.getStatNames()
    runTestOperationsId = restObj.runTraffic()
    restObj.pollStats(statsDict, pollStatInterval=pollStatInterval, csvFile=csvStatFile,
                      csvEnableFileTimestamp=csvEnableFileTimestamp, csvFilePrependName=csvFilePrependName)
    restObj.waitForActiveTestToUnconfigure()
    resultPath = restObj.getResultPath()

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
 
