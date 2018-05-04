
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
	Set Global Variable  ${session}  # new line
    
    ${result} =  Start Session  ${session}
    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"
    
##########################
# Create Communities     #
##########################
    
	${test} =  Get IxLoad Test  session=${session}
    ${clientCommunity} =  Add Community  ${test}
	${serverCommunity} =  Add Community  ${test}
    
###################
# Clear chassis   #
###################
    
   Clear Chassis List  session=${session}

########################
# 	Add new chassis    #
########################
   
   
	${result} =  Add Chassis  session=${session}  name=${chassisIp}
	${status} =  Get From Dictionary  ${result}  status
	${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"
	
##########################
# Re-assign ports        #
##########################
	
	Assign Ports To Community  community=${clientCommunity}  portList=${portList1}
	Assign Ports To Community  community=${serverCommunity}  portList=${portList2}
	
##########################
# Create activities      #
##########################
    
    ${clientActivity} =  Add Activity  community=${clientCommunity}  protocolAndType=HTTP Client
	${serverActivity} =  Add Activity  community=${serverCommunity}  protocolAndType=HTTP Server
    
    
    ${httpClientAgent} =  Cget  object=${clientActivity}  field=agent
    ${httpClientActionList} =  Cget  object=${httpClientAgent}  field=actionList
    ${httpCommand_get} =  Append Item  ${httpClientActionList}  commandType=GET
    Config  object=${httpCommand_get}  destination=Traffic2_HTTPServer1:80  pageObject=/1b.html
	
	${httpCommand_post} =  Append Item  ${httpClientActionList}  commandType=POST
    Config  object=${httpCommand_post}  destination=Traffic2_HTTPServer1:80  pageObject=/256k.html  arguments=C:/Program Files (x86)/Ixia/IxLoad/8.20.115.124-EB/RobotFramework/DNS.rxf
	
	${httpCommand_think} =  Append Item  ${httpClientActionList}  commandType=THINK
     
	
##########################
# Save the repository    #
##########################
    
    Save As  ${test}  fullPath=${path_save_file}  overWrite=${TRUE}  # <- TO BE MODIFIED, path to the location f the new .rxf file

#########################
#  Apply configuration  #
#########################

    ${result} =  Apply Configuration  ${test}
    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
    Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS" 
    Sleep  30s        

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
#	Collect Diagnostics  #
##########################
    ${result} =  Collect Diagnostics  ${activeTest}  zipFileLocation=D:/robot_framework/2.zip
    ${status} =  Get From Dictionary  ${result}  status
    ${error} =  Get From Dictionary  ${result}  error
	Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"    
    
##########################
# Delete Session         #
##########################
   
*** Keywords ***
    
Teardown Actions
    Delete Session  session=${session}