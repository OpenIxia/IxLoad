import sys, os

class IxLoadRobot(object):
    """Library for IxLoad Robot API.

    = Table of contents =

    - `Prerequisites`
    - `Samples`
    - `Importing`
    - `Shortcuts`
    - `Keywords`

    = Prerequisites =

    In order to be able to run Robot API scripts, Ixload must be installed with the custom install option IxLoad Gateway. This will install the IxLoad Gateway service which handles creating new IxLoad session/instances.

    IxLoad includes also Python 2.7. This can be found at the following location: e.g. C:\Program Files (x86)\Ixia\IxLoad\[IxLoad_Version]\ 3rdParty\Python2.7\python.exe.

    The validation of Robot API has been done with the above mentioned Python version and installation.

    The next step is to install robotframework and requests modules for Python. This can be achieved by using "pip".

    Example: 
    _pip install requests_

    _pip install robotframework_

    The IxLoadRobot API library can be found in the RobotFramework subfolder as part of the IxLoad install folder (e.g. C:\Program Files (x86)\Ixia\IxLoad\[IxLoad_Version]\RobotFramework)
 
    = Samples =

    A set of Robot API samples is included in the IxLoad installation. These can be found at the following path: e.g. C:\Program Files (x86)\Ixia\IxLoad\[IxLoad_Version]\RobotFramework.

    Samples cover 2 main areas: loading a configuration file versus creating a configuration file. They also include running the resulted configuration and querying statistics.

    | =Sample name= | =Short description=         |
    | HTTP_colect_diagnostics.robot   | Create an HTTP new configuration. Apply the configuration, run the test and collect diagnostics.  |
    | HTTP_new_config.robot   | Create an HTTP new configuration. Assign ports, modify the IP range count, run test and interogate statistics.     |
    | Preferences_settings.robot   | Load an HTTP configuration. Assign new ports, clear ownership and reboot, change preferences, save configuration and run.      |
    | SIP_export_config.robot   | Load a SIP configuration. Edit settings on SIP activities, save configuration and export to CRF.      |

    In order to execute the sample scripts, the path to the IxLoad build(used when initializing the IxLoadRobot library) needs to be changed. 

    In case you are running IxLoad Robot scripts against an IxLoad Gateway service installed on a remote machine, please also change the ipAdress to be different than 127.0.0.1 as defined in the sample scripts.

    A similar change is required in case the IxLoad Gateway service has been started on a different port than 8080.

    """

    def __init__(self, pathToIxLWrapper):
        '''The path to the IxLoad build install folder that will be used for creating new IxLoad Robot API sessions. 

        Example:

            _Library           IxLoadRobot  C:/Program Files (x86)/Ixia/IxLoad/8.20.115.120-EB_

        '''
        
        pathToIxLoadInstallDir = pathToIxLWrapper

        pathToIxLWrapper    = os.path.join(pathToIxLWrapper, "RobotFramework")
        pathToRestUtils     = os.path.join(pathToIxLoadInstallDir, "RestScripts", "Utils")
        self.pathToIxLWrapper = pathToIxLWrapper

        sys.path.append(pathToIxLWrapper)
        sys.path.append(pathToRestUtils)

        from ixLoadRobotFwWrapper import ixLoadRobotFwWrapper
        self.IxLoadWrapper = ixLoadRobotFwWrapper()

    def _is_keyword_valid(self, keyword):
        return True

    def _run_keyword(self, keyword, kwargs):
        return self.IxLoadWrapper.runKeyword(keyword, **kwargs)

    def _run_operation_keyword(self, operation, obj, kwargs):
        return self.IxLoadWrapper.runOperation(operation, obj, **kwargs)

    ####################################

    def create_session(self, **kwargs):
        '''Create a new IxLoad instance. This new instance will need to be also started by using the start_session keyword.

        The Create Session keyword receives as parameter the IxLoad version that is going to be used.

        Example: Please check the example for `Start Session` keyword.

        For more examples please consult `Samples`.

        '''
        return self._run_keyword("create_session", kwargs)

    def delete_session(self, **kwargs):
        '''Close an IxLoad instance and remove this from the list of active instances.

        The Delete Session keyword receives as parameter an IxLoad session/instance to be deleted.

        Example:

            _Delete Session  session=${session}  _

        For more examples please consult `Samples`.

        '''
        return self._run_keyword("delete_session", kwargs)

    def connect(self, **kwargs):
        '''Connect to the IxLoadGateway service. Required in order to start a new IxLoad instance.
        
        The Connect keyword receives as parameters the IP of the machine on which the IxLoad Gateway is running(where the IxLoad sessions/instances will be started) and the port on which the service is listening(by default this is 8080).

        Example: Please check the example for `Start Session` keyword.

        For more examples please consult `Samples`.

        '''
        return self._run_keyword("connect", kwargs)

    def cget(self, **kwargs):
        '''Return a field from a specified object.

        The Cget keyword can be applied on any object from the IxLoad data model. It receives as parameter the object and the field to retrieve from that particular object.

        It can return primitive values, objects or lists. Filter can also be applied on this keyword, similar to the bellow example.

        All possible filter operators are:

        _eq - equals_
        
        _ne - not equal to_
        
        _lt - lower than_
        
        _gt - greater than_
        
        _le - lower or equal to_
        
        _ge - greater or equal to_
        
        Example: Retrieve the active test from the IxLoad Test. On the active test retrieve the list of communities(nettraffics) with a specific name.

            _${activeTest} =  Cget  object=${test}  field=activeTest_
            
            _${communityList} =  Cget  object=${activeTest}  field=communityList  filter=name eq Traffic1@Network1 _

        For more examples please consult `Samples`.

        '''
        return self._run_keyword("cget", kwargs)

    def config(self, object, **kwargs):
        '''Modify a primitive field on a specified object.

        The Config keyword can be applied on any object from the IxLoad data model. It receives as parameter the object and the field to modify from that particular object.
        
        Example: Configure settings on an HTTP Client Agent.

            _${httpClientAgent} =  Cget  object=${httpClientActivity}  field=agent_

            _Config  object=${httpClientAgent}  httpVersion=2  commandTimeout=450  commandTimeout_ms=0  ipPreference=2 _

        For more examples please consult `Samples`.

        '''
        kwargs['_object_'] = object
        return self._run_keyword("config", kwargs)

    def clear_list(self, object, **kwargs):
        '''Clear all the elements in a list.

        Receives as input parameter the list which needs to be cleared.

        Example: Remove the chassisList from the current test chassis chain 

            _${chassisChain} =  Get IxLoad Chassis Chain  session=${session}_

            _${chassisList} =  Cget  object=${chassisChain}  field=chassisList_

            _Clear List  ${chassisList}_

        For more examples please consult `Samples`.

        '''
        kwargs['_object_'] = object
        return self._run_keyword("clearList", kwargs)

    def set_result_directory(self, **kwargs):
        '''Set the path to the run results directory.

        This keyword receives as parameter the activeTest object from the current IxLoad test and the path to the folder that will be used as results directory.

        Example: 

            _${test} =  Get IxLoad Test  session=${session}_

            _Set Result Directory  test=${test}  path=C:/robot_framework/results   _

        For more examples please consult `Samples`.

        '''
        return self._run_keyword("set_result_directory", kwargs)

    def get_stat_value(self, **kwargs):
        '''Retrieve the value of a statistic, for a particular timestamp and for a particular stat source.

        The Get Stat Value keyword receives as parameters an ixLoadStats objects, the statsource where to find the statistic, the stat to be retrieved and the timestamp at which the value should be taken. 

        Example: Retrieve a list with all available stat sources. From this list obtain only the values for the HTTPClientPerURL statsource.

        From the HTTPClientPerURL stat values get the value for the HTTP Requrest Sent stat at timestamp 6000.

        At the same timestamp get the values also for HTTP Requests Successful stat. If HTTP Requests Successful differ from HTTP Requrest Sent fail the test.

            _${ixLoadStats} =  Get IxLoad Stats  session=${session}_

            _${httpClientPerURLStatSource} =  Cget  object=${ixLoadStats}  field=HTTPClientPerURL_
    
            _${statValues} =  Cget  object=${httpClientPerURLStatSource}  field=values_
    
            _${timeStamp} =  Cget  object=${statValues}  field=6000_
    
            _${statNewValue} =  Get Stat Value  object=${ixLoadStats}  statSource=HTTPClientPerURL  statName=HTTP Requests Sent  timeStamp=6000_
    
            _${requestsSent} =  Cget  object=${timeStamp}  field=HTTP Requests Sent_

            _${requestsSuccessful} =  Cget  object=${timeStamp}  field=HTTP Requests Successful_
    
            _Run Keyword If  '${requestsSent}' != '${requestsSuccessful}'  FAIL  "Requests Sent differ from Requests Successful"  ELSE  Log  "Status is SUCCESS"_

        For more examples please consult `Samples`.

        '''
        return self._run_keyword("get_stat_value", kwargs)

    def append_item(self, object, **kwargs):
        '''Append an item to a list.

        The Append Item keyword receives as input parameter the list on which the item will be added and the item to be added in the list.

        This keyword returns a reference to the object added in the list.

        Example: Adding a new chassis in the chassisList.

            _${chassis} =  Append Item  ${chassisList}  name=${chassisIp}_

        For more examples please consult `Samples`.

        '''
        kwargs['_object_'] = object
        return self._run_keyword("appendItem", kwargs)

    def delete_item(self, object, **kwargs):
        '''Delete an item.

        This keyword can be called on either a list in which case it will remove all elements from the list or on an object that is part of a list in which case it will remove just that particular object.

        The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 

        Example: Delete the client community(nettraffic) from the current IxLoad test.

            _${clientCommunity} =  Set Variable  @{communityList}[0]_

            _Delete Item  ${clientCommunity}_

        For more examples please consult `Samples`.

        '''
        kwargs['_object_'] = object
        return self._run_keyword("deleteItem", kwargs)

    def get_ixload_test(self, **kwargs):
        '''Get the current IxLoad test. This is the root object for the entire IxLoad configuration.

        This keyword receives as parameter the IxLoad session/instance.

        Example: Please check the example for `Collect Diagnostics` keyword.

        For more examples please consult `Samples`.

        '''
        return self._run_keyword("get_ixload_test", kwargs)

    def get_ixload_chassis_chain(self, **kwargs):
        '''Returns the chassis chain in the current IxLoad test. The chassis chain contains the chassis list.

        This keyword receives as parameter the IxLoad session/instance.

        Example: Please check the example for `Refresh Connection` keyword.

        For more examples please consult `Samples`.

        '''
        return self._run_keyword("get_ixload_chassis_chain", kwargs)

    def get_ixload_stats(self, **kwargs):
        '''Retrieve a list of all available stat sources for the current IxLoad test.

        The Get IxLoad Stats keyword receives as parameter an IxLoad session/instance object.

        Example: Please check the example for `Get Stat Value` keyword.

        For more examples please consult `Samples`.
        '''
        return self._run_keyword("get_ixload_stats", kwargs)

    def get_ixload_preferences(self, **kwargs):
        '''Retrieve the current set of preferences(global options) for IxLoad. 

        This keyword receives as parameter an IxLoad session/instance object.

        The global options that can be changed on the preferences object are the settings described in the example bellow.

        Example:

            _${preferences} =  Get IxLoad Preferences  session=${session}_

            _Config_

            _...  object=${preferences}_

            _...  continueTestOnLoadModuleFail=True  logCollectorSize=500  maximumInstances=3  enableDebugLogs=True  overloadProtection=False_

            _...  autoRebootCrashedPorts=False  detailedChassisMonitoring=False  checkLinkStateAtApplyConfig=True  ntpServer2=ntpServer2_

            _...  ntpServer1=ntpServer1  allowIPOverlapping=True  allowRouteConflicts=True  enableAnonymousUsageStatistics=True_

            _Config  object=${preferences}  licenseServer=10.215.170.21  licenseModel=Perpetual Mode_

        For more examples please consult `Samples`.     

        Note: IxLoad Robot API sessions are started under the System user, not the user you are logged in as. 

        As all the Global Options except Maximum Instances, License Model, and License Server are saved per-user, this means that settings made in the IxLoad UI will have no effect on Robot API runs, since the Robot API will be registered under the System user. 

        Therefore, for the Maximum Instances, License Model, and License Server options to have an effect on Robot API tests, you must set them from the Robot API.  

        '''
        return self._run_keyword("get_ixload_preferences", kwargs)
      
    def add_chassis(self, **kwargs):
        '''Add and connect to a new chassis in the current IxLoad test.

        Receives as parameter the IxLoad session/instance and the name or IP of the chassis.

        This is an alternate approach for adding a chassis. 

        The same can be achieved by using Append Item keyword on the chassisChain chassisList field and then refreshing the connection the newly added chassis.

        Example:

            _${result} =  Add Chassis  ${session}  name=${chassisIp}_

            _${status} =  Get From Dictionary  ${result}  status_

            _${error} =  Get From Dictionary  ${result}  error_

            _Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"_

        For more examples please consult `Samples`.  

        '''
        return self._run_keyword("add_chassis", kwargs)

    def clear_chassis_list(self, **kwargs):
        '''Remove all chassis from the current IxLoad test.

        Receives as parameter the IxLoad current session/instance.

        The same can be achieved by obtaing the chassisList from the chassis chain and running the Clear List keyword on it.

        Example:

            _Clear Chassis List  session=${session}_

        For more examples please consult `Samples`.   

        '''
        return self._run_keyword("clear_chassis_list", kwargs)
        
    def get_community_by_name(self, **kwargs):
        '''Retrieve from the current IxLoad test a community matching the specified name.

        Receives as parameter the IxLoad current test and the name of the community(nettraffic) that we want to retrieve.

        The same can be achieved by obtaining the communityList from the activeTest and iterating on it until the communityName required has been found.

        Example:

            _${test} =  Get IxLoad Test  session=${session}_
    
            _${clientCommunity} =  Get Community By Name  test=${test}  communityName=Traffic1@Network1_

        For more examples please consult `Samples`.   

        '''
        return self._run_keyword("get_community_by_name", kwargs)

    def add_community(self, object, **kwargs):
        '''Add a new community(NetTraffic) to the current IxLoad test.

        Receives as parameter the IxLoad current test.

        This is an alternate approach for adding a community. 

        The same can be achieved by using Append Item keyword on the activeTest communityList field. 

        Example:

            _${test} =  Get IxLoad Test  session=${session}_
    
            _${clientCommunity} =  Add Community  ${test}_

            _${serverCommunity} =  Add Community  ${test}_

        For more examples please consult `Samples`.   

        '''
        kwargs['_object_'] = object
        return self._run_keyword("add_community", kwargs)

    def add_activity(self, **kwargs):
        '''Add a new activity to the specified community.

        Receives as parameter the commnity(nettraffic) and the protocol and type(client/server/peer) of the activity to be added.

        This is an alternate approach for adding an activity. 

        The same can be achieved by using Append Item keyword on the community activityList field. 

        Example:

            _${test} =  Get IxLoad Test  session=${session}_
    
            _${clientCommunity} =  Add Community  ${test}_

            _${clientActivity} =  Add Activity  community=${clientCommunity}  protocolAndType=HTTP client_

        For more examples please consult `Samples`.   

        '''
        return self._run_keyword("add_activity", kwargs)

    def assign_ports_to_community(self, **kwargs):
        '''Assign the provided port list to the specified community.

        This keyword receives as parameter the community(netttraffic) on which the ports should be added and the list of ports.

        This is an alternate approach for adding ports. 

        The same can be achieved by using Append Item keyword on the community portList field. For a detailed example please check the  `Clear Ownership` keyword example.

        Example:

            _${test} =  Get IxLoad Test  session=${session}_
    
            _${clientCommunity} =  Add Community  ${test}_

            _${serverCommunity} =  Add Community  ${test}_

            _Assign Ports To Community  community=${clientCommunity}  portList=${portList1}_

            _Assign Ports To Community  community=${serverCommunity}  portList=${portList2}_

        For more examples please consult `Samples`.   

        '''
        return self._run_keyword("assign_ports_to_community", kwargs)        

    ####### Start of REST API OPERATIONS

    def start_session(self, obj, **kwargs):
        '''Start a new IxLoad session/instance.

        The Start Session keyword starts an already created session, which needs to be passed on as parameter.

        The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 

        Example: Connecting to the IxLoad Gateway service, creating and starting a new IxLoad session/instance.

            _${clientIp} =  127.0.0.1_

            _${clientPort} =  8080_

            _${ixLoadVersion} =  8.20.115.117_

            _Connect  ipAddress=${clientIp}  port=${clientPort}_

            _${session} =  Create Session  ixLoadVersion=${ixLoadVersion}_

            _Set Global Variable  ${session}  _
    
            _${result} =  Start Session  ${session}_

            _${status} =  Get From Dictionary  ${result}  status_

            _${error} =  Get From Dictionary  ${result}  error_

            _Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"_

        For more examples please consult `Samples`.

        '''
        return self._run_operation_keyword("start", obj, kwargs)

    def export_config(self, obj, **kwargs):
        '''Exports the currently loaded configuration file as a .crf file.

           The Export Config keyword receives as parameter the current IxLoad test object and the path to the .crf file to be created.

           The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 

           Example: 

                _Export Config  ${test}  destFile=G:/newFile.crf_

                _${status} =  Get From Dictionary  ${result}  status_

                _${error} =  Get From Dictionary  ${result}  error_

                _Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"  _

           For more examples please consult `Samples`.
        '''
        return self._run_operation_keyword("exportConfig", obj, kwargs)

    def collect_diagnostics(self, obj, **kwargs):
        '''Collect diagnostics. To use this keyword the current test must be either in configured or unconfigured state.

        IxLoad includes a diagnostics collection utility that collects log files and packages them into a ZIP file, so that they can be stored or emailed conveniently. 

        In the UI, the utility can be accessed from the File > Tools > Diagnostics menu. The same log files can be collected also using Robot API.

        The Collect Diagnostics keyword receives as parameters the active test, the path where to save the diagnostics archive and a boolean variable which specifies if diagnostics should be collected from the client only or also from the chassis.
        
        The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 

        Example:

            _${test} =  Get IxLoad Test  session=${session}_

            _${activeTest} =  Cget  object=${test}  field=activeTest_

            _${result} =  Collect Diagnostics  ${activeTest}  zipFileLocation=C:/robot_framework/diagnostics.zip  clientOnly=${FALSE}_

            _${status} =  Get From Dictionary  ${result}  status_

            _${error} =  Get From Dictionary  ${result}  error_

            _Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCES" _

        For more examples please consult `Samples`.           

        '''
        return self._run_operation_keyword("collectDiagnostics", obj, kwargs)

    def reboot(self, obj, **kwargs):
        '''Reboot the provided port.

        The Reboot keyword receives as parameter the port to be rebooted.

        The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 

        Example: Please check the example for `Clear Ownership` keyword.

        For more examples please consult `Samples`.

        '''
        return self._run_operation_keyword("reboot", obj, kwargs)

    def clear_ownership(self, obj, **kwargs):
        '''Clear the current user's ownership on the provided port.

        The Clear Ownership keyword receives as parameter the port on which to remove the current ownership.

        The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 

        Example: Adding ports to a community, clearing ownership and rebooting them.

            _${clientCommunity} =  Set Variable  @{communityList}[0]_

            _${clientNetwork} =  Cget  object=${clientCommunity}  field=network_ 

            _${clientPortList} =  Cget  object=${clientNetwork}  field=portList_

    
            _: FOR    ${port}    IN    @{portList1}_

                _\    @{portData} =  Split String  ${port}  ._

                _\    ${port} =  Append Item  ${clientPortList}  chassisId=@{portData}[0]  cardId=@{portData}[1]  portId=@{portData}[2]_

                _\    ${result} =  Clear Ownership  ${port}  _

                _\    ${status} =  Get From Dictionary  ${result}  status_

                _\    ${error} =  Get From Dictionary  ${result}  error_

                _\    Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCES" _

                _\    ${result} =  Reboot  ${port}  _

                _\    ${status} =  Get From Dictionary  ${result}  status_

                _\    ${error} =  Get From Dictionary  ${result}  error_

                _\    Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCES"  _

        For more examples please consult `Samples`.

        '''
        return self._run_operation_keyword("clearOwnership", obj, kwargs)

    def refresh_connection(self, obj, **kwargs):
        '''Refresh the connection to a specified chassis.

        The Refresh Connection keyword receives as parameter the chassis to be refreshed.           

        The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 

        Example: Adding and refresing the connection to a new chassis.

            _${chassisChain} =  Get IxLoad Chassis Chain  session=${session}_

            _${chassisList} =  Cget  object=${chassisChain}  field=chassisList_

            _Clear List  ${chassisList}_
    
            _${chassis} =  Append Item  ${chassisList}  name=${chassisIp}_
    
            _${result} =  Refresh Connection  ${chassis}_
    
            _${status} =  Get From Dictionary  ${result}  status_

            _${error} =  Get From Dictionary  ${result}  error_

            _Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"_

        For more examples please consult `Samples`.
        '''
        return self._run_operation_keyword("refreshConnection", obj, kwargs)

    def set_cards_aggregation_mode(self, obj, **kwargs):
        '''Sets the specified aggregation mode on a list of cards.

        The Set Cards Aggregation Mode keyword receives as parameters the chassis chain object, the IP for the chassis on which the cards are located, a list of card ids (separated by commas) and the desired aggregation mode.
        
        In order to call this keyword, the chassis must already be added to the Chassis Chain and refreshed.

        Available options for the mode parameter are NA (Non Aggregated), 1G, 10G, 40G. 
        
        The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 
        
        Example: Changing aggregation mode on two cards from a chassis.

            _${chassisChain} =  Get IxLoad Chassis Chain  session=${session}_

            _${result} =  Set Cards Aggregation Mode  ${chassisChain}  chassisIp=10.200.105.22  cardIdList=1,2  mode=10G_
    
            _${status} =  Get From Dictionary  ${result}  status_

            _${error} =  Get From Dictionary  ${result}  error_

            _Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"_

        For more examples please consult `Samples`.
        '''
        return self._run_operation_keyword("setCardsAggregationMode", obj, kwargs)        
        
    def change_cards_interface_mode(self, obj, **kwargs):
        '''Sets the specified interface mode on a list of cards.

        The Change Cards Interface Mode keyword receives as parameters the chassis chain object, the IP for the chassis on which the cards are located, a list of card ids (separated by commas) and the desired interface mode.
        
        In order to call this keyword, the chassis must already be added to the Chassis Chain and refreshed.

        Available options for the mode parameter are 1G, 10G, 40G, 100G (depending on the card type). 
        
        The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 
        
        Example: Changing interface mode on two cards from a chassis.

            _${chassisChain} =  Get IxLoad Chassis Chain  session=${session}_

            _${result} =  Change Cards Interface Mode  ${chassisChain}  chassisIp=10.200.105.22  cardIdList=3,4  mode=40G_
    
            _${status} =  Get From Dictionary  ${result}  status_

            _${error} =  Get From Dictionary  ${result}  error_

            _Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"_

        For more examples please consult `Samples`.
        '''
        return self._run_operation_keyword("changeCardsInterfaceMode", obj, kwargs)    
        
    def load_test(self, obj, **kwargs):
        '''Load an IxLoad configuration file.

           The Load Test keyword receives as parameters the current IxLoad test object and the full path to the configuration file.

           The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 

           Example: 

                _${result} =  Load Test  ${test}  fullPath=C:/robot_framework/modified_config.rxf_

                _${status} =  Get From Dictionary  ${result}  status_

                _${error} =  Get From Dictionary  ${result}  error_

                _Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"_

           For more examples please consult `Samples`.
        '''
        return self._run_operation_keyword("loadTest", obj, kwargs)

    def apply_configuration(self, obj, **kwargs):
        '''Apply configuration on the current IxLoad test. The test will go to Configured state. This keyword is equivalent to the Apply Config button in the IxLoad UI.
        
           The Apply Configuration keyword receives as parameter the current IxLoad test object.

           The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 

           Example: 

                _${result} =  Apply Configuration  ${test}_

                _${status} =  Get From Dictionary  ${result}  status_

                _${error} =  Get From Dictionary  ${result}  error_

                _Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"_

           For more examples please consult `Samples`.

        '''
        return self._run_operation_keyword("applyConfiguration", obj, kwargs)


    def run_test(self, obj, **kwargs):
        '''Run the current IxLoad test. This keyword is equivalent to the Run test button from IxLoad UI.

           The Run Test keyword receives as parameter the current IxLoad test object.

           The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 

           Example: 

                _${result} =  Run Test  ${test}_

                _${status} =  Get From Dictionary  ${result}  status_

                _${error} =  Get From Dictionary  ${result}  error_

                _Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"_

           For more examples please consult `Samples`.

        '''
        return self._run_operation_keyword("runTest", obj, kwargs)

    def save_as(self, obj, **kwargs):
        '''Save the currently loaded configuration file as a new file.

           The Save As keyword receives as parameters the current IxLoad test object, the new file path and the overwrite option in case the file path already exists.

           The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 

           Example: 

                _Save As  ${test}  fullPath=C:/robot_framework/modified_config.rxf  overWrite=${TRUE}_

                _${status} =  Get From Dictionary  ${result}  status_

                _${error} =  Get From Dictionary  ${result}  error_

                _Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"  _

           For more examples please consult `Samples`.

        '''
        return self._run_operation_keyword("saveAs", obj, kwargs)

    def abort_test(self, obj, **kwargs):
        '''Stop the currently running test and release configuration. 

           The Abort Test keyword receives as parameter the current IxLoad test object.

           The keyword execution will return a result dictionary which contains the status of the execution. If the status has a value different than 1 the execution has failed and from the result dictionary the error can be retrieved. 

           Example: 

                _${result} =  Abort Test  ${test}_

                _${status} =  Get From Dictionary  ${result}  status_

                _${error} =  Get From Dictionary  ${result}  error_

                _Run Keyword If  '${status}' != '1'  FAIL  ${error}  ELSE  Log  "Status is SUCCESS"_

           For more examples please consult `Samples`.
        '''
        return self._run_operation_keyword("abortAndReleaseConfigWaitFinish", obj, kwargs)