import sys
import inspect, os
import _winreg
import time
from CustomThread import *
import Utils.IxLoadUtils as IxLoadUtils
import Utils.IxRestUtils as IxRestUtils



class MyTest(object):
    def __init__(self):
        self.StartedLogs = False
        self.StopLogs = False
        self.k_gateway_server = "127.0.0.1"
        self.k_gateway_port = 8443
        self.k_ixload_version = "8.10.30.44" #TODO - to be changed by user
        self.results_path = r"C:\\User\\ixia\Desktop" #TODO - to be changed by user
        self.zip_file = os.path.join(self.results_path, "diagnostics.zip") #TODO - to be changed by user
        self.rxf = r"C:\\User\\ixia\\Desktop\\Test.rxf"  #TODO - to be changed by user
        self.diag = True
        self.connection = None
        self.session_url = None
        self.error = False
        self.test_run_error = False

    def pollLog(self, file="IxLoadLog.log", pollingInterval=0.1):
        IxLoadUtils.log("Creating the log file.")
        sleepTime = 0
        lastID = 0

        while not self.StartedLogs:
            time.sleep(1)
            sleepTime += 1
            if sleepTime > 600:
                break

        IxLoadUtils.log("Start logging.")

        try:
            while not self.StopLogs:
                logWebObject = self.connection.httpGet("%s/ixload/test/logs" % self.session_url)
                if logWebObject is None:
                    time.sleep(0.5)
                    continue
                if not any(logWebObject):
                    time.sleep(0.5)
                    continue

                with open(file, 'a+') as f:
                    time.sleep(pollingInterval)
                    f.write("".join([str(logWebObject[i].objectID) + " *" + str(logWebObject[i].severity) + " " + str(logWebObject[i].timeStamp)+ " : " + str(logWebObject[i].message) + "\n" for i in range(0, len(logWebObject)) if int(logWebObject[i].objectID) > lastID]))
                    log = ["IxLoad Log: " + str(logWebObject[i].objectID) + " *" + str(logWebObject[i].severity) + " " + str(logWebObject[i].timeStamp)+ " : " + str(logWebObject[i].message) for i in range(0, len(logWebObject)) if int(logWebObject[i].objectID) > lastID]
                    if log is not "":
                        for l in log:
                            IxLoadUtils.log(l)
                    lastID = int(logWebObject[len(logWebObject) - 1].objectID)

                    if lastID < 0:
                        time.sleep(0.1)
                        continue

        except AttributeError:
            IxLoadUtils.log("Attribute error detected!")
        except Exception, e:
            IxLoadUtils.log("The pollLog exited with the following error: %s" % e)

    # ----------------------------------------------------------------------------------------------------------------------
    # TEST CONFIG
    # ----------------------------------------------------------------------------------------------------------------------
    def config_test(self, build_version, rxf_name, csv_path, zip_file):
        self.k_rxf_path = rxf_name

        # Create a connection to the gateway
        self.connection = IxRestUtils.getConnection(self.k_gateway_server, self.k_gateway_port)

        # Create a session
        IxLoadUtils.log("Creating a new session...")
        self.session_url = IxLoadUtils.createSession(self.connection, self.k_ixload_version)
        IxLoadUtils.log("Session created.")

        try:
            # Load a repository
            IxLoadUtils.log("Loading repository %s..." % self.k_rxf_path)
            IxLoadUtils.loadRepository(self.connection, self.session_url, self.k_rxf_path)
            IxLoadUtils.log("Repository loaded.")

            # Modify CSVs results path
            load_test_url = "%s/ixload/test/" % self.session_url
            payloadDict = {"outputDir" : "true", "runResultDirFull" : csv_path}
            IxLoadUtils.log("Perform CSVs results path modification.")
            IxLoadUtils.performGenericPatch(self.connection, load_test_url, payloadDict)

            # Enable Capture on both ports
            communtiyListUrl = "%s/ixload/test/activeTest/communityList" % self.session_url
            communityList = self.connection.httpGet(url=communtiyListUrl)

            for community in communityList:
                portListUrl = "%s/%s/network/portList" % (communtiyListUrl, community.objectID)
                payloadDict = {"enableCapture" : "true"}
                IxLoadUtils.log("Perform enable capture on port : %s." % str(community.objectID))
                IxLoadUtils.performGenericPatch(self.connection, portListUrl, payloadDict)
                IxLoadUtils.log("Enabled capture on port : %s." % str(community.objectID))

            # Save repository
            IxLoadUtils.log("Saving repository %s..." % (rxf_name.split(".")[0]))
            IxLoadUtils.saveRxf(self.connection, self.session_url, rxf_name.split(".")[0]+"save")
            IxLoadUtils.log("Repository saved.")

            self.StartedLogs = True

            # Start test
            IxLoadUtils.log("Starting the test...")
            IxLoadUtils.runTest(self.connection, self.session_url)
            IxLoadUtils.log("Test started.")

            testIsRunning = True
            while testIsRunning:
                time.sleep(2)
                testIsRunning = IxLoadUtils.getTestCurrentState(self.connection, self.session_url) == "Running"

            # Test ended
            IxLoadUtils.log("Test finished.")

            # Get test error
            IxLoadUtils.log("Checking test status...")
            self.test_run_error = IxLoadUtils.getTestRunError(self.connection, self.session_url)

            if self.test_run_error:
                IxLoadUtils.log("The test exited with the following error: %s" % self.test_run_error)
                self.error = True
                self.diag = True
            else:
                IxLoadUtils.log("The test completed successfully.")
                self.error = False
                self.diag = False

            IxLoadUtils.log("Waiting for test to clean up and reach 'Unconfigured' state...")
            IxLoadUtils.waitForTestToReachUnconfiguredState(self.connection, self.session_url)
            IxLoadUtils.log("Test is back in 'Unconfigured' state.")

            time.sleep(1)
            self.StopLogs = True

            # Collect Diagnostics
            if self.diag:
                IxLoadUtils.log("Collecting diagnostics...")
                collectDiagnosticsUrl = "%s/ixload/test/activeTest/operations/collectDiagnostics" % (self.session_url)
                data = {"zipFileLocation": zip_file}
                IxLoadUtils.performGenericOperation(self.connection, collectDiagnosticsUrl, data)

        finally:
            self.StopLogs = True
            self.StartedLogs = True
            IxLoadUtils.log("Closing IxLoad session...")

            if self.connection is not None and self.session_url is not None:
                IxLoadUtils.deleteSession(self.connection, self.session_url)
            IxLoadUtils.log("IxLoad session closed.")

    def run_IxLoad(self):

        self.zip_file = self.zip_file.replace("\\", "\\\\")
        self.config_test(str(self.k_ixload_version), str(self.rxf), str(self.results_path), str(self.zip_file))


test1 = MyTest()
t1 = CustomThread(test1.run_IxLoad)
t2 = CustomThread(test1.pollLog)

t1.start()
t2.start()

t1.join()
t2.join()

IxLoadUtils.log("Test ended with status: %s" % test1.test_run_error)

if test1.error:
    exit(1)
else:
    exit(0)
