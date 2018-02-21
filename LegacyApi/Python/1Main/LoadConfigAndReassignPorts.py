#!/usr/local/python2.7.14/bin/python2.7

# By Hubert Gee
#
# Description
#
#    This script will load a saved IxLoad config file stored in the
#    Windows Client PC.
# 
#    You could also reassign ports so you could use this config file
#    on any testbed or device.  Making your config file dynamic.
#    If you do not wish to reassign ports, comment out the variable:
#    $portsToReassign
#
#    Runs traffic and show real time stats.
#
#    While traffic is running, all stats are saved in a CSV format file locally
#    into a file name that you could name by using the variable: $csvFilePathAndName
#
# ABORT TEST at run time:
#  
#    This script allows you to press the <enter> key to abort a running test.
#    But you must have the Tkinter module installed in your Python.
#    Set the first variable enableAbortTest = True if you satisfied the above
#    requirements. Otherwise, set to False or else the script will error out.
#
# Optionally:
#   
#    Email the PDF report to user.
#    This script uses the Linux sendmail command to send emails.
#    To verify if sendmail works on your Linux, send an email to yourself with the below command:
#       echo "Subject: Sendmail Test" | sendmail -v you@domain.com
#
# Notes:
#
#   In order for this script to save the stats to a csv format file on your local
#   Linux machine, you have to go to the IxLoad GUI, under File/Preferences/Statistics, 
#   enabled "CSV Logging".
#   Enable CSV Logging and select the throughput type: kbps, mbps, gbps or bytes
#
#   All Statistics results are saved in the Windows PC C: drive under the variable
#   name $resultsOnWindows.  This is a value that you could define.
#
#   To get all the statistics that you want, you have to configure everything on IxLoad,
#   run traffic and ensure the configuration and traffic runs fine, then do a Scriptgen
#   to generate a script.  Open the script and scroll near the bottom and copy and paste
#   the stats that you want to the variable name HTTP_Client_StatList and HTTP_Server_StatList.
#   You can change the variable names.
#
#   Also, after the GUI test, go to the $resultsOnWindows directory to view the csv files to
#   get for statsToGet variable. At the end of the test, there are some code logics to 
#   retrieve the csv stat files.
#

# Change the value to True if you want to be able
# to press the <enter> key to abort the running test AND if 
# you have Tkinter module installed for Python 
enableAbortTest = False

import sys
from IxLoad import IxLoad, StatCollectorUtils

if enableAbortTest == True:
    import Tkinter
    # This Tkinter module is only needed if you want to be able
    # to abort the running test.
    # The followings allows users to press the <enter> key
    # to abort the running test.  But not everybody has Tkinter installed.
    if enableAbortTest == True:
        tclEval = Tkinter.Tcl()

remote_server = '192.168.70.3'

# For Python, the whacks are forward slashes.
configFile = 'C:/Users/hgee/Dropbox/MyIxiaWork/IxLoad/IxL_Http_Ipv4.rxf'
configFile = 'C:/Results/IxL_Http_Ipv4Ftp_vm_8.20.rxf'

# Where do you want IxLoad to store your csv statistic results
resultsOnWindows = 'C:/Results'

# Set the path and the PDF file name to copy from Windows to Linux at the end of the test.
pdfPathOnWindows = resultsOnWindows+'/IxLoad Summary Report.pdf'
generatePdfResult = True
pdfDestinationPathAndFilename = './IxLoadPdfResult.pdf'

# Creating a local csv file with all of your runtime stats
csvFilePathAndName = 'IxL_statResults.csv'

# Uncomment this if you want to reassign ports:
portsToReassign = [['192.168.70.11', 1, 1], ['192.168.70.11', 2, 1]]

#--------------- Email 
emailSubject = 'IxLoad Test is done'
emailFrom = 'IxLoad script'
sendEmailFrom = 'IxLoad@test.com' ;# Could be anything .com
sendEmailTo = 'hubert.gee@keysight.com'
sendEmail = False

# These .csv files are stats results stored on your Windows client PC.
# You could retreive them after the test. Leave an empty tuple list
# if you don't want to retrieve any.
#
# Note:  For Python, no backslash is required for 
#        filenames with spaces in between. 
statsToGet = (
	'HTTP Client - Per URL.csv',
	'HTTP_Server.csv'
	)

