import sys
import inspect, os
import time
from CustomThread import *
import Utils.IxLoadUtils as IxLoadUtils
import Utils.IxRestUtils as IxRestUtils


class MyTest(object):
    def __init__(self):
        self.StartedLogs = False
        self.StopLogs = False
        self.k_gateway_server = "127.0.0.1"                                     # TODO - to be changed by user
        self.k_gateway_port = 8443
        self.k_ixload_version = "8.50.115.144"                                  # TODO - to be changed by user
        self.results_path = r"C:\\Path\\to\\Results\\Folder"                    # TODO - to be changed by user
        self.zip_file = '/'.join([self.results_path, "diagnostics.zip"])        # TODO - to be changed by user
        self.zip_gateway_file = '/'.join([self.results_path, "gatewayDiag.zip"])# TODO - to be changed by user
        self.rxf = r"C:\\Path\\to\\config.rxf"                                  # TODO - to be changed by user
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
        except Exception as e:
            IxLoadUtils.log("The pollLog exited with the following error: %s" % e)

    # ----------------------------------------------------------------------------------------------------------------------
    # TEST CONFIG
    # ----------------------------------------------------------------------------------------------------------------------
    def config_test(self, build_version, rxf_name, csv_path, zip_file, gateway_file):

        location=inspect.getfile(inspect.currentframe())
        kStatsToDisplayDict =   {
                            #format: { statSource : [stat name list] }
                            "HTTPClient": ["HTTP Simulated Users"],
                            "HTTPServer": ["HTTP Requests Received"]
                        }
        self.k_rxf_path = rxf_name

        # Create a connection to the gateway
        self.connection = IxRestUtils.getConnection(self.k_gateway_server, self.k_gateway_port)

        # Create a session
        IxLoadUtils.log("Creating a new session...")
        self.session_url = IxLoadUtils.createNewSession(self.connection, self.k_ixload_version)
        IxLoadUtils.log("Session created.")

        try:
            # Upload file to gateway server
            kRxfRelativeUploadPath = os.path.split(self.k_rxf_path)[1]
            kRxfAbsoluteUploadPath = self.k_rxf_path
            if self.k_gateway_server not in ["127.0.0.1", "localhost", "::1"]:
                IxLoadUtils.log('Uploading file %s...' % self.k_rxf_path)
                kResourcesUrl = IxLoadUtils.getResourcesUrl(self.connection)
                IxLoadUtils.uploadFile(self.connection, kResourcesUrl, self.k_rxf_path, kRxfRelativeUploadPath)
                IxLoadUtils.log('Upload file finished.')
                kRxfAbsoluteUploadPath = '/'.join([IxLoadUtils.getSharedFolder(self.connection), kRxfRelativeUploadPath])

            # Load a repository
            IxLoadUtils.log("Loading repository %s..." % kRxfAbsoluteUploadPath)
            IxLoadUtils.loadRepository(self.connection, self.session_url, kRxfAbsoluteUploadPath)
            IxLoadUtils.log("Repository loaded.")

            # Modify CSVs results path
            IxLoadUtils.log("Perform CSVs results path modification.")
            IxLoadUtils.changeRunResultDir(self.connection,self.session_url, csv_path)

            IxLoadUtils.log("Refresh all chassis...")
            IxLoadUtils.refreshAllChassis(self.connection, self.session_url)
            IxLoadUtils.log("All chassis refreshed...")

            # Enable Capture on assigned ports
            IxLoadUtils.enableAnalyzerOnAssignedPorts(self.connection, self.session_url)

            # Save repository
            result = time.localtime()
            kRxfName = kRxfRelativeUploadPath.split(".")[0] + "%s-%s-%s-%s:%s" % (result.tm_mday, result.tm_mon, result.tm_year, result.tm_hour, result.tm_min) + '.rxf'
            IxLoadUtils.log("Saving repository %s..." % (kRxfName))
            IxLoadUtils.saveRxf(self.connection, self.session_url, kRxfName)
            IxLoadUtils.log("Repository saved.")

            self.StartedLogs = True

            # Start test
            IxLoadUtils.log("Starting the test...")
            IxLoadUtils.runTest(self.connection, self.session_url)
            IxLoadUtils.log("Test started.")

            IxLoadUtils.log("Polling values for stats %s..." % (kStatsToDisplayDict))
            IxLoadUtils.pollStats(self.connection, self.session_url, kStatsToDisplayDict)

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

            IxLoadUtils.log("Retrieving capture for assisgned ports..." )
            IxLoadUtils.retrieveCaptureFileForAssignedPorts(self.connection, self.session_url, os.path.dirname(self.rxf))

            time.sleep(1)
            self.StopLogs = True

            # Collect Diagnostics
            if self.diag:
                IxLoadUtils.log("Collecting diagnostics...")
                IxLoadUtils.collectDiagnostics(self.connection, self.session_url, zip_file)
                IxLoadUtils.collectGatewayDiagnostics(self.connection, gateway_file)
                IxLoadUtils.log("Collecting diagnostics operation is successful...")

        finally:
            self.StopLogs = True
            self.StartedLogs = True
            IxLoadUtils.log("Closing IxLoad session...")

            if self.connection is not None and self.session_url is not None:
                IxLoadUtils.deleteSession(self.connection, self.session_url)
            IxLoadUtils.log("IxLoad session closed.")

    def run_IxLoad(self):

        self.zip_file = self.zip_file.replace("\\", "\\\\")
        self.zip_gateway_file = self.zip_gateway_file.replace("\\", "\\\\")
        self.config_test(str(self.k_ixload_version), str(self.rxf), str(self.results_path), str(self.zip_file), str(self.zip_gateway_file))

test1 = MyTest()
# t1 = CustomThread(test1.run_IxLoad)
# t2 = CustomThread(test1.pollLog)

test1.run_IxLoad()
test1.pollLog()
# t1.start()
# t2.start()

# t1.join()
# t2.join()

IxLoadUtils.log("Test ended with status: %s" % test1.test_run_error)

if test1.error:
    exit(1)
else:
    exit(0)
