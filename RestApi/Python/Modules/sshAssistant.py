"""
By Hubert Gee

Description
   SSH to a device and enter commands.
   Supports SFTP to download files also.

Usage:
  sshClient = sshExecCommand.Connect(apiServerIp, username, password)
      
  # linux
     sshClient.transferFile('/mnt/ixload-share/http.rxf', '/home/hgee/http.rxf')
     stdout,stderr = sshClient.enterCommand('rm /mnt/ixload-share/http.rxf')
     stdout,stderr = sshClient.enterCommand('ls /mnt/ixload-share')

  # windows
     stdout,stderr = sshClient.enterCommand('dir c:\\Results')
     for line in stdout:
         print(line.replace('\r\n', ''))

     sshClient.enterCommand('copy c:\\Results\\file1.txt c:\\temp\\temp1\\file1.txt')
     sshClient.deleteFile('c:\\temp\\temp1\\file1.txt')
     sshClient.transferFile('c:\\Results\\file1.txt', '/home/hgee/file1.txt')

  sshClient.close()

Command line:
   Accepts password file containing the SSH password.
   You could also set the default password inside this file.

   sshExecCommand passwordFile.txt
"""

import paramiko, time, sys

class Connect:
    def __init__(self, host, username, password, pkeyFile=None, port=22, timeout=10):
        self.host = host
        self.username = username
        self.password = password
        self.pkey = None
        self.port = port
        self.timeout = timeout

        if pkeyFile:
            # Convert the pkey file into a string
            pkeyFileOpen = open(pkeyFile)
            pkeyContents = pkeyFileOpen.read()
            pkeyFileOpen.close()

            pkeyString = StringIO.StringIO(pkeyContents)
            self.pkey = paramiko.RSAKey.from_private_key(pkeyString)

        try:
            self.sshClient = paramiko.SSHClient()
            self.sshClient.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            self.sshClient.connect(hostname=self.host, username=self.username, password=self.password, port=self.port, pkey=self.pkey, timeout=self.timeout)
            print('\nSuccessfully SSH to {}'.format(host))
        except paramiko.SSHException:
            raise Exception('\nSSH Failed to connect: {}.format(host)')

        self.sftp = self.sshClient.open_sftp()
            
    def enterCommand(self, command, commandInput=None):
        stdin, stdout, stderr = self.sshClient.exec_command(command)
        while not stdout.channel.exit_status_ready() and not stdout.channel.recv_ready():
            time.sleep(1)

        stdoutString = stdout.readlines()
        stderrString = stderr.readlines()
        return stdoutString, stderrString

    def deleteFile(self, path):
        """
        Delete Windows files

        Parameter
           path: The full path + filename
        """
        self.sftp.remove(path)
   
    def transferFile(self, sourceFilePath, destFilePath):
        print('\nTransferring file from: {} to: {}'.format(sourceFilePath, destFilePath))
        ftpClient = self.sshClient.open_sftp()
        ftpClient.get(sourceFilePath, destFilePath)
        ftpClient.close()

    def downloadFile(self, remoteFile, localFile, directory=False):
        # Copy remoteFile to localFile. Overwriting or creating as needed.
        if directory == False:
            print('\nDownloading file from: {} to: {}'.format(remoteFile, localFile))
            self.sftp.get(remoteFile, localFile)

        if directory:
            self.sftp.chdir(os.path.split(remoteFile)[0])
            parent = os.path.split(remoteFile)[1]
            try:
                os.mkdir(localFile)
            except:
                pass
            
            for walker in self.sftp_walk(parent):
                try:
                    os.mkdir(os.path.join(localFile, walker[0]))
                except:
                    pass
                for file in walker[2]:
                    self.get(os.path.join(walker[0], file), os.path.join(localFile, walker[0], file))
                    
                             
        self.sftp.close()

    def uploadFile(self, localFile, remoteFile, directory=False):
        # Copy localFile to remoteFile. Overwriting or creating as needed.
        if directory == False:
            print('\nUploadinging file from: {} to: {}'.format(localFile, remoteFile))
            self.sftp.put(localFile, remoteFile)
            self.sftp.close()

        if directory:
            # recursively upload a full directory
            os.chdir(os.path.split(localFile)[0])
            parent = os.path.split(localFile)[1]
            for walker in os.walk(parent):
                try:
                    self.sftp.mkdir(os.path.join(remoteFile, walker[0]))
                except:
                    pass
                
                for file in walker[2]:
                    self.put(os.path.join(walker[0], file, os.path.join(remoteFile, walker[0], file)))

    def close(self):
        self.sftp.close()
        self.sshClient.close()

