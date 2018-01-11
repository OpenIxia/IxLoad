REM Runs most unit tests
REM Skips those that require special network setups (e.g. DHCP, PPPoE)
REM Protocols that are optionally installed are commented out
source ..\bin\ixiawish.tcl
echo Runall.bat > runall.out
pushd "Application Features"
rmdir /s /q RESULTS
REM ..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_Capture.tcl >> ..\runall.out 2<&1
REM ..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_CaptureManual.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_ActivityIpMapping.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_ConfigStopRun.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_CustomTrafficMap.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe FTP_MixedTrafficMaps.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe FTP_ModifyOnTheFly.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe SIP_RenamedObjective.tcl >> ..\runall.out 2<&1
popd
pushd Network
rmdir /s/q RESULTS
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_IPv6.tcl >> ..\runall.out 2<&1
REM ..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_IPSec.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_EmulatedRouter.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_VLAN_Impairment.tcl >> ..\runall.out 2<&1
popd
pushd Protocols
rmdir /s/q RESULTS
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe ApplicationTest.tcl >> ..\runall.out 2<&1
REM ..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe DDoS.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe DHCP.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe DNS.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe FTP.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe FTP_POP3.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_SSL.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe IMAP.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe LDAP.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe MGCP.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe MGCP_Signaling.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe MGCP_Signaling_RTP.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe POP3.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe QuickHTTP.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe QuickTCP.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe RTSP.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe SIP.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe SIP_DTMP >> ..\runall.out 2<&1
popd
pushd Stats
rmdir /s/q RESULTS
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_RepRun_Stats.tcl tclsimplehttp.rxf >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_PerInterfaceStats.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_PerUrlPerIpStats.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_StateStats.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe HTTP_StatFilter.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe SIP_PerStreamStats.tcl >> ..\runall.out 2<&1
..\..\..\..\..\Tcl\8.5.12.0\bin\tclsh.exe Video_PerStreamStats.tcl >> ..\runall.out 2<&1
popd
