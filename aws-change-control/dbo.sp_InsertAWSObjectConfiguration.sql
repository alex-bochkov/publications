USE [DBA]
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_InsertAWSObjectConfiguration]
	@ObjectId varchar(20),
	@ConfigurationJSON varchar(max)
AS

/* PARSE JSON FILE */
IF OBJECT_ID('tempdb..#TopLevelProperties') IS NOT NULL DROP TABLE #TopLevelProperties;

CREATE TABLE #TopLevelProperties(
	[key] [nvarchar](4000) NOT NULL,
	[value] [nvarchar](max) NULL,
	[type] [tinyint] NOT NULL
) 

IF OBJECT_ID('tempdb..#Buffer') IS NOT NULL DROP TABLE #Buffer;

CREATE TABLE #Buffer(
	[key] [nvarchar](4000) NOT NULL,
	[value] [nvarchar](max) NULL,
	[type] [tinyint] NOT NULL
) 

IF OBJECT_ID('tempdb..#FinalResult') IS NOT NULL DROP TABLE #FinalResult;

CREATE TABLE #FinalResult(
	[key] [nvarchar](4000) NOT NULL,
	[value] [nvarchar](max) NULL,
	[type] [tinyint] NOT NULL
) 

INSERT INTO #TopLevelProperties
SELECT 
	[key], [value], [type]
FROM OPENJSON(@ConfigurationJSON)

INSERT INTO #FinalResult
SELECT [key], [value], [type] 
FROM #TopLevelProperties 
WHERE [type] NOT IN (4, 5)

DELETE FROM #TopLevelProperties
WHERE [type] NOT IN (4, 5)

WHILE (1 = 1)
BEGIN

	INSERT INTO #Buffer ([key], [value], [type])
	SELECT 
		t.[key] + ' -> ' + 
			CASE WHEN t.[type] = 4 
				THEN '#' 
				ELSE CAST(a.[key] AS VARCHAR(256)) collate  SQL_Latin1_General_CP1_CI_AS
			END,
		a.[value],
		a.[type]
	FROM #TopLevelProperties t
	CROSS APPLY OPENJSON(t.[value]) a

	DELETE FROM #TopLevelProperties;

	INSERT INTO #FinalResult
	SELECT [key], [value], [type] 
	FROM #Buffer 
	WHERE [type] NOT IN (4, 5)

	INSERT INTO #TopLevelProperties
	SELECT [key], [value], [type] 
	FROM #Buffer 
	WHERE [type] IN (4, 5)

	DELETE FROM #Buffer;

	IF NOT EXISTS (SELECT 1 FROM #TopLevelProperties) 
		BREAK;
END


DECLARE @LastId int;

SELECT @LastId = MAX(id) 
FROM [Monitor].[AWSConfigurationChangesHistory] 
WHERE [ObjectId] = @ObjectId

IF @LastId IS NULL
	OR EXISTS (SELECT [key], [value] FROM #FinalResult 
				EXCEPT 
			   SELECT [key], [value] FROM [Monitor].[AWSConfigurationChangesHistoryParsed] WHERE history_id = @LastId)
	OR EXISTS (SELECT [key], [value] FROM [Monitor].[AWSConfigurationChangesHistoryParsed] WHERE history_id = @LastId
				EXCEPT
			   SELECT [key], [value] FROM #FinalResult)
BEGIN

	DECLARE @id int;

	INSERT INTO [Monitor].[AWSConfigurationChangesHistory] ([ObjectId], [ConfigurationJSON])
	VALUES (@ObjectId, @ConfigurationJSON)

	SELECT @id = SCOPE_IDENTITY();

	INSERT INTO [Monitor].[AWSConfigurationChangesHistoryParsed] ([history_id], [key], [value])
	SELECT @id, [key], [value] FROM #FinalResult	

END
