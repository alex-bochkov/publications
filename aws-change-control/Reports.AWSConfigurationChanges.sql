USE [DBA]
GO
CREATE OR ALTER PROCEDURE [Reports].[AWSConfigurationChanges]
AS
IF EXISTS (SELECT 1 FROM [Monitor].[AWSConfigurationChangesHistory] WHERE [AlertSent] = 0)
BEGIN

	IF OBJECT_ID('tempdb..#Report') IS NOT NULL DROP TABLE #Report;

	CREATE TABLE #Report(
		[ChangeDateTime] [datetime] NOT NULL,
		[ObjectName] [varchar](256) NOT NULL,
		[ObjectId] [varchar](128) NOT NULL,
		CurrentVersion int NULL,
		PreviousVersion int NULL);

	WITH RecentChanges AS (
		SELECT 
			MAX(id) as id,
			MAX([ChangeDateTime]) AS [ChangeDateTime],
			[ObjectId]
		FROM [Monitor].[AWSConfigurationChangesHistory]
		WHERE AlertSent = 0
		GROUP BY [ObjectId]),
	Versions AS (
		SELECT 
			rc.id,
			rc.[ChangeDateTime],
			(SELECT MAX(b.id) FROM [Monitor].[AWSConfigurationChangesHistory] b WHERE b.id < rc.id AND b.[ObjectId] = rc.[ObjectId]) AS PreviousVersion,
			rc.ObjectId
		FROM RecentChanges rc)

	INSERT INTO #Report
	SELECT 
		v.[ChangeDateTime],
		(SELECT j.Value
		  FROM [DBA].[Monitor].[AWSConfigurationChangesHistory] h
		  CROSS APPLY OPENJSON (h.[ConfigurationJSON], N'$.Tags')  
				   WITH (  
					  [Key]   varchar(200) N'$.Key',   
					  [Value]     varchar(200)     N'$.Value'
				   )  j
			WHERE j.[Key] = 'Name'
			AND h.id = v.id) AS ObjectName,
		v.ObjectId,
		v.id,
		v.PreviousVersion
	FROM Versions v

	DECLARE @tableHTML VARCHAR(max), @subject VARCHAR(max);
	SET @tableHTML =
		N'<H3>AWS configuration has been modified</H3>' +
		N'<table border="1">' +
		N'<tr> 
			<th>Change Detected On</th> 
			<th>Object Name</th> 
			<th>Object ID</th> 
			<th>New (modified) Values</th> 
			<th>Old (deleted) Values</th> 
		</tr>'
	
	SELECT @tableHTML = @tableHTML + '<tr>' + 
		'<td>' + FORMAT(R.[ChangeDateTime], 'yyyy-MM-dd HH:mm:ss') + '</td>' +
		'<td>' + R.[ObjectName] + '</td>' +
		'<td>' + R.[ObjectId] + '</td>' +
		'<td>' + '<table>' + 
			ISNULL(CAST((
				SELECT td = Val FROM (
					SELECT h1.[key] + ' : ' + ISNULL(h1.[value], '') AS Val FROM [Monitor].[AWSConfigurationChangesHistoryParsed] h1 WHERE h1.[history_id] = R.CurrentVersion
					EXCEPT
					SELECT h2.[key] + ' : ' + ISNULL(h2.[value], '') FROM [Monitor].[AWSConfigurationChangesHistoryParsed] h2 WHERE h2.[history_id] = R.PreviousVersion
				) AS T
				FOR XML PATH('tr'), TYPE 
			) AS NVARCHAR(MAX) ), '')
		+ '</table>' + '</td>' +
		'<td>' + '<table>' +
			ISNULL(CAST((
				SELECT td = Val FROM (
					SELECT h1.[key] + ' : ' + ISNULL(h1.[value], '') AS Val FROM [Monitor].[AWSConfigurationChangesHistoryParsed] h1 WHERE h1.[history_id] = R.PreviousVersion
					EXCEPT
					SELECT h2.[key] + ' : ' + ISNULL(h2.[value], '') FROM [Monitor].[AWSConfigurationChangesHistoryParsed] h2 WHERE h2.[history_id] = R.CurrentVersion
				) AS T
				FOR XML PATH('tr'), TYPE 
			) AS NVARCHAR(MAX) ), '')
		+ '</table>' + '</td>'
	FROM #Report R
	ORDER BY R.[ChangeDateTime] DESC

	SET @tableHTML = @tableHTML + '</table>' ;
		
	SET @subject = '[Report] AWS configuration has been modified';

	EXEC msdb.dbo.sp_send_dbmail 
		@profile_name = 'DBA',
		@recipients = 'dba@contoso.com',
		@subject = @subject,
		@body = @tableHTML,
		@body_format = 'HTML';

		
	UPDATE [Monitor].[AWSConfigurationChangesHistory]
	SET [AlertSent] = 1
	WHERE [AlertSent] = 0
	
END
GO


