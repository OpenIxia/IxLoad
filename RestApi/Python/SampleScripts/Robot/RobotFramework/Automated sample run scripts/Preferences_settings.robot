
*** Settings ***
Variables  variables.py
Library  BuiltIn
Library  String
Library  Collections
Library           IxLoadRobot  ${path_IxLoad_version}   # <-NEEDS TO BE MODIFIED, Path to the IxLoad instalation folder
Test Teardown     Teardown Actions 

*** Variables ***

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
# Load Test              #
##########################
    
    ${test} =  Get IxLoad Test  session=${session}
    
    ${result} =  Load Test  ${test}  fullPath=${rxf_full_path}
    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"

    ${activeTest} =  Cget  object=${test}  field=activeTest
    ${communityList} =  Cget  object=${activeTest}  field=communityList
 

 
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
# Change preferences     #
##########################

    ${preferences} =  Get IxLoad Preferences  session=${session}
    Config
	...  object=${preferences}
    ...	 continueTestOnLoadModuleFail=True  logCollectorSize=500  maximumInstances=3  enableDebugLogs=True  overloadProtection=False
    ...  autoRebootCrashedPorts=False  detailedChassisMonitoring=False  checkLinkStateAtApplyConfig=True  ntpServer2=ntpServer2
	...  ntpServer1=ntpServer1  allowIPOverlapping=True  allowRouteConflicts=True  enableAnonymousUsageStatistics=True

    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"


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
    Sleep  10s
	
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