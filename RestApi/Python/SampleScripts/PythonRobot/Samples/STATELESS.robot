*** Variables ***

${path_IxLoad_version} =  C:/Program Files (x86)/Ixia/IxLoad/8.30.0.116-EB

${path_save_file} =  D:/robot_framework/empty_config_modified.rxf

${ixLoadVersion} =  8.30.0.116		# <-NEEDS TO BE MODIFIED, IxLoad version the test will run 
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
	Set Global Variable  ${session}  
	
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
# Re-assign ports        #
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

    
##########################
# Create activities      #
##########################
    
    ${clientActivityList} =  Cget  object=${clientCommunity}  field=activityList
    ${statelessClientActivity} =  Append Item  ${clientActivityList}  protocolAndType=stateless Peer
    
    ${serverActivityList} =  Cget  object=${serverCommunity}  field=activityList
    ${statelessServerActivity} =  Append Item  ${serverActivityList}  protocolAndType=stateless Peer
    
    
    #  Client side #    
    ${statelessClientAgent} =  Cget  object=${statelessClientActivity}  field=agent
	${pm} =  Cget  object=${statelessClientAgent}  field=pm
	${protocolFlows} =  Cget  object=${pm}  field=protocolFlows
	
	${stateless} =  Append Item  ${protocolFlows}  commandType=GenerateStream
    Config  object=${stateless}  cmdName=Generate UDP Stream  destination=Traffic2_StatelessPeer2
    
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

    ${statNewValue1} =  Get Stat Value  object=${ixLoadStats}  statSource=StatelessPeer  statName=Initiator Peer Count  timeStamp=latest
    ${statNewValue2} =  Get Stat Value  object=${ixLoadStats}  statSource=StatelessPeer  statName=Total Bytes Sent  timeStamp=latest
	${statNewValue3} =  Get Stat Value  object=${ixLoadStats}  statSource=StatelessPeer  statName=Total Packets Sent  timeStamp=latest
	${statNewValue4} =  Get Stat Value  object=${ixLoadStats}  statSource=StatelessPeer  statName=Active Streams Transmitting  timeStamp=latest
	${statNewValue5} =  Get Stat Value  object=${ixLoadStats}  statSource=StatelessPeer  statName=Fragments Sent  timeStamp=latest

	
	Log To Console 	Initiator Peer Count=${statNewValue1}
	Log To Console 	Total Bytes Sent=${statNewValue2}
	Log To Console  Total Packets Sent=${statNewValue3}
	Log To Console  Active Streams Transmitting=${statNewValue4}
	Log To Console  Fragments Sent=${statNewValue5}
	
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