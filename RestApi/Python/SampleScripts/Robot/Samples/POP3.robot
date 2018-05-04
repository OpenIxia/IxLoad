*** Variables ***

${path_IxLoad_version} =  C:/Program Files (x86)/Ixia/IxLoad/8.30.0.116-EB # <-NEEDS TO BE MODIFIED, Path to the IxLoad instalation folder

${path_save_file} =  D:/robot_framework/empty_config_modified.rxf          # <-NEEDS TO BE MODIFIED, Path to the location you want to save the rxf 

${ixLoadVersion} =  8.30.0.116			# <-NEEDS TO BE MODIFIED, IxLoad version the test will run 
${chassisIp} =  10.215.124.37			# <-NEEDS TO BE MODIFIED, IP of the chassis on which the card is found
@{portList1} =  1.7.1  					# <-NEEDS TO BE MODIFIED, chassis.card.port on which the test will run 
@{portList2} =  1.7.5					# <-NEEDS TO BE MODIFIED, chassis.card.port on which the test will run		


*** Settings ***
Library  BuiltIn
Library  String
Library  Collections
Library           IxLoadRobot  ${path_IxLoad_version}   # <-NEEDS TO BE MODIFIED, Path to the IxLoad instalation folder
Test Teardown     Teardown Actions 

*** Variables ***

${clientIp} =  127.0.0.1
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
    Append Item  ${clientActivityList}  protocolAndType=POP3 Client
    
    ${serverActivityList} =  Cget  object=${serverCommunity}  field=activityList
    Append Item  ${serverActivityList}  protocolAndType=POP3 Server
    
    ${pop3ClientActivity} =  Set Variable  @{clientActivityList}
    ${pop3ClientAgent} =  Cget  object=${pop3ClientActivity}  field=agent
    ${pop3ClientActionList} =  Cget  object=${pop3ClientAgent}  field=commandList
    
    Append Item  ${pop3ClientActionList}  commandType={Get}
    ${pop3Command} =  Set Variable  @{pop3ClientActionList}[1]

    Config  object=${pop3Command}  arguments=Traffic2_POP3Server1:110 
    
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

    ${statNewValue1} =  Get Stat Value  object=${ixLoadStats}  statSource=POP3Client  statName=POP3 Simulated Users  timeStamp=latest
    ${statNewValue2} =  Get Stat Value  object=${ixLoadStats}  statSource=POP3Client  statName=POP3 Sessions Failed  timeStamp=latest
	${statNewValue3} =  Get Stat Value  object=${ixLoadStats}  statSource=POP3Client  statName=POP3 Authentication Failed  timeStamp=latest
	
	
	${statNewValue8} =  Get Stat Value  object=${ixLoadStats}  statSource=POP3Server  statName=POP3 Session Requests Received  timeStamp=latest
	${statNewValue9} =  Get Stat Value  object=${ixLoadStats}  statSource=POP3Server  statName=POP3 Session Requests Successful  timeStamp=latest
	${statNewValue10} =  Get Stat Value  object=${ixLoadStats}  statSource=POP3Server  statName=POP3 Session Requests Failed  timeStamp=latest
	
	
	
	Log To Console 	Simulated Users=${statNewValue1}
	Log To Console 	Sessions Failed=${statNewValue2}
	Log To Console  Authentication Failed=${statNewValue3}
	
	Log To Console  DNS Total Queries Received=${statNewValue8}
	Log To Console  DNS Total Queries Responded Successfully=${statNewValue9}
	Log To Console  DNS Total Queries Failed=${statNewValue10}

	Run Keyword If  '${statNewValue10}' != '0'  FAIL  '${statNewValue10}'"Session Requests Failed !"  ELSE  Log To Console  "Session Requests stat check done."     
	
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