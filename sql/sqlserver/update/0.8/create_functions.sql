/*
 * SSNAP EXPORT FUNCTIONS
 * VERSION 0.8.3
 */
 
USE stroke;
go

/*
--
-- REASON TABLE TYPE
-- Holds reasons for procedure non-performance
--    First need to drop functions depending on this type before
--    dropping an recreating the type
--
*/
IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[performanceRecord]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION dbo.performanceRecord;
IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[performanceRecord2]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION dbo.performanceRecord2;		
IF EXISTS(SELECT * FROM sys.types st 
   JOIN sys.schemas ss ON st.schema_id = ss.schema_id 
   WHERE st.name = N'ReasonTableType' AND ss.name = N'dbo')
   DROP TYPE [dbo].[ReasonTableType]
GO

CREATE TYPE ReasonTableType AS TABLE 
( cimms_reason_desc VARCHAR(24)
, ssnap_reason_code VARCHAR(4) );
GO

/*
 * --
 * ADD DATES AND TIMES
 * --
 */
 
 IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[makeDateTime]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.makeDateTime;
GO


create function makeDateTime(@theDate DATETIME,@theTime INT )
RETURNS VARCHAR(16)
AS
BEGIN
	RETURN
		CONVERT (CHAR(10), @theDate, 103)
		+ ' ' +
		CONVERT(CHAR(5), DATEADD(minute, @theTime, ISNULL(@theDate,0)), 114)
END
GO



create function performanceRecord(@_date DATETIME, @_min INT, @_performed INT, @_nonPerformanceReason VARCHAR(24), @_reasons ReasonTableType READONLY)
RETURNS
	@perfTab
	TABLE ( perfDate VARCHAR(16), perfTimeNotIncluded VARCHAR(1), notPerformed VARCHAR(1), codedReason VARCHAR(4) ) 
AS
BEGIN
	
	DECLARE @perfDate VARCHAR(16) = ''
	DECLARE @perfTimeNotIncluded VARCHAR(1) = '1'
	DECLARE @notPerformed VARCHAR(1) = '1'
	DECLARE @codedReason VARCHAR(4) = ''
	
	IF ISNULL(@_performed, 0) = 1 
	BEGIN
		SET @notPerformed = '0'
		IF @_min IS NOT NULL
		BEGIN
			SET @perfTimeNotIncluded = '0'
		END
		SET @perfDate = dbo.makeDateTime(@_date, ISNULL(@_min,0))			
	END
	ELSE
	BEGIN
		SELECT 
			@codedReason = r.ssnap_reason_code
		FROM 
			@_reasons r 
		WHERE
			r.cimms_reason_desc = @_nonPerformanceReason	
	END
	
	INSERT INTO @perfTab VALUES (@perfDate, @perfTimeNotIncluded, @notPerformed, @codedReason)
	RETURN 
END
GO


create function performanceRecord2(@_date DATETIME, @_min INT, @_performed VARCHAR(255), @_nonPerformanceReason VARCHAR(24), @_reasons ReasonTableType READONLY)
RETURNS
	@perfTab
	TABLE ( perfDate VARCHAR(16), perfTimeNotIncluded VARCHAR(1), notPerformed VARCHAR(1), codedReason VARCHAR(4) ) 
AS
BEGIN
	DECLARE @perfDate VARCHAR(16) = ''
	DECLARE @perfTimeNotIncluded VARCHAR(1) = '1'
	DECLARE @notPerformed VARCHAR(1) = '1'
	DECLARE @codedReason VARCHAR(4) = ''
	
	IF ISNULL(@_performed, 'false') = 'true' 
	BEGIN
		SET @notPerformed = '0'
		IF @_min IS NOT NULL
		BEGIN
			SET @perfTimeNotIncluded = '0'
		END
		SET @perfDate = dbo.makeDateTime(@_date, ISNULL(@_min,0))			
	END
	ELSE
	BEGIN
		SELECT 
			@codedReason = r.ssnap_reason_code
		FROM 
			@_reasons r 
		WHERE
			r.cimms_reason_desc = @_nonPerformanceReason	
	END
	
	INSERT INTO @perfTab VALUES (@perfDate, @perfTimeNotIncluded, @notPerformed, @codedReason)
	RETURN 
END
GO


/*
 * ---
 * PRODUCE YES OR NO ANSWERS - 'Y' if @value1 = @value2
 * --
 */
 
 IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[yesOrNo]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.yesOrNo;
GO

CREATE FUNCTION dbo.yesOrNo(@value1 varchar(255), @value2 varchar(255))
RETURNS VARCHAR(1)
AS
BEGIN
	RETURN 
	CASE 
		WHEN @value1 = @value2 THEN 'Y'
		ELSE 'N'
	END
END
GO

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[zeroOrOne]')
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.zeroOrOne;
GO

CREATE FUNCTION dbo.zeroOrOne(@value1 varchar(255))
RETURNS VARCHAR(1)
AS
BEGIN
	RETURN 
	CASE 
		WHEN ISNULL(@value1,'false') = 'false' THEN '0'
		ELSE '1'
	END
END
GO


IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[propertyParser]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.propertyParser;
GO

CREATE FUNCTION dbo.propertyParser(@properties varchar(max), @propName varchar(32))
RETURNS VARCHAR(1)
AS
BEGIN
	DECLARE @start INT, @end INT, @length INT, @propValue varchar(255), @propPat varchar(34)
	SET @propPat = '%' + @propName + '%'
	SET @propValue = ''
	SET @start = PATINDEX(@propPat, @properties)
	IF @start > 0
	BEGIN
		SET @end = @start + LEN(@propName)
		SET @start = @end +1 
	    SET @propValue = SUBSTRING(@properties,@start,4)
	END
	RETURN 
		CASE 
			WHEN @propValue = 'true' THEN '1'
			ELSE '0'
		END
END
go

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[noThromboReason]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.noThromboReason;
GO

CREATE FUNCTION dbo.noThromboReason()
RETURNS @noThromboReasonTab TABLE(
	hospital_stay_id varchar(255),
	medical_history_id numeric(19,0),
	noThrombolysisOther TINYINT,
	noThrombolysisMedication TINYINT,
	noThrombolysisAge TINYINT,
	noThrombolysisOutsideHours TINYINT,
	noThrombolysisNotAvailable TINYINT,
	noThrombolysisNone TINYINT,
	noThrombolysisRefused TINYINT,
	noThrombolysisTooLate TINYINT,
	noThrombolysisComorbidity TINYINT,
	noThrombolysisScanLate TINYINT,
	noThrombolysisHaemorhagic TINYINT,
	noThrombolysisSymptomsImproving TINYINT,
	noThrombolysisTooMildOrTooSevere TINYINT, 
	noThrombolysisOnsetTimeUnknown TINYINT,
	noThrombolysisReason VARCHAR(4),
	x varchar(max) 
)
AS
BEGIN
	
	INSERT INTO @noThromboReasonTab
	SELECT 
		c.hospital_stay_id AS hospital_stay_id,
		c.medical_history_id AS medical_history_id,
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisOther') ,
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisMedication'),
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisAge' ),
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisOutsideHours'),
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisNotAvailable'),
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisNone'),
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisRefused'),
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisTooLate'),
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisComorbidity'),
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisScanLate'),
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisHaemorhagic'),
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisSymptomsImproving'),
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisTooMildOrTooSevere'), 
		dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisOnsetTimeUnknown'),
		CASE
			WHEN dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisOutsideHours') = 1 THEN  'OTSH'
			WHEN dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisNotAvailable') = 1 THEN  'TNA'
			WHEN dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisScanLate') = 1 THEN  'USQE'
			WHEN dbo.propertyParser( p.care_activity_properties_elt, 'noThrombolysisNone') = 1 THEN  'N'
		END AS noThrombolysisReason,
		p.care_activity_properties_elt
	FROM 
		care_activity AS c				
	LEFT OUTER JOIN 
		care_activity_care_activity_properties p 
			ON p.care_activity_properties = c.id
			AND p.care_activity_properties_idx = 'reasonsNotThrombolysed'
	RETURN
END
GO

/*
 * ---
 * IMAGING TABLE GENERATOR
 * ---
 */
IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[imageRec]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.imageRec;
GO
 
CREATE FUNCTION dbo.imageRec() 
RETURNS @imageTab TABLE (
	medical_history_id numeric(19,0),
	brainImagingDateTime varchar(16) ,
	brainImagingTimeNotEntered TINYINT,
	brainImagingNotPerformed TINYINT,
	strokeType varchar(3),
	imageType varchar(3)
	)
AS
BEGIN
	INSERT INTO @imageTab
    SELECT 
		a.medical_history_id,
		CONVERT (CHAR(10), s.taken_date, 103)
		+ ' ' +
		CONVERT(CHAR(5), DATEADD(minute, s.taken_time, s.taken_date), 114)
		AS takenDatetime, 
		CASE
			WHEN s.taken_time IS NULL THEN 1		
			ELSE 0
		END
		AS timeNotEntered,
		CASE
			WHEN i.scan_post_stroke <> 'yes' THEN 1
			ELSE 0
		END
		AS brainImagingNotPerformed,
		CASE 
			WHEN i.scan_post_stroke = 'yes' AND s.diagnosis_type_id = 2 THEN 'I'
			WHEN i.scan_post_stroke = 'yes' AND s.diagnosis_type_id = 3 THEN 'PIH'
			ELSE ' '
		END
		AS strokeType,
		imgt.description AS imageType
	FROM
		dbo.care_activity AS a
	LEFT OUTER JOIN
		dbo.imaging AS i ON a.imaging_id = i.id
	LEFT OUTER JOIN
		dbo.scan AS s ON i.scan_id = s.id
	JOIN
		dbo.image_type AS imgt ON imgt.id = s.image_type_id
	RETURN
END
GO

/*
 * ---
 * CLINICAL ASSESSMENT TABLE GENERATOR
 * ---
 */
IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[clinicAsmt]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.clinicAsmt;
GO
 
