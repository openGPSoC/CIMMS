/*
   20 April 201214:03:28
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
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK787D8C7DA1C0C699
GO
ALTER TABLE dbo.medical_history SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK787D8C7DB5532281
GO
ALTER TABLE dbo.continence_management SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK787D8C7D64158A38
GO
ALTER TABLE dbo.imaging SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK787D8C7D29D6FE40
GO
ALTER TABLE dbo.patient_proxy SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK787D8C7DF4FE840D
GO
ALTER TABLE dbo.fluid_management SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK787D8C7DAA226EA9
GO
ALTER TABLE dbo.nutrition_management SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK787D8C7DBF7884CB
GO
ALTER TABLE dbo.therapy_management SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK787D8C7DFB21439C
GO
ALTER TABLE dbo.thrombolysis SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK787D8C7DBD56D383
GO
ALTER TABLE dbo.clinical_assessment SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK_care_activity_post_discharge_care
GO
ALTER TABLE dbo.post_discharge_care SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_care_activity
	(
	id numeric(19, 0) NOT NULL IDENTITY (1, 1),
	version numeric(19, 0) NOT NULL,
	hospital_stay_id varchar(255) NOT NULL,
	start_date datetime NOT NULL,
	start_time int NULL,
	final_diagnosis varchar(255) NULL,
	fit_for_discharge_date datetime NULL,
	social_worker_referral varchar(50) NULL,
	social_worker_referral_date datetime NULL,
	social_worker_referral_unknown tinyint NULL,
	social_worker_assessment varchar(50) NULL,
	social_worker_assessment_date datetime NULL,
	social_worker_assessment_unknown tinyint NULL,
	end_date datetime NULL,
	end_time int NULL,
	care_activities_idx int NULL,
	clinical_assessment_id numeric(19, 0) NULL,
	patient_life_style_id numeric(19, 0) NULL,
	continence_management_id numeric(19, 0) NULL,
	imaging_id numeric(19, 0) NULL,
	medical_history_id numeric(19, 0) NULL,
	nutrition_management_id numeric(19, 0) NULL,
	fluid_management_id numeric(19, 0) NULL,
	therapy_management_id numeric(19, 0) NULL,
	thrombolysis_id numeric(19, 0) NULL,
	post_discharge_care_id numeric(19, 0) NULL,
	patient_id numeric(19, 0) NOT NULL,
	fit_for_discharge_date_unknown tinyint NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_care_activity SET (LOCK_ESCALATION = TABLE)
GO
SET IDENTITY_INSERT dbo.Tmp_care_activity ON
GO
IF EXISTS(SELECT * FROM dbo.care_activity)
	 EXEC('INSERT INTO dbo.Tmp_care_activity (id, version, hospital_stay_id, start_date, start_time, final_diagnosis, fit_for_discharge_date, social_worker_referral, social_worker_referral_date, social_worker_referral_unknown, end_date, end_time, care_activities_idx, clinical_assessment_id, patient_life_style_id, continence_management_id, imaging_id, medical_history_id, nutrition_management_id, fluid_management_id, therapy_management_id, thrombolysis_id, post_discharge_care_id, patient_id, fit_for_discharge_date_unknown)
		SELECT id, version, hospital_stay_id, start_date, start_time, final_diagnosis, fit_for_discharge_date, social_worker_referral, social_worker_referral_date, social_worker_referral_unknown, end_date, end_time, care_activities_idx, clinical_assessment_id, patient_life_style_id, continence_management_id, imaging_id, medical_history_id, nutrition_management_id, fluid_management_id, therapy_management_id, thrombolysis_id, post_discharge_care_id, patient_id, fit_for_discharge_date_unknown FROM dbo.care_activity WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_care_activity OFF
GO
ALTER TABLE dbo.observation
	DROP CONSTRAINT FK74AD82CC11D709F
GO
ALTER TABLE dbo.treatment
	DROP CONSTRAINT FKFC397878C11D709F
GO
ALTER TABLE dbo.evaluation
	DROP CONSTRAINT FK332C073CC11D709F
GO
ALTER TABLE dbo.care_activity
	DROP CONSTRAINT FK_care_activity_care_activity
GO
DROP TABLE dbo.care_activity
GO
EXECUTE sp_rename N'dbo.Tmp_care_activity', N'care_activity', 'OBJECT' 
GO
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	PK__care_act__3213E83F03317E3D PRIMARY KEY CLUSTERED 
	(
	id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	UNQ__care_activity__hospital_stay_id UNIQUE NONCLUSTERED 
	(
	hospital_stay_id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	FK_care_activity_post_discharge_care FOREIGN KEY
	(
	post_discharge_care_id
	) REFERENCES dbo.post_discharge_care
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	FK787D8C7DBD56D383 FOREIGN KEY
	(
	clinical_assessment_id
	) REFERENCES dbo.clinical_assessment
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	FK787D8C7DFB21439C FOREIGN KEY
	(
	thrombolysis_id
	) REFERENCES dbo.thrombolysis
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
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
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	FK787D8C7DAA226EA9 FOREIGN KEY
	(
	nutrition_management_id
	) REFERENCES dbo.nutrition_management
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
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
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	FK787D8C7D29D6FE40 FOREIGN KEY
	(
	patient_id
	) REFERENCES dbo.patient_proxy
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	FK787D8C7D64158A38 FOREIGN KEY
	(
	imaging_id
	) REFERENCES dbo.imaging
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	FK787D8C7DB5532281 FOREIGN KEY
	(
	continence_management_id
	) REFERENCES dbo.continence_management
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	FK_care_activity_care_activity FOREIGN KEY
	(
	id
	) REFERENCES dbo.care_activity
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.care_activity ADD CONSTRAINT
	FK787D8C7DA1C0C699 FOREIGN KEY
	(
	medical_history_id
	) REFERENCES dbo.medical_history
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.evaluation ADD CONSTRAINT
	FK332C073CC11D709F FOREIGN KEY
	(
	care_activity_id
	) REFERENCES dbo.care_activity
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.evaluation SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.treatment ADD CONSTRAINT
	FKFC397878C11D709F FOREIGN KEY
	(
	care_activity_id
	) REFERENCES dbo.care_activity
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.treatment SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.observation ADD CONSTRAINT
	FK74AD82CC11D709F FOREIGN KEY
	(
	care_activity_id
	) REFERENCES dbo.care_activity
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.observation SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
