/*
   13 April 201206:34:42
   User: 
   Server: D630-G2SLT3J
   Database: stroke
   Application: 
*/

/* To prevent any potential data loss issues, you should review this script in detail before running it outside the context of the database designer.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_fluid_management
	(
	id numeric(19, 0) NOT NULL IDENTITY (1, 1),
	version numeric(19, 0) NOT NULL,
	litre_plus_at24 varchar(255) NULL,
	inadequate_at24fluid_reason_type_id numeric(19, 0) NULL,
	inadequate_at24reason_other varchar(255) NULL,
	litre_plus_at48 varchar(255) NULL,
	inadequate_at48fluid_reason_type_id numeric(19, 0) NULL,
	inadequate_at48reason_other varchar(255) NULL,
	litre_plus_at72 varchar(255) NULL,
	inadequate_at72fluid_reason_type_id numeric(19, 0) NULL,
	inadequate_at72reason_other varchar(255) NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_fluid_management SET (LOCK_ESCALATION = TABLE)
GO
SET IDENTITY_INSERT dbo.Tmp_fluid_management ON
GO
IF EXISTS(SELECT * FROM dbo.fluid_management)
	 EXEC('INSERT INTO dbo.Tmp_fluid_management (id, version, litre_plus_at24, litre_plus_at48, litre_plus_at72)
		SELECT id, version, litre_plus_at24, litre_plus_at48, litre_plus_at72 FROM dbo.fluid_management WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_fluid_management OFF
GO
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK787D8C7DF4FE840D
GO
DROP TABLE dbo.fluid_management
GO
EXECUTE sp_rename N'dbo.Tmp_fluid_management', N'fluid_management', 'OBJECT' 
GO
ALTER TABLE dbo.fluid_management ADD CONSTRAINT
	PK__fluid_ma__3213E83F571DF1D5 PRIMARY KEY CLUSTERED 
	(
	id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	FK787D8C7DF4FE840D FOREIGN KEY
	(
	fluid_management_id
	) REFERENCES dbo.fluid_management
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.care_activity SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
