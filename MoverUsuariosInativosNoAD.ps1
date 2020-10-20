#Script mantido internamente por Rafael Alves v1.0 ITP Soluções 27/08/2020

#Este script move contas inativas a mais de 90 dias para a OU Usuarios Inativos
#Verifique as variaveis e caminhos antes de executa-lo

#Excluir OU de contas de serviço e Users da Query
$OUDN = "OU=Contas de Servicos,DC=celi,DC=hotel"
$OUDN2 = "CN=Users,DC=celi,DC=hotel"

foreach ($user in search-adaccount -UsersOnly -AccountInactive -TimeSpan 90.00:00:00 | Where-Object { $_.DistinguishedName -notlike "*,$OUDN" } | Where-Object { $_.DistinguishedName -notlike "*,$OUDN2" }){
    move-adobject -identity $user.DistinguishedName -targetpath "OU=Usuarios,OU=Contas Inativas,DC=celi,DC=hotel"
    }