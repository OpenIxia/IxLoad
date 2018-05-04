*** Settings ***
Library  BuiltIn
Library  String
Library  Collections
#Library           IxLoadRobot  C:/Program Files (x86)/Ixia/IxLoad/8.30.0.116-EB   # <-NEEDS TO BE MODIFIED, Path to the IxLoad instalation folder

Library  /home/hgee/Dropbox/MyIxiaWork/OpenIxiaGit/IxLoad/RestApi/Python/SampleScripts/Robot/RobotFramework/IxLoadRobot.py  /home/hgee/Dropbox/MyIxiaWork/OpenIxiaGit/IxLoad/RestApi/Python/SampleScripts/Robot/RobotFramework

Test Teardown     Teardown Actions 

*** Variables ***
#${clientIp} =  127.0.0.1
#${clientPort} =  8443
#${ixLoadVersion} =  8.30.0.116		# <-NEEDS TO BE MODIFIED, IxLoad version the test will run 
#${chassisIp} =  10.215.124.37			# <-NEEDS TO BE MODIFIED, IP of the chassis on which the card is found
#@{portList1} =  1.7.1  					# <-NEEDS TO BE MODIFIED, chassis.card.port on which the test will run 
#@{portList2} =  1.7.2					# <-NEEDS TO BE MODIFIED, chassis.card.port on which the test will run 


${clientIp} =  192.168.70.3
${clientPort} =  8443
${ixLoadVersion} =  8.40.0.277		# <-NEEDS TO BE MODIFIED, IxLoad version the test will run 
${chassisIp} =  192.168.70.11			# <-NEEDS TO BE MODIFIED, IP of the chassis on which the card is found
@{portList1} =  1.1.1  					# <-NEEDS TO BE MODIFIED, chassis.card.port on which the test will run 
@{portList2} =  1.2.1					# <-NEEDS TO BE MODIFIED, chassis.card.port on which the test will run 

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

    ${clientCommunity} =  Append Item  ${communityList}
    ${serverCommunity} =  Append Item  ${communityList}
    
    
##########################
# Add new chassis        #
##########################
    
    ${chassisChain} =  Get IxLoad Chassis Chain  session=${session}
    ${chassisList} =  Cget  object=${chassisChain}  field=chassisList
    Clear List  ${chassisList}
    
    ${chassis} =  Append Item  ${chassisList}  name=${chassisIp}
    ${result} =  Refresh Connection  ${chassis}
    
    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"
    
##########################
# Assign ports        #
##########################
    
    ${clientNetwork} =  Cget  object=${clientCommunity}  field=network    
    ${clientPortList} =  Cget  object=${clientNetwork}  field=portList
    
    : FOR    ${port}    IN    @{portList1}
    \    @{portData} =  Split String  ${port}  .
    \    Append Item  ${clientPortList}  chassisId=@{portData}[0]  cardId=@{portData}[1]  portId=@{portData}[2]
    
    ${serverNetwork} =  Cget  object=${serverCommunity}  field=network    
    ${serverPortList} =  Cget  object=${serverNetwork}  field=portList
    
    : FOR    ${port}    IN    @{portList2}
    \    @{portData} =  Split String  ${port}  .
    \    Append Item  ${serverPortList}  chassisId=@{portData}[0]  cardId=@{portData}[1]  portId=@{portData}[2]
	

	${ClientNetwork}=  Cget  object=${clientCommunity}  field=network
	${ClientStack}=  Cget  object=${ClientNetwork}  field=stack
	${ClientStackChildren}=  Cget  object=${ClientStack}  field=childrenList
	${ChildrenList} =  Set Variable  @{ClientStackChildren}[0]
	${ClientStackChildren_secondary}=  Cget  object=${ChildrenList}  field=childrenList
	${ChildrenList_secondary} =  Set Variable  @{ClientStackChildren_secondary}[0]
	${ClientMacVlanChildren}=  Cget  object=${ChildrenList_secondary}  field=rangeList
	Config  object=${ClientMacVlanChildren}  count=20
	
