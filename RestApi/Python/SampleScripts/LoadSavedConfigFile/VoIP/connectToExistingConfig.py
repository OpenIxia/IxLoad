"""
Description
   Connect to an existing session ID

"""

from IxL_RestApi import *

apiServerIp = '192.168.70.3'
apiServerIpPort = 8443 ;# https: Starting with version 8.50

if apiServerIpPort == 8443:
    useHttps = True
else:
    useHttps = False

localCrfFileToUpload = 'VoLTE_S1S11_1UE_2APNs_8.50.crf'
crfFileOnServer = 'c:\\VoIP\\VoLTE_S1S11_1UE_2APNs_8.50.crf'

restObj = Main(apiServerIp=apiServerIp, apiServerIpPort=apiServerIpPort, useHttps=useHttps)
restObj.connect(sessionId=7)
#restObj.setResultDir('c:\\VoIP')

restObj.uploadFile(localCrfFileToUpload, crfFileOnServer)
restObj.importCrfFile(crfFileOnServer)




