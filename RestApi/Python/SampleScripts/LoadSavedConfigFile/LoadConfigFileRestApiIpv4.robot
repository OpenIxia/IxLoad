
# Description
#    Load a saved config file (FTP Client/Server)
#    Reassign chassisIp/ports, run traffic and get stats.
#
# Requirements
#    Python 2.7-3+
#    requests module
#    ../../Modules/IxL_RestApi.py module
#
# Prerequisites
#   - For Linux: Add the Module path to .bashrc PYTHONPATH env variable     
#   - For Windows: Add c:\Program Files (x86)\Ixia\IxLoad\<version folder>
#   - pip install robotframework
#
# Usage:
#    robot LoadConfigFileRestApiIpv4.robot


*** Settings ***
Library  BuiltIn
Library  String
Library  Collections
Library  IxL_RestApi.Main  apiServerIp=${apiServerIp}  apiServerIpPort=${apiServerIpPort}  deleteSession=${deleteSessionAfterTest}
...  generateRestLogFile=robotLogs  robotFrameworkStdout=True   WITH NAME  ixlObj  


*** Variables ***
${serverOs} =  windows

# Must state the exact version you are using
${ixLoadVersion} =  8.40.0.277
${deleteSessionAfterTest} =  True
${apiServerIp} =  192.168.70.3
${apiServerIpPort} =  8080

# For Linux
#${uploadRxfFileToLinuxServer} =  IxL_Http_Ipv4Ftp_vm_8.20.rxf
#${rxfFile} =  /mnt/ixload-share/IxL_Http_Ipv4Ftp_vm_8.20.rxf

# For Windows
${rxfFile} =  C:\\Results\\IxL_Http_Ipv4Ftp_vm_8.20.rxf

${licenseServerIp} =  192.168.70.3
# licenseModel choices: 'Subscription Mode' or 'Perpetual Mode'
${licenseModel} =  Subscription Mode

# To record stats to CSV file: True or False
${csvStatFile} =  False

# Enable timestamp to not overwrite the previous csv file: True or False
${csvEnableFileTimestamp} =  False

# To add a custom ID name to the beginning of the CSV file: string format
${csvFilePrependName} =  None
${pollStatInterval} =  2

# To reassign ports, uncomment this and replace chassis and port values
# Format = (cardId,portId)
# To get the Key names: On the IxLoad GUI config, get the name of the stacks:
# Also, could be found here: http://<ip>:8080/api/v0/sessions/<id>/ixload/test/activeTest/communityList
# Create a list
${chassisIp} =  192.168.70.11
@{port1} =  1  1
@{port2} =  2  1
@{port1List} =  ${port1}
@{port2List} =  ${port2}

# Create a Dict
&{communityPortList} =  chassisIp=${chassisIp}  Traffic1@Network1=${port1List}  Traffic2@Network2=${port2List}  

# Set the stats to get and display at real time testing.
# To get the Key names such as HTTPClient1 HTTPServer1 FTPClient1 FTPServer1, look at "statName" in the below link...
# Two ways to get them:  
#    1: Do a scriptgen on IxLoad GUI. Open the scriptgen file and do a word search for "statName".
#    2: Use ReST API to load the config and do an apply. 
# Then go to: http://192.168.70.3:8080/api/v0/sessions/10/ixload/stats/HTTPServer/availableStats
@{httpClient} =  TCP Connections Established
                 ...  HTTP Simulated Users
                 ...  HTTP Concurrent Connections
                 ...  HTTP Connections
                 ...  HTTP Transactions
                 ...  HTTP Connection Attempts

@{httpServer} =  TCP Connections Established   TCP Connection Requests Failed

@{ftpClient} =  FTP Concurrent Sessions   FTP Transactions
@{ftpServer} =  FTP Control Conn Established

&{statsDict} =  HTTPClient=${httpClient}  HTTPServer=${httpServer}
&{statsDictFtp} =  FTPClient=${ftpClient}  FTPServer=${ftpServer}

*** Test Cases ***
Test FTP Client Server

   # For Linux API server
   Log To Console  Connecting to IxLoad gateway. Please wait for a new session to come up
   ${connectTimeout} =  Convert To Integer  140
   ixlObj.Connect  ixLoadVersion=${ixLoadVersion}  timeout=${connectTimeout}

   Log To Console  Configuring license preferences
   ixlObj.config License Preferences  licenseServerIp=${licenseServerIp}  licenseModel=${licenseModel}

   Run Keyword If  "${serverOs}"=="linux"  RunKeyword
   ...  ixlObj.Upload File  ${uploadRxfFileToLinuxServer}  ${rxfFile}

   Log To Console  Loading config file to gateway server
   ixlObj.Load Config File  ${rxfFile}

   Log To Console  Assigning chassis and ports
   ixlObj.Assign Chassis And Ports  ${communityPortList}

   Log To Console  Enable port force ownership
   ixlObj.Enable Force Ownership
   ixlObj.Get Stat Names

   Log To Console  Run Traffic and verify for success
   ixlObj.Run Traffic

   Log To Console  Poll stat
   ${pollStatInterval} =  Convert To Integer  2	
   ixlObj.Poll Stats  ${statsDict}   pollStatInterval=${pollStatInterval}   csvFile=${csvStatFile}   
   ...  csvEnableFileTimestamp=${csvEnableFileTimestamp}   csvFilePrependName=${csvFilePrependName}

   Log To Console  Wait for active test to unconfigure
   ixlObj.Wait For Active Test To Unconfigure

   Log To Console  Delete session ID
   ixlObj.Delete Session Id