CREATE FUNCTION dbo.clinicAsmt() 
RETURNS @AsmtTab TABLE (
	medical_history_id numeric(19,0),
	hospital_stay_id varchar(255),
	loc_stimulation INT ,
	loc_questions INT,
	loc_tasks INT,
	best_gaze INT,
	hemianopia INT,
	facial_palsy INT,
	left_arm_mrc_scale INT,
	right_arm_mrc_scale INT,
	left_leg_mrc_scale INT,
	right_leg_mrc_scale INT,
	limb_ataxia INT,
	sensory_loss INT,
	aphasia INT,
	dysarthia INT,
	inattention INT
   )
AS
BEGIN
	INSERT INTO @AsmtTab
    SELECT DISTINCT a.medical_history_id, a.hospital_stay_id,
	CASE
		WHEN c.loc_stimulation = 'keen' THEN 3 
		WHEN c.loc_stimulation = 'arousal' THEN 2
		WHEN c.loc_stimulation = 'repeated'  THEN 1
		WHEN c.loc_stimulation = 'unresponsive' THEN 0
		ELSE 0
	END
	AS loc_stimulation,
	CASE
		WHEN c.loc_questions = 'both' THEN 0
		WHEN c.loc_questions = 'one' THEN 1
		WHEN c.loc_questions = 'neither' THEN 2
		ELSE -1
	END
	AS loc_questions,
	CASE
		WHEN c.loc_tasks = 'both' THEN 0
		WHEN c.loc_tasks = 'one' THEN 1
		WHEN c.loc_tasks = 'neither' THEN 2
		ELSE -1
	END
	AS loc_tasks,
	CASE 
		WHEN c.best_gaze = 'normal'  THEN 0
		WHEN c.best_gaze = 'partial' THEN 1
		WHEN c.best_gaze = 'forced'  THEN 2
		ELSE -1
	END
	AS best_gaze,
	CASE
		WHEN c.hemianopia = 'none' THEN 0
		WHEN c.hemianopia = 'partial' THEN 1
		WHEN c.hemianopia = 'complete' THEN 2
		WHEN c.hemianopia = 'bilateral' THEN 3
		ELSe -1
	END
	AS hemianopia,
	CASE
		WHEN c.facial_palsy = 'Normal'   THEN 0
		WHEN c.facial_palsy = 'Minor'    THEN 1
		WHEN c.facial_palsy = 'Partial'  THEN 2
		WHEN c.facial_palsy = 'Complete' THEN 3
		ELSE -1
	END
	AS facial_palsy,
	ISNULL(c.left_arm_mrc_scale, -1)AS left_arm_mrc_scale,
	ISNULL(c.right_arm_mrc_scale, -1) AS right_arm_mrc_scale,
	ISNULL(c.left_leg_mrc_scale, -1) AS left_leg_mrc_scale,
	ISNULL(c.right_leg_mrc_scale, -1) AS right_leg_mrc_scale,
	CASE
		WHEN c.limb_ataxia = 'yes' THEN 0
		WHEN c.limb_ataxia = 'single' THEN 1
		WHEN c.limb_ataxia = 'two' THEN 2
		ELSE -1
	END 
	AS limb_ataxia,
	CASE
		WHEN c.sensory_loss = 'none' THEN 0
		WHEN c.sensory_loss = 'mild' THEN 1
		WHEN c.sensory_loss = 'severe' THEN 2
		ELSE -1
	END AS sensory_loss,
	CASE
		WHEN c.aphasia = 'normal' THEN 0
		WHEN c.aphasia = 'mild'   THEN 1
		WHEN c.aphasia = 'severe' THEN 2
		WHEN c.aphasia = 'global' THEn 3
		ELSE -1 
	END
	AS aphasia,
	CASE 
		WHEN c.dysarthria = 'normal' THEN 0
		WHEN c.dysarthria = 'mild'   THEN 1
		WHEN c.dysarthria = 'severe' THEN 2
		ELSE -1
	END 
	AS dysarthia,
	CASE
		WHEN c.inattention = 'normal'   THEN 0
		WHEN c.inattention = 'single'   THEN 1
		WHEN c.inattention = 'profound' THEN 2
		ELSE -1
	END
	AS inattention
	FROM 
		dbo.clinical_assessment AS c,
		dbo.care_activity AS a
	WHERE
		a.clinical_assessment_id = c.id
	RETURN
END
GO

/*
 * ---
 * RANKIN SCORE TABLE GENERATOR
 * ---
 */
IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[rankinScore]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.rankinScore;
GO
 
CREATE FUNCTION dbo.rankinScore() 
RETURNS @RankinTab TABLE (
   medical_history_id numeric(19,0),
   hospital_stay_id varchar(255),
   pre_admission_rankin integer,
   baseline_rankin integer,
   discharge_rankin integer
   )
AS
BEGIN
	INSERT INTO @RankinTab
    SELECT 
		care.medical_history_id,
		care.hospital_stay_id,
		preRn.modified_rankin_score,
		baseRn.modified_rankin_score,
		dschRn.modified_rankin_score
	FROM		 
		dbo.care_activity AS care
	LEFT OUTER JOIN 
		dbo.therapy_management AS trpy 
		ON care.therapy_management_id = trpy.id		
	LEFT OUTER JOIN 
		dbo.assessment_management AS asmt 
		ON trpy.assessment_management_id = asmt.id
	
	LEFT OUTER JOIN 
		dbo.modified_rankin AS preRn 
		ON preRn.assessment_management_id = asmt.id
	LEFT OUTER JOIN [dbo].[pathway_stage] AS preStage
		ON preStage.description = 'Pre-admission' 
		AND preStage.id = preRn.pathway_stage_id
	
	LEFT OUTER JOIN 
		dbo.modified_rankin AS baseRn 
		ON baseRn.assessment_management_id = asmt.id
	LEFT JOIN [dbo].[pathway_stage] AS baseStage
		ON baseStage.description = 'Baseline' 
		AND baseStage.id = baseRn.pathway_stage_id
	
	LEFT OUTER JOIN 
		dbo.modified_rankin AS dschRn 
		ON dschRn.assessment_management_id = asmt.id
	LEFT OUTER JOIN [dbo].[pathway_stage] AS dschStage
		ON dschStage.description = 'Discharge' 
		AND dschStage.id = dschRn.pathway_stage_id
	
 RETURN
END
GO

/*
 * --
 * Comorbidity
 * --
 */
IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[como]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.como;
go

CREATE FUNCTION dbo.como() 
RETURNS @comoTab TABLE 
	( 
	hospital_stay_id varchar(255),
		previous_stroke varchar(1),
		previous_tia varchar(1),
		diabetes varchar(1),
		atrial_fibrillation varchar(1),
		myocardial_infarction varchar(1),
		hyperlipidaemia varchar(1),
		hypertension varchar(1),
		valvular_heart_disease varchar(1),
		ischaemic_heart_disease varchar(1),
		congestive_heart_failure varchar(1)
     )
AS
BEGIN 
	INSERT INTO @comoTab

	SELECT  
		DISTINCT care.hospital_stay_id, 
		ISNULL(
		(SELECT  
		 CASE
			WHEN como1.value = 'true' THEN 'Y'
			ELSE 'N'
		 END
		 FROM [dbo].[comorbidity] AS como1
		 JOIN [dbo].[comorbidity_type] as como_type1
		 ON como1.type_id = como_type1.id 
		 AND como1.medical_history_id = como.medical_history_id
		 AND como_type1.description = 'previous stroke') ,'N') AS previous_stroke,
		 
		ISNULL(
		(SELECT  
		 CASE
			WHEN como1.value = 'true' THEN 'Y'
			ELSE 'N'
		 END
		 FROM [dbo].[comorbidity] AS como1
		 JOIN [dbo].[comorbidity_type] as como_type1
		 ON como1.type_id = como_type1.id 
		 AND como1.medical_history_id = como.medical_history_id
		 AND como_type1.description = 'previous tia') ,'N') AS previous_tia,	 
		 
		ISNULL(
		(SELECT  
		 CASE
			WHEN como1.value = 'true' THEN 'Y'
			ELSE 'N'
		 END
		 FROM [dbo].[comorbidity] AS como1
		 JOIN [dbo].[comorbidity_type] as como_type1
		 ON como1.type_id = como_type1.id 
		 AND como1.medical_history_id = como.medical_history_id
		 AND como_type1.description = 'diabetes') ,'N') AS diabetes,
		 
		ISNULL(
		(SELECT  
		 CASE
			WHEN como1.value = 'true' THEN 'Y'
			ELSE 'N'
		 END
		 FROM [dbo].[comorbidity] AS como1
		 JOIN [dbo].[comorbidity_type] as como_type1
		 ON como1.type_id = como_type1.id 
		 AND como1.medical_history_id = como.medical_history_id
		 AND como_type1.description = 'atrial fibrillation') ,'N') AS atrial_fibrillation,
		 	

		ISNULL(
		(SELECT  
		 CASE
			WHEN como1.value = 'true' THEN 'Y'
			ELSE 'N'
		 END
		 FROM [dbo].[comorbidity] AS como1
		 JOIN [dbo].[comorbidity_type] as como_type1
		 ON como1.type_id = como_type1.id 
		 AND como1.medical_history_id = como.medical_history_id
		 AND como_type1.description = 'myocardial infarction') ,'N') AS myocardial_infarction,

		ISNULL(
		(SELECT  
		 CASE
			WHEN como1.value = 'true' THEN 'Y'
			ELSE 'N'
		 END
		 FROM [dbo].[comorbidity] AS como1
		 JOIN [dbo].[comorbidity_type] as como_type1
		 ON como1.type_id = como_type1.id 
		 AND como1.medical_history_id = como.medical_history_id
		 AND como_type1.description = 'hyperlipidaemia') ,'N') AS hyperlipidaemia,
		 
		ISNULL(
		(SELECT  
		 CASE
			WHEN como1.value = 'true' THEN 'Y'
			ELSE 'N'
		 END
		 FROM [dbo].[comorbidity] AS como1
		 JOIN [dbo].[comorbidity_type] as como_type1
		 ON como1.type_id = como_type1.id 
		 AND como1.medical_history_id = como.medical_history_id
		 AND como_type1.description = 'hypertension') ,'N') AS hypertension,
		 		 
		
		ISNULL(
		(SELECT  
		 CASE
			WHEN como1.value = 'true' THEN 'Y'
			ELSE 'N'
		 END
		 FROM [dbo].[comorbidity] AS como1
		 JOIN [dbo].[comorbidity_type] as como_type1
		 ON como1.type_id = como_type1.id 
		 AND como1.medical_history_id = como.medical_history_id
		 AND como_type1.description = 'valvular heart disease') ,'N') AS valvular_heart_disease,
		 	 
		ISNULL(
		(SELECT  
		 CASE
			WHEN como1.value = 'true' THEN 'Y'
			ELSE 'N'
		 END
		 FROM [dbo].[comorbidity] AS como1
		 JOIN [dbo].[comorbidity_type] as como_type1
		 ON como1.type_id = como_type1.id 
		 AND como1.medical_history_id = como.medical_history_id
		 AND como_type1.description = 'ischaemic heart disease') ,'N') AS ischaemic_heart_disease,

		ISNULL(
		(SELECT  
		 CASE
			WHEN como1.value = 'true' THEN 'Y'
			ELSE 'N'
		 END
		 FROM 
			[dbo].[comorbidity] AS como1
			
		JOIN [dbo].[comorbidity_type] as como_type1
		 ON como1.type_id = como_type1.id 
		 AND como1.medical_history_id = como.medical_history_id
		 AND como_type1.description = 'congestive heart failure') ,'N') 
		 AS congestive_heart_failure
		 		 
		FROM [dbo].[care_activity] AS care
		LEFT OUTER JOIN  [dbo].[comorbidity] AS como
		ON care.medical_history_id = como.medical_history_id
	RETURN
