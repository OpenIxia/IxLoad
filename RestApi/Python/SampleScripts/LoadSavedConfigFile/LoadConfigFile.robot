
# Description
#    Load a saved config file
#    Reassign chassisIp/ports
#    Enable port capturing
#    Run traffic
#    Get run time stats
#    Retrieve csv stats (For Linux gateway only)
#
# Requirements
#    Python 2.7 or Python3
#    requests module
#    ../../Modules/IxL_RestApi.py module
#
# Prerequisites
#   - For Linux: Add the Module path to .bashrc PYTHONPATH env variable     
#   - For Windows: Add c:\Program Files (x86)\Ixia\IxLoad\<version folder>
#   - pip install robotframework
#
# Usage:
#    robot LoadConfigFile.robot


*** Settings ***
Library  BuiltIn
Library  String
Library  Collections
Library  IxL_RestApi.Main  apiServerIp=${apiServerIp}  apiServerIpPort=${apiServerIpPort}  deleteSession=${deleteSessionAfterTest}
...  generateRestLogFile=True  robotFrameworkStdout=True  osPlatform=${serverOs}  WITH NAME  ixlObj  


*** Variables ***
# windows | linux
${serverOs} =  linux

# Must state the exact version you are using
${ixLoadVersion} =  9.00.115.204

${apiServerIp} =  192.168.70.129
${apiServerIpPort} =  8080
${deleteSessionAfterTest} =  True

# Upload the config file to the IxLoad Gateway server
${uploadConfigFile} =  True

# The name of the saved config file
${configFilename} =  IxL_Http_Ipv4Ftp_vm_8.20.rxf

# The path to the saved config file. In this example, the config file is in the current directory
${uploadRxfFile} =  ${CURDIR}/${configFilename}

# For using IxLoad on Linux: Upload the config file to /mnt/ixload-share.  No where else.
${linuxRxfFileLocation} =   /mnt/ixload-share/${configFilename}

# For using IxLoad on Windows:  Tell IxLoad where to upload the saved config file so it knows where to read it.
${windowsRxfFileLocation} =  C:\\Results\\${configFilename}

# The IP address of the IxLoad license server
${licenseServerIp} =  192.168.70.3

# licenseModel choices: 'Subscription Mode' or 'Perpetual Mode'
${licenseModel} =  Subscription Mode

# Record stats to CSV file: True or False
${csvStatFile} =  True

# Enable timestamp to not overwrite the previous csv file: True or False
${csvEnableFileTimestamp} =  True

# To add a custom name to the beginning of the CSV file: string format
${csvFilePrependName} =  None
${pollStatInterval} =  2

# To reassign ports, uncomment this and replace chassis and port values
#    List format = [cardId, portId]
#    To get the Key names: On the IxLoad GUI config, get the name of the stacks:
#    Also, could be found here: http://<ip>:8080/api/v0/sessions/<id>/ixload/test/activeTest/communityList
# Create a list
${chassisIp} =  192.168.70.128
@{port1} =  1  1
@{port2} =  2  1
@{port1List} =  ${port1}
@{port2List} =  ${port2}

# Create a Dict of chassis and ports to use for both client/server communities
&{communityPortList1} =  chassisIp=${chassisIp}  Traffic1@Network1=${port1List}
&{communityPortList2} =  chassisIp=${chassisIp}  Traffic2@Network2=${port2List}  
@{combinedPortList} =  ${communityPortList1}  ${communityPortList2}

# Optional.  Example to show that you could modify the saved config before
# running the test.
&{userObjectiveValue} =  userObjectiveValue=100

# Getting Stats at run time:
#    Every IxLoad feature has its own stats.
#    Set the stats to get and display at rrun time.
#    To get the Key stat names such as HTTPClient1 HTTPServer1 and all its available stats, follow below instructions:

#    Load the config and apply the traffic.
#       - Then go to on the API browser: http://<ixLoad IP>:8080 and go under "stats"
#       - More help: https://www.openixia.com/tutorials?subject=ixLoad/getStatNames&page=fromApiBrowserForRestApi.html

#
# Create stats to get for HTTP Client
@{httpClient} =  TCP Connections Established
                 ...  HTTP Simulated Users
                 ...  HTTP Concurrent Connections
                 ...  HTTP Connections
                 ...  HTTP Transactions
                 ...  HTTP Connection Attempts

@{httpServer} =  TCP Connections Established   TCP Connection Requests Failed
&{statsDict} =  HTTPClient=${httpClient}  HTTPServer=${httpServer}


*** Test Cases ***
Test HTTP/FTP Client Server
   # For Linux API server
   Log To Console  Connecting to IxLoad gateway. Please wait for a new session to come up
   ${connectTimeout} =  Convert To Integer  140
   ixlObj.Connect  ixLoadVersion=${ixLoadVersion}  sessionId=${null}  timeout=${connectTimeout}

   Log To Console  Configuring license preferences
   ixlObj.config License Preferences  licenseServerIp=${licenseServerIp}  licenseModel=${licenseModel}

   Run Keyword If  ("${uploadConfigFile}"=="True") and ("${serverOs}"=="linux")  Run Keyword
   ...  ixlObj.Upload File  ${uploadRxfFile}  ${linuxRxfFileLocation}
   ...  ELSE  ixlObj.Upload File  ${uploadRxfFile}  ${windowsRxfFileLocation}

   Log To Console  Loading config file to gateway server
   Run Keyword If  "${serverOs}"=="linux"  Run Keyword
   ...  ixlObj.Load Config File  ${linuxRxfFileLocation}
   ...  ELSE  ixlObj.Load Config File  ${windowsRxfFileLocation}

   Log  Assigning chassis and ports
   ixlObj.Assign Chassis And Ports  ${combinedPortList}
    
   Log To Console  Enable port force ownership
   ixlObj.Enable Force Ownership

   ixlObj.Enable Analyzer On Assigned Ports
   ixlObj.Config Time Line  name=Timeline1  sustainTime=12

   ixlObj.Config Activity Attributes  communityName=Traffic1@Network1  activityName=HTTPClient1  attributes=${userObjectiveValue}
   ixlObj.Get Stat Names

   Log To Console  Run Traffic and verify for success
   ixlObj.Run Traffic

   Log To Console  Polling stats
   ${pollStatInterval} =  Convert To Integer  2  
   ixlObj.Poll Stats  ${statsDict}   pollStatInterval=${pollStatInterval}   csvFile=${csvStatFile}   
   ...  csvEnableFileTimestamp=${csvEnableFileTimestamp}   csvFilePrependName=${csvFilePrependName}
   
   Log To Console  Wait for active test to unconfigure
   ixlObj.Wait For Active Test To Unconfigure

   # Linux has SSH installed.  Windows don't come with SSH.
   # If you are using Windows and if you want CSV stats at the end of the test, set csvStatFile to True.
   Run Keyword If  "${serverOs}"=="linux"  RunKeywords
   ...  Log To Console  Download CSV stat result files
   ...  AND  ixlObj.Download Results

   Log To Console  Retrieving port capture file
   ixlObj.Retrieve Port Capture File For Assigned Ports  ${CURDIR}
   
   Run Keyword If  "${deleteSessionAfterTest}"=="True"  Run Keywords
   ...  Log To Console  Delete session ID
   ...  AND  ixlObj.Delete Session Id



