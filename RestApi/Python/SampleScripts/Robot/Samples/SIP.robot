*** Variables ***

${path_IxLoad_version} =  C:/Program Files (x86)/Ixia/IxLoad/8.30.0.116-EB   # <-NEEDS TO BE MODIFIED, Path to the IxLoad instalation folder

${path_save_file} =  D:/robot_framework/empty_config_modified.rxf            # <-NEEDS TO BE MODIFIED, Path to the location you want to save the rxf 

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
${rxf_full_path} =  C:/Users/adimache/Desktop/Scripturi/final form/SIP.rxf
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
# 		Load Test        #
##########################
    
    ${test} =  Get IxLoad Test  session=${session}
    ${result} =  Load Test  ${test}  fullPath=${rxf_full_path}
    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"
    ${activeTest} =  Cget  object=${test}  field=activeTest
	
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
    
######################################################
# 	Re-assign ports + Reboot + Clear Ownership       #
######################################################

	${clientCommunity} =  Get Community By Name  test=${test}  communityName=Traffic1@Network1
    ${clientNetwork} =  Cget  object=${clientCommunity}  field=network    
    ${clientPortList} =  Cget  object=${clientNetwork}  field=portList
    
    : FOR    ${port}    IN    @{portList1}
    \    @{portData} =  Split String  ${port}  .
	\    ${port}=  Append Item  ${clientPortList}  chassisId=@{portData}[0]  cardId=@{portData}[1]  portId=@{portData}[2]
	\ 	 ${result} =  Reboot  ${port}  
	\	 ${status} =  Get From Dictionary  ${result}  status
	\	 ${error} =  Get From Dictionary  ${result}  error
	\	 Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCES"
	\ 	 ${result} =  Clear Ownership  ${port}  force=${TRUE}
	\	 ${status} =  Get From Dictionary  ${result}  status
	\	 ${error} =  Get From Dictionary  ${result}  error
	\	 Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCES"
		
	${serverCommunity} =  Get Community By Name  test=${test}  communityName=Traffic2@Network2
    ${serverNetwork} =  Cget  object=${serverCommunity}  field=network    
    ${serverPortList} =  Cget  object=${serverNetwork}  field=portList
    
    : FOR    ${port}    IN    @{portList2}
    \    @{portData} =  Split String  ${port}  .
    \    ${port}=  Append Item  ${serverPortList}  chassisId=@{portData}[0]  cardId=@{portData}[1]  portId=@{portData}[2]
	\ 	 ${result} =  Reboot  ${port}  
	\	 ${status} =  Get From Dictionary  ${result}  status
	\	 ${error} =  Get From Dictionary  ${result}  error
	\	 Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCES"
	\ 	 ${result} =  Clear Ownership  ${port}  force=${TRUE}
	\	 ${status} =  Get From Dictionary  ${result}  status
	\	 ${error} =  Get From Dictionary  ${result}  error
	\	 Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCES"

##########################
#    Edit activities     #
##########################
   
    ${ClientActivityList} =  Cget  object=${clientCommunity}  field=activityList
	${Activity} =  Set Variable  @{ClientActivityList}[0]
    ${ClientAgent} =  Cget  object=${Activity}  field=agent
    ${ClientActionList} =  Cget  object=${ClientAgent}  field=pm 
	${AudioSettings} =  Cget  object=${ClientActionList}  field=audioSettings
    Config  object=${AudioSettings}  enableAudio=false  enableAudioOWD=true

##########################
# Save the repository    #
##########################
    
    Save As  ${test}  fullPath=D:/robot_framework/empty_config_modified.rxf  overWrite=${TRUE}  # <- TO BE MODIFIED with the path to the location of the new .rxf file

