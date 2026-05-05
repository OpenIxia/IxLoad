# Description
#   A sample Python REST API script to:
#      - Load a saved configuration file
#      - Enable port analyzer
#      - Set runtime stats
#      - Run traffic
#      - Get stats and evaluate for user defined expected stat values.
#      - Retrieve port capture files to local folder.
#      - Download test results and PDF test report to local host
#
#   Supports both IxLoad in Windows and in Linux gateway Servers
#
# Requirements
#    IxL_RestApi.py
#
# IxL_RestApi.py and sample scripts by: Hubert Gee

import os, sys, time, signal, traceback, platform

# Insert the Modules path to env in order to import IxL_RestApi.py
currentDir = os.path.abspath(os.path.dirname(__file__))

# Automatically create the os path to the IxL_RestApi.py module for this script to use
if platform.system() == 'Windows':
    sys.path.insert(0, (currentDir.replace('SampleScripts\\LoadSavedConfigFile', 'Modules')))
else:
    sys.path.insert(0, (currentDir.replace('SampleScripts/LoadSavedConfigFile', 'Modules')))

from IxL_RestApi import *

# Which IxLoad Gateway server are you using: linux or windows 
ixLoadGatewayOS = 'windows'

# Which IxLoad version are you using for your test?
# To view all the installed versions, go on a web browser and enter:
#    http://<server ip>:8080/api/v0/applicationTypes
ixLoadVersion = '9.10.115.43'
#ixLoadVersion = '11.20.116.145'
ixLoadVersion = '11.00.0.320'
#ixLoadVersion = '26.0.0.94'

# Get the current timestamp to store the results in a unique timestamp folder
timestamp = getTime()

# Do you want to delete the session at the end of the test or if the test failed?
deleteSession = False
forceTakePortOwnership = True

# Do you want to delete the test session's result files on the IxLoad gateway server after downloading them?
deleteTestResultDirOnApiServer = False

# API-Key: Use your user API-Key if you want added security
apiKey = None

# The saved config file to load
rxfFile = 'IxL_Http_910_update1.rxf'
rxfFile = 'IxL_Http_Ipv4Ftp_vm_8.20.rxf'

if ixLoadGatewayOS == 'windows':
    apiServerIp = '10.0.2.5'

    # Where to store all of the result files in Windows
    resultsDirOnIxLoadGateway = f'C:\\Results\\{timestamp}'

    # Where to upload the IxLoad .rxf config file or where is the IxLoad config location if you're not uploading it
    rxfFileOnServer = f'{resultsDirOnIxLoadGateway}\\{rxfFile}'
    pdfTestReportFileName = f'{resultsDirOnIxLoadGateway}\\Report.pdf'
    
if ixLoadGatewayOS == 'linux':
    apiServerIp = '10.0.2.14'

    # Leave everything below as defaults. For this script reference only.
    resultsDirOnIxLoadGateway = f'/mnt/ixload-share/Results/{timestamp}'
    rxfFileOnServer = f'{resultsDirOnIxLoadGateway}/{rxfFile}'
    pdfTestReportFileName = f'{resultsDirOnIxLoadGateway}/Report.pdf'

# Where do you want to put the downloaded result files at the end of the test in the localhost running this script
saveResultsInLocalPath = currentDir

# The localhost path to the saved IxLoad config file to load. In this example, get it from the current folder.
localConfigFileToUpload = f'{currentDir}/{rxfFile}'

# For IxLoad versions prior to 8.50 that doesn't have the rest api to download results.
# Set to True if you want to save run time stat results to CSV files.
saveStatsToCsvFile = False

# http=8080.  https=8443 (https is supported starting 8.50)
apiServerIpPort = 8443

licenseServerIp = '10.0.2.5'

# licenseModel choices: 'Subscription Mode' or 'Perpetual Mode'
licenseModel = 'Subscription Mode'

# To assign ports for testing.  Format = (cardId,portId)
# Traffic1@Network1 are activity names.
# To get the Activity names, got to: /ixload/test/activeTest/communityList
communityPortList1 = {
    'chassisIp': '10.0.2.4',
    'Traffic1@Network1': [(1,1)],
}

