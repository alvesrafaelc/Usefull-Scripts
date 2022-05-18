$FolderPath = dir -Directory -Path "\\AGPZSRFS02\Dados" -Force #Variavel para pegar mais 1 nivel de diretorio -Depth 1
$Report = @()
Foreach ($Folder in $FolderPath) {
    $Acl = Get-Acl -Path $Folder.FullName
    foreach ($Access in $acl.Access)
        {
            $Properties = [ordered]@{'FolderName'=$Folder.FullName;'AD
Group or
User'=$Access.IdentityReference;'Permissions'=$Access.FileSystemRights;'Inherited'=$Access.IsInherited}
            $Report += New-Object -TypeName PSObject -Property $Properties
        }
}
$Report | Export-Csv -path "C:\temp\FolderPermissions.csv"