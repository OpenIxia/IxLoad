

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
    sys.path.insert(0, (currentDir.replace('SampleScripts\\LoadSavedConfigFile\\VoIP', 'Modules')))
else:
    sys.path.insert(0, (currentDir.replace('SampleScripts/LoadSavedConfigFile/VoIP', 'Modules')))

from IxL_RestApi import *

# Choices of IxLoad Gateway server: linux or windows 
ixLoadGatewayOS = 'linux'

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
deleteSession = False
forceTakePortOwnership = True

# Do you want to delete the test session's result files on the IxLoad gateway server after downloading them?
deleteTestResultDirOnApiServer = True

# The saved config file to load
crfFile = 'voipSip.crf'

# API-Key: Use your user API-Key if you want added security
apiKey = None

if ixLoadGatewayOS == 'windows':
    apiServerIp = '10.0.2.5'

    # Where to store all of the result files in Windows
    resultsDirOnIxLoadGateway = f'C:\\Results\\{timestamp}'

    # Where to upload the IxLoad .rxf config file or where is the IxLoad config location if you're not uploading it.
    crfFileOnServer = f'{resultsDirOnIxLoadGateway}\\{crfFile}'
    pdfTestReportFileName = f'{resultsDirOnIxLoadGateway}\\Report.pdf'
    
if ixLoadGatewayOS == 'linux':
    apiServerIp = '10.0.2.16'

    # Leave everything below as defaults. For this script reference only.
    resultsDirOnIxLoadGateway = f'/mnt/ixload-share/Results/{timestamp}'
    crfFileOnServer = f'{resultsDirOnIxLoadGateway}/{crfFile}'
    pdfTestReportFileName = f'{resultsDirOnIxLoadGateway}/Report.pdf'

# Where do you want to put the downloaded result files at the end of the test in the localhost running this script
saveResultsInLocalPath = currentDir

# The localhost path to the saved IxLoad VoIP config file to load. In this example, get it from the current folder.
localConfigFileToUpload = f'{currentDir}/{crfFile}'

# For IxLoad versions prior to 8.50 that doesn't have the rest api to download results.
# Set to True if you want to save run time results to CSV files.
saveStatsToCsvFile = False

# Where to put the csv results on your local system. This example puts it in the current directory.
scpResultsDestPath = currentDir

# http=8080.  https=8443 (https is supported starting 8.50)
apiServerIpPort = 8443

licenseServerIp = '10.0.2.5'
# licenseModel choices: 'Subscription Mode' or 'Perpetual Mode'
licenseModel = 'Subscription Mode'

# Assign ports for testing.  Format = (cardId,portId)
# 'Traffic1@Network1' are activity names.
# To get the Activity names, go to: /ixload/test/activeTest/communityList
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
statsDict = {
    'SIP(VoIPSip)':       ['SIP Requests Parsed', 'SIP Requests Matched'],
    'RTP(VoIPSip)':       ['Successful Records', 'Successful Playbacks'],
    'Signaling(VoIPSip)': ['Received Calls', 'Answered Calls']
}

try:
    restObj = Main(apiServerIp=apiServerIp,
                   apiServerIpPort=apiServerIpPort,
                   osPlatform=ixLoadGatewayOS,
                   deleteSession=deleteSession,
                   pollStatusInterval=1,
                   apiKey=apiKey,
                   generateRestLogFile='VoIP_test.log')

   # sessionId is an opened existing session that you like to connect to instead of starting a new session.
    restObj.connect(ixLoadVersion, sessionId=None, timeout=120)
    
    restObj.configLicensePreferences(licenseServerIp=licenseServerIp, licenseModel=licenseModel)

    # localConfigFileToUpload: None or path to the config file on your local host    
    restObj.importCrfFile(crfFileOnServer, localConfigFileToUpload)
    
    # Tell IxLoad where to save the results on the IxLoad gateway server
    restObj.setResultDir(resultsDirOnIxLoadGateway)

    # Enable these settings if you want to generate a PDF test report
    restObj.enableNetworkDiagnostics(True)
    restObj.setPreferences({"enableL23RestStatViews": True,
                            "saveDataModelSnapshot": True,
                            "enableRestStatViewsCsvLogging": True})
            
    restObj.assignChassisAndPorts([communityPortList1, communityPortList2])
    if forceTakePortOwnership:
        restObj.enableForceOwnership()

    # Enable packet capturing
    restObj.enableAnalyzerOnAssignedPorts()
    
    # Modify timeline attributes: sustain time and iterations
    restObj.configTimeline(name='Timeline1', sustainTime=12, iterations=2)

    runTestOperationsId = restObj.runTraffic()

    restObj.pollStats(statsDict,
                      csvFile=saveStatsToCsvFile, 
                      pollStatInterval=2, 
                      csvEnableFileTimestamp=True,
                      csvFilePrependName=None)

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
 