END
GO

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[como1]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.como1;
go

CREATE FUNCTION dbo.como1() 
RETURNS @comoTab TABLE 
	( 
		previous_stroke varchar(1),
		previous_tia varchar(1),
		diabetes varchar(1),
		atrial_fibrillation varchar(1),
		myocardial_infarction varchar(1),
		hyperlipidaemia varchar(1),
		hypertension varchar(1),
		valvular_heart_disease varchar(1),
		ischaemic_heart_disease varchar(1),
		congestive_heart_failure varchar(1)
     )
AS
BEGIN 
	INSERT INTO @comoTab

	SELECT  

	CASE 
		WHEN ISNULL(previousStroke.value,'false') = 'false' THEN 'N'
		ELSE 'Y'
	END,
	CASE 
		WHEN ISNULL(previousTia.value,'false') = 'false' THEN 'N'
		ELSE 'Y'
	END,
	CASE 
		WHEN ISNULL(diabetes.value,'false') = 'false' THEN 'N'
		ELSE 'Y'
	END,
	CASE 
		WHEN ISNULL(atrialFibrilation.value,'false') = 'false' THEN 'N'
		ELSE 'Y'
	END,
	CASE 
		WHEN ISNULL(mycardialInfarction.value,'false') = 'false' THEN 'N'
		ELSE 'Y'
	END,		
	CASE 
		WHEN ISNULL(_hyperlipidaemia.value,'false') = 'false' THEN 'N'
		ELSE 'Y'
	END,
	CASE 
		WHEN ISNULL(_hypertension.value,'false') = 'false' THEN 'N'
		ELSE 'Y'
	END,
	CASE 
		WHEN ISNULL(valvularHeartDisease.value,'false') = 'false' THEN 'N'
		ELSE 'Y'
	END,
	CASE 
		WHEN ISNULL(ischaemicHeartDisease.value,'false') = 'false' THEN 'N'
		ELSE 'Y'
	END,	
	CASE 
		WHEN ISNULL(congestiveHeartDisease.value,'false') = 'false' THEN 'N'
		ELSE 'Y'
	END
	
	FROM 
		dbo.care_activity AS care
	JOIN [dbo].[comorbidity] AS previousStroke
	ON care.medical_history_id = previousStroke.medical_history_id
	JOIN [dbo].[comorbidity_type] AS previousStroke_d 
		ON previousStroke.type_id = previousStroke_d.id 
		AND previousStroke_d.description = 'previous stroke'

	JOIN [dbo].[comorbidity] AS previousTia 
		ON care.medical_history_id = previousTia.medical_history_id
	JOIN [dbo].[comorbidity_type] AS previousTia_d 
		ON previousTia.type_id = previousTia_d.id 
		AND previousTia_d.description = 'previous tia'

	JOIN [dbo].[comorbidity] AS diabetes 
		ON care.medical_history_id = diabetes.medical_history_id
	JOIN [dbo].[comorbidity_type] AS diabetes_d 
		ON diabetes.type_id = diabetes_d.id 
		AND diabetes_d.description = 'diabetes'

	JOIN [dbo].[comorbidity] AS atrialFibrilation 
		ON care.medical_history_id = atrialFibrilation.medical_history_id
	JOIN [dbo].[comorbidity_type] AS atrialFibrilation_d 
		ON atrialFibrilation.type_id = atrialFibrilation_d.id 
		AND atrialFibrilation_d.description =  'atrial fibrillation'
		
		
		
	JOIN [dbo].[comorbidity] AS mycardialInfarction 
		ON care.medical_history_id = mycardialInfarction.medical_history_id
	JOIN [dbo].[comorbidity_type] AS mycardialInfarction_d 
		ON mycardialInfarction.type_id = mycardialInfarction_d.id 
		AND mycardialInfarction_d.description = 'myocardial infarction'
		
		 
	JOIN [dbo].[comorbidity] AS _hyperlipidaemia 
		ON care.medical_history_id = _hyperlipidaemia.medical_history_id
	JOIN [dbo].[comorbidity_type] AS _hyperlipidaemia_d 
		ON _hyperlipidaemia.type_id = _hyperlipidaemia_d.id 
		AND _hyperlipidaemia_d.description = 'hyperlipidaemia'
	 
		
	JOIN [dbo].[comorbidity] AS _hypertension 
		ON care.medical_history_id = _hypertension.medical_history_id
	JOIN [dbo].[comorbidity_type] AS _hypertension_d 
		ON _hypertension.type_id = _hypertension_d.id 
		AND _hypertension_d.description = 'hypertension'
	 
		
	JOIN [dbo].[comorbidity] AS valvularHeartDisease 
		ON care.medical_history_id = valvularHeartDisease.medical_history_id
	JOIN [dbo].[comorbidity_type] AS valvularHeartDisease_d 
		ON valvularHeartDisease.type_id = valvularHeartDisease_d.id 
		AND valvularHeartDisease_d.description = 'valvular heart disease'
	
	
		
	JOIN [dbo].[comorbidity] AS ischaemicHeartDisease 
		ON care.medical_history_id = ischaemicHeartDisease.medical_history_id
	JOIN [dbo].[comorbidity_type] AS ischaemicHeartDisease_d 
		ON ischaemicHeartDisease.type_id = ischaemicHeartDisease_d.id 
		AND ischaemicHeartDisease_d.description = 'ischaemic heart disease'
	
	
	
	JOIN [dbo].[comorbidity] AS congestiveHeartDisease 
		ON care.medical_history_id = congestiveHeartDisease.medical_history_id
	JOIN [dbo].[comorbidity_type] AS congestiveHeartDisease_d 
		ON congestiveHeartDisease.type_id = congestiveHeartDisease_d.id 
		AND congestiveHeartDisease_d.description = 'congestive heart failure'
	RETURN
END
GO

/*
 * ---
 * THROMBOLYSIS TABLE GENERATOR
 * ---
 */
IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[thromboRec2]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.thromboRec2;
GO
 
CREATE FUNCTION dbo.thromboRec2() 
RETURNS @thromboTab TABLE (
	medical_history_id numeric(19,0),
	hospital_stay_id varchar(255),
	thrombolysis varchar(1),
	takenDatetime varchar(16),
	timeNotEntered varchar(1),
	complications VARCHAR(1),
	complicationHaemorrhage VARCHAR(1),
	complicationOedema VARCHAR(1),
	complicationBleed VARCHAR(1),
	complicationOther VARCHAR(1),
	complicationOtherText varchar(30),
	nihss24Hrs TINYINT,
	nihss24_unknown TINYINT
	)
AS
BEGIN
	INSERT INTO @thromboTab
    SELECT 
		a.medical_history_id,
		a.hospital_stay_id,
		CASE 
			WHEN t.thrombolysis_date IS NULL THEN 'N'
			ELSE 'Y'
		END AS thrombolysis,
		CONVERT (CHAR(10), t.thrombolysis_date, 103)
		+ ' ' +
		CONVERT(CHAR(5), DATEADD(minute, t.thrombolysis_time, t.thrombolysis_date), 114)
		AS takenDatetime, 
		
		CASE
			WHEN t.thrombolysis_date IS NOT NULL THEN 1
			ELSE 0
		END AS timeNotEntered,
		
		CASE
			WHEN t.complications = 1 THEN 'Y'
			ELSE 'N'
		END AS complications,
		
		CASE 
			WHEN t.complications = 1 AND t.complication_type_haemorrhage = 1 THEN '1'			
			ELSE '0'
		END
		AS complicationHaemorrhage,
		
		CASE 
			WHEN t.complications = 1 AND t.complication_type_oedema = 1 THEN '1'			
			ELSE '0'
		END
		AS complicationOedema,
		
		CASE 
			WHEN t.complications = 1 AND t.complication_type_bleed = 1 THEN '1'			
			ELSE '0'
		END
		AS complicationBleed,	
				
		CASE 
			WHEN t.complications = 1 AND t.complication_type_other = 1 THEN '1'			
			ELSE '0'
		END
		AS complicationOther,	
		
		CASE 
			WHEN t.complications = 1 AND t.complication_type_other = 1 THEN complication_type_other_text
			ELSE ''
		END
		AS complicationOtherText,
		
		t.nihss_score_at24hours AS nihss24Hrs,
		t.nihss_score_at24hours_unknown AS nihss24_unknown	
	FROM
		dbo.care_activity AS a
	LEFT OUTER JOIN
		dbo.thrombolysis AS t ON a.thrombolysis_id = t.id
	RETURN
