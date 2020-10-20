pushd .
    try
    {
         $windowsIdentity=[System.Security.Principal.WindowsIdentity]::GetCurrent()
         $principal=new-object System.Security.Principal.WindowsPrincipal($windowsIdentity)
         $administrators=[System.Security.Principal.WindowsBuiltInRole]::Administrator
         $isAdmin=$principal.IsInRole($administrators)
         if (!$isAdmin)
         {
            "Please run the script as an administrator in elevated mode."
            $choice = Read-Host
            return;       
         }

        $error.Clear()    
        "This script will remove the old Azure Site Recovery Provider related properties. Do you want to continue (Y/N) ?"
        $choice =  Read-Host

        if (!($choice -eq 'Y' -or $choice -eq 'y'))
        {
        "Stopping cleanup."
        return;
        }

        $serviceName = "dra"
        $service = Get-Service -Name $serviceName
        if ($service.Status -eq "Running")
        {
            "Stopping the Azure Site Recovery service..."
            net stop $serviceName
        }

        $asrHivePath = "HKLM:\SOFTWARE\Microsoft\Azure Site Recovery"
        $registrationPath = $asrHivePath + '\Registration'
        $proxySettingsPath = $asrHivePath + '\ProxySettings'
        $draIdvalue = 'DraID'

        if (Test-Path $asrHivePath)
        {
            if (Test-Path $registrationPath)
            {
                "Removing registration related registry keys."    
                Remove-Item -Recurse -Path $registrationPath
            }

            if (Test-Path $proxySettingsPath)
        {
                "Removing proxy settings"
                Remove-Item -Recurse -Path $proxySettingsPath
            }

            $regNode = Get-ItemProperty -Path $asrHivePath
            if($regNode.DraID -ne $null)
            {            
                "Removing DraId"
                Remove-ItemProperty -Path $asrHivePath -Name $draIdValue
            }
            "Registry keys removed."
        }

        # First retrive all the certificates to be deleted
        $ASRcerts = Get-ChildItem -Path cert:\localmachine\my | where-object {$_.friendlyname.startswith('ASR_SRSAUTH_CERT_KEY_CONTAINER') -or $_.friendlyname.startswith('ASR_HYPER_V_HOST_CERT_KEY_CONTAINER')}
        # Open a cert store object
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My","LocalMachine")
        $store.Open('ReadWrite')
        # Delete the certs
        "Removing all related certificates"
        foreach ($cert in $ASRcerts)
        {
            $store.Remove($cert)
        }
    }catch
    {    
        [system.exception]
        Write-Host "Error occured" -ForegroundColor "Red"
        $error[0]
        Write-Host "FAILED" -ForegroundColor "Red"
    }
    popd