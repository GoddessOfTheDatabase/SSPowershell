<#Use this snipped at the beginning of every PS script you use to address a set of SQL Availability Group servers.
By passing the ClusterListener name, you will not have to guess/know which replica is in the Primary or Secondary
role, if you have more than 1 Availability Group you can specify the one you want, and if you want to act on
one or more Databases within the group, that can be passed as parameter values, too.  All parameters in this example are MANDATORY.  This snippet would be called as shown:
Get-PrimaryRoleAG -ClusterListener CLLJMHSql01 -AGName CLCJMHSql01 -DBNames JuliesDatabase1

#>
  Param (  
    [Parameter(Mandatory=$true)][string]$ClusterListener,
    [Parameter(Mandatory=$true)][string]$AGName,
    [Parameter(Mandatory=$true)][string[]]$DBNames
   )
  Import-Module -Name sqlserver
  $myServerAGReplicas = "SQLSERVER:\SQL\$ClusterListener\DEFAULT\AvailabilityGroups\$AGName\AvailabilityReplicas"
  Set-Location -Path $myServerAGReplicas
  
  $primaryReplica = Get-ChildItem -Path $myServerAGReplicas | Where-Object {$_.Role -eq "Primary"}
  $pReplicaName = $primaryReplica.Name
  Write-Output -InputObject $pReplicaName
  $ServerInstance = $pReplicaName