# These are stats that you want to view at runtime and collect.
httpClientStats = [ [ "HTTP Client", "TCP Connections Established", "kSum" ], 
		      [ "HTTP Client", "TCP Connection Requests Failed", "kSum" ] , 
		      [ "HTTP Client", "HTTP Simulated Users", "kSum" ],
		      [ "HTTP Client", "HTTP Concurrent Connections", "kSum" ],
		      [ "HTTP Client", "HTTP Connections", "kSum" ],
		      [ "HTTP Client", "HTTP Transactions", "kSum" ],
		      [ "HTTP Client", "HTTP Connection Attempts", "kSum" ]
		      ]

httpServerStats = [ [ "HTTP Server", "TCP Connections Established", "kSum" ],
		      [ "HTTP Server", "TCP Connection Requests Failed", "kSum" ]
		      ]

statList = httpClientStats + httpServerStats

# -----------------------------------------------------
#  Methods for enableAbortTest:  For Tkinter installs only

def TclEval(tclStatement):
    # wrapper function for debugging, etc.
    return tclEval.eval(tclStatement)

def setTestControllerMonitorVar():
    print '\nTclEval: setTestControllerMonitor'
    TclEval("set ::ixTestControllerMonitor \"\"")

def waitForTestFinishAndAbortAtEnterKey(testController):
    print '\nTclEval: waitForTestFinishedAbortAtEntekey'
    TclEval("""\
        # configure stdin for polling                                                                                                      
        fconfigure stdin -blocking 0 -buffering none

        # wait for the first sample or test stop                                                                                           
        while {$::ixTestControllerMonitor == "" && [read stdin] == ""} {
            after 100 set wakeup 1                                                                                 
            vwait wakeup
        }

        if {$::ixTestControllerMonitor == ""} {
            %s stopRun
            vwait ::ixTestControllerMonitor
            puts $::ixTestControllerMonitor
        }
        """ % (testController._tclObj_))

#-------------------------------------------------------

def IxL_StatCollector( *args ):
    # This API will display user defined statList at real time.
    # The exact spelling and all the available stats are shown
    # by doing a scriptgen on the IxLoad GUI of your test configuration.
    # Copy and paste stats that you want and discard the rest.
    # 
    # Step 1 of 2: Create a statList variable with a list of stats:
    # statList = [
    #    ["HTTP Client", "TCP Connections Established", "kSum"],
    #    ["HTTP Client", "TCP Connection Requests Failed", "kSum"],
    #    ["HTTP Client", "HTTP Simulated Users", "kSum"],
    #    ["HTTP Client", "HTTP Concurrent Connections", "kSum"],
    #    ["HTTP Client", "HTTP Connections", "kSum"],
    #    ["HTTP Client", "HTTP Transactions", "kSum"] ,
    #    ["HTTP Client", "HTTP Connection Attempts", "kSum"] ,
    #    ["HTTP Server", "TCP Connections Established", "kSum"],
    #    ["HTTP Server", "TCP Connection Requests Failed", "kSum"]
    # ]
    # 
    # Step 2 of 2:
    #    Do a word search for NS.StartCollector and make it call this API:
    #        NS.StartCollector(IxL_StatCollector)
    # 
    # This API is called by NS.StartCollector and it passes
    # in the statList's stats:
    # ('statcollectorutils', 'timestamp 4000 stats {{kInt 0} {kInt 0} {kInt} {kInt} {kInt} {kInt}')

    import re
    match = re.search('{({.*})}', args[1])

    # '{kInt 0} {kInt 0} {kInt 1} {kInt 0} {kInt 0} {kInt 0} {kInt 4} {kInt 0} {kInt 0}'
    #stats = match.group(1)
    fix1 = re.sub('{', '(', match.group(1))
    fix2 = re.sub('}', ')', fix1)
    stats = re.sub('kInt ', 'kInt,', fix2)
    # stats: ['(kInt,0)', '(kInt,0)', '(kInt,11)', '(kInt,0)', '(kInt,0)', '(kInt,0)', '(kInt,34)']
    stats = stats.split(' ')
    timestamp = args[1].split(' ')[1]
    eachRowStatsForCsv = ''

    print '\n', '='*35
    print 'Incoming stats: Time interval:', timestamp
    print '='*35

    # { "HTTP Server" "TCP Connections Established" "kSum" }
    for index in range(0,len(stats)):
        # (kInt', '0) could just be (kInt) when stats aren't ready for display.
        if len(stats[index].split(',')) > 1:
            sourceType  = statList[index][0]
            statName    = statList[index][1]
            currentStatIndex = stats[index].split(',')[1] ;# (kInt', '0)
            statNumber = re.sub('\)', '', currentStatIndex)

            if sourceType!= '' or statName != '':
                print '%s:  %s: %s' % (sourceType, statName, statNumber)
                # Note: You could write code to record your own stats here

