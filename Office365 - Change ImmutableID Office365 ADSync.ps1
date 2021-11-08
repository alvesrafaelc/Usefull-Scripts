###########################
# Autor: Rafael Alves     #
# alves.rafaelc@gmail.com #
###########################

#Allow Remote Scripts To Run 
Set-ExecutionPolicy RemoteSigned

#Store Office 365 Global Admin Creds and connect to MS online 
$credential = Get-Credential 
Import-Module MsOnline 
Connect-MsolService -Credential $credential

#Verify Active Directory Sync Has Been Disabled - Money Command will not run with it on 
$IsDirSyncEnabled = (Get-MsolCompanyInformation).DirectorySynchronizationEnabled 
If($IsDirSyncEnabled -eq $false) {Write-Host "Office 365 Active Directory Sync Disabled - Good to go!"} else {Write-Host "Please disable Active Directory Sync and Wait" Exit} 
Start-Sleep -Seconds 5

#If you want to dump your existing AD to text file for reference uncomment the next line 
#ldifde -f C:\export.txt -r "(Userprincipalname=*)" -l "objectGuid, userPrincipalName"

do{ 
# Query the local AD and get all the users output to grid for selection 
$ADGuidUser = Get-ADUser -Filter * | Select-Object Name,ObjectGUID | Sort-Object Name | Out-GridView -Title "Select Local AD User To Get Immutable ID for" -PassThru 
#Convert the GUID to the Immutable ID format 
$UserimmutableID = [System.Convert]::ToBase64String($ADGuidUser.ObjectGUID.tobytearray())

# Query the existing users on Office 365 and output to grid for selection 
$OnlineUser = Get-MsolUser | Select-Object UserPrincipalName,DisplayName,ProxyAddresses,ImmutableID | Sort-Object DisplayName | Out-GridView -Title "Select The Office 365 Online User To HardLink The AD User To" -PassThru

#Uncommend the ###Careful### out of the following command to purge all the deleted users from the users recycle bin on Office 365 
#This will only query for users that are unlicensed so it will skip users with mailboxes but still use at your own risk 
###Careful### Get-MsolUser -ReturnDeletedUsers | Where-Object {$_.isLicensed -NE "false"} | Remove-MsolUser -RemoveFromRecycleBin -Force

# Money command that sets the office 365 user you picked with the OnPrem AD ImmutableID 
Set-MSOLuser -UserPrincipalName $OnlineUser.UserPrincipalName -ImmutableID $UserimmutableID

#Verify ImmutableID has been updated 
$Office365UserQuery = Get-MsolUser -UserPrincipalName $OnlineUser.UserPrincipalName | Select-Object DisplayName,ImmutableId 
Write-Host "Do the ID's Match? if not something is wrong" 
Write-Host "AD Immutable ID Used" $UserimmutableID 
Write-Host "Office365 UserLinked" $Office365UserQuery.ImmutableId

# Ask To Repeat The Script 
$Repeat = read-host "Do you want to choose another user? Y or N" 
} 
while ($Repeat -eq "Y")

#List Users and ImmutableId 
Get-MsolUser | Select-Object DisplayName,ImmutableID | Sort-Object DisplayName | Out-GridView -Title "Office 365 User List With Immutableid Showing"

#Close your PS Office 365 Connection 
Get-PSSession | Remove-PSSession