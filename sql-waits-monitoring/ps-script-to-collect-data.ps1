<#
  1. Define Central server that stores consolidated wait stats from all server (`Get-Target-Server` function)
  2. Define ElasticSearch server address to bulk insert data (`Export-Wait-Statistics-Into-ElasticSearch` function)
#>

Param(
    [String]$ProcedureToRun
)

Function Get-All-Database-Servers {
    Param(
        [String]$DatabaseServerTarget
    )

    $DatabaseServers = @();

    $AllDBServers = Invoke-Sqlcmd "SELECT [ServerName] FROM [DBA].[Meta].[DatabaseServers]" -ServerInstance $DatabaseServerTarget
    $AllDBServers | % { $DatabaseServers += $_["ServerName"]}

    Return $DatabaseServers;
}
Function Get-Target-Server {

    Return " <Central Server Name> "

}

Function Get-Differential-Wait-Statistics {
    Param(
        [String]$DatabaseServerSource, 
        [String]$DatabaseServerTarget
    )

    <# To ease the debug
    $DatabaseServerSource = "SourceServer"
    $DatabaseServerTarget = "CentralServer"
    #>
        
    try {

        $LocalData = Invoke-Sqlcmd "SELECT ISNULL(MAX([CollectTime]), '1900-01-01') AS LastRecordedValue
				    FROM DBA.Monitor.DifferentialWaitStatistics WHERE [ServerName] = '$DatabaseServerSource'" -ServerInstance $DatabaseServerTarget       

        if ($LocalData) {

            $Date = $LocalData.LastRecordedValue.ToString("yyyy-MM-dd HH:mm:ss.fff")

            $CollectedData = Invoke-Sqlcmd "
                SELECT [CollectedDateTime]
                      ,[WaitType]
                      ,[WaitSec]
                      ,[WaitCount]
                  FROM [DBA].[Monitor].[CollectedWaitStatistics]
                  WHERE [CollectedDateTime] > '$Date' 
					          AND ServerName = @@SERVERNAME --make sure to pull data that belongs to this server only
                  ORDER BY [CollectedDateTime]
                 " -ServerInstance $DatabaseServerSource  
            

            ForEach ($Row in $CollectedData) {

                Invoke-Sqlcmd "
                            INSERT INTO [Monitor].[DifferentialWaitStatistics]
                               ([CollectTime]
                               ,[ServerName]
                               ,[WaitType]
                               ,[WaitSec]
                               ,[WaitCount])
                             VALUES
                                   ('$($Row["CollectedDateTime"].ToString("yyyy-MM-dd HH:mm:ss.fff"))',
                                        '$DatabaseServerSource',
                                        '$($Row["WaitType"])',
                                        $($Row["WaitSec"]),
                                        $($Row["WaitCount"])
                                   )" -ServerInstance $DatabaseServerTarget -Database "DBA"

            }
        }

    } catch {}

}

##############################################################################################
# Functions that are called from SQL AGent Job

Function Collect-All-Differential-Wait-Statistics {

    $DatabaseServerTarget = Get-Target-Server;
    $DatabaseServers = Get-All-Database-Servers -DatabaseServerTarget $DatabaseServerTarget;

    ForEach ($DB in $DatabaseServers) {

        Get-Differential-Wait-Statistics -DatabaseServerSource $DB -DatabaseServerTarget $DatabaseServerTarget

    }

}

Function Export-Wait-Statistics-Into-ElasticSearch {

    $DatabaseServerTarget = Get-Target-Server;

    While (1 -eq 1) {
    
        $RS = Invoke-Sqlcmd "EXEC [DBA].[ElasticSearch].[GetNextExportBatch_WaitStatistics]" -ServerInstance $DatabaseServerTarget   

        if ($RS) {

            $LastId = -1
            $PostString = ""

            ForEach ($Row in $RS) {

                $LastId = $Row["id"];

                $PostString = $PostString + $Row["IndexLine"] + [Environment]::NewLine + $Row["RecordLine"] + [Environment]::NewLine;

            }
            
            $Result = Invoke-RestMethod -Method Post -Uri `
                    " <ES Server Address> /_bulk?" `
                    -Body $PostString  -ContentType 'application/json' -ErrorAction Stop 
            
           
            if ($LastId -gt 0) {

                Invoke-Sqlcmd "UPDATE [DBA].[Meta].[Config]
                                   SET [longValue] = $LastId
                                      ,[dateValue] = GETDATE()
                                WHERE [keyName] = 'ElasticSearchIntegration'
                                      AND [subKeyName] = 'LastExportedId_WaitsStatistics';" -ServerInstance $DatabaseServerTarget | Out-Null
            
            }
            

        } else { break; }

    }
    
}

If ($ProcedureToRun -eq "ESExport") {

    Export-Wait-Statistics-Into-ElasticSearch

}