def ReassignPorts(test, repository, portsToReassign):
    print '\nReassignPorts:', test, repository
    chassisChain = repository.cget('chassisChain')
    chassisList = chassisChain.getChassisNames()
    communityTypes = ['clientCommunityList', 'serverCommunityList']
    startListIdx = -1
    endListIdx = -1
    portsToSet = []

    import string
    for communityType in communityTypes:
            print '\nfor: ', communityType

            #numCommunities = eval("{}{}{}{}{}()".format(test, '.', communityType, '.', 'indexCount'))
            #numCommunities = int(eval("{}.{}.indexCount()".format(test, communityType)))
            #numCommunities = "%(test)s.%(communityType)s.indexCount()" % locals())
            exec "numCommunities = test." + communityType + '.indexCount' + '()'
            print '\nnumCommunities 1:', numCommunities
            #numCommunities = test.clientCommunityList.indexCount()
            communityDestination = []
            currentSourceList = []

            for i in range(0, int(numCommunities)):
                    #networkObj = test.communityType+i.cget('network')
                    communityTypeConverted = communityType + '[' + str(i) + ']'
                    exec "networkObj = test." + communityTypeConverted + '.cget("network")'
                    currentSourceList.append(networkObj.cget('portList'))
                    sourceListNum = len(currentSourceList)
                    startListIdx = endListIdx + 1
                    endListIdx = (startListIdx + sourceListNum) - 1
                    #  partialDestinationList: {"10.219.117.101" 1 4}
                    partialDestinationList = portsToReassign[startListIdx:endListIdx+1]
                    formattedDestination = []

                    if len(partialDestinationList) == 0 and int(sourceListNum) != 0:
                            print '\nError: Unable to remap ports. Too few ports.\n'
                            ixLoad.delete(repository)
                            ixLoad.disconnect()				

                    for currentDestination in partialDestinationList:
                            currentDestinationChassis = currentDestination[0]
                            currentDestinationCard    = currentDestination[1]
                            currentDestinationPort    = currentDestination[2]
                            formattedDestination.append("%s;%s;%s" % (currentDestinationChassis, currentDestinationCard, currentDestinationPort))

                    communityDestination.append(formattedDestination)
            portsToSet.append(communityDestination[0])

    try:
            print '\nReassigning ports:', portsToSet
            test.setPorts(portsToSet)
    except:
            print '\Error: Could not remap port assignment for:', portsToSet
            ixLoad.delete(repository)
            ixLoad.disconnect()


def setResultsDir(resultsOnWindows):
    """
    If the folder doesn't exists on the Windows Client PC,
    IxLoad will automatically create it.
    """
    try:
            testController.setResultDir(resultsOnWindows)
    except:
            print '\nError creating results directory on Windows Client PC: ', resultsOnWindows
            print '\nActual error message: ', sys.exc_info()[0]
            sys.exit()

def loadConfigFile( configFile ):
    try:
            repository = ixLoad.new("ixRepository", name=configFile)
            return repository
    except:
            print '\nError: IxLoad config file not found: ', configFile
            sys.exit()

def generatePdfReport(testController, pdfPathOnWindows, testName):
    print 'Generating PDF result file ...'
    try:
        testController.generateReport(detailedReport=1, format="PDF", orientation="Portrait", outputFile=pdfPathOnWindows, testName=testName)
    except Exception as errMsg:
        print '\nError: Faild to generate PDF file: %s' % errMsg

def copyFileFromWindows(sourcePath, destPath):
    ixLoad.retrieveFileCopy(sourcePath, destPath)

