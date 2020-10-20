#Script mantido internamente por Rafael Alves v1.0 ITP Soluções 27/08/2020

#Este script move Computadores inativas a mais de 90 dias para a OU Computadores Inativos
#Verifique as variaveis e caminhos antes de executa-lo

foreach ($computer in search-adaccount -Computersonly -AccountInactive -TimeSpan 90.00:00:00){
    move-adobject -identity $computer.DistinguishedName -targetpath "OU=Computadores,OU=Contas Inativas,DC=celi,DC=hotel" -whatif
    }
   