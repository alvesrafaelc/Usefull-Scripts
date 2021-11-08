#Alterar variaveis
$OUpath = 'ou=Migrados,dc=decosdh,dc=com'
$ExportPath = 'c:\temp\users_in_ou1.csv'
Get-ADUser -Filter * -SearchBase $OUpath | Select-object DistinguishedName,Name,UserPrincipalName | Export-Csv -NoType $ExportPath