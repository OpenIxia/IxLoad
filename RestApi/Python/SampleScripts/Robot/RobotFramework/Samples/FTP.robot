*** Variables ***

${path_IxLoad_version} =  C:/Program Files (x86)/Ixia/IxLoad/8.30.0.116-EB   # <-NEEDS TO BE MODIFIED, Path to the IxLoad instalation folder

${path_IxLoad_version} =  /home/hgee/Dropbox/MyIxiaWork/OpenIxiaGit/IxLoad/RestApi/Python/SampleScripts/Robot/RobotFramework

#${path_save_file} =  D:/robot_framework/empty_config_modified.rxf
${path_save_file} =  c:/Results/ftp_robot2.rxf

${ixLoadVersion} =  8.40.0.277			# <-NEEDS TO BE MODIFIED, IxLoad version the test will run 
${chassisIp} =  192.168.70.11			# <-NEEDS TO BE MODIFIED, IP of the chassis on which the card is found
@{portList1} =  1.1.1  					# <-NEEDS TO BE MODIFIED, chassis.card.port on which the test will run 
@{portList2} =  1.2.1					# <-NEEDS TO BE MODIFIED, chassis.card.port on which the test will run		


*** Settings ***
Library  BuiltIn
Library  String
Library  Collections
Library           IxLoadRobot  ${path_IxLoad_version}   # <-NEEDS TO BE MODIFIED, Path to the IxLoad instalation folder
Test Teardown     Teardown Actions 

*** Variables ***

${clientIp} =  192.168.70.3
${clientPort} =  8443

*** Test Cases ***
Run IxLoad Configuration

##########################
# Start IxLoad Session   #
##########################
    
    Connect  ipAddress=${clientIp}  port=${clientPort}
    ${session} =  Create Session  ixLoadVersion=${ixLoadVersion}
	Set Global Variable  ${session}  # new line
    
    ${result} =  Start Session  ${session}
    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"
    
##########################
# Create Communities     #
##########################
    
    ${test} =  Get IxLoad Test  session=${session}

    ${activeTest} =  Cget  object=${test}  field=activeTest
    ${communityList} =  Cget  object=${activeTest}  field=communityList

    Append Item  ${communityList}
    Append Item  ${communityList}
    
##########################
# Add new chassis        #
##########################
    
    ${chassisChain} =  Get IxLoad Chassis Chain  session=${session}
    ${chassisList} =  Cget  object=${chassisChain}  field=chassisList
    Clear List  ${chassisList}
    
    Append Item  ${chassisList}  name=${chassisIp}
    
    ${result} =  Refresh Connection  @{chassisList}[0]
    
    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"
    
##########################
# Re-assign ports        #
##########################
        
    ${clientCommunity} =  Set Variable  @{communityList}[0]
    ${clientNetwork} =  Cget  object=${clientCommunity}  field=network    
    ${clientPortList} =  Cget  object=${clientNetwork}  field=portList
    
    : FOR    ${port}    IN    @{portList1}
    \    @{portData} =  Split String  ${port}  .
    \    Append Item  ${clientPortList}  chassisId=@{portData}[0]  cardId=@{portData}[1]  portId=@{portData}[2]
        
    ${serverCommunity} =  Set Variable  @{communityList}[1]
    ${serverNetwork} =  Cget  object=${serverCommunity}  field=network    
    ${serverPortList} =  Cget  object=${serverNetwork}  field=portList
    
    : FOR    ${port}    IN    @{portList2}
    \    @{portData} =  Split String  ${port}  .
    \    Append Item  ${serverPortList}  chassisId=@{portData}[0]  cardId=@{portData}[1]  portId=@{portData}[2]

    
##########################
# Create activities      #
##########################
    
    ${clientActivityList} =  Cget  object=${clientCommunity}  field=activityList
    Append Item  ${clientActivityList}  protocolAndType=FTP Client
    
    ${serverActivityList} =  Cget  object=${serverCommunity}  field=activityList
    Append Item  ${serverActivityList}  protocolAndType=FTP Server
    
    ${httpClientActivity} =  Set Variable  @{clientActivityList}
    ${httpClientAgent} =  Cget  object=${httpClientActivity}  field=agent
    ${httpClientActionList} =  Cget  object=${httpClientAgent}  field=actionList
    
    Append Item  ${httpClientActionList}  commandType={Get}
    ${ftpCommand} =  Set Variable  @{httpClientActionList}[1]

    Config  object=${ftpCommand}  destination=Traffic2_FTPServer1:21 
    
##########################
# Save the repository    #
##########################
    
    Save As  ${test}  fullPath=${path_save_file}  overWrite=${TRUE}
    
 ##########################
# Run Test               #
##########################
    
    ${result} =  Run Test  ${test}
    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"
    
     Sleep  20s

	
##########################
# Check Stats            #
##########################
    
    ${ixLoadStats} =  Get IxLoad Stats  session=${session}

    ${statNewValue1} =  Get Stat Value  object=${ixLoadStats}  statSource=FTPClient  statName=FTP Simulated Users  timeStamp=latest
    ${statNewValue2} =  Get Stat Value  object=${ixLoadStats}  statSource=FTPClient  statName=FTP Connections  timeStamp=latest
	${statNewValue3} =  Get Stat Value  object=${ixLoadStats}  statSource=FTPClient  statName=FTP Concurrent Sessions  timeStamp=latest
	${statNewValue4} =  Get Stat Value  object=${ixLoadStats}  statSource=FTPClient  statName=FTP Transactions  timeStamp=latest
	${statNewValue5} =  Get Stat Value  object=${ixLoadStats}  statSource=FTPClient  statName=FTP Bytes  timeStamp=latest

	
	
	${statNewValue8} =  Get Stat Value  object=${ixLoadStats}  statSource=FTPServer  statName=FTP Control Bytes Sent  timeStamp=latest
	${statNewValue9} =  Get Stat Value  object=${ixLoadStats}  statSource=FTPServer  statName=FTP File Downloads Failed  timeStamp=latest
	${statNewValue10} =  Get Stat Value  object=${ixLoadStats}  statSource=FTPServer  statName=Data TCP SYN Failed  timeStamp=latest
	${statNewValue11} =  Get Stat Value  object=${ixLoadStats}  statSource=FTPServer  statName=Data TCP Timeouts  timeStamp=latest
	${statNewValue12} =  Get Stat Value  object=${ixLoadStats}  statSource=FTPServer  statName=Control TCP FIN Sent  timeStamp=latest

	
	
	Log To Console 	FTP Simulated=${statNewValue1}
	Log To Console 	FTP Connections=${statNewValue2}
	Log To Console  FTP Concurrent Sessions=${statNewValue3}
	Log To Console  FTP Transactions Failed=${statNewValue4}
	Log To Console  FTP Bytes=${statNewValue5}
	
	Log To Console  FTP Control Bytes Sent=${statNewValue8}
	Log To Console  FTP File Downloads Failed=${statNewValue9}
	Log To Console  Data TCP SYN Failed=${statNewValue10}
	Log To Console  Data TCP Timeouts=${statNewValue11}
	Log To Console  Control TCP FIN Sent=${statNewValue12}

    
##########################
# Stop Test              #
##########################
    
    ${result} =  Abort Test  ${test}
    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"
    
##########################
# Delete Session         #
##########################
    ${result} =  Abort Test  ${test}
    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"
    
    
*** Keywords ***
    
Teardown Actions
    Delete Session  session=${session}   