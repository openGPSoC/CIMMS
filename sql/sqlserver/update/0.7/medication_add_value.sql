/*
   17 October 201218:13:04
   User: 
   Server: BHTS-MATERNITYB
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
ALTER TABLE dbo.medication
	DROP CONSTRAINT FK7725CACFA1C0C699
GO
ALTER TABLE dbo.medical_history SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.medical_history', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.medical_history', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.medical_history', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.medication
	DROP CONSTRAINT FK7725CACF82F8391B
GO
ALTER TABLE dbo.medication_type SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.medication_type', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.medication_type', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.medication_type', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_medication
	(
	id numeric(19, 0) NOT NULL IDENTITY (1, 1),
	version numeric(19, 0) NOT NULL,
	type_id numeric(19, 0) NULL,
	value varchar(250) NULL,
	medical_history_id numeric(19, 0) NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_medication SET (LOCK_ESCALATION = TABLE)
GO
SET IDENTITY_INSERT dbo.Tmp_medication ON
GO
IF EXISTS(SELECT * FROM dbo.medication)
	 EXEC('INSERT INTO dbo.Tmp_medication (id, version, type_id, medical_history_id)
		SELECT id, version, type_id, medical_history_id FROM dbo.medication WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_medication OFF
GO
DROP TABLE dbo.medication
GO
EXECUTE sp_rename N'dbo.Tmp_medication', N'medication', 'OBJECT' 
GO
ALTER TABLE dbo.medication ADD CONSTRAINT
	PK__medicati__3213E83F3C69FB99 PRIMARY KEY CLUSTERED 
	(
	id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.medication ADD CONSTRAINT
	FK7725CACF82F8391B FOREIGN KEY
	(
	type_id
	) REFERENCES dbo.medication_type
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.medication ADD CONSTRAINT
	FK7725CACFA1C0C699 FOREIGN KEY
	(
	medical_history_id
	) REFERENCES dbo.medical_history
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
COMMIT
select Has_Perms_By_Name(N'dbo.medication', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.medication', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.medication', 'Object', 'CONTROL') as Contr_Per 