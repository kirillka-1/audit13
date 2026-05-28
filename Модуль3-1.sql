
USE master;
GO


DECLARE @BackupPath NVARCHAR(500) = 'C:\SQL_Backup\';
DECLARE @Command NVARCHAR(1000);

BEGIN TRY
    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC sp_configure 'xp_cmdshell', 1;
    RECONFIGURE;
    
    SET @Command = 'if not exist "' + @BackupPath + '" mkdir ' + @BackupPath;
    EXEC xp_cmdshell @Command;
    
    PRINT 'Папка для бэкапов: ' + @BackupPath;
END TRY
BEGIN CATCH
    PRINT 'ВНИМАНИЕ: Не удалось создать папку автоматически. Создайте папку C:\SQL_Backup\ вручную.';
END CATCH
GO


DECLARE @DatabaseName NVARCHAR(100) = 'BD';
DECLARE @BackupPath NVARCHAR(500) = 'C:\SQL_Backup\';
DECLARE @BackupFileName NVARCHAR(500);
DECLARE @BackupFilePath NVARCHAR(500);
DECLARE @Timestamp NVARCHAR(20);
DECLARE @BackupDescription NVARCHAR(255);

SET @Timestamp = CONVERT(NVARCHAR(20), GETDATE(), 112) + '_' + 
                 REPLACE(CONVERT(NVARCHAR(20), GETDATE(), 108), ':', '');
SET @BackupFileName = @DatabaseName + '_FullBackup_' + @Timestamp + '.bak';
SET @BackupFilePath = @BackupPath + @BackupFileName;
SET @BackupDescription = 'Резервное копирование создано ' + CONVERT(NVARCHAR(30), GETDATE(), 120);

PRINT '========================================';
PRINT 'НАЧАЛО РЕЗЕРВНОГО КОПИРОВАНИЯ';
PRINT '========================================';
PRINT 'База данных: ' + @DatabaseName;
PRINT 'Путь к бэкапу: ' + @BackupFilePath;
PRINT 'Время начала: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
PRINT '----------------------------------------';

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = @DatabaseName)
BEGIN
    PRINT 'ОШИБКА: База данных ' + @DatabaseName + ' не существует!';
    RETURN;
END

BACKUP DATABASE [BD]
TO DISK = @BackupFilePath
WITH 
    NAME = N'Полная резервная копия базы данных BD',
    COMPRESSION,
    STATS = 10,
    INIT,
    SKIP,
    NOREWIND;
    
PRINT '----------------------------------------';
PRINT 'РЕЗЕРВНОЕ КОПИРОВАНИЕ ЗАВЕРШЕНО';
PRINT 'Время окончания: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
PRINT '========================================';
GO


DECLARE @BackupPath NVARCHAR(500) = 'C:\SQL_Backup\';
DECLARE @BackupFilePath NVARCHAR(500);
DECLARE @LatestBackup NVARCHAR(500);

CREATE TABLE #BackupFiles (FileName NVARCHAR(500));

INSERT INTO #BackupFiles
EXEC xp_cmdshell 'dir "C:\SQL_Backup\BD_FullBackup_*.bak" /b';

SELECT TOP 1 @LatestBackup = FileName 
FROM #BackupFiles 
WHERE FileName IS NOT NULL AND FileName LIKE '%.bak'
ORDER BY FileName DESC;

DROP TABLE #BackupFiles;

IF @LatestBackup IS NOT NULL
BEGIN
    SET @BackupFilePath = @BackupPath + @LatestBackup;
    
    PRINT '';
    PRINT 'ПРОВЕРКА ЦЕЛОСТНОСТИ РЕЗЕРВНОЙ КОПИИ:';
    PRINT '----------------------------------------';
    
    RESTORE VERIFYONLY 
    FROM DISK = @BackupFilePath
    WITH CHECKSUM;
    
    PRINT '----------------------------------------';
    PRINT 'Проверка целостности пройдена успешно!';
END
ELSE
    PRINT 'ВНИМАНИЕ: Не удалось найти файл бэкапа для проверки';
GO



PRINT '';
PRINT 'ИНФОРМАЦИЯ О ПОСЛЕДНЕМ БЭКАПЕ:';
PRINT '----------------------------------------';

SELECT TOP 1
    database_name AS [Имя БД],
    backup_start_date AS [Дата начала],
    backup_finish_date AS [Дата окончания],
    CASE [type] 
        WHEN 'D' THEN 'Полный'
        WHEN 'I' THEN 'Дифференциальный'
        WHEN 'L' THEN 'Журнал транзакций'
    END AS [Тип бэкапа],
    bmf.physical_device_name AS [Путь к файлу],
    CAST(backup_size / 1024 / 1024 AS INT) AS [Размер (МБ)],
    CAST(compressed_backup_size / 1024 / 1024 AS INT) AS [Сжатый размер (МБ)]
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf 
    ON bs.media_set_id = bmf.media_set_id
WHERE database_name = 'BD'
ORDER BY backup_start_date DESC;

PRINT '========================================';
PRINT 'СКРИПТ РЕЗЕРВНОГО КОПИРОВАНИЯ ЗАВЕРШЕН';
PRINT '========================================';
GO