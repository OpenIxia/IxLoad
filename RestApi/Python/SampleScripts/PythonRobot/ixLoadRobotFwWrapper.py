import sys, os

import IxRestUtils as IxRestUtils
import IxLoadUtils as IxLoadUtils


class ixLoadRobotFwWrapper(object):

    kKeyWordDict = {
        "connect"                   : ["ipAddress", "port"],
        "create_session"            : ["ixLoadVersion"],
        "delete_session"            : ["session"],
        "get_ixload_test"           : ["session"],
        "get_ixload_chassis_chain"  : ["session"],
        "get_ixload_preferences"    : ["session"],
        "get_ixload_stats"          : ["session"],
    }

    kErrorCodes = [400,404,500]

    def __init__(self, ):
        self.connection = None

    def missingKeywordFunc(self, keyword, kwargs):
        raise Exception("Keyword %s does not exist." % (keyword))

    def checkRequestReply(self, keyword, kwargs, reply):

        if reply.status_code in ixLoadRobotFwWrapper.kErrorCodes:
            raise Exception("Error on executing Keyword '%s' with parameters '%s' : %s" % (keyword, kwargs, reply.text))

    @staticmethod
    def processArguments(**kwargs):
        params = {}

        for key, value in kwargs.items():
            try:
                if type(key) == unicode:
                    key = str(key)
                if type(value) == unicode:
                    value = str(value)
            except:
                pass
            
            params[key] = value

        return params

    def connect(self, ipAddress=None, port=None):
        self.connection = IxRestUtils.getConnection(ipAddress, port)

    def create_session(self, ixLoadVersion=None):
        sessionId = IxLoadUtils.performGenericPost(self.connection, "sessions", {"ixLoadVersion":ixLoadVersion})

        sessionsUrl = "sessions"
        newSessionUrl = "%s/%s" % (sessionsUrl, sessionId)

        return self.connection.httpGet(newSessionUrl, errorCodes=ixLoadRobotFwWrapper.kErrorCodes)

    def delete_session(self, session=None):
        return self.connection.httpDelete(session._url_)

    def get_ixload_test(self, session=None):
        testUrl = "%s/ixload/test" % (session._url_)
        return self.connection.httpGet(testUrl, errorCodes=ixLoadRobotFwWrapper.kErrorCodes)
        

    def get_ixload_preferences(self, session=None):
        preferencesUrl = "%s/ixload/preferences" % (session._url_)
        return self.connection.httpGet(preferencesUrl, errorCodes=ixLoadRobotFwWrapper.kErrorCodes)

    def get_ixload_stats(self, session=None):
        statsUrl = "%s/ixload/stats" % (session._url_)
        return self.connection.httpGet(statsUrl, errorCodes=ixLoadRobotFwWrapper.kErrorCodes)

    def get_stat_value(self, object=None, statSource=None, statName=None, timeStamp=None):
        statSourceObj = self.cget(object, statSource)
        statValuesObj = self.cget(statSourceObj, "values")
        availableTimeStamps = [ts for ts in statValuesObj.jsonOptions.keys() if ts != "_url_"]

        if str(timeStamp).lower() == "latest":
            intList = [int(ts) for ts in availableTimeStamps]
            timeStamp = str(max(intList)) # get the biggest timestamp
        elif not timeStamp in availableTimeStamps:
            raise Exception("Provided timeStamp '%s' is not in the available timeStamps : %s" % (timeStamp, availableTimeStamps))

        timeStampObj  = self.cget(statValuesObj, timeStamp)

        statValue = self.cget(timeStampObj, statName)

        return statValue

    def set_result_directory(self, test=None, path=None):
        parameters = {}
        parameters["_object_"] = test
        parameters["outputDir"] = True
        parameters["runResultDirFull"] = path
        self.config(**parameters)
        
    ### Chassis Chain Helper Keywords
    def get_ixload_chassis_chain(self, session=None):
        chassisChainUrl = "%s/ixload/chassischain" % (session._url_)
        return self.connection.httpGet(chassisChainUrl, errorCodes=ixLoadRobotFwWrapper.kErrorCodes)
    
    def clear_chassis_list(self, session=None):
        chassisChain = self.get_ixload_chassis_chain(session)
        chassisList = self.cget(object=chassisChain, field="chassisList")
        self.clearList(_object_=chassisList)
        
    def add_chassis(self, session=None, name=None):
        chassisChain = self.get_ixload_chassis_chain(session)
        chassisList = self.cget(object=chassisChain, field="chassisList")
        kwargs = {}
        kwargs['_object_'] = chassisList
        kwargs['name']     = name
        chassisObj = self.appendItem(**kwargs)
        return self.runOperation("refreshConnection", chassisObj)
        
    ### End Chassis Chain Helper Keywords    
    
    ### Community Helper Keywords
    def get_community_by_name(self, test=None, communityName=None):
        activeTest      = self.cget(object=test, field="activeTest")
        communityList   = self.cget(object=activeTest, field="communityList")
        
        for community in communityList:
            if community.name == communityName:
                return community
                
        raise Exception("Community with name '%s' was not found. Existing communities are : %s" % (communityName, [comm.name for comm in communtyList]))
        
    def add_community(self, **kwargs):
        if not '_object_' in kwargs:
            raise Exception("No test provided to Add Community keyword")
        
        test = kwargs['_object_']
        del kwargs['_object_']
        
        activeTest      = self.cget(object=test, field="activeTest")
        communityList   = self.cget(object=activeTest, field="communityList")
        
        kwargs['_object_'] = communityList
        return self.appendItem(**kwargs)
        
    def add_activity(self, community=None, protocolAndType=None):
        activityList    = self.cget(object=community, field="activityList")
        kwargs = {}
        kwargs['_object_']          = activityList
        kwargs['protocolAndType']   = protocolAndType
        
        return self.appendItem(**kwargs)
       
    def assign_ports_to_community(self, community=None, portList=None):
        network     = self.cget(object=community, field="network")
        portObjList    = self.cget(object=network, field="portList")
        
        for port in portList:
            elements = port.split(".")
            
            kwargs = {}
            kwargs['chassisId']   = elements[0]
            kwargs['cardId']      = elements[1]
            kwargs['portId']      = elements[2]
            kwargs['_object_']    = portObjList
            self.appendItem(**kwargs)
            

    ### End Community Helper Keywords 
        
    def cget(self, object=None, field=None, filter=None):
        try:
            if field in object.jsonOptions and filter is None:
                return object.jsonOptions.get(field)
            else:
                url = "%s/%s" % (object._url_, field)

                if filter is not None:
                    url = "%s?filter=%s" % (url, filter)

                return self.connection.httpGet(url, errorCodes=ixLoadRobotFwWrapper.kErrorCodes)
        except Exception:
            raise Exception("Error on executing Keyword 'Cget': Failed to get field '%s' on object %s. Object fields : %s" %(field, object, object.jsonOptions))

    def config(self, **kwargs):
        if not '_object_' in kwargs:
            raise Exception("No object provided to Config keyword")

        object = kwargs['_object_']
        del kwargs['_object_']

        url = object._url_

        reply = self.connection.httpPatch(url, kwargs)
        self.checkRequestReply("Config", kwargs, reply)

        self.connection.refreshData(object)

    def clearList(self, **kwargs):
        if not '_object_' in kwargs:
            raise Exception("No object provided to Clear List keyword")

        object = kwargs['_object_']
        del kwargs['_object_']

        if not object.isContainerObject():
            raise Exception("Clear List keyword can only be executed on lists.")

        reply = self.connection.httpDelete(object._url_)

        self.checkRequestReply("Clear List", kwargs, reply)
        self.connection.refreshData(object)

    def appendItem(self, **kwargs):
        if not '_object_' in kwargs:
            raise Exception("No object provided to Append Item keyword")

        object = kwargs['_object_']
        del kwargs['_object_']

        if not object.isContainerObject():
            raise Exception("Append Item keyword can only be executed on lists.")

        reply = self.connection.httpPost(object._url_, kwargs)
        self.checkRequestReply("Append Item", kwargs, reply)

        newObjLocation = reply.headers.get("Location")
        newObjLocation = IxLoadUtils.stripApiAndVersionFromURL(newObjLocation)

        self.connection.refreshData(object)

        return self.connection.httpGet(newObjLocation, errorCodes=ixLoadRobotFwWrapper.kErrorCodes)

    def deleteItem(self, **kwargs):
        if '_object_' not in kwargs:
            raise Exception("No object provided to Delete Item keyword")

        reply = self.connection.httpDelete(kwargs['_object_']._url_)
        self.checkRequestReply("Delete Item", kwargs, reply)

    def runKeyword(self, keyword, **kwargs):
        params = ixLoadRobotFwWrapper.processArguments(**kwargs)
        requiredParameters = ixLoadRobotFwWrapper.kKeyWordDict.get(keyword, [])

        missingParameters = []
        [missingParameters.append(parameter) for parameter in requiredParameters if not parameter in params]
        if len(missingParameters) > 0:
            raise Exception("The following required parameters were not sent for keyword %s : %s" % (keyword, missingParameters))

        if keyword != "connect" and self.connection is None:
            raise Exception("Please set up a connection to the desired username and port before running any other keyword.")

        return getattr(self, keyword, self.missingKeywordFunc)(**params)

    def runOperation(self, operation, object, **kwargs):
        result = {}
        status = 1
        error = None

        try:
            params = ixLoadRobotFwWrapper.processArguments(**kwargs)

            if not object._url_:
                raise Exception("Could not find URL in object %s" % (object))

            ###### validate that the provided operation is valid for the object

            operationsUrl = "%s/operations" % (object._url_)
            availableOperationsObj = self.connection.httpGet(operationsUrl, errorCodes=ixLoadRobotFwWrapper.kErrorCodes)
            availableOperationsDict = ixLoadRobotFwWrapper.processArguments(**availableOperationsObj.jsonOptions)

            if '_url_' in availableOperationsDict:
                del availableOperationsDict['_url_']

            if operation not in availableOperationsDict:
                raise Exception("Provided operation %s is not valid for object %s" % (operation, object))
            ######

            ######
            operationUrl = "%s/%s" % (operationsUrl, operation)

            IxLoadUtils.performGenericOperation(self.connection, operationUrl, params)

        except Exception as ex:
            status = 0
            error = str(ex)
        finally:
            result['status'] = status
            result['error'] = error

            return result
