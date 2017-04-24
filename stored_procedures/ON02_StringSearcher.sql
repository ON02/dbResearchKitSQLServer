



IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ON02_StringSearcher]') AND type in (N'P', N'PC')) 
DROP PROCEDURE [dbo].[ON02_StringSearcher] 
GO


CREATE PROCEDURE [dbo].[ON02_StringSearcher]
(
	@StringSearch NVARCHAR(255)
)
AS
/* LIBRARY: ON02 DATABASE RESEARCH KIT
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   
																														 
-- Parameter: @StringSearch																											 
-- Returns: ColumnName, ColumnValue																											 																										 
																														 
-- USE CASE: EXEC ON02_StringSearcher '<FirstName>Wind</FirstName>';  																											 
																														 
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   
*/
BEGIN

	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;


	CREATE TABLE #Report
	(
		 ColumnName NVARCHAR(255)
		,ColumnValue NVARCHAR(255)
	);
	
	DECLARE  @TableName NVARCHAR(255)
			,@ColumnName NVARCHAR(255)
			,@QStringSearch NVARCHAR(130)
			,@Query NVARCHAR(MAX) = '';
	
	SET @QStringSearch = QUOTENAME('%'+@StringSearch+'%','''');
	
	
	DECLARE test_cursor CURSOR LOCAL FORWARD_ONLY STATIC FOR
	SELECT 
		
		 QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
		,QUOTENAME(COLUMN_NAME)
		--,OBJECT_ID(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)) --,ROW_NUMBER() OVER (ORDER BY QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) ASC)

	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE OBJECTPROPERTY(OBJECT_ID(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)), 'IsMSShipped') = 0
	AND OBJECT_ID(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)) IN 
	( SELECT OBJECT_ID(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' )
	AND DATA_TYPE IN
	(
		 'char'
		,'varchar'
		,'nchar'
		,'nvarchar'
	)
	ORDER BY OBJECT_ID(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)) ASC;
	
	OPEN test_cursor;
	FETCH NEXT FROM test_cursor
	INTO @TableName, @ColumnName
	
		WHILE @@FETCH_STATUS = 0
		BEGIN
	
			BEGIN TRY

				SET @Query = 'INSERT INTO #Report 
							SELECT ''' + @TableName + '.' + @ColumnName + ''', LEFT( '+ @ColumnName +', 255 ) 
							FROM ' + @TableName + ' (NOLOCK) ' + ' WHERE ' + @ColumnName + CASE WHEN @QStringSearch IS NOT NULL THEN ' LIKE ' + @QStringSearch ELSE 'IS NULL' END;					
				EXEC (@Query);

			END TRY 
			BEGIN CATCH

			PRINT  
			'<ERROR>' + CHAR(13) +
			'<TableName>' + @TableName + '</TableName>' + CHAR(13) + 
			'<ColumnName>' + @ColumnName + '</ColumnName>' + CHAR(13) +
			'<LookingFor>' + @QStringSearch + '</LookingFor>' + CHAR(13) +
			'<Query>' + @Query + '</Query>' + CHAR(13) +
			'<ErrorLine>' + ERROR_LINE() + '</ErrorLine>' + CHAR(13) +
			'<ErrorMessage>' + ERROR_MESSAGE() + '</ErrorMessage>' + CHAR(13) +
			'</ERROR>' + CHAR(13);

			END CATCH
	
			FETCH NEXT FROM test_cursor
			INTO @TableName, @ColumnName
		
		END;
	
	
	CLOSE test_cursor;
	DEALLOCATE test_cursor;		
	
	
	SELECT
	
		 ColumnName AS [SchemaName.TableName.ColumnName]
		,ColumnValue
	
	FROM #Report;

END
GO