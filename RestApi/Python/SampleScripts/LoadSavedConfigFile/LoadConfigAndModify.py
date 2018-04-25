# Description
#   A sample Python REST API script to demonstrate loading a saved configuration,
#   run traffic and getting stats.  Modify the configuration and rerun test.
#
#   This sample script supports both Windows and Linux Server. If connecting to a 
#   Linux server, a license server running on Windows PC is still required.
#   This script will configure the license server IP and license model on the Linux server.
#
#   - Load a saved config .rxf file
#   - Run traffic
#   - Get stats
#   - Intentionally set an statistic error
#   - Modify the configuration
#   - Rerun test.
#   - Get stats
#
# Requirements
#    Python2.7 minimum. (Supports Python2 and 3)
#    IxL_RestApi.py API file.

import requests, json, sys, os, time, traceback

sys.path.insert(0, '../../Modules')
from IxL_RestApi import *

# Choices: linux or windows 
serverOs = 'windows'
#
# It is mandatory to include the exact IxLoad version.
ixLoadVersion = '8.40.0.277'

# Do you want to delete the session if the test failed and at the end of the test? True|False
deleteSession = True

# CLI parameter input:  windows|linux
if len(sys.argv) > 1:
    serverOs = sys.argv[1]

if serverOs == 'windows':
    # Windows settings
    apiServerIp = '192.168.70.3'
    apiServerIpPort = '8080'
    rxfFile = 'C:\\Results\\IxL_Http_Ipv4Ftp_vm_8.20.rxf'

if serverOs == 'linux':
    # Linux settings.  Comment out these variables if you are using Windows.
    apiServerIp = '192.168.70.111'
    apiServerIpPort = '8080'
    localRxfFileToUpload = 'IxL_Http_Ipv4Ftp_vm_8.20.rxf'
    rxfFile = '/mnt/ixload-share/IxL_Http_Ipv4Ftp_vm_8.20.rxf'

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
# To get the Key names: On the IxLoad GUI config, get the name of the stacks:
# Also, could be found here: http://<ip>:8080/api/v0/sessions/<id>/ixload/test/activeTest/communityList
communityPortList = {
    'chassisIp': '192.168.70.11',
    'Traffic1@Network1': [(1,1)],
    'Traffic2@Network2': [(2,1)]
}

# Set the stats to get and display at real time testing.
# To get the Key names such as HTTPClient1 HTTPServer1 FTPClient1 FTPServer1, look at "statName" in the below link...
# Two ways to get them:  
#    1: Do a scriptgen on IxLoad GUI. Open the scriptgen file and do a word search for "statName".
#    2: Use ReST API to load the config and do an apply. Then go to: http://192.168.70.127:8080/api/v0/sessions/10/ixload/stats/HTTPServer/availableStats
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
                ]
}

statsDictFtp = {
    'FTPClient': ['FTP Concurrent Sessions', 'FTP Transactions'],
    'FTPServer': ['FTP Control Conn Established']
}

