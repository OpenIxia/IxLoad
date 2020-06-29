"""
extractDataModelToFile.py

Description
   Upload a saved configuration to IxLoad gateway servr and extract
   the data model to a text file.

   Note: This script supports Windows and Linux IxLoad gateway.  
         You will see if conditions for Windows or Linux throughout this script.
         
Steps:
   - Connect to IxLoad Gateway server to create a session.
   - Upload the saved config to the gateway server.
   - Load the saved config file.
   - Extract data model.
   - Download the file as ixLoadConfigDataModel.txt to
     the target location of your preference.
   - Delete the session.
"""

import os, sys, traceback, platform

# Insert the Modules path to the system's memory in order to import IxL_RestApi.py
currentDir = os.path.abspath(os.path.dirname(__file__))

# Where is the path to the IxL_RestApi.py library module.
if platform.system() == 'Windows':
    sys.path.insert(0, (currentDir.replace('SampleScripts\\LoadSavedConfigFile', 'Modules')))
else:
    sys.path.insert(0, (currentDir.replace('SampleScripts/LoadSavedConfigFile', 'Modules')))

from IxL_RestApi import *

# Which IxLoad version are you using for your test?
# To view all the installed versions, go on a web browser and enter: 
#    http://<server ip>:8080/api/v0/applicationTypes
ixLoadVersion = '8.50.115.333'
ixLoadVersion = '9.00.0.347'    ;# EA
ixLoadVersion = '9.00.115.204' ;# Update-2

serverOs = 'linux'
apiServerIpPort = 8443

# Do you want to delete the session at the end of the test?
deleteSession = True

# The name of the saved IxLoad config file
rxfFilename = 'IxL_Http_Ipv4Ftp_vm_8.20.rxf'

if serverOs == 'linux':
    apiServerIp = '192.168.70.129'
    
    # Don't touch below two lines
    serverFilePath = '/mnt/ixload-share'
    rxfFileOnServer = '{}/{}'.format(serverFilePath, rxfFilename)
    
if serverOs == 'windows':
    apiServerIp = '192.168.70.3'
    
    # You must have the c: drive folder in Windows created.
    serverFilePath = 'c:\\Results'
    
    # Don't touch the below line
    rxfFileOnServer = '{}\\{}'.format(serverFilePath, rxfFilename)

# Do you need to upload your saved config file to the gateway server?
# If not, make sure a saved config must be already in the IxLoad gateway server filesystem.
upLoadFile = True

# The filename to give for the extracted data model file
dataModelFilename = 'ixLoadConfigDataModel.txt'

# Where to put the extracted data model text file on the gateway to be downloaded.
if serverOs == 'linux':
    # For IxLoad on Linux, don't modify this default Linux location. 
    extractDataModelSrcLocation = '/mnt/ixload-share/{}'.format(dataModelFilename)
else:
    # For IxLoad Windows users, you have to first create a folder in the c: drive.
    extractDataModelSrcLocation = 'c:\\Results\\{}'.format(dataModelFilename)

# The local path to download the extracted data model file
downloadToLocalDestination = '/home/hgee'

# The src path for the .rxf config file to be uploaded to the gateway server.
# In this example, assuming you are running this script on a Linux OS and
# the path to the config file from the current folder.
localConfigFileToUpload = '{}/LoadSavedConfigFile/{}'.format(currentDir, rxfFilename)

try:
    restObj = Main(apiServerIp=apiServerIp,
                   apiServerIpPort=apiServerIpPort,
                   osPlatform=serverOs,
                   deleteSession=deleteSession,
                   generateRestLogFile=True)

    # The sessionId param is for connecting to an opened existing session that you like to connect to 
    # instead of starting a new session.
    restObj.connect(ixLoadVersion, sessionId=18, timeout=120)

    if upLoadFile == True:
        restObj.uploadFile(localConfigFileToUpload, rxfFileOnServer)
    restObj.loadConfigFile(rxfFileOnServer)
    
    # Extracting a data model takes approximately 60 seconds for a small configuration.
    # Set the timeout value to a higher value for large config files.
    restObj.extractDataModelToFile(extractToFilename=dataModelFilename, timeout=120)
    
    restObj.downloadFile(srcPathAndFilename=extractDataModelSrcLocation, 
                         targetLocation=downloadToLocalDestination, 
                         targetFilename=dataModelFilename)
    
    if deleteSession:
        restObj.deleteSessionId()
    
except (IxLoadRestApiException, Exception) as errMsg:
    print('\n%s' % traceback.format_exc())
    if deleteSession:
        restObj.deleteSessionId()
    sys.exit(errMsg)

except KeyboardInterrupt:
    print('\nCTRL-C detected.')
    if deleteSession:
        restObj.abortActiveTest()
        restObj.deleteSessionId()