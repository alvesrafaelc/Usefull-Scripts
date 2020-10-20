#Instalar Modulo Excel
#Install-Module -Name ImportExcel -RequiredVersion 5.0.1

Get-Module ActiveDirectory

#List all OU at least link to one GPO
$OUs = Get-ADOrganizationalUnit -Filter {LinkedGroupPolicyObjects -like "*"} 

#Foreach all linked GPO OU and check is empty OU
$EmptyLinkedGPO=@()
$AllLinkedGPO=@()
foreach($aOU in $OUs)
{
      $AllLinkedGPO += [pscustomobject]@{
      GPO = $aOU.LinkedGroupPolicyObjects
      }
}
foreach($aOU in $OUs)
{
$objects = Get-ADObject -Filter {ObjectClass -ne "organizationalUnit"} -SearchBase $aOU

    if (!($objects))
    {
       $EmptyLinkedGPO += [pscustomobject]@{

            GPO = $aOU.LinkedGroupPolicyObjects
            is_Empty = $true
        }
     
      
    }
}

$resultGPO=@()
foreach($aGPO in Get-GPO -All)
{
$GPO_id=$aGPO.Id
$GPO_name=$aGPO.DisplayName
$GPO_CreateTime=$aGPO.ModificationTime
$GPO_ModifyTime=$aGPO.ModificationTime
   foreach($aGPOchk in $EmptyLinkedGPO)
   {
     if ($aGPOchk.GPO -like "*$GPO_id*")
     {
        $resultGPO+=[pscustomobject]@{
         ID=$GPO_id
         Name=$GPO_name
         CreatedTime=$GPO_CreateTime
         ModifyTime=$GPO_ModifyTime
        }
     }
   }
   $check_Linked=$false
   foreach($aGPOchk in $AllLinkedGPO)
    {
        if ($aGPOchk.GPO -like "*$GPO_id*")
        {
        $check_Linked=$true
        Write-Host "True"
        }
    }
    if($check_Linked -eq $false)
    {
        $resultGPO+=[pscustomobject]@{
         ID=$GPO_id
         Name=$GPO_name
         CreatedTime=$GPO_CreateTime
         ModifyTime=$GPO_ModifyTime
        }
    }
}
$resultGPO | Export-Excel C:\Unused_GPO.xlsx -Title "Report Unused GPO"