#Load the required Snapins
 if (!(import-module "activedirectory" -ea 0)) {
 Write-Host "Loading active directory module." -ForegroundColor Yellow
 import-module "activedirectory" -ea Stop
 }#endif

#users
 foreach ($user in search-adaccount -UsersOnly -AccountInactive -TimeSpan 90.00:00:00){
 move-adobject -identity $user.DistinguishedName -targetpath "OU=Usuarios,OU=Contas Inativas,DC=celi,DC=hotel" -whatif
 }

#computers
 foreach ($computer in search-adaccount -Computersonly -AccountInactive -TimeSpan 90.00:00:00){
 move-adobject -identity $computer.DistinguishedName -targetpath "OU=Computadores,OU=Contas Inativas,DC=celi,DC=hotel" -whatif
 }