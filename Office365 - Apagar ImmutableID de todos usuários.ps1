###########################
# Autor: Rafael Alves     #
# alves.rafaelc@gmail.com #
###########################
Set-ExecutionPolicy Unrestricted -Scope Process

$domain = Read-Host 'Please enter your domain name'

try
{
    $cred = Get-Credential
    Import-Module MSOnline
   
    Write-Host "Connecting to domain using credentials provided..."
   
    Connect-MsolService -Credential $cred

    Write-Host "Connected to domain."
           
    Write-Host "Fetching users from domain."

    $allUsers = Get-MsolUser –All -DomainName $domain | Select userPrincipalName,ImmutableId
    $totalUserCount = $allUsers.Count

    Write-Host "Fetched" $totalUserCount "users from domain."

    Write-Host "Going to clear ImmutableId property of all users who have a value."

    $count = 0
    foreach ($user in $allUsers)
    {
        try
        {
            if ($user.ImmutableID -ne "$null")
            {                   
                Set-MsolUser -UserPrincipalName $user.userPrincipalName -ImmutableId "$null"
                Write-Host "ImmutabelId cleared for user : " $user.userPrincipalName
                $count++
            }
        }
        catch
        {
            Write-Host "Error - ImmutableId could not be cleared for user : " $user.userPrincipalName
            write-host "Exception Message: $($_.Exception.Message)"
        }
    }
    Write-Host "Success - ImmutableId cleared for" $count "users."   
}
catch
{
    Write-Host "Error - Failed to run the process."
    write-host "Exception Message: $($_.Exception.Message)"
}