##########################
# Create activities      #
##########################
    
    ${clientActivityList} =  Cget  object=${clientCommunity}  field=activityList
    ${httpClientActivity} =  Append Item  ${clientActivityList}  protocolAndType=HTTP Client
    
    ${serverActivityList} =  Cget  object=${serverCommunity}  field=activityList
    ${httpServerActivity} =  Append Item  ${serverActivityList}  protocolAndType=HTTP Server
    
    
    ${httpClientAgent} =  Cget  object=${httpClientActivity}  field=agent
    ${httpClientActionList} =  Cget  object=${httpClientAgent}  field=actionList
    ${httpCommand_get} =  Append Item  ${httpClientActionList}  commandType=GET
    Config  object=${httpCommand_get}  destination=Traffic2_HTTPServer1:80  pageObject=/1b.html
	
	${httpCommand_post} =  Append Item  ${httpClientActionList}  commandType=POST
    Config  object=${httpCommand_post}  destination=Traffic2_HTTPServer1:80  pageObject=/256k.html  arguments=c:/robot_framework/test_preferences.rxf
	
	${httpCommand_think} =  Append Item  ${httpClientActionList}  commandType=THINK
     
#########################
#  Apply configuration #
#########################

    ${result} =  Apply Configuration  ${test}
    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"
    
    Sleep  30s
	
##########################
# Save the repository    #
##########################
    
    Save As  ${test}  fullPath=c:/Results/http_robot.rxf  overWrite=${TRUE}  # <- TO BE MODIFIED, path to the location f the new .rxf file
    
##########################
# 	Run Test	         #
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

    ${HTTP_Client_Requests_Sent} =  Get Stat Value  object=${ixLoadStats}  statSource=HTTPClientPerURL  statName=HTTP Requests Sent  timeStamp=latest
    ${HTTP_Client_Requests_Successful} =  Get Stat Value  object=${ixLoadStats}  statSource=HTTPClientPerURL  statName=HTTP Requests Successful  timeStamp=latest
	${HTTP_Client_Requests_Failed} =  Get Stat Value  object=${ixLoadStats}  statSource=HTTPClientPerURL  statName=HTTP Requests Failed  timeStamp=latest
	
	${HTTP_Server_Requests_Received} =  Get Stat Value  object=${ixLoadStats}  statSource=HTTPServerPerURL  statName=HTTP Requests Received  timeStamp=latest
	${HTTP_Server_Responses_Sent} =  Get Stat Value  object=${ixLoadStats}  statSource=HTTPServerPerURL  statName=HTTP Responses Sent  timeStamp=latest
	${HTTP_Server_Requests_Successful} =  Get Stat Value  object=${ixLoadStats}  statSource=HTTPServerPerURL  statName=HTTP Requests Successful  timeStamp=latest
	
    Log To Console  ${\n}
    Log To Console  ${\n}
	
    Log To Console  Client Request Successful=${HTTP_Client_Requests_Sent}
    Log To Console  Client Request Sent=${HTTP_Client_Requests_Successful}
    Log To Console  Client Request Failed=${HTTP_Client_Requests_Failed}

    Log To Console  Server Requests Received=${HTTP_Server_Requests_Received}
    Log To Console  Server Responses Sent=${HTTP_Server_Responses_Sent}
    Log To Console  Server Requests Successful=${HTTP_Server_Requests_Successful}
	
#######################
# Stats Interrogation #	
#######################


    Run Keyword If  '${HTTP_Client_Requests_Sent}' != '${HTTP_Client_Requests_Successful}'  FAIL  "Requests Sent differ from Requests Successful on Client"  ELSE  Log To Console  Successful stat check on client done.
    Run Keyword If  '${HTTP_Server_Requests_Received}' != '${HTTP_Server_Requests_Successful}'  FAIL  "Requests Sent differ from Requests Successful on Server"  ELSE  Log To Console  Successful stat check on server done.
    Run Keyword If  '${HTTP_Client_Requests_Failed}' != '0'  FAIL  "Requests Failed stat check failed."  ELSE  Log To Console  Requests Failed stat check done.
    
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
*** Keywords ***    
Teardown Actions
    Delete Session  session=${session} 