$Dusers = Search-ADAccount -UsersOnly -AccountInactive -TimeSpan 180.00:00:00 | ?{$_.enabled -eq $True}

Disable-ADAccount $Dusers

Get-ADUser -Properties * -Filter * | ? Enabled -eq $False | Move-ADObject “OU=Usuarios,OU=Usuarios Inativos,DC=piodecimo,DC=com”