##########################
#   Export Configurtion  #
##########################	

	Export Config  ${test}  destFile=D:/robot_framework/newFile.crf
	${status} =  Get From Dictionary  ${result}  status
	${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"
	
##########################
# Set Result Directory   #
##########################	

	${test} =  Get IxLoad Test  session=${session}
	${activeTest} =  Cget  object=${test}  field=activeTest
	Set Result Directory  test=${test}  path=C:/robot_framework/results   
    
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

    ${statNewValue1} =  Get Stat Value  object=${ixLoadStats}  statSource=Signaling(VoIPSip)  statName=Failed Registrations  timeStamp=latest
    ${statNewValue2} =  Get Stat Value  object=${ixLoadStats}  statSource=Signaling(VoIPSip)  statName=Talk Time (Avg) [ms]  timeStamp=latest
	${statNewValue3} =  Get Stat Value  object=${ixLoadStats}  statSource=Signaling(VoIPSip)  statName=Answered Calls  timeStamp=latest
	
	${statNewValue4} =  Get Stat Value  object=${ixLoadStats}  statSource=RTP(VoIPSip)  statName=RTP Packets Sent  timeStamp=latest
	${statNewValue5} =  Get Stat Value  object=${ixLoadStats}  statSource=RTP(VoIPSip)  statName=RTP Lost Packets  timeStamp=latest
	${statNewValue6} =  Get Stat Value  object=${ixLoadStats}  statSource=RTP(VoIPSip)  statName=Delay Variation Jitter (Avg) [us]  timeStamp=latest
	
	${statNewValue7} =  Get Stat Value  object=${ixLoadStats}  statSource=SIP(VoIPSip)  statName=SIP Requests Sent  timeStamp=latest
	${statNewValue8} =  Get Stat Value  object=${ixLoadStats}  statSource=SIP(VoIPSip)  statName=Rejected Calls  timeStamp=latest
	${statNewValue9} =  Get Stat Value  object=${ixLoadStats}  statSource=SIP(VoIPSip)  statName=Failed Session Refreshes  timeStamp=latest
	
	${statNewValue10} =  Get Stat Value  object=${ixLoadStats}  statSource=Flow(VoIPSip)  statName=Total Channels  timeStamp=latest
	${statNewValue11} =  Get Stat Value  object=${ixLoadStats}  statSource=Flow(VoIPSip)  statName=Active Callers  timeStamp=latest
	${statNewValue12} =  Get Stat Value  object=${ixLoadStats}  statSource=Flow(VoIPSip)  statName=Failed Channels  timeStamp=latest
	
	${statNewValue13} =  Get Stat Value  object=${ixLoadStats}  statSource=Errors(VoIPSip)  statName=Internal Errors  timeStamp=latest
	${statNewValue14} =  Get Stat Value  object=${ixLoadStats}  statSource=Errors(VoIPSip)  statName=Timeout Errors  timeStamp=latest
	${statNewValue15} =  Get Stat Value  object=${ixLoadStats}  statSource=Errors(VoIPSip)  statName=RTP Errors  timeStamp=latest
	
	
	
	Log To Console 	Failed Registrations=${statNewValue1}
	Log To Console 	Talk Time (Avg) [ms]=${statNewValue2}
	Log To Console  Answered Calls=${statNewValue3}
	
	Log To Console 	RTP Packets Sent=${statNewValue4}
	Log To Console 	RTP Lost Packets=${statNewValue5}
	Log To Console  Delay Variation Jitter (Avg) [us]=${statNewValue6}
	
	Log To Console 	SIP Requests Sent=${statNewValue7}
	Log To Console 	Rejected Calls=${statNewValue8}
	Log To Console  Failed Session Refreshes=${statNewValue9}
	
	Log To Console 	Total Channels=${statNewValue10}
	Log To Console 	Active Callers=${statNewValue11}
	Log To Console  Failed Channels=${statNewValue12}
	
	Log To Console  Internal Errors=${statNewValue13}
	Log To Console  Timeout Errors=${statNewValue14}
	Log To Console  RTP Errors=${statNewValue15}

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