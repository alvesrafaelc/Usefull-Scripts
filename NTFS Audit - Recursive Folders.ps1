$FolderPath = Get-ChildItem -Directory -Path "D:" -Recurse -Force
$Output = @()
ForEach ($Folder in $FolderPath) {
    $Acl = Get-Acl -Path $Folder.FullName
    ForEach ($Access in $Acl.Access) {
$Properties = [ordered]@{'Folder Name'=$Folder.FullName;'Group/User'=$Access.IdentityReference;'Permissions'=$Access.FileSystemRights;'Inherited'=$Access.IsInherited}
$Output += New-Object -TypeName PSObject -Property $Properties            
}
}
$Output | Out-GridView


#Exportando para arquivo csv
$ExportPath = 'c:\temp\ntfs_fileserver.csv'
$FolderPath = Get-ChildItem -Directory -Path "E:" -Recurse -Force
$Output = @()
ForEach ($Folder in $FolderPath) {
    $Acl = Get-Acl -Path $Folder.FullName
    ForEach ($Access in $Acl.Access) {
$Properties = [ordered]@{'Folder Name'=$Folder.FullName;'Group/User'=$Access.IdentityReference;'Permissions'=$Access.FileSystemRights;'Inherited'=$Access.IsInherited}
$Output += New-Object -TypeName PSObject -Property $Properties            
}
}
$Output | Export-Csv -NoType $ExportPath