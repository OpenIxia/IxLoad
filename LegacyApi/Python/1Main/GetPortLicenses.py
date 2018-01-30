# Description
#   SSH into the IxVM chassis and enter "show licenses --floatingstats".
#   Get the available port licenses for IxNetwork VE and IxLoad VE.
# 
# Usage:
#   python ./GetPortLicenses.py <IxVM Chassis IP> ixnetwork 
#   python ./GetPortLicenses.py <IxVM Chassis IP> ixload
#
# Return:
#   The remaining number of available ports license(s).
#
# Tested with IxVM 8.10.
# Date: 7/26/2016
# Written by: Hubert Gee


import pexpect
import sys
import time
import re

prompt = '#'
host = sys.argv[1]
username = 'admin'
password = 'admin'

if sys.argv[2] not in ['ixnetwork', 'ixload']:
    sys.exit('\nNo such platform: %s\nMust be either ixnetwork or ixload\n\n' % sys.argv[1])

def send(command):
    spawnId.sendline(command)
    spawnId.expect(prompt)
    return spawnId.before 

def ssh():
    global spawnId

    spawnId = pexpect.spawn('ssh %s@%s' % (username, host))
    spawnId.logfile = sys.stdout ;# Display the output at real time
    spawnId.timeout = 10
    spawnId.ignorecase = True

    expect = spawnId.expect(['Are you sure you want to continue connecting',
                             'password:',
                             pexpect.EOF])

    if expect == 0:
        spawnId.sendline('yes')
        expect = spawnId.expect(['Are you sure you want to continue connecting',
                                 'password:',
                                 prompt,
                                 pexpect.EOF])
    if expect == 1:
        spawnId.sendline(password)
        spawnId.expect([prompt, pexpect.EOF])
    elif expect == 2:
        # Got either key or connection timeout
        pass

    # Show the result
    # If connection failed, EOF will be captured and you get a message:
    # ssh: connect to host x.x.x.x port 22: No route to host
    if spawnId.before:
        print '\n SSH failed: ', spawnId.before, '\n'


ssh()
time.sleep(1)
output = send('show licenses --floatingstats')

if sys.argv[2] == 'ixnetwork':
    licenseNameToGet = 'VM-IXN-TIER3'
if sys.argv[2] == 'ixload':
    licenseNameToGet = 'VM-IXL-TIER3'

for line in output.split('\r\n'):
    match = re.match('^%s.*' % licenseNameToGet, line)
    if match:
        #print '\n\n\n%s\n\n: ' % line.split(' ')
        availablePorts = line.split(' ')[25]
        print '\nAvailable port:%s\n' % availablePorts
        break

spawnId.kill(0)
sys.exit(availablePorts)
