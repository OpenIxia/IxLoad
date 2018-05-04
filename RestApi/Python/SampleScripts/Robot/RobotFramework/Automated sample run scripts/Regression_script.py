import subprocess
import time
import os
import sys

def generateFile(clientIp, chassisIp, ixLoad_Version, path_IxLoad_version, rxf_full_path, rxf_full_path2, path_save_file, LIST__port_List1, LIST__port_List2, LIST__port_List3, LIST__port_List4):
	f = open("variables.py", "wt")

	f.write("clientIp = \"%s\"\n" % (clientIp))
	f.write("chassisIp = \"%s\"\n" % (chassisIp))
	f.write("ixLoad_Version = \"%s\"\n" % (ixLoad_Version))
	f.write("path_IxLoad_version = \"%s\"\n" % (path_IxLoad_version))
	f.write("rxf_full_path = \"%s\"\n" % (rxf_full_path))
	f.write("rxf_full_path2 = \"%s\"\n" % (rxf_full_path))
	f.write("path_save_file = \"%s\"\n" % (path_save_file))
	f.write("LIST__port_List1 = %s\n" % (LIST__port_List1))
	f.write("LIST__port_List2 = %s\n" % (LIST__port_List2))
	f.write("LIST__port_List3 = %s\n" % (LIST__port_List3))
	f.write("LIST__port_List4 = %s\n" % (LIST__port_List4))
	f.close()

######################################	
#####	HTTP_new_config.robot	######	
######################################	
if __name__ == "__main__":

	clientIp = "127.0.0.1"### the IP of the machine where the IxLoad client is installed
	chassisIp = "10.215.123.50"
	ixLoad_Version = "8.30.115.36"
	path_IxLoad_version =  "C:/Program Files (x86)/Ixia/IxLoad/8.30.115.36-EB/"
	#path_IxLoad_version =  "/opt/ixia/ixload/8.30.115.36"  # the path on Linux machines
	rxf_full_path =  "C:/Program Files (x86)/Ixia/IxLoad/8.20.115.124-EB/RobotFramework/DNS.rxf"
	rxf_full_path2 =  "C:/Program Files (x86)/Ixia/IxLoad/8.20.115.124-EB/RobotFramework/FTP.rxf"
	path_save_file =  "C:/Program Files (x86)/Ixia/IxLoad/8.20.115.124-EB/RobotFramework/SAVED/HTTP_new_config.rxf"
	LIST__port_List1 = ['1.2.1']
	LIST__port_List2 = ['1.2.2']
	LIST__port_List3 = ['1.2.3']
	LIST__port_List4 = ['1.2.4']

	generateFile(clientIp, chassisIp, ixLoad_Version, path_IxLoad_version, rxf_full_path, rxf_full_path2, path_save_file, LIST__port_List1, LIST__port_List2, LIST__port_List3, LIST__port_List4)
	isWindows = sys.platform[0:3] == "win"
	if not isWindows:
		pathToRobotFwFolder = os.getcwd()
		pPath = os.environ.get("PYTHONPATH")
		if not pathToRobotFwFolder in str(pPath):
			os.environ["PYTHONPATH"] = "%s:%s" % (pPath, pathToRobotFwFolder)

	scriptName = "HTTP_new_config.robot"
	commandString = "pybot %s" % (scriptName)
	if isWindows:
		process = subprocess.Popen(commandString, shell=True, creationflags=subprocess.CREATE_NEW_PROCESS_GROUP)
	else:
		process = subprocess.Popen(commandString, shell=True)
	process.communicate()
	
	

	
		