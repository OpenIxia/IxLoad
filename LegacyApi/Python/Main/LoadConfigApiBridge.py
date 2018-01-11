#!/opt/Python-2.7.6/bin/python2.7

# Description
# 
#     This Python file uses TKinter to interact with TCL APIs.
#     The TCL API file is LoadConfigApi.tcl.
#     This is the only file you should be modifying.
#     If there is any failure, the test will not run and the failed messages will be 
#     returned. 
#     If there is no failure, it will return "eventType TEST_STOPPED status OK"
#
# Written by: Hubert Gee
# July 26, 2016

import Tkinter

tcl = Tkinter.Tcl()

tcl.eval('package forget Tcl')
tcl.eval('package provide Tcl 8.5')
tcl.eval('package require Tcl')

tcl.eval('source LoadConfigApi.tcl')
tcl.eval('set windowsClientIp 10.219.117.103')
tcl.eval('set configFile c:\\\Results\\\IxL_Http_Ipv4.rxf')
tcl.eval('set resultDirectoryOnWindows c:\\\Results')
tcl.eval('set csvFilePathAndName IxL_statResults.csv')
tcl.eval('set localLinuxPath /ws/geraghav-sjc/Ixia/csvStatResults')

# The API library file looks for this variable "portsToReassign".
# If it exist, then it will use the port values. 
# Only include this line if you want to reassign ports so you could use this script on other testbeds.
#tcl.eval('set portsToReassign {{"10.219.117.101" 1 5} {"10.219.117.101" 1 6}}')

# These are the stats to show at real time.
tcl.eval('set statList { \
{"HTTP Client" "TCP Connections Established" "kSum"} \
{"HTTP Client" "TCP Connection Requests Failed" "kSum"} \
{"HTTP Client" "HTTP Simulated Users" "kSum"} \
{"HTTP Client" "HTTP Concurrent Connections" "kSum"} \
{"HTTP Client" "HTTP Connections" "kSum"} \
{"HTTP Client" "HTTP Transactions" "kSum"} \
{"HTTP Client" "HTTP Connection Attempts" "kSum"} \
{"HTTP Server" "TCP Connections Established" "kSum"} \
{"HTTP Server" "TCP Connection Requests Failed" "kSum"} \
}')

# This script already saves the stats in a csv file under the variable name
# $csvFilePathAndName.
# If you are still interested in downloading the CSV stat files from the Windows
# PC, you need to know the exact file names. Use backslashes to break the whitespaces.
tcl.eval('set statsFilesToGet { \
    "HTTP_Client.csv" \
    "HTTP\ Client\ -\ Per\ URL.csv" \
    "HTTP\ Server\ -\ Per\ URL.csv" \
}')

testResult = tcl.eval('IxL_Main')

print('\nTest Result: ', testResult)

    