END
GO


IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[withinHours]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.withinHours;
GO

create function withinHours(@startDate DATETIME,@startTime INT, @endDate DATETIME,@endTime INT, @timeWindow INT )
RETURNS INT
AS
BEGIN
	DECLARE @begin DATETIME
	DECLARE @end DATETIME
	DECLARE @duration DATETIME
	DECLARE @timeWindowMinutes INT
	
	SET	@begin = DATEADD(minute, @startTime, @startDate)
	SET @end = DATEADD(minute, @endTime, @endDate)
	SET @timeWindowMinutes = @timeWindow * 60
	
	RETURN 
		CASE 
			WHEN DATEDIFF(minute, @begin, @end) > @timeWindowMinutes THEN 0	
			ELSE 1
		END
END
GO

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[getNoSwallowScreenCode]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.getNoSwallowScreenCode;
GO

create function getNoSwallowScreenCode(@cimms_noswallow_desc varchar(255) )
RETURNS VARCHAR(2)
AS
BEGIN
	
	RETURN 
		CASE 
			WHEN @cimms_noswallow_desc = 'impaired' THEN ''
			WHEN @cimms_noswallow_desc = 'unknown' THEN 'NK'
			WHEN @cimms_noswallow_desc = 'palliative' THEN ''
			WHEN @cimms_noswallow_desc = 'refused' THEN 'PR'
			WHEN @cimms_noswallow_desc = 'unwell' THEN 'PU'
			WHEN @cimms_noswallow_desc = 'noproblem' THEN ''
			WHEN @cimms_noswallow_desc = 'organisational' THEN 'OR'
			ELSE ''
		END
END
GO

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[swallowScreen]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.swallowScreen;
GO

CREATE FUNCTION dbo.swallowScreen()
RETURNS @swallowScreenTab TABLE(
	hospital_stay_id varchar(255),
	medical_history_id numeric(19,0),
	swallowScreen4hrsDateTime varchar(16),
	swallowScreen4hrsTimeNotEntered TINYINT,
	swallowScreen4hrsNotPerformed TINYINT,
	swallowScreen4hrsNotPerformedReason CHAR(2),
	swallowScreen72hrsDateTime varchar(16),
	swallowScreen72hrsTimeNotEntered TINYINT,
	swallowScreen72hrsNotPerformed TINYINT,
	swallowScreen72hrsNotPerformedReason CHAR(2),
	admissionDate varchar(16)
)
AS
BEGIN	
	INSERT INTO @swallowScreenTab
	SELECT 
		c.hospital_stay_id AS hospital_stay_id,
		c.medical_history_id AS medical_history_id,
		
		CASE
			WHEN s.swallow_screen_date IS NULL THEN ''
			WHEN s.swallow_screen_performed = 1 THEN dbo.makeDatetime(s.swallow_screen_date, s.swallow_screen_time)
			WHEN dbo.withinHours(c.start_date, c.start_time, s.swallow_screen_date, s.swallow_screen_time, 4) = 1 THEN dbo.makeDatetime(s.swallow_screen_date, s.swallow_screen_time) 
			ELSE ''
		END AS swallowScreen4hrsDateTime,
								
		CASE
			WHEN s.swallow_screen_time IS NULL THEN 1 
			ELSE 0
		END 
		AS swallowScreen4hrsTimeNotEntered,
		
		CASE 
			WHEN s.swallow_screen_date IS NULL THEN 0
			WHEN s.swallow_screen_performed = 0 THEN 1 
			WHEN NOT dbo.withinHours(c.start_date, c.start_time, s.swallow_screen_date, s.swallow_screen_time, 4) = 1 THEN 1
			ELSE 0
		END AS swallowScreen4hrsNotPerformed,		
		
		CASE
			WHEN s.swallow_screen_date IS NULL THEN 'NK'
			WHEN s.swallow_screen_performed = 0 THEN dbo.getNoSwallowScreenCode(r4.description)
			WHEN NOT dbo.withinHours(c.start_date, c.start_time, s.swallow_screen_date, s.swallow_screen_time, 4) = 1 THEN dbo.getNoSwallowScreenCode(r4.description)
			ELSE ''
		END AS swallowScreen4hrsNotPerformedReason,
		
		CASE
			WHEN s.swallow_screen_date IS NULL THEN ''
			WHEN s.swallow_screen_performed = 1 THEN dbo.makeDatetime(s.swallow_screen_date, s.swallow_screen_time)
			WHEN dbo.withinHours(c.start_date, c.start_time, s.swallow_screen_date, s.swallow_screen_time, 72) = 1 THEN dbo.makeDatetime(s.swallow_screen_date, s.swallow_screen_time) 
			ELSE ''
		END AS swallowScreen72hrsDateTime,
	
		CASE
			WHEN s.swallow_screen_time IS NULL THEN 1 
			ELSE 0
		END 
		AS swallowScreen72hrsTimeNotEntered,
						
		CASE
			WHEN s.swallow_screen_date IS NULL THEN 0
			WHEN s.swallow_screen_performed = 0 THEN 1
			WHEN NOT dbo.withinHours(c.start_date, c.start_time, s.swallow_screen_date, s.swallow_screen_time, 72) = 1 THEN 1
			ELSE 0
		END AS swallowScreen72hrsNotPerformed,

		
		CASE
			WHEN s.swallow_screen_date IS NULL THEN 'NK'
			WHEN s.swallow_screen_performed = 1 THEN dbo.getNoSwallowScreenCode(r72.description)
			WHEN NOT dbo.withinHours(c.start_date, c.start_time, s.swallow_screen_date, s.swallow_screen_time, 72) = 1 THEN dbo.getNoSwallowScreenCode(r72.description)
			ELSE ''
		END AS swallowScreen72hrsNotPerformedReason,
		dbo.makeDatetime(c.start_date, c.start_time)

	FROM 
		care_activity AS c 	
	JOIN
		clinical_assessment s
		ON c.clinical_assessment_id = s.id	
	LEFT OUTER JOIN
		no_swallow_screen_performed_reason_type as r4
		ON s.no_swallow_screen_performed_reason_at4hours_id = r4.id
	LEFT OUTER JOIN
		no_swallow_screen_performed_reason_type as r72
		ON s.no_swallow_screen_performed_reason_id = r72.id	
	RETURN
END
GO

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[medical_history_rec]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.medical_history_rec;
GO

CREATE FUNCTION dbo.medical_history_rec()
RETURNS @medicalHistoryTab TABLE(
	medical_history_id numeric(19,0),
	previous_tia VARCHAR(2),
	assessed_in_vascular_clinic VARCHAR(1)
)
AS
BEGIN	
	INSERT INTO @medicalHistoryTab
	SELECT 
		s.id AS medical_history_id,
		
		CASE
			WHEN s.previous_tia IS NULL THEN 'NK'
			WHEN s.previous_tia = 'yesWithinMonth' THEN 'Y'
			ELSE 'N'
		END AS previous_tia,
								
		CASE
			WHEN s.previous_tia <> 'yesWithinMonth' THEN  ''
			WHEN s.assessed_in_vascular_clinic = 1 THEN 'Y'
			ELSE 'N' 
		END 
		AS assessed_in_vascular_clinic

	FROM 
		medical_history AS s
	RETURN
END
GO

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[barthelRec]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.barthelRec;
GO

CREATE FUNCTION dbo.barthelRec(@stage varchar(20))
RETURNS @barthelTab TABLE(
	medical_history_id numeric(19,0),
	hospital_stay_id varchar(255),
	barthel_score TINYINT,
	barthel_id TINYINT
)
AS
BEGIN	
	INSERT INTO @barthelTab
	SELECT 
		c.medical_history_id AS medical_history_id,
		c.hospital_stay_id AS hospital_stay_id,
		CASE
			WHEN b.bowels >=0  OR b.bladder >=0 OR b.grooming >=0 OR b.toilet >=0 OR b.feeding  >=0	
			OR b.transfer  >=0 OR b.mobility  >=0 OR b.dressing >=0 OR b.stairs  >=0 OR b.bathing  >=0
 THEN (b.bowels +  b.bladder +  b.grooming  +  b.toilet + b.feeding + b.transfer   +  b.mobility   +  b.dressing  +  b.stairs  + b.bathing)
			ELSE b.manual_total
		END AS barthel_score,
		b.id AS barthel_id
								
		

	FROM 
		dbo.care_activity AS c
	LEFT OUTER JOIN
		dbo.therapy_management as thmg
		ON c.therapy_management_id = thmg.id
	LEFT OUTER JOIN
		dbo.assessment_management AS asmg
		ON thmg.assessment_management_id = asmg.id
	LEFT OUTER JOIN
		dbo.barthel AS b
		ON b.assessment_management_id = asmg.id
	JOIN
		dbo.pathway_stage AS pstg
		ON b.pathway_stage_id = pstg.id 
		AND pstg.description = @stage	
	RETURN
END
GO

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[clSmry]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.clSmry;
GO

