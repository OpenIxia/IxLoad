from __future__ import print_function

from future.utils import iteritems


class IxLoadTestSettings():

    ApiVersion = "v0"
    GatewayServer = "127.0.0.1"
    HttpRedirect = False
    GatewayPort = 8443
    ApiKey = ''
    IxLoadVersion = ""
    ChassisList = []
    PortListPerCommunity = {}
    AnalyzerTupleList = []

    def __init__(self, **kwargs):

        self.apiVersion = IxLoadTestSettings.ApiVersion
        self.gatewayServer = IxLoadTestSettings.GatewayServer
        self.gatewayPort = IxLoadTestSettings.GatewayPort
        self.httpRedirect = IxLoadTestSettings.HttpRedirect
        self.apiKey = IxLoadTestSettings.ApiKey
        self.ixLoadVersion = IxLoadTestSettings.IxLoadVersion
        self.chassisList = IxLoadTestSettings.ChassisList
        self.portListPerCommunity = IxLoadTestSettings.PortListPerCommunity
        self.analyzerTupleList = IxLoadTestSettings.AnalyzerTupleList
        for key, value in iteritems(kwargs):
            setattr(self, key, value)

        if self.httpRedirect is True:
            self.gatewayPort = 8080

    def isLocalHost(self):
        LocalHost = False
        if self.gatewayServer in ["127.0.0.1", "localhost", "::1"]:
            LocalHost = True

        return LocalHost
