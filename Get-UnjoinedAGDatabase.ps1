function Get-UnjoinedAGDatabase {
    <#
      .SYNOPSIS
      Get-UnjoinedAGDatabase Adds an previously Unjoined database to the primary replica of an Availability group, then to all of the secondary replicas where the database exists. 

      .DESCRIPTION
      Get-UnjoinedAGDatabase Determines the replicas of an availability group by using the cluster listener name.  It then ensures the database(s) are ready to be joined, have not already been joined, and are joined and reporting a HEALTHY state when complete. The database(s) are joined to both primary and secondary replicas.

      .PARAMETER ClusterListener
      The Cluster Listener name that provides the replica names and their roles.

      .PARAMETER AGName
      The Availability Group Name that exists on the cluster to which the database will be checked.

      .PARAMETER DBNames
      The Database Name to be checked to see if it is joined to an availability Group.

      .EXAMPLE
      Get-UnjoinedAGDatabase -ClusterListener CLLDEVListener -AGName AG_DEVAG -DBName Jumpjive1
      The database name listed will be checked to see if it is part of the availablility group AG_DEVAG on the cluster identified by the ClusterListener CLLDEVListener.
#>
  Param (  
    [Parameter(Mandatory=$true)][string]$ClusterListener,
    [Parameter(Mandatory=$true)][string]$AGName,
    [Parameter(Mandatory=$true)][string]$DBName
   )
  Import-Module -Name sqlserver
  $myServerAGReplicas = "SQLSERVER:\SQL\$ClusterListener\DEFAULT\AvailabilityGroups\$AGName\AvailabilityReplicas"
  Set-Location -Path $myServerAGReplicas
  
  $primaryReplica = Get-ChildItem -Path $myServerAGReplicas | Where-Object {$_.Role -eq "Primary"}
  $pReplicaName = $primaryReplica.Name
  Write-Host -InputObject $pReplicaName
  $ServerInstance = $pReplicaName.Name

  $CheckForUnJoinedAGDBSQL = (@"
    USE Master
    GO
select name from sys.databases
where database_id  > 4 
and name = '$DBName'
and 
replica_id IS NULL
"@)
  Write-Output $CheckForUnJoinedAGDBSQL
  #Invoke-Sqlcmd -Query $CheckForUnJoinedAGDBSQL -QueryTimeout 3600 -ServerInstance $DBServer
  $UnJoinedAGDB = (Invoke-Sqlcmd -Query $CheckForUnJoinedAGDBSQL -QueryTimeout 3600 -ServerInstance $ServerInstance)
  $NonAGDB = $UnJoinedAGDB.name

If (!$UnJoinedAGDB) {Write-Output "Already Joined to AG"}
Else {Write-Output "Adding to AG" }

