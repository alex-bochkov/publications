CREATE SCHEMA Meta;
GO

CREATE TABLE [Meta].[Config](
	[PK_id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[keyName] [varchar](256) NULL,
	[subKeyName] [varchar](40) NULL,
	[charValue] [varchar](150) NULL,
	[longValue] [bigint] NULL,
	[dateValue] [datetime] NULL,
	[floatValue] [float] NULL,
	[comment] [varchar](max) NULL,
	CONSTRAINT [PK_config] PRIMARY KEY CLUSTERED ([PK_id])
)
GO

CREATE TABLE [Meta].[DatabaseServers](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [varchar](128) NOT NULL,
	[ClusterGroup] [varchar](64) NULL,
  PRIMARY KEY CLUSTERED ([id])
)
GO
