
<#*************************************************************************
 MICROSOFT LEGAL STATEMENT

 The information in this script is provided "AS IS" with no
 warranties, confers no rights, and is not supported by 
 the authors or Microsoft Corporation.
 **************************************************************************  
 
 ***** Script Header *****

 Solution: Custom script to report the installed Intergratrion Services 

 File:     Check_installed_IS.ps1

 Purpose:  The purpose of this script is to automate the process of 
           collecting the IS version available on the host and installed
           on the VMs, within a cluster.

 Version:  1.0

 Version History:
 v1.0   -  21/01/2015   -   Initial Script created

 
**************************************************************************  
#>

$a = "<style>"
$a = $a + "BODY{background-color:white;Font-family:Calibri;Font-size:10pt}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;font-size:10pt}"
$a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:Lightgrey}"
$a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:white}"
$a = $a + "</style>"

$HTMOutput = Read-Host "Enter the file and path for the output file (example C:\Temp\Output.htm)"

$Cluster = Read-Host "Enter Cluster Name"

Add-Content $HTMOutput " <font face='Calibri' color='BLUE' size=4pt> Cluster Name: $Cluster <br></Font>"

Foreach ($VMHost in Get-ClusterNode -Cluster $Cluster){
            $HostISVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\GuestInstaller\Version" | select -ExpandProperty Microsoft-Hyper-V-Guest-Installer
 Add-Content $HTMOutput "<p>==============================================================================<br>"
 Add-Content $HTMOutput "<font face='Calibri' color='BLUE' size=3pt> Host Name: $VMHost<br></font>"
 Add-Content $HTMOutput "<font face='Calibri' color='BLUE' size=3pt>Integration Services (IS) Available: $HostISVersion<br></font>"

ForEach ($VM in Get-VM -ComputerName $VMHost){

$VMName = $VM.Name
$VMIS = $VM.IntegrationServicesVersion

If($VMIS -eq $HostISVersion){

 Add-Content $HTMOutput  "<font face='Calibri' color='GREEN' size=2pt>The IS component version on $VMName is $VMIS <br></font>" 
 }
 If($VMIS -notmatch $HostISVersion){

 Add-Content $HTMOutput  "<font face='Calibri' color='RED' size=2pt>The IS component version on $VMName is $VMIS<br></font>" 
 }
            }

 }
 Add-Content $HTMOutput "<br>=====================================v1.0=====================================<p>"