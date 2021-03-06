/****** Object:  Table [dbo].[comorbidity_type]    Script Date: 11/10/2011 11:48:55 ******/
DELETE FROM [dbo].[comorbidity_type]
GO
/****** Object:  Table [dbo].[comorbidity_type]    Script Date: 11/10/2011 11:48:55 ******/
SET IDENTITY_INSERT [dbo].[comorbidity_type] ON
INSERT [dbo].[comorbidity_type] ([id], [version], [description]) VALUES (CAST(1 AS Numeric(19, 0)), CAST(0 AS Numeric(19, 0)), N'previous stroke')
INSERT [dbo].[comorbidity_type] ([id], [version], [description]) VALUES (CAST(2 AS Numeric(19, 0)), CAST(0 AS Numeric(19, 0)), N'previous tia')
INSERT [dbo].[comorbidity_type] ([id], [version], [description]) VALUES (CAST(3 AS Numeric(19, 0)), CAST(0 AS Numeric(19, 0)), N'diabetes')
INSERT [dbo].[comorbidity_type] ([id], [version], [description]) VALUES (CAST(4 AS Numeric(19, 0)), CAST(0 AS Numeric(19, 0)), N'atrial fibrillation')
INSERT [dbo].[comorbidity_type] ([id], [version], [description]) VALUES (CAST(5 AS Numeric(19, 0)), CAST(0 AS Numeric(19, 0)), N'myocardial infarction')
INSERT [dbo].[comorbidity_type] ([id], [version], [description]) VALUES (CAST(6 AS Numeric(19, 0)), CAST(0 AS Numeric(19, 0)), N'hyperlipidaemia')
INSERT [dbo].[comorbidity_type] ([id], [version], [description]) VALUES (CAST(7 AS Numeric(19, 0)), CAST(0 AS Numeric(19, 0)), N'hypertension')
INSERT [dbo].[comorbidity_type] ([id], [version], [description]) VALUES (CAST(8 AS Numeric(19, 0)), CAST(0 AS Numeric(19, 0)), N'valvular heart disease')
INSERT [dbo].[comorbidity_type] ([id], [version], [description]) VALUES (CAST(9 AS Numeric(19, 0)), CAST(0 AS Numeric(19, 0)), N'ischaemic heart disease')
SET IDENTITY_INSERT [dbo].[comorbidity_type] OFF
