# Description
#   A sample Python REST API script to:
#      - Load a saved configuration file
#      - Run traffic
#      - Get stats and evaluate for user defined expected stat values.
#      - Get test result
#
#   - For IxLoad Gateway running in Windows only.  Linux Gateway is not supported at this time.
#   - This script will set the license model to "Perpetual Mode".  This is a 5G requirement.
#
#   If the saved config file is located on a remote pc, this script could upload it to the gateway.
#   Otherwise, the saved config file must be already in the IxLoad API gateway server.
#
# Requirements
#    IxL_RestApi.py
#    Air Mosaic installed in the Windows OS where IxLoad is installed
#    The Air Mosaic version must be the same version as IxLoad for compatibility
#    5G cell

import os, sys, time, signal, traceback, platform

# Insert the Modules path to env in order to import IxL_RestApi.py
currentDir = os.path.abspath(os.path.dirname(__file__))

# Automatically create the os path to the IxL_RestApi.py module for this script to use
if platform.system() == 'Windows':
    sys.path.insert(0, (currentDir.replace('SampleScripts\\LoadSavedConfigFile', 'Modules')))
else:
    sys.path.insert(0, (currentDir.replace('SampleScripts/LoadSavedConfigFile', 'Modules')))

from IxL_RestApi import *

# Choices of IxLoad Gateway server OS: linux or windows
ixLoadGatewayOS = 'windows'

# Which IxLoad version are you using for your test?
# To view all the installed versions, go on a web browser and enter:
#    http://<server ip>:8080/api/v0/applicationTypes
ixLoadVersion = '9.10.115.43'
ixLoadVersion = '10.40.144.35'
ixLoadVersion = '11.00.0.320'
#ixLoadVersion = '26.0.0.94'

# Get the current timestamp to store the results in a unique timestamp folder
timestamp = getTime()

# Do you want to delete the session at the end of the test or if the test failed?
deleteSession = True
forceTakePortOwnership = True

# Do you want to delete the test session's result files after downloading them?
deleteTestResultDirOnApiServer = True

# API-Key: Use your user API-Key if you want added security
apiKey = None

# The saved config file to load
rxfFile = '5G-eLSU_HTTP_UXM_stats.rxf'

if ixLoadGatewayOS == 'windows':
    apiServerIp = '10.0.2.5'

    # Where to store all of the result files in Windows
    resultsDirOnIxLoadGateway = f'C:\\Results\\{timestamp}'

    # Where to upload the IxLoad .rxf config file or where is the IxLoad config location if you're not uploading it.
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

# For 5G, the license model must be Perpetual Mode
licenseModel = 'Perpetual Mode'

# To assign ports for testing.  Format = (cardId,portId)
# Traffic1@Network1 are activity names.
# To get the Activity names, got to: /ixload/test/activeTest/communityList
communityPortList1 = {
    'chassisIp': '10.0.2.4',
    'Traffic2@Network1': [(1,1)],
}

communityPortList2 = {
    'chassisIp': '10.0.2.4',
    'Traffic1@SGi': [(1,2)],
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
    'HTTPClient': [{'caption': 'Rx Rate (Kbps)', 'operator': '>', 'expect': 5000000}]
}

#NRstatsDict = {
#    'UESIM-NRLayer1Statistics': [{'caption': "CRC OK TBs - PDSCH", 'operator': '>', 'expect': 1000)}]
#}


try:
    restObj = Main(apiServerIp=apiServerIp,
                   apiServerIpPort=apiServerIpPort,
                   osPlatform=ixLoadGatewayOS,
                   deleteSession=deleteSession,
                   pollStatusInterval=1,
                   apiKey=apiKey,
                   generateRestLogFile='5g_eval_stats.log')

    # sessionId is an opened existing session that you like to connect to instead of starting a new session.
    restObj.connect(ixLoadVersion, sessionId=None, timeout=120)

    restObj.configLicensePreferences(licenseServerIp=licenseServerIp, licenseModel=licenseModel)
    restObj.loadConfigFile(rxfFileOnServer)
    
    # Tell IxLoad where to save the results on the IxLoad gateway server
    resultsDirOnIxLoadGateway = restObj.setResultDir(resultsDirOnIxLoadGateway)

    # Enable these settings if you want to generate a PDF test report
    restObj.enableNetworkDiagnostics(True)
    restObj.setPreferences({"enableL23RestStatViews": True,
                            "saveDataModelSnapshot": True,
                            "enableRestStatViewsCsvLogging": True})
    
    restObj.assignChassisAndPorts([communityPortList1, communityPortList2])

    if forceTakePortOwnership:
        restObj.enableForceOwnership()

    # Optional: Modify the sustain time
    #restObj.configTimeline(name='Timeline1', sustainTime=12)

    runTestOperationsId = restObj.runTraffic()

    restObj.pollStatsAndCheckStatResults(statsDict,
                                         csvFile=saveResultsInLocalPath,
                                         csvFilePrependName=None,
                                         pollStatInterval=2,
                                         exitAfterPollingIteration=None)

    restObj.waitForActiveTestToUnconfigure()
    restObj.retrievePortCaptureFileForAssignedPorts(saveResultsInLocalPath)

    # Showing you where the results are stored on the server running IxLoad gateway.
    # You have to manually delete these result folders as they accumulate over time.
    restObj.logInfo(f'Results are saved in the IxLoad Gateway path: {restObj.getTestResultFolder()}')

    restObj.generatePdfTestReport(filePath=pdfTestReportFileName)
    restObj.downloadResults(targetPath=saveResultsInLocalPath)

    # Use this API if you want to download the Report.pdf file to a different path
    # Otherwise, the Report.pdf is included in saveResultsInLocalPath when calling downloadResults.
    restObj.downloadFile(pdfTestReportFileName,
                         targetLocation='/home/hgee/Downloads/ixload',
                         targetFilename='ixload_test_report.pdf')
    
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

