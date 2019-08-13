###########################
# Autor: Rafael Alves     #
# alves.rafaelc@gmail.com #
###########################

#Desabilitar ADSync com Office365

$msolcred = get-credential

connect-msolservice -credential $msolcred

Set-MsolDirSyncEnabled -EnableDirSync $false

#Rodar comando abaixo para verificar se o serviço foi realmente desabilitado, se receber o status de falso é pq foi desabilitado
(Get-MSOLCompanyInformation).DirectorySynchronizationEnabled

#Para habilitar novamente a sincronização executar comando abaixo

#Set-MsolDirSyncEnabled -EnableDirSync $true