CREATE FUNCTION dbo.clSmry()
RETURNS @smryTab TABLE(
	medical_history_id numeric(19,0),
	hospital_stay_id varchar(255),
	palliativeCare varchar(1),
	palliativeCareDecisionDate varchar(10),
	endOfLifePathway varchar(1),
	locWorst7Days TINYINT,
	urinaryTractInfection7Days  varchar(2),
	pneumoniaAntibiotics7Days  varchar(2),
	palliativeCareByDischarge VARCHAR(1),
	palliativeCareByDischargeDate VARCHAR(10),
	endOfLifePathwayByDischarge VARCHAR(1)
)
AS
BEGIN	
	INSERT INTO @smryTab
	SELECT 
		c.medical_history_id AS medical_history_id,
		c.hospital_stay_id AS hospital_stay_id,
		CASE
			WHEN ISNULL(s.palliative_care,'no') = 'no' THEN 'N'
			WHEN dbo.withinHours(c.start_date, c.start_time, s.palliative_care_date, 0, 72) = 1 THEN 'Y'
			ELSE 'N'
		END
		AS palliativeCare,
		CASE
			WHEN ISNULL(s.palliative_care,'no') = 'no' THEN ''
			WHEN s.palliative_care_date IS NULL THEN ''
			WHEN dbo.withinHours(c.start_date, c.start_time, s.palliative_care_date, 0, 72) = 1 THEN CONVERT( varchar(10), s.palliative_care_date, 103 )
		END
		AS palliativeCareDecisionDate,
		CASE
			WHEN ISNULL(s.palliative_care,'no') = 'no' THEN ''
			WHEN s.end_of_life_pathway = 'yes' THEN 'Y'
			ELSE 'N'
		END
		AS endOfLifePathway,
		CASE
			WHEN ISNULL(loc.description, 'fully') = 'fully' THEN 0
			WHEN loc.description = 'drowsy' THEN 1
			WHEN loc.description = 'semi' THEN 2
			WHEN loc.description = 'unconscious' THEN 3
		END AS locWorst7Days,
		CASE
			WHEN ISNULL(s.[urinary_tract_infection],'notknown') = 'notknown' THEN 'NK'
			WHEN s.[urinary_tract_infection] = 'yes' THEN 'Y'
			WHEN s.[urinary_tract_infection] = 'no' THEN 'N'
			ELSE ''
		END AS urinaryTractInfection7Days,
		CASE
			WHEN ISNULL(s.[new_pneumonia],'notknown') = 'notknown' THEN 'NK'
			WHEN s.[new_pneumonia] = 'yes' THEN 'Y'
			WHEN s.[new_pneumonia] = 'no' THEN 'N'
			ELSE ''
		END AS pneumoniaAntibiotics7Days,
		CASE
			WHEN ISNULL(s.palliative_care,'no') = 'no' THEN 'N'
			WHEN dbo.withinHours(c.start_date, c.start_time, s.palliative_care_date, 0, 72) = 0 THEN 'Y'
			ELSE ''
		END
		AS palliativeCareByDischarge,
		CASE
			WHEN ISNULL(s.palliative_care,'no') = 'no' THEN ''
			WHEN dbo.withinHours(c.start_date, c.start_time, s.palliative_care_date, 0, 72) = 0 THEN CONVERT( varchar(10), s.palliative_care_date, 103 )
			ELSE ''
		END
		AS palliativeCareByDischargeDate,
		CASE
			WHEN ISNULL(s.palliative_care,'no') = 'no' THEN ''
			WHEN dbo.withinHours(c.start_date, c.start_time, s.palliative_care_date, 0, 72) = 1 THEN ''
			WHEN s.end_of_life_pathway = 'yes' THEN 'Y'
			ELSE 'N'
		END
		AS endOfLifePathwayByDischarge
	FROM 
		dbo.care_activity AS c
	LEFT OUTER JOIN
		dbo.clinical_summary AS s
		ON c.clinical_summary_id = s.id
	JOIN
		dbo.level_of_consciousness AS loc
		ON loc.id = s.worst_level_of_consciousness_id
	RETURN
END
GO

--
-- Stroke Onset 
--
IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[strkOnset]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.strkOnset;
GO

CREATE FUNCTION dbo.strkOnset()
RETURNS @strkOnsetTab TABLE(
	care_activity_id numeric(19,0),
	medical_history_id numeric(19,0),
	hospital_stay_id varchar(255),
	strokeNurseAssessedDateTime varchar(16),
	strokeNurseAssessedTimeNotEntered char(1),
	strokeNurseNotAssessed char(1),
	strokeConsultantAssessedDateTime varchar(16),
	strokeConsultantAssessedTimeNotEntered char(1),
	strokeConsultantNotAssessed VARCHAR(10)
)
AS
BEGIN	
	INSERT INTO @strkOnsetTab
	SELECT
		c.id AS care_activity_id, 
		c.medical_history_id AS medical_history_id,
		c.hospital_stay_id AS hospital_stay_id,
		ISNULL(dbo.makeDateTime( ne.date_evaluated, ne.time_evaluated),'') AS strokeNurseAssessedDateTime,
		CASE
			WHEN ne.time_evaluated IS NULL THEN '1'
			ELSE '0'
		END
		AS strokeNurseAssessedTimeNotEntered,
		
		CASE
			WHEN np.care_activity_properties_elt IS NULL THEN ''
			WHEN np.care_activity_properties_elt = 'true' THEN '1'
			ELSE '0'
		END
		AS strokeNurseNotAssessed,
		
		ISNULL(dbo.makeDateTime( de.date_evaluated, de.time_evaluated),'') AS strokeConsultantAssessedDateTime,
		CASE
			WHEN de.time_evaluated IS NULL THEN '1'
			ELSE '0'
		END
		AS strokeConsultantAssessedTimeNotEntered,
				
		CASE
			WHEN dp.care_activity_properties_elt IS NULL THEN ''
			WHEN dp.care_activity_properties_elt = 'true' THEN '1'
			ELSE dp.care_activity_properties_elt
		END 
		AS strokeConsultantNotAssessed		
		
	FROM 
		dbo.care_activity AS c
	LEFT OUTER JOIN
		dbo.evaluation AS ne
		ON ne.care_activity_id = c.id
		AND ne.evaluator_id = 2
	LEFT OUTER JOIN
		dbo.evaluation AS de
		ON de.care_activity_id = c.id
		AND de.evaluator_id = 3	
	LEFT OUTER JOIN 
		care_activity_care_activity_properties np 
			ON np.care_activity_properties = c.id
			AND np.care_activity_properties_idx = 'Ward based nurse not seen'		
	LEFT OUTER JOIN 
		care_activity_care_activity_properties dp 
			ON  c.id = dp.care_activity_properties
			AND dp.care_activity_properties_idx = 'Stroke consultant not seen'		

	RETURN
END
GO

--
-- OCCUPATIONAL THERAPY ASSESSMENT
--


IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[occThrpy]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.occThrpy;
GO





CREATE FUNCTION dbo.occThrpy()
RETURNS @occThrpyTab TABLE(
	care_activity_id numeric(19,0),
	medical_history_id numeric(19,0),
	hospital_stay_id varchar(255),
	occTherapist72HrsDateTime varchar(16),  
	occTherapist72HrsTimeNotEntered char(1),
	occTherapist72HrsNotAssessed char(64),
	occTherapist72HrsNotAssessedReason char(2),
	therapyRequired VARCHAR(1),
	therapyDays VARCHAR(4),
	therapyMinutes VARCHAR(6),
	occTherapistByDischargeDateTime varchar(16),
	occTherapistByDischargeTimeNotEntered varchar(1),
	occTherapistByDischargeNotAssessed varchar(1),
	occTherapistByDischargeNotAssessedReason varchar(2),
	moodScreeningDate varchar(16),
	moodScreeningNoScreening varchar(1),
	moodScreeningnoScreeningReaaon varchar(2),
	cognitionScreeningDate varchar(16),
	cognitionScreeningNoScreening varchar(1),
	cognitionScreeningNoScreeningReaaon varchar(2),
	firstRehabGoalsDate VARCHAR(1)
)
AS
BEGIN	
	/*
	-- POPULATE Reasons for non-performance
	--
	*/

	DECLARE @MoodScreenNotPerformedReason AS [dbo].[ReasonTableType];
	INSERT 
		INTO @MoodScreenNotPerformedReason 
		VALUES 
			('organisational', 'OR'),
			('unknown', 'NK'),
			('unwell',  'MU'),
			('refused', 'PR'),
			('notRequired',NULL),
			('notFit',	NULL),
			('palliative',	NULL),
			('noproblem',	NULL);


	DECLARE @CognitiveAssessmentNotPerformedReason AS [dbo].[ReasonTableType];
	INSERT 
		INTO @CognitiveAssessmentNotPerformedReason 
		VALUES 
			('organisational', 'OR'),
			('unknown', 'NK'),
			('unwell',  'MU'),
			('refused', 'PR'),
			('died',	NULL),
			('unconcious',	NULL),
			('palliative',	NULL),
			('none',	NULL);
		
	INSERT INTO @occThrpyTab
	SELECT
		c.id AS care_activity_id, 
		c.medical_history_id AS medical_history_id,
		c.hospital_stay_id AS hospital_stay_id,
		
		CASE
			WHEN o.assessment_performed <> 1 THEN ''
			WHEN o.assessment_date IS NULL THEN  ''
			ELSE dbo.makeDateTime( o.assessment_date, o.assessment_time) 
		END AS occTherapist72HrsDateTime,
		
		CASE
			WHEN o.assessment_time IS NULL THEN '1'
			ELSE '0'
		END
		AS occTherapist72HrsTimeNotEntered,
		
		CASE
			WHEN ISNULL(o.assessment_performed,0) = 0 THEN '0'
			ELSE '1'
		END 
		AS occTherapist72HrsNotAssessed,
		
		CASE
			WHEN o.assessment_performed <> 1 THEN ''
			WHEN o.assessment_date IS NOT NULL THEN ''
			WHEN r.description IS NULL THEN ''
			WHEN r.description = 'organisational' THEN 'OR'
			WHEN r.description = 'refused' THEN 'PR'
			WHEN r.description = 'unwell' THEN 'PU'
			WHEN r.description = 'noproblem' THEN 'ND'
			ELSE 'NK'
		END
		AS occTherapist72HrsNotAssessedReason,
		CASE 
			WHEN ISNULL(o.therapy_required,0) = 0 THEN 'N' 
			ELSE  'Y'
		END AS therapyRequired,
		
		ISNULL(o.days_of_therapy,0) AS therapyDays,
		ISNULL(o.minutes_of_therapy,0) AS therapyMinutes,
		
		CASE
			WHEN o.assessment_performed <> 1 THEN ''
			WHEN o.assessment_date IS NULL THEN  ''
			ELSE dbo.makeDateTime( o.assessment_date, o.assessment_time) 
		END AS occTherapistByDischargeDateTime,
		
		CASE
			WHEN o.assessment_time IS NULL THEN '1'
			ELSE '0'
		END
		AS occTherapistByDischargeTimeNotEntered,
		
		CASE
			WHEN o.assessment_performed <> 1 THEN '0'
			ELSE '1'
		END 
		AS occTherapistByDischargeNotAssessed,
		
		CASE
			WHEN o.assessment_performed <> 1 THEN ''
			WHEN o.assessment_date IS NOT NULL THEN ''
			WHEN r.description IS NULL THEN ''
			WHEN r.description = 'organisational' THEN 'OR'
			WHEN r.description = 'refused' THEN 'PR'
			WHEN r.description = 'unwell' THEN 'PU'
			WHEN r.description = 'noproblem' THEN 'ND'
			ELSE 'NK'
		END
		AS occTherapistByDischargeNotAssessedReason,
		
		
		moodAsmtPerf.perfDate AS moodScreeningDate,
		moodAsmtPerf.notPerformed AS moodScreeningNoScreening,
		moodAsmtPerf.codedReason AS moodScreeningnoScreeningReaaon,
		
		cognAsmtPerf.perfDate AS cognitionScreeningDate,
		cognAsmtPerf.notPerformed AS cognitionScreeningNoScreening,
		cognAsmtPerf.codedReason AS cognitionScreeningNoScreeningReason,
		'' AS firstRehabGoalsDate
	FROM 
		dbo.care_activity AS c
	LEFT OUTER JOIN
		dbo.therapy_management t
		ON c.therapy_management_id = t.id
	LEFT OUTER JOIN
		dbo.occupational_therapy_management AS o
		ON t.occupational_therapy_management_id = o.id
	JOIN
		dbo.occupational_therapy_no_assessment_reason_type AS r	
		ON o.no_assessment_reason_type_id = r.id
	JOIN
		dbo.occupational_therapy_no_assessment_reason_type AS mr	
		ON o.no_mood_assessment_reason_type_id = mr.id
	JOIN
		dbo.occupational_therapy_no_assessment_reason_type AS cr	
		ON t.cognitive_status_no_assessment_type_id = cr.id
	CROSS APPLY
		dbo.performanceRecord2(
			o.mood_assessment_date,
			o.mood_assessment_time,
			o.mood_assessment_performed, 
			mr.description, 
			@MoodScreenNotPerformedReason) AS moodAsmtPerf
	CROSS APPLY
		dbo.performanceRecord(
			t.cognitive_status_assessment_date,
			t.cognitive_status_assessment_time,
			t.cognitive_status_assessed, 
			cr.description, 
			@CognitiveAssessmentNotPerformedReason) AS cognAsmtPerf	 
	RETURN
