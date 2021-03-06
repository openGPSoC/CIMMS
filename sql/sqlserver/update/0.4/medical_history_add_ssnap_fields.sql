/*
   14 September 201210:15:48
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
ALTER TABLE dbo.medical_history ADD
	onset_date_estimated tinyint NULL,
	onset_time_estimated tinyint NULL,
	during_sleep tinyint NULL,
	assessed_in_vascular_clinic tinyint NULL
GO
ALTER TABLE dbo.medical_history SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.medical_history', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.medical_history', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.medical_history', 'Object', 'CONTROL') as Contr_Per 