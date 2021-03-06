/*
   24 February 201216:15:50
   User: 
   Server: 2740-2CE13203BP
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
ALTER TABLE dbo.speech_and_language_therapy_management
	DROP CONSTRAINT FKC1288C5B72134C8E
GO
ALTER TABLE dbo.swallowing_no_assessment_reason_type SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.speech_and_language_therapy_management
	DROP CONSTRAINT FKC1288C5B2D5728A0
GO
ALTER TABLE dbo.communication_no_assessment_reason_type SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.physiotherapy_management
	DROP CONSTRAINT FK114847918703F2E4
GO
ALTER TABLE dbo.physiotherapy_no_assessment_reason_type SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.therapy_management
	DROP CONSTRAINT FK4046B5D9FA3677E5
GO
ALTER TABLE dbo.speech_and_language_therapy_management ADD CONSTRAINT
	FKC1288C5B2D5728A0 FOREIGN KEY
	(
	no_communication_assessment_reason_type_id
	) REFERENCES dbo.communication_no_assessment_reason_type
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.speech_and_language_therapy_management ADD CONSTRAINT
	FKC1288C5B72134C8E FOREIGN KEY
	(
	no_swallowing_assessment_reason_type_id
	) REFERENCES dbo.swallowing_no_assessment_reason_type
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.speech_and_language_therapy_management SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_physiotherapy_management
	(
	id numeric(19, 0) NOT NULL IDENTITY (1, 1),
	version numeric(19, 0) NOT NULL,
	assessment_date datetime NULL,
	assessment_time int NULL,
	assessment_performed tinyint NULL,
	no_assessment_reason_type_id numeric(19, 0) NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_physiotherapy_management SET (LOCK_ESCALATION = TABLE)
GO
SET IDENTITY_INSERT dbo.Tmp_physiotherapy_management ON
GO
IF EXISTS(SELECT * FROM dbo.physiotherapy_management)
	 EXEC('INSERT INTO dbo.Tmp_physiotherapy_management (id, version, assessment_date, assessment_time, assessment_performed, no_assessment_reason_type_id)
		SELECT id, version, assessment_date, assessment_time, assessment_performed, no_assessment_reason_type_id FROM dbo.physiotherapy_management WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_physiotherapy_management OFF
GO
ALTER TABLE dbo.therapy_management
	DROP CONSTRAINT FK4046B5D9AD908856
GO
DROP TABLE dbo.physiotherapy_management
GO
EXECUTE sp_rename N'dbo.Tmp_physiotherapy_management', N'physiotherapy_management', 'OBJECT' 
GO
ALTER TABLE dbo.physiotherapy_management ADD CONSTRAINT
	PK__physioth__3213E83F75A278F5 PRIMARY KEY CLUSTERED 
	(
	id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.physiotherapy_management ADD CONSTRAINT
	FK114847918703F2E4 FOREIGN KEY
	(
	no_assessment_reason_type_id
	) REFERENCES dbo.physiotherapy_no_assessment_reason_type
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.therapy_management ADD CONSTRAINT
	FK4046B5D9AD908856 FOREIGN KEY
	(
	physiotherapy_management_id
	) REFERENCES dbo.physiotherapy_management
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.therapy_management ADD CONSTRAINT
	FK4046B5D9FA3677E5 FOREIGN KEY
	(
	speech_and_language_therapy_management_id
	) REFERENCES dbo.speech_and_language_therapy_management
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.therapy_management SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