END
GO

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[physio]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.physio;
GO

CREATE FUNCTION dbo.physio()
RETURNS @physioTab TABLE(
	care_activity_id numeric(19,0),
	medical_history_id numeric(19,0),
	hospital_stay_id varchar(255),
	physio_id numeric(19,0),
	physio72HrsDateTime varchar(16),
	physio72HrsTimeNotEntered varchar(1),
	physio72HrsNotAssessed varchar(1),
	physio72HrsNotAssessedReason  varchar(2),
	physioRequired VARCHAR(1),
	physioDays VARCHAR(4),
	physioMinutes VARCHAR(6),
	physioByDischargeDateTime varchar(16),
	physioByDischargeTimeNotEntered varchar(1),
	physioByDischargeNotAssessed varchar(1),
	physioByDischargeNotAssessedReason  varchar(2)
)
AS
BEGIN	
	INSERT INTO @physioTab
	SELECT
		c.id AS care_activity_id, 
		c.medical_history_id AS medical_history_id,
		c.hospital_stay_id AS hospital_stay_id,
		o.id,
		CASE
			WHEN o.assessment_performed <> 1 THEN ''
			WHEN o.assessment_date IS NULL THEN  ''
			ELSE dbo.makeDateTime( o.assessment_date, o.assessment_time) 
		END AS physio72HrsDateTime,
		
		CASE
			WHEN o.assessment_time IS NULL THEN '1'
			ELSE '0'
		END
		AS physio72HrsTimeNotEntered,
		
		CASE
			WHEN o.assessment_performed IS NULL THEN '1'			
			WHEN o.assessment_performed = 1 THEN ''
			WHEN dbo.withinHours(c.start_date, c.start_time, o.assessment_date, o.assessment_time, 72) = 1 THEN '0'
			ELSE '1'
		END 
		AS physio72HrsNotAssessed,
		
		CASE			
			WHEN o.assessment_performed = 1 THEN ''			
			--WHEN dbo.withinHours(c.start_date, c.start_time, o.assessment_date, o.assessment_time, 72) = 1 THEN ''
			WHEN r.description IS NULL THEN 'NK'
			WHEN r.description = 'organisational' THEN 'OR'
			WHEN r.description = 'refused' THEN 'PR'
			WHEN r.description = 'unwell' THEN 'PU'
			WHEN r.description = 'noDeficit' THEN 'ND'
			ELSE 'NK'
		END
		AS physio72HrsNotAssessedReason,
		
		CASE 
			WHEN ISNULL(o.therapy_required,0) = 0 THEN 'N' 
			ELSE  'Y'
		END AS physioRequired,
		
		ISNULL(o.days_of_therapy,'0') AS physioDays,
		ISNULL(o.minutes_of_therapy,'0') AS physioMinutes,
		
		
		CASE
		 
			WHEN ISNULL(o.assessment_performed,0) = 0 THEN ''
			WHEN r.description = 'noDeficit' THEN ''
			WHEN dbo.withinHours(c.start_date, c.start_time, o.assessment_date, o.assessment_time, 72) = 1 THEN ''
			WHEN pas.S7StrokeUnitDischargeDateTime is null THEN ''
			WHEN DATEDIFF(MINUTE, pas.S7StrokeUnitDischargeDateTime, DATEADD(minute, ISNULL(o.assessment_time, 0), o.assessment_date)) < 0 THEN ''
			ELSE dbo.makeDateTime(o.assessment_date, ISNULL(o.assessment_time, 0)) 
			 
		END
		AS physioByDischargeDateTime,
		
		
		CASE
			WHEN o.assessment_time IS NULL THEN '1'
			ELSE '0'
		END
		AS physioByDischargeTimeNotEntered,
		
		CASE
			WHEN ISNULL(o.assessment_performed, 0) = 0 THEN '1'
			ELSE '0'
		END 
		AS physioByDischargeNotAssessed,
		
		CASE			
			WHEN ISNULL(o.assessment_performed,0) = 1 THEN ''
			WHEN r.description IS NULL THEN 'NK'
			WHEN r.description = 'organisational' THEN 'OR'
			WHEN r.description = 'refused' THEN 'PR'
			WHEN r.description = 'unwell' THEN 'MU'
			WHEN r.description = 'noDeficit' THEN 'ND'
			ELSE 'NK'
		END
		AS physioByDischargeNotAssessedReason		
		
	FROM 
		dbo.care_activity AS c
	LEFT OUTER JOIN
		dbo.therapy_management t
		ON c.therapy_management_id = t.id
	LEFT OUTER JOIN
		dbo.physiotherapy_management AS o
		ON t.physiotherapy_management_id = o.id
	LEFT OUTER JOIN
		dbo.physiotherapy_no_assessment_reason_type AS r	
		ON o.no_assessment_reason_type_id = r.id
	LEFT OUTER JOIN 
		dbo.PAS AS pas
		ON convert(varchar(255),pas.spell_id) = c.hospital_stay_id
	
	RETURN
END
GO

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[spchThpy]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.spchThpy;
GO