# This is to demonstrate how to set a failure condition in statistics and then modify the config and rerun the test.
def pollStats(sessionIdUrl, statsDict, pollStatInterval=2, csvFile=False, csvEnableFileTimestamp=False, csvFilePrependName=None):
    if csvFile:
        import csv
        csvFilesDict = {}
        for key in statsDict.keys():
            fileName = key
            if csvFilePrependName:
                fileName = csvFilePrependName+'_'+fileName
            csvFilesDict[key] = {}

            if csvEnableFileTimestamp:
                import datetime
                timestamp = datetime.datetime.now().strftime('%H%M%S')
                fileName = fileName+'_'+timestamp

            fileName = fileName+'.csv'
            csvFilesDict[key]['filename'] = fileName
            csvFilesDict[key]['columnNameList'] = []
            csvFilesDict[key]['fileObj'] = open(fileName, 'w')
            csvFilesDict[key]['csvObj'] = csv.writer(csvFilesDict[key]['fileObj'])
            
        # Create the csv top row column name list
        for key,values in statsDict.items():        
            for columnNames in values:
                csvFilesDict[key]['columnNameList'].append(columnNames)
            csvFilesDict[key]['csvObj'].writerow(csvFilesDict[key]['columnNameList'])

    while True:
        if restObj.getActiveTestCurrentState() == 'Running':
            # statType:  HTTPClient or HTTPServer (Just a example using HTTP.)
            # statNameList: transaction success, transaction failures, ...
            for statType,statNameList in statsDict.items():
                print('\n%s:' % statType)
                statUrl = restObj.sessionIdUrl+'/ixLoad/stats/'+statType+'/values'
                response = restObj.getStats(statUrl)
                highestTimestamp = 0
                # Each timestamp & statnames: values                
                for eachTimestamp,valueList in response.json().items():
                    if eachTimestamp == 'error':
                        print('\npollStats error: Probable cause: Misconfigured stat names to retrieve.')
                        return 1

                    if int(eachTimestamp) > highestTimestamp:
                        highestTimestamp = int(eachTimestamp)
                if highestTimestamp == 0:
                    time.sleep(3)
                    continue

                if csvFile:
                    csvFilesDict[statType]['rowValueList'] = []

                # Get the interested stat names only
                for statName in statNameList:
                    if statName == 'TCP Connections Established' and response.json()[str(highestTimestamp)][statName] > 400:
                        return 2

                    if statName in response.json()[str(highestTimestamp)]:
                        statValue = response.json()[str(highestTimestamp)][statName]
                        print('\t%s: %s' % (statName, statValue))
                        if csvFile:
                            csvFilesDict[statType]['rowValueList'].append(statValue)
                    else:
                        print('\tStat name not found. Check spelling and case sensitivity:', statName)

                if csvFile:
                    if csvFilesDict[statType]['rowValueList'] != []:
                        csvFilesDict[statType]['csvObj'].writerow(csvFilesDict[statType]['rowValueList']) 
                
            time.sleep(pollStatInterval)
        else:
            break

    if csvFile:
        for key in statsDict.keys():
            csvFilesDict[key]['fileObj'].close()

        
try:
    restObj = Main(apiServerIp=apiServerIp, apiServerIpPort=apiServerIpPort, deleteSession=deleteSession, generateRestLogFile=False)
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
    restObj.runTrafficAndVerifySuccess()

    if pollStats(restObj.sessionIdUrl, statsDict, pollStatInterval=pollStatInterval, csvFile=csvStatFile,
                 csvEnableFileTimestamp=csvEnableFileTimestamp, csvFilePrependName=csvFilePrependName) == 2:

        # If pollStats caught a failure or returned 1, stop the test.
        restObj.abortActiveTest()

        print('\nModifying configuraiton ...')
        # Disable HTTP Client
        restObj.patch(restObj.sessionIdUrl+'ixLoad/test/activeTest/communityList/0/activityList/0', data={'enable': False})

        # Disable HTTP Server
        restObj.patch(restObj.sessionIdUrl+'ixLoad/test/activeTest/communityList/1/activityList/0', data={'enable': False})

        # Enable FTP Client
        restObj.patch(restObj.sessionIdUrl+'ixLoad/test/activeTest/communityList/0/activityList/1', data={'enable': True})

        # Enable FTP Server
        restObj.patch(restObj.sessionIdUrl+'ixLoad/test/activeTest/communityList/1/activityList/1', data={'enable': True})

        # Show the stat names on the terminal
        restObj.getStatNames()
        runTestOperationsId = restObj.runTrafficAndVerifySuccess()

        restObj.pollStats(statsDictFtp, pollStatInterval=pollStatInterval, csvFile=csvStatFile, csvEnableFileTimestamp=csvEnableFileTimestamp,
                          csvFilePrependName=csvFilePrependName)

    restObj.waitForActiveTestToUnconfigure()

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
 
