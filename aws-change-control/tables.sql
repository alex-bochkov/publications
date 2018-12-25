USE [DBA]
GO
CREATE TABLE [Monitor].[AWSConfigurationChangesHistory](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[ObjectId] [varchar](20) NULL,
	[ChangeDateTime] [datetime] NULL,
	[ConfigurationJSON] [varchar](max) NULL,
	[AlertSent] [bit] NULL,
  PRIMARY KEY CLUSTERED ([id])
)

ALTER TABLE [Monitor].[AWSConfigurationChangesHistory] ADD  DEFAULT (getdate()) FOR [ChangeDateTime]
GO

ALTER TABLE [Monitor].[AWSConfigurationChangesHistory] ADD  DEFAULT ((0)) FOR [AlertSent]
GO

CREATE TABLE [Monitor].[AWSConfigurationChangesHistoryParsed](
	[history_id] [int] NOT NULL,
	[key] [nvarchar](512) NOT NULL,
	[value] [nvarchar](512) NULL
)
GO