CREATE FUNCTION dbo.spchThpy()
RETURNS @spchThpyTab TABLE(
	care_activity_id numeric(19,0),
	medical_history_id numeric(19,0),
	hospital_stay_id varchar(255),
	spchThpy_id numeric(19,0),
	spchThpyComms72HrsDateTime varchar(16),
	spchThpyComms72HrsTimeNotEntered varchar(1),
	spchThpyComms72HrsNotAssessed varchar(1),
	spchThpyComms72HrsNotAssessedReason  varchar(2),
	spchThpySwallow72HrsDateTime varchar(16),
	spchThpySwallow72HrsTimeNotEntered varchar(1),
	spchThpySwallow72HrsNotAssessed varchar(1),
	spchThpySwallow72HrsNotAssessedReason  varchar(2),
	therapyRequired VARCHAR(1),
	therapyDays VARCHAR(4),
	therapyMinutes VARCHAR(6),
	spchThpyCommsByDischargeDateTime varchar(16),
	spchThpyCommsByDischargeTimeNotEntered varchar(1),
	spchThpyCommsByDischargeNotAssessed varchar(1),
	spchThpyCommsByDischargeNotAssessedReason  varchar(2),
	spchThpySwallowByDischargeDateTime varchar(16),
	spchThpySwallowByDischargeTimeNotEntered varchar(1),
	spchThpySwallowByDischargeNotAssessed varchar(1),
	spchThpySwallowByDischargeNotAssessedReason  varchar(2)
	
)
AS
BEGIN	
	INSERT INTO @spchThpyTab
	SELECT	
		c.id AS care_activity_id, 		
		c.medical_history_id AS medical_history_id,		
		c.hospital_stay_id AS hospital_stay_id,
		o.id,		
		
		CASE 
			WHEN o.communication_assessment_performed <> 1 THEN ''
			ELSE dbo.makeDateTime(o.communication_assessment_date, o.communication_assessment_time) 
		END 
		AS spchThpyComms72HrsDateTime,
				
		CASE
			WHEN o.communication_assessment_time IS NULL THEN '1'
			ELSE '0'
		END
		AS spchThpyComms72HrsTimeNotEntered,
		
		CASE
			WHEN o.communication_assessment_performed IS NULL THEN '1'			
			WHEN o.communication_assessment_performed = 1 THEN ''
			WHEN dbo.withinHours(c.start_date, c.start_time, o.communication_assessment_date, o.communication_assessment_time, 72) = 1 THEN 0
			ELSE 1
		END 
		AS spchThpyComms72HrsNotAssessed,
		
		CASE			
			WHEN o.communication_assessment_performed = 1 THEN ''						
			WHEN ncr.description IS NULL THEN 'NK'
			WHEN ncr.description = 'organisational' THEN 'OR'
			WHEN ncr.description = 'refused' THEN 'PR'
			WHEN ncr.description = 'unwell' THEN 'PU'
			WHEN ncr.description = 'noproblem' THEN 'ND'
			ELSE 'NK'
		END
		AS spchThpyComms72HrsNotAssessedReason,
		
		

		CASE 
			WHEN o.communication_assessment_performed <> 1 THEN ''
			ELSE dbo.makeDateTime(o.communication_assessment_date, o.communication_assessment_time) 
		END 
		AS spchThpySwallow72HrsDateTime,
		
		
		CASE
			WHEN o.communication_assessment_time IS NULL THEN '1'
			ELSE '0'
		END
		AS spchThpySwallow72HrsTimeNotEntered,
		
		CASE
			WHEN o.swallowing_assessment_performed IS NULL THEN '1'			
			WHEN o.swallowing_assessment_performed = 1 THEN ''
			WHEN dbo.withinHours(c.start_date, c.start_time, o.swallowing_assessment_date, o.swallowing_assessment_time, 72) = 1 THEN 0
			ELSE 1
		END 
		AS spchThpySwallow72HrsNotAssessed,
		
		CASE			
			WHEN o.swallowing_assessment_performed = 1 THEN ''						
			WHEN nsr.description IS NULL THEN 'NK'
			WHEN nsr.description = 'organisational' THEN 'OR'
			WHEN nsr.description = 'refused' THEN 'PR'
			WHEN nsr.description = 'unwell' THEN 'PU'
			WHEN nsr.description = 'noproblem' THEN 'ND'
			WHEN nsr.description = 'passedswallowscreen' THEN 'PS'
			ELSE 'NK'
		END
		AS spchThpySwallow72HrsNotAssessedReason,
		
		--
		
		CASE 
			WHEN ISNULL(o.therapy_required,0) = 0 THEN 'N' 
			ELSE  'Y'
		END AS therapyRequired,
		
		ISNULL(o.days_of_therapy,0) AS therapyDays,
		ISNULL(o.minutes_of_therapy,0) AS therapyMinutes,
		
		 --
		 
		CASE 
			WHEN o.communication_assessment_performed <> 1 THEN ''
			WHEN o.swallowing_assessment_date IS NULL THEN ''
			WHEN nsr.description = 'noproblem' THEN ''
			WHEN dbo.withinHours(c.start_date, c.start_time, o.swallowing_assessment_date, o.swallowing_assessment_time, 72) = 1 THEN ''
			WHEN pas.S7StrokeUnitDischargeDateTime IS NULL  THEN ''
			WHEN DATEDIFF(MINUTE, pas.S7StrokeUnitDischargeDateTime, DATEADD(minute, ISNULL(o.swallowing_assessment_time, 0), o.swallowing_assessment_date)) < 0 THEN ''
			ELSE dbo.makeDateTime(o.communication_assessment_date, o.communication_assessment_time) 
		END 
		AS spchThpyCommsByDischargeDateTime,
				
		CASE
			WHEN o.communication_assessment_time IS NULL THEN '1'
			ELSE '0'
		END
		AS spchThpyCommsByDischargeTimeNotEntered,
		
		CASE
			WHEN ISNULL(o.communication_assessment_performed,0) = 1 THEN '0'			
			ELSE '1'
		END 
		AS spchThpyCommsByDischargeNotAssessed,
		
		CASE			
			WHEN ISNULL(o.communication_assessment_performed,0) = 1 THEN ''						
			WHEN ncr.description IS NULL THEN 'NK'
			WHEN ncr.description = 'organisational' THEN 'OR'
			WHEN ncr.description = 'refused' THEN 'PR'
			WHEN ncr.description = 'unwell' THEN 'PU'
			WHEN ncr.description = 'noproblem' THEN 'ND'
			ELSE 'NK'
		END
		AS spchThpyCommsByDischargeNotAssessedReason,
		
		
		CASE /* --- */
			WHEN ISNULL(o.swallowing_assessment_performed,0) = 0 THEN ''
			WHEN nsr.description = 'passedswallowscreen' THEN ''
			WHEN dbo.withinHours(c.start_date, c.start_time, o.swallowing_assessment_date, o.swallowing_assessment_time, 72) = 1 THEN ''
			WHEN pas.S7StrokeUnitDischargeDateTime IS NULL  THEN ''
			WHEN DATEDIFF(MINUTE, pas.S7StrokeUnitDischargeDateTime, DATEADD(minute, ISNULL(o.swallowing_assessment_time, 0), o.swallowing_assessment_date)) < 0 THEN ''
			ELSE dbo.makeDateTime(o.swallowing_assessment_date, o.swallowing_assessment_time) 
			 
		END 
		AS spchThpySwallowByDischargeDateTime,
		
		
		CASE
			WHEN o.communication_assessment_time IS NULL THEN '1'
			ELSE '0'
		END
		AS spchThpySwallowByDischargeTimeNotEntered,
		
		CASE
			WHEN ISNULL(o.swallowing_assessment_performed, 0) = 0 THEN '1'
			ELSE 1
		END 
		AS spchThpySwallowByDischargeNotAssessed,
		
		CASE			
			WHEN ISNULL(o.swallowing_assessment_performed,0) = 1 THEN ''						
			WHEN nsr.description IS NULL THEN 'NK'
			WHEN nsr.description = 'organisational' THEN 'OR'
			WHEN nsr.description = 'refused' THEN 'PR'
			WHEN nsr.description = 'unwell' THEN 'MU'
			ELSE 'NK'
		END
		AS spchThpySwallowByDischargeNotAssessedReason		

		
	FROM 
		dbo.care_activity AS c
	LEFT OUTER JOIN
		dbo.therapy_management t
		ON c.therapy_management_id = t.id
	LEFT OUTER JOIN
		dbo.speech_and_language_therapy_management AS o
		ON t.speech_and_language_therapy_management_id = o.id
	LEFT OUTER JOIN
		dbo.communication_no_assessment_reason_type AS ncr	
		ON o.no_communication_assessment_reason_type_id = ncr.id
	LEFT OUTER JOIN
		dbo.swallowing_no_assessment_reason_type AS nsr
		ON o.no_swallowing_assessment_reason_type_id = nsr.id
	LEFt OUTER JOIN 
		dbo.pas AS pas
		ON c.hospital_stay_id = convert(varchar(255),pas.spell_id)
	RETURN
	
END
GO

-- 
-- THERAPY MANAGMENT
--

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[thpyMgMt]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.thpyMgMt;
GO

CREATE FUNCTION dbo.thpyMgMt()
RETURNS @spchThpyTab TABLE(
	care_activity_id numeric(19,0),
	medical_history_id numeric(19,0),
	hospital_stay_id varchar(255),
	thpy_id numeric(19,0),	
	psychoRequired VARCHAR(1),
	psychoDays VARCHAR(4),
	psychoMinutes VARCHAR(6),
	rehabGoalsDate varchar(16),
	rehabGoalsNone varchar(1),
	rehabGoalsNoneReason varchar(3)
)
AS
BEGIN	
	INSERT INTO @spchThpyTab
	SELECT	
		c.id AS care_activity_id, 		
		c.medical_history_id AS medical_history_id,		
		c.hospital_stay_id AS hospital_stay_id,
		t.id,		

		CASE 
			WHEN ISNULL(t.[pyschology_therapy_required],0) = 0 THEN 'N' 
			ELSE  'Y'
		END AS psychoRequired,
		
		ISNULL(t.[pyschology_days_of_therapy],0) AS psychoDays,
		ISNULL(t.[pyschology_minutes_of_therapy],0) AS psychoMinutes,
		CASE
			WHEN ISNULL(t.rehab_goals_set, 0) = 0 THEN '' 
			WHEN t.rehab_goals_set_date IS NULL THEN ''			
			ELSE dbo.makeDateTime(t.rehab_goals_set_date, ISNULL(t.rehab_goals_set_time,0))
		END AS rehabGoalsDate,
		CASE 
			WHEN ISNULL(t.rehab_goals_set, 0) = 0 THEN 'Y'
			ELSE 'N'
		END AS rehabGoalsNone,
		
		CASE
			WHEN ISNULL(t.rehab_goals_set, 0) = 1 THEN '' 
			WHEN r.description = 'refused' THEN 'PR'
			WHEN r.description = 'organisational' THEN 'OR'
			WHEN r.description = 'unwell' THEN 'MU'
			WHEN r.description = 'noproblem' THEN 'NI'
			WHEN r.description = 'nopotential' THEN 'NRP'
			WHEN r.description = 'unknown' THEN 'NK'
			ELSE ''
		END AS rehabGoalsNoneReason 
		
	FROM 
		dbo.care_activity AS c
	LEFT OUTER JOIN
		dbo.therapy_management t
		ON c.therapy_management_id = t.id
	LEFT OUTER JOIN
		dbo.rehab_goals_not_set_reason_type	AS r	
		ON t.rehab_goals_not_set_reason_type_id = r.id
		
	RETURN
	
END
GO

