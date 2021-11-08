$OUpath = 'ou=28Abril,ou=Migrados,dc=decosdh,dc=com'
Get-aduser -filter * -SearchBase $OUpath -properties sidhistory | Where-Object sidhistory

#Mesmo comando porem exportando para arquivo csv
#$OUpath = 'ou=Migrados,dc=decosdh,dc=com'
#$ExportPath = 'c:\temp\users_with_sidhistory.csv'
#Get-aduser -filter * -SearchBase $OUpath -properties sidhistory | Where-Object sidhistory | Export-Csv -NoType $ExportPath