*** Variables ***

${path_IxLoad_version} =  C:/Program Files (x86)/Ixia/IxLoad/8.30.0.116-EB

${path_save_file} =  D:/robot_framework/empty_config_modified.rxf

${ixLoadVersion} =  8.30.0.116   		# <-NEEDS TO BE MODIFIED, IxLoad version the test will run 
${chassisIp} =  10.215.123.50			# <-NEEDS TO BE MODIFIED, IP of the chassis on which the card is found
@{portList1} =  1.2.3  					# <-NEEDS TO BE MODIFIED, chassis.card.port on which the test will run 
@{portList2} =  1.2.4					# <-NEEDS TO BE MODIFIED, chassis.card.port on which the test will run		

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
    ${imapClientActivity} =  Append Item  ${clientActivityList}  protocolAndType=IMAP Client
    
    ${serverActivityList} =  Cget  object=${serverCommunity}  field=activityList
    ${imapServerActivity} =  Append Item  ${serverActivityList}  protocolAndType=IMAP Server

#  Client side #    
    ${imapClientAgent} =  Cget  object=${imapClientActivity}  field=agent
	${pm} =  Cget  object=${imapClientAgent}  field=pm
	${imapCommands} =  Cget  object=${pm}  field=imapCommands
	${getMailsCommand} =  Append Item  ${imapCommands}  commandType=GETMAILS
    Config  object=${getMailsCommand}  imapServerIp=Traffic2_IMAPServer1:143

#  Server side #    
	${imapServerAgent} =  Cget  object=${imapServerActivity}  field=agent
	${pm} =  Cget  object=${imapServerAgent}  field=pm
	${imapServerConfig} =  Cget  object=${pm}  field=imapServerConfig
	${mails} =  Cget  object=${imapServerConfig}  field=mails
	${newMail} =  Append Item  ${mails}
    Config  object=${newMail}  mail_name=Simple  
	
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

    ${statNewValue1} =  Get Stat Value  object=${ixLoadStats}  statSource=IMAPClient  statName=IMAP Connection Established  timeStamp=latest
    ${statNewValue2} =  Get Stat Value  object=${ixLoadStats}  statSource=IMAPClient  statName=IMAP Sessions Requested  timeStamp=latest
	${statNewValue3} =  Get Stat Value  object=${ixLoadStats}  statSource=IMAPClient  statName=IMAP Sessions Established  timeStamp=latest
	${statNewValue4} =  Get Stat Value  object=${ixLoadStats}  statSource=IMAPClient  statName=IMAP Sessions Failed  timeStamp=latest
	${statNewValue5} =  Get Stat Value  object=${ixLoadStats}  statSource=IMAPClient  statName=IMAP Sessions Aborted  timeStamp=latest

	
	
	${statNewValue8} =  Get Stat Value  object=${ixLoadStats}  statSource=IMAPServer  statName=IMAP Session Requests Received   timeStamp=latest
	${statNewValue9} =  Get Stat Value  object=${ixLoadStats}  statSource=IMAPServer  statName=IMAP Session Requests Completed  timeStamp=latest
	${statNewValue10} =  Get Stat Value  object=${ixLoadStats}  statSource=IMAPServer  statName=IMAP Session Requests Failed  timeStamp=latest
	
	
	
	Log To Console 	IMAP Connection Established=${statNewValue1}
	Log To Console 	IMAP Sessions Requested=${statNewValue2}
	Log To Console  IMAP Sessions Established=${statNewValue3}
	Log To Console  IMAP Sessions Failed=${statNewValue4}
	Log To Console  IMAP Sessions Aborted=${statNewValue5}
	
	Log To Console  IMAP Session Requests Received=${statNewValue8}
	Log To Console  IMAP Session Requests Completed=${statNewValue9}
	Log To Console  IMAP Session Requests Failed=${statNewValue10}

	Run Keyword If  '${statNewValue4}' != '0'  FAIL  '${statNewValue4}'"IMAP Sessions Failed !!!!!!"  ELSE  Log To Console  "IMAP Sessions Failed stat check done."
	Run Keyword If  '${statNewValue5}' != '0'  FAIL  '${statNewValue5}'"IMAP Sessions Aborted !!!!!!"  ELSE  Log To Console  "IMAP Sessions Aborted  stat check done."
	Run Keyword If  '${statNewValue10}' != '0'  FAIL  '${statNewValue6}'"IMAP Session Requests Failed !!!!!!"  ELSE  Log To Console  "IMAP Session Requests Failed  stat check done."
   
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