-- 
-- Admission Assessment
--

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[admissionAsmt]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.admissionAsmt;
GO
CREATE FUNCTION dbo.admissionAsmt()
RETURNS @admAsmtTab TABLE(
	care_activity_id numeric(19,0),
	medical_history_id numeric(19,0),
	hospital_stay_id varchar(255),
	urinaryContinencePlanDate VARCHAR(16),
	urinaryContinencePlanNoPlan VARCHAR(4),
	urinaryContinencePlanNoPlanReason VARCHAR(4),
	malnutritionScreening VARCHAR(4),
	malnutritionScreeningDietitianDate VARCHAR(16),
	malnutritionScreeningDietitianNotSeen VARCHAR(4)
)
AS
BEGIN	
	/*
	-- POPULATE Reasons for non-performance
	--
	*/

	DECLARE @UrinaryContinenceNoPlanReason AS [dbo].[ReasonTableType];
	INSERT 
		INTO @UrinaryContinenceNoPlanReason 
		VALUES 
			('organisational', 'OR'),
			('unknown', 'NK'),
			('continent',  'PC'),
			('refused', 'PR'),
			('unconcious',NULL),
			('other',	NULL);




		
	INSERT INTO @admAsmtTab
	SELECT
		c.id AS care_activity_id, 
		c.medical_history_id AS medical_history_id,
		c.hospital_stay_id AS hospital_stay_id,
				
		contPlanPerf.perfDate AS urinaryContinencePlanDate,
		contPlanPerf.notPerformed AS urinaryContinencePlanNoPlan,
		contPlanPerf.codedReason AS urinaryContinencePlanNoPlanReason,
		
		CASE
			WHEN nm.date_screened IS NULL THEN 'N'
			WHEN nm.must_score > 2 THEN 'NS'
			ELSE 'Y'
		END
		AS malnutritionScreening,
		CONVERT(VARCHAR(10), nm.dietitian_referral_date,103) AS malnutritionScreeningDietitianDate,
		nm.dietitian_not_seen AS malnutritionScreeningDietitianNotSeen
	FROM 
		dbo.care_activity AS c
	LEFT OUTER JOIN
		dbo.continence_management AS co
		ON c.continence_management_id = co.id
	LEFT OUTER JOIN
		dbo.nutrition_management AS nm
		ON c.nutrition_management_id = nm.id
	JOIN
		dbo.no_continence_plan_reason_type AS cpr	
		ON co.no_continence_plan_reason_id = cpr.id
	CROSS APPLY
		dbo.performanceRecord(
			co.continence_plan_date,
			0,
			co.has_continence_plan, 
			cpr.description, 
			@UrinaryContinenceNoPlanReason) AS contPlanPerf	 
	RETURN
END
GO


-- 
-- POST DISCHARGE CARE
--

IF EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[postDchg]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION dbo.postDchg;
GO

CREATE FUNCTION dbo.postDchg()
RETURNS @postDchgTab TABLE(
	care_activity_id numeric(19,0),
	medical_history_id numeric(19,0),
	hospital_stay_id varchar(255),
	end_rehab_date varchar(10),
	discharge_type VARCHAR(2),	
	care_home_discharge VARCHAR(3),
	care_home_discharge_type VARCHAR(1),
	home_discharge_type varchar(3),
	discharged_esdmt varchar(3),
	discharged_mcrt varchar(3),
	adl_help varchar(1),
	adl_help_type varchar(3),
	discharge_visits_per_week INT,
	discharge_visits_per_week_nk VARCHAR(1),
	discharge_atrial_fibrilation VARCHAR(1),
	discharge_atrial_fibrillation_anticoagulation VARCHAR(2),
	discharge_joint_care_planning VARCHAR(2),
	discharge_named_contact VARCHAR(1),
	discharge_barthel TINYINT,
	discharge_pi_consent  VARCHAR(2)
)
AS
BEGIN	
	INSERT INTO @postDchgTab
	SELECT	
		c.id AS care_activity_id, 		
		c.medical_history_id AS medical_history_id,		
		c.hospital_stay_id AS hospital_stay_id,
		CASE
			WHEN PAS.S7DeathDate IS NOT NULL THEN ''
			WHEN pdc.discharged_to = 'otherHospital' THEN ''
			WHEN c.fit_for_discharge_date IS NULL THEN '' 
			ELSE CONVERT(VARCHAR(10), c.fit_for_discharge_date, 103)   
		END 
		AS end_rehab_date,
		CASE		
			WHEN pdc.discharged_to = 'residentialCareHome' THEN 'CH'
			WHEN pdc.discharged_to = 'home' THEN 'H'
			WHEN pdc.discharged_to = 'otherHospital' THEN 'T'
			WHEN pdc.discharged_to = 'somewhere' THEN 'SE'
			WHEN pdtt.description = 'ESD' THEN 'TC'
			WHEN pdtt.description = 'Generic Community Rehab' THEN 'TC'
		END
		AS discharge_type,
		CASE			
			WHEN pdc.discharged_to <> 'residentialCareHome' THEN ''
			WHEN pdc.patient_previously_resident = 0 THEN 'NPR'
			WHEN pdc.patient_previously_resident = 1 THEN 'PR'
			ELSE ''
		END
		AS care_home_discharge,
		CASE			
			WHEN pdc.discharged_to <> 'residentialCareHome' THEN ''
			WHEN pdc.temporary_or_permanent = 'perm' THEN 'P'
			WHEN pdc.temporary_or_permanent = 'temporary' THEN 'T'
			ELSE ''
		END
		AS care_home_discharge_type,
		CASE
			WHEN pdc.discharged_to <> 'home' THEN ''
			WHEN pdc.alone_post_discharge = 1 THEN 'LA'
			WHEN pdc.alone_post_discharge = 0 THEN 'NLA'
			WHEN pdc.alone_post_discharge_unknown = 1 THEN 'NK'
			ELSE '' 
		END 
		AS home_discharge_type,
		CASE
			WHEN pdc.discharged_to <> 'otherHospital' THEN '' -- @TODO How about DIED = 7.1
			WHEN pdst.description = 'Stroke/neurology specific ESD' THEN 'SNS'
			WHEN pdst.description = 'Non specialist ESD' THEN 'NS'
			ELSE 'N'
		END
		AS discharged_esdmt,
		CASE
			WHEN pdc.discharged_to <> 'otherHospital' THEN '' -- @TODO How about DIED = 7.1
			WHEN pdst.description = 'Stroke/neurology specific community rehabilitation team' THEN 'SNS'
			WHEN pdst.description = 'Non specialist community rehabilitation team' THEN 'NS'
			ELSE 'N'
		END
		AS discharged_mcrt,
		CASE
			WHEN pdc.discharged_to <> 'otherHospital' THEN '' -- @TODO How about DIED = 7.1
			WHEN pdc.support_on_discharge_needed = 'Yes' THEN 'Y'
			ELSE 'N'
		END
		AS adl_help,
		CASE
			WHEN pdc.discharged_to <> 'otherHospital' THEN ''
			WHEN pdc.support_on_discharge_needed <> 'Yes' THEN ''
			WHEN pdst.description = 'Social Services' THEN 'PC'
			WHEN pdst.description = 'Informal Carers' THEN 'IC'
			WHEN pdst.description = 'Social Services Unavailable' THEN 'U'
			WHEN pdst.description = 'Patient Refused' THEN 'PR'
			ELSE '' -- @TODO SSNAP 7.9.1 - No 'PIC' option  
		END,
		CASE
			WHEN pdc.discharged_to <> 'otherHospital' THEN ''
			WHEN pdc.support_on_discharge_needed <> 'Yes' THEN ''
			ELSE pdc.number_of_social_service_visits  
		END
		AS discharge_visits_per_week,
		ISNULL(pdc.number_of_social_service_visits_unknown,'1')  
		AS discharge_visits_per_week_nk,
		CASE
			WHEN pdc.discharged_to <> 'otherHospital' THEN '' -- @TODO How about DIED = 7.1
			WHEN c.in_af_on_discharge = 'Yes' THEN 'Y'
			WHEN c.in_af_on_discharge = 'No' THEN 'N'
			ELSE ''
		END
		AS discharge_atrial_fibrilation,
		CASE
			WHEN pdc.discharged_to <> 'otherHospital' THEN '' -- @TODO How about DIED = 7.1
			WHEN c.in_af_on_discharge <> 'Yes' THEN ''
			WHEN c.on_anticoagulant_at_discharge = 'Yes' THEN 'Y'
			WHEN c.on_anticoagulant_at_discharge = 'No' THEN 'N'
			ELSE ''
		END,
		CASE
			WHEN pdc.discharged_to <> 'otherHospital' THEN '' -- @TODO How about DIED = 7.1
			WHEN pdc.documented_evidence = 'Yes' THEN 'Y'
			WHEN pdc.documented_evidence = 'No' THEN 'Y'
			WHEN pdc.documented_evidence = 'NotApplicable' THEN 'NA'
			ELSE ''
		END,
		CASE
			WHEN pdc.discharged_to <> 'otherHospital' THEN '' -- @TODO How about DIED = 7.1
			WHEN pdc.documentation_post_discharge = 1 THEN 'Y'
			WHEN pdc.documentation_post_discharge = 0 THEN 'N'
			ELSE ''
		END, 
		barthel.barthel_score AS discharge_barthel,
		'' AS discharge_pi_consentb
	FROM 
		dbo.care_activity AS c
	LEFT OUTER JOIN
		dbo.post_discharge_care pdc
		ON c.post_discharge_care_id = pdc.id
	LEFT OUTER JOIN
		dbo.post_discharge_support AS pds	
		ON pds.post_discharge_care_id = pdc.id
	JOIN
		dbo.post_discharge_support_type AS pdst
		ON pds.type_id = pdst.id
	LEFT OUTER JOIN
		dbo.post_discharge_therapy AS pdt
		ON pdt.post_discharge_care_id = c.post_discharge_care_id
	JOIN
		dbo.post_discharge_therapy_type AS pdtt
		ON pdt.type_id = pdtt.id
	LEFT OUTER JOIN
		dbo.barthelRec('Discharge') As barthel 
		ON c.hospital_stay_id = barthel.hospital_stay_id
	LEFT OUTER JOIN	
		dbo.PAS AS PAS
		ON PAS.spell_id = c.hospital_stay_id
	RETURN
	
END
GO
