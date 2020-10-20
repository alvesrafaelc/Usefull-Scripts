#Script mantido internamente por Rafael Alves v1.0 ITP Solucoes 27/08/2020

#Este script utiliza a variavel seachbase para mover apenas os usuarios daquele diretorio

foreach ($user in search-adaccount -UsersOnly -AccountInactive -TimeSpan 90.00:00:00 -SearchBase "OU=Contas de Servicos,DC=celi,DC=hotel"){
    move-adobject -identity $user.DistinguishedName -targetpath "OU=Usuarios,OU=Contas Inativas,DC=celi,DC=hotel"
    }