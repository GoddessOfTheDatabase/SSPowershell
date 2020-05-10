<#Import-Module sqlserver
 $ServerInstance = 'your instance name here'
 $DBName = 'your db name here'

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
Else {Write-Output "Adding to AG" }#>

function Check-Database  {
  Param (  
    [Parameter(Mandatory=$true)][string]$ServerInstance,
    [Parameter(Mandatory=$true)][string]$DBName,
    [Parameter(Mandatory=$true)][string]$DBStatus
   )
  

  Import-Module -Name sqlserver
      $dbState = ""
      $realDBStatus = ""
      $ReturnCode = ""

      Write-Output $ServerInstance
      Write-Output $DBName
      Write-Output "The Desired State supplied is $DBStatus"
      $srv = New-Object Microsoft.SqlServer.Management.Smo.Server($ServerInstance)
      $db = New-Object Microsoft.SqlServer.Management.Smo.Database
      $db = $srv.Databases.Item($DBName)
      $realDBStatus = $db.Status
      $dbState = $db.State 
      Write-Output $ReturnCode
      #Write-Output $realDBStatus
      #Write-Output $dbState 
      $ReturnCode = ""
      If (!$realDBStatus) {
        Write-Output -InputObject "Database does not exist on this server! $DBName"
        Write-Output -InputObject "Error identifying database on replica. Make sure database exists on server and is reachable."
        'NOWAY'
      }
      Elseif ($realDBStatus -ne $DBStatus) {
        Write-Output -InputObject "Database Exists but not in correct state"
        Write-Output "$dbName,$realDBStatus" 
        'NOWAY' 
      }
      Else {
        Write-Output -InputObject "Database Exists and in correct state!"
        Write-Output "$dbName,$realDBStatus" 
        'YES' 
      }
     Return 
  } 
  
  #Check-Database  -ServerInstance arx-devsqlc-02 -DBName JuliesTestDB -DBStatus Normal
  #Function Add-AGDatabase connects to server object, checks the replica role (primary or secondary), for
  #each db name, Checks to see if there is a database named that, only then, checks if the current state
  #of the database is the desired state, if not, and the Primary replica, execute 
  #Add-SqlAvailabilityDatabase -Path SQLSERVER:\SQL\PrimaryServer\InstanceName\AvailabilityGroups\MyAG `   -Database "MyDatabase" or if Secondary replica, execute 
  # Add-SqlAvailabilityDatabase -Path $MyAgSecondaryPath -Database "MyDatabase"
  # Now here's what calls all of the check functions before Add-SqlAvailabilityDatabase

  function Add-AGDatabase {
  Param (  
    [Parameter(Mandatory=$true)][string]$ClusterListener,
    [Parameter(Mandatory=$true)][string]$AGName,
    [Parameter(Mandatory=$true)][string[]]$DBNames
   )
  
  Import-Module -Name sqlserver

  #DBName='Your DB Name'
  $myServerAGReplicas = "SQLSERVER:\SQL\$ClusterListener\DEFAULT\AvailabilityGroups\$AGName\AvailabilityReplicas"
  Set-Location -Path $myServerAGReplicas
  
  $primaryReplica = Get-ChildItem -Path $myServerAGReplicas | where-object {$_.Role -eq "Primary"}
  $pReplicaName = $primaryReplica.Name
  Write-Output -InputObject $pReplicaName
  #$pReplicaName = 'Your PRIMARY ReplicaName if passing the value instead'

 
  Foreach ( $dbName in $DBNames ) {
    $passedDBCheck =  Check-Database -ServerInstance $pReplicaName -DBName $dbName -DBStatus Normal
    Write-Output $passedDBCheck
    #Write-Output $ReturnCode
    #If ($ReturnCode != 'YES') {
    #    Return}
    
    Write-Output 'Returning control to main'
    If ($passedDBCheck -eq 'YES') {
              $CheckForUnJoinedAGDBSQL = (@"
            USE Master
            GO
        select name from sys.databases
        where database_id  > 4 
        and name = '$dbName'
        and 
        replica_id IS NULL
"@)
          Write-Output $CheckForUnJoinedAGDBSQL
          #Invoke-Sqlcmd -Query $CheckForUnJoinedAGDBSQL -QueryTimeout 3600 -ServerInstance $DBServer
          $UnJoinedAGDB = (Invoke-Sqlcmd -Query $CheckForUnJoinedAGDBSQL -QueryTimeout 3600 -ServerInstance $ServerInstance)
          $NonAGDB = $UnJoinedAGDB.name
          Write-Output $NonAGDB

        If (!$UnJoinedAGDB) {Write-Output "Already Joined to AG"}   #  this should not fire if DB doesn't exist!
        Else {Write-Output "Adding $dbName to Availability Group Replica"
        
        
        
        
        
        }
    
    
    }
  }
}

  Add-AGDatabase -ClusterListener cllJMHSpec -AGName cluJMHSpec -DBNames AdventureWorks2016,AdventureWorks2016LT