def sendEmail(sendEmailTo, sendEmailFrom, fileAttachment=None):
    from email.mime.text import MIMEText
    from email.mime.multipart import MIMEMultipart
    from email.mime.application import MIMEApplication
    from subprocess import Popen, PIPE

    body = MIMEText('IxLoad test is complete.')
    msg = MIMEMultipart("alternative")
    msg["From"] = sendEmailFrom
    msg["To"] = sendEmailTo
    msg["Subject"] = emailSubject
    msg.attach(body)

    filename = fileAttachment.split('/')[-1]
    attachment = MIMEApplication(open(fileAttachment, 'rb').read())
    attachment.add_header('Content-Disposition', 'attachment', filename=filename)
    msg.attach(attachment)

    print '\nSending email notification...'
    try:
        # Python 2
        p = Popen(["sendmail", "-t"], stdin=PIPE)
    except:
        # Python 3
        p = Popen(["sendmail", "-t"], stdin=PIPE, universal_newlines=True)

    p.communicate(msg.as_string())

ixLoad = IxLoad()

try:
    ixLoad.connect(remote_server)
except:
    sys.exit('Failed to connect to: %s' % remote_server)

logTag = "IxLoad-api"
logName = "reprun"
logger  = ixLoad.new("ixLogger", logTag, 1)
logEngine = logger.getEngine()
logEngine.setLevels(ixLoad.ixLogger.kLevelDebug, ixLoad.ixLogger.kLevelInfo)
logEngine.setFile(logName, 2, 256, 1)

# Initialize stat collection utilities
statUtils = StatCollectorUtils()

testController = ixLoad.new("ixTestController", outputDir=1)
repository = loadConfigFile(configFile)
numTests = int(repository.testList.indexCount())

# Get the first test on the testList
test_name = repository.testList[0].cget("name")
test = repository.testList.getItem(test_name)

setResultsDir(resultsOnWindows)
testController.enableAutoGenerateReport(1)

test.config(
	statsRequired = 1,
	enableResetPorts = 1,
	csvInterval = 2,
	enableForceOwnership = True
	)

try:
    ReassignPorts(test, repository, portsToReassign)
except:
    pass

# -----------------------------------------------------------------------
# Set up stat Collection

test_server_handle = testController.getTestServerHandle()
statUtils.Initialize(test_server_handle)

# Clear any stats that may have been registered previously
statUtils.ClearStats()

count = 1
for stat in statList:
    statUtils.AddStat(caption           = "Watch_Stat_%d" % count,
                      statSourceType    = stat[0],
                      statName          = stat[1],
                      aggregationType   = stat[2],
                      filterList        = {})
    count += 1

statUtils.StartCollector(IxL_StatCollector)
# -----------------------------------------------------------------------

testControllerMonitor = ''

if enableAbortTest == False:
    testController.run(test)
    ixLoad.waitForTestFinish()
else:
    # The following 3 lines allow users to press the
    # <enter> key to abort the running test.
    setTestControllerMonitorVar()
    testController.run(test)
    testController.releaseConfigWaitFinish()
    waitForTestFinishAndAbortAtEnterKey(testController)

#testController.releaseConfigWaitFinish()

# Stop the collector (running in the tcl event loop)
statUtils.StopCollector()

if generatePdfResult:
    testName = repository.testList[0].cget('name')
    generatePdfReport(testController, pdfPathOnWindows, testName)
    copyFileFromWindows(pdfPathOnWindows, pdfDestinationPathAndFilename)
    
# Cleanup
testController.releaseConfigWaitFinish()

ixLoad.delete(test)
ixLoad.delete(testController)
ixLoad.delete(logger)
ixLoad.delete(logEngine)

print '\nRetrieving CSV stats from Windows Client PC ...'
for stat_file in statsToGet:
	enhancedStatFile = stat_file.replace('-', '')
	enhancedStatFile = enhancedStatFile.replace(' ', '_')
	enhancedStatFile = enhancedStatFile.replace('__', '_')

	print 'Getting csv stat file: %s' % (stat_file)
	ixLoad.retrieveFileCopy('%s/%s' % (resultsOnWindows, stat_file), 'ixLoad_%s' % enhancedStatFile)

if sendEmail:
    if generatePdfResult == False:
        pdfDestinationPathAndFilename = None
    sendEmail(sendEmailTo, sendEmailFrom, fileAttachment=pdfDestinationPathAndFilename)

ixLoad.disconnect()