communityPortList2 = {
    'chassisIp': '10.0.2.4',
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
    'HTTPClient': [{'caption': 'TCP Connections Established', 'operator': '>', 'expect': 60},
                   {'caption': 'HTTP Simulated Users',        'operator': '>', 'expect': 100},
                   {'caption': 'HTTP Connections',            'operator': '>', 'expect': 300},
                   {'caption': 'HTTP Transactions',           'operator': '>', 'expect': 190},
                   {'caption': 'HTTP Connection Attempts',    'operator': '>', 'expect': 300}
               ],
    'HTTPServer': [{'caption': 'TCP Connections Established',    'operator': '>=', 'expect': 1000},
                   {'caption': 'TCP Connection Requests Failed', 'operator': '<', 'expect': 1}
               ]
}

try:
    restObj = Main(apiServerIp=apiServerIp,
                   apiServerIpPort=apiServerIpPort,
                   osPlatform=ixLoadGatewayOS,
                   deleteSession=deleteSession,
                   pollStatusInterval=1,
                   apiKey=apiKey,
                   generateRestLogFile='ixload_eval_stats.log')

    # sessionId is an opened existing session that you like to connect to instead of starting a new session.
    restObj.connect(ixLoadVersion, sessionId=None, timeout=120)

    restObj.configLicensePreferences(licenseServerIp=licenseServerIp, licenseModel=licenseModel)

    # uploadConfigFile: None or path to the config file on your local host
    restObj.loadConfigFile(rxfFileOnServer, uploadConfigFile=localConfigFileToUpload)

    # Tell IxLoad where to save the results on the IxLoad gateway server
    restObj.setResultDir(resultsDirOnIxLoadGateway)

    # Enable these settings if you want to generate a PDF test report
    restObj.enableNetworkDiagnostics(True)
    restObj.setPreferences({"enableL23RestStatViews": True,
                            "saveDataModelSnapshot": True,
                            "enableRestStatViewsCsvLogging": True})
            
    restObj.assignChassisAndPorts([communityPortList1, communityPortList2])
    if forceTakePortOwnership:
        restObj.enableForceOwnership(enable=True, enableResetPorts=True)

    restObj.enableAnalyzerOnAssignedPorts()

    # Optional: Modify the sustain time
    restObj.configTimeline(name='Timeline1', sustainTime=12)

    # Example on how to use the configActivityAttribute function to modify
    # some of its attributes.
    restObj.configActivityAttributes(communityName='Traffic1@Network1',
                                     activityName='HTTPClient1',
                                     attributes={'userObjectiveValue': 100})

    runTestOperationsId = restObj.runTraffic()

    saveStatsToCsvFile = False
    # Set csvFile only if you are using IxLoad version >=8.50
    restObj.pollStatsAndCheckStatResults(statsDict,
                                         csvFile=saveStatsToCsvFile,
                                         csvFilePrependName=None,
                                         pollStatInterval=2,
                                         exitAfterPollingIteration=None)

    # Wait if your configuration has port capturing enabled
    restObj.waitForAllCapturedData()
    
    restObj.waitForActiveTestToUnconfigure()
    restObj.retrievePortCaptureFileForAssignedPorts(saveResultsInLocalPath)

    # Showing you where the results are stored on the server running IxLoad gateway.
    # You have to manually delete these result folders as they accumulate over time.
    restObj.logInfo(f'Results are saved in the IxLoad Gateway path: {restObj.getTestResultFolder()}')

    restObj.generatePdfTestReport(filePath=pdfTestReportFileName)
    restObj.downloadResults(targetPath=saveResultsInLocalPath)

    # Use this API if you want to download the Report.pdf file to a different path
    # Otherwise, the Report.pdf is included in saveResultsInLocalPath when calling downloadResults.
    restObj.downloadFile(pdfTestReportFileName, targetLocation='/home/hgee/Downloads/ixload', targetFilename='ixload_test_report.pdf')

    if deleteTestResultDirOnApiServer: 
        restObj.deleteResultDir()
            
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

