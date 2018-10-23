CREATE SCHEMA ElasticSearch;
GO

CREATE OR ALTER PROCEDURE [ElasticSearch].[GetNextExportBatch_WaitStatistics]
AS

DECLARE @LastExportedId AS INT;

SELECT @LastExportedId = [longValue]
FROM [Meta].[Config]
WHERE [keyName] = 'ElasticSearchIntegration'
      AND [subKeyName] = 'LastExportedId_WaitsStatistics';

IF @LastExportedId IS NULL
    SET @LastExportedId = 0;

WITH Records
AS (SELECT TOP 1000 stat.[id],
                    FORMAT(DATEADD(hh, DATEDIFF(hh, GETDATE(), GETUTCDATE()), stat.[CollectTime]), 'yyyy-MM-ddTHH:mm:ss.fffZ') AS [CollectTime],
                    REPLACE(stat.[ServerName], '\', '\\') AS [ServerName],
                    stat.[WaitType],
                    CAST (stat.[WaitSec] AS VARCHAR (20)) AS [WaitSec],
                    CAST (stat.[WaitCount] AS VARCHAR (20)) AS [WaitCount],
                    FORMAT(stat.[CollectTime], 'yyyyMMddmmHHss') + '_' + REPLACE(stat.[ServerName], '\', '_') + '_' + stat.[WaitType] AS RecordId,
                    'wait-statistics-' + FORMAT(stat.[CollectTime], 'yyy-MM-dd') AS IndexName,
                    'wait-statistics' AS ObjectType,
                    s.[ClusterGroup] AS ClusterGroup
    FROM [Monitor].[DifferentialWaitStatistics_v2] AS stat
         INNER JOIN [Meta].[DatabaseServers] AS s
			ON stat.[ServerName] = s.[ServerName]
    WHERE stat.id > @LastExportedId
	ORDER BY stat.[id])
SELECT [id],
       '{"index":{"_index":"' + IndexName + '", "_type":"' + ObjectType + '", "_id":"' + RecordId + '"}}' AS IndexLine,
       '{"CollectDate":"' + [CollectTime] + '",' 
			+ '"ServerName" : "' + [ServerName] + '",' 
			+ '"ClusterGroup" : "' + ClusterGroup + '",' 
			+ '"WaitType" : "' + [WaitType] + '",' 
			+ '"WaitSec" : ' + [WaitSec] + ',' 
			+ '"WaitCount" : ' + [WaitCount] + '}' AS RecordLine
FROM Records;
