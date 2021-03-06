/*
   24 February 201216:20:04
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
	DROP CONSTRAINT FK4046B5D9E4185627
GO
ALTER TABLE dbo.occupational_therapy_management SET (LOCK_ESCALATION = TABLE)
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
ALTER TABLE dbo.therapy_management
	DROP CONSTRAINT FK4046B5D9AD908856
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
ALTER TABLE dbo.physiotherapy_management SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.therapy_management
	DROP CONSTRAINT FK4046B5D93611E1FF
GO
ALTER TABLE dbo.rehab_goals_not_set_reason_type SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.therapy_management
	DROP CONSTRAINT FK4046B5D931DB5E90
GO
ALTER TABLE dbo.cognitive_status_no_assessment_type SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.therapy_management
	DROP CONSTRAINT FK4046B5D916479FC5
GO
ALTER TABLE dbo.baseline_assessment_management SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_therapy_management
	(
	id numeric(19, 0) NOT NULL IDENTITY (1, 1),
	version numeric(19, 0) NOT NULL,
	cognitive_status_assessed tinyint NULL,
	cognitive_status_assessment_date datetime NULL,
	cognitive_status_assessment_time int NULL,
	cognitive_status_no_assessment_type_id numeric(19, 0) NULL,
	rehab_goals_set tinyint NULL,
	rehab_goals_set_date datetime NULL,
	rehab_goals_set_time int NULL,
	rehab_goals_not_set_reason_type_id numeric(19, 0) NULL,
	baseline_assessment_management_id numeric(19, 0) NULL,
	physiotherapy_management_id numeric(19, 0) NULL,
	occupational_therapy_management_id numeric(19, 0) NULL,
	speech_and_language_therapy_management_id numeric(19, 0) NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_therapy_management SET (LOCK_ESCALATION = TABLE)
GO
SET IDENTITY_INSERT dbo.Tmp_therapy_management ON
GO
IF EXISTS(SELECT * FROM dbo.therapy_management)
	 EXEC('INSERT INTO dbo.Tmp_therapy_management (id, version, cognitive_status_assessed, cognitive_status_assessment_date, cognitive_status_assessment_time, cognitive_status_no_assessment_type_id, rehab_goals_set, rehab_goals_set_date, rehab_goals_set_time, rehab_goals_not_set_reason_type_id, baseline_assessment_management_id, physiotherapy_management_id, occupational_therapy_management_id, speech_and_language_therapy_management_id)
		SELECT id, version, cognitive_status_assessed, cognitive_status_assessment_date, cognitive_status_assessment_time, cognitive_status_no_assessment_type_id, rehab_goals_set, rehab_goals_set_date, rehab_goals_set_time, rehab_goals_not_set_reason_type_id, baseline_assessment_management_id, physiotherapy_management_id, occupational_therapy_management_id, speech_and_language_therapy_management_id FROM dbo.therapy_management WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_therapy_management OFF
GO
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK787D8C7DBF7884CB
GO
DROP TABLE dbo.therapy_management
GO
EXECUTE sp_rename N'dbo.Tmp_therapy_management', N'therapy_management', 'OBJECT' 
GO
ALTER TABLE dbo.therapy_management ADD CONSTRAINT
	PK__therapy___3213E83F5AEE82B9 PRIMARY KEY CLUSTERED 
	(
	id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.therapy_management ADD CONSTRAINT
	FK4046B5D916479FC5 FOREIGN KEY
	(
	baseline_assessment_management_id
	) REFERENCES dbo.baseline_assessment_management
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.therapy_management ADD CONSTRAINT
	FK4046B5D931DB5E90 FOREIGN KEY
	(
	cognitive_status_no_assessment_type_id
	) REFERENCES dbo.cognitive_status_no_assessment_type
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.therapy_management ADD CONSTRAINT
	FK4046B5D93611E1FF FOREIGN KEY
	(
	rehab_goals_not_set_reason_type_id
	) REFERENCES dbo.rehab_goals_not_set_reason_type
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
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
ALTER TABLE dbo.therapy_management ADD CONSTRAINT
	FK4046B5D9E4185627 FOREIGN KEY
	(
	occupational_therapy_management_id
	) REFERENCES dbo.occupational_therapy_management
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	FK787D8C7DBF7884CB FOREIGN KEY
	(
	therapy_management_id
	) REFERENCES dbo.therapy_management
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.care_activity SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
