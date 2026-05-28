USE master;
GO


DECLARE @Counter INT = 1;
DECLARE @UserName NVARCHAR(50);
DECLARE @DbName NVARCHAR(50);
DECLARE @RandomPassword NVARCHAR(50);
DECLARE @SqlCommand NVARCHAR(MAX);


IF OBJECT_ID('tempdb..##PasswordLog') IS NOT NULL DROP TABLE ##PasswordLog;
CREATE TABLE ##PasswordLog (Username NVARCHAR(50), PasswordHash NVARCHAR(50), CreationDate DATETIME DEFAULT GETDATE());

PRINT 'Начало выполнения скрипта...';
PRINT '----------------------------------------';

WHILE @Counter <= 10
BEGIN
    SET @UserName = 'user' + CAST(@Counter AS VARCHAR(2));
    SET @DbName = 'BD' + CAST(@Counter AS VARCHAR(2));
    
   
    SET @RandomPassword = (
        SELECT CHAR(ABS(CHECKSUM(NEWID())) % 10 + 48) +  
               CHAR(ABS(CHECKSUM(NEWID())) % 26 + 65) + 
               CHAR(ABS(CHECKSUM(NEWID())) % 26 + 97) +  
               CHAR(ABS(CHECKSUM(NEWID())) % 10 + 48) + 
               CHAR(ABS(CHECKSUM(NEWID())) % 26 + 65)   	
    );

    PRINT 'Обработка: ' + @UserName + ' (' + @DbName + ')';

    
    SET @SqlCommand = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD = ''' + @RandomPassword + ''', CHECK_POLICY = OFF, DEFAULT_DATABASE = [master];';
    EXEC sp_executesql @SqlCommand;

    
    SET @SqlCommand = 'CREATE DATABASE [' + @DbName + '];';
    EXEC sp_executesql @SqlCommand;

    
    SET @SqlCommand = 
        'USE [' + @DbName + ']; ' +
        'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']; ' +
        'ALTER ROLE [db_owner] ADD MEMBER [' + @UserName + '];';
    EXEC sp_executesql @SqlCommand;

    INSERT INTO ##PasswordLog (Username, PasswordHash) VALUES (@UserName, @RandomPassword);

    SET @Counter = @Counter + 1;
END
PRINT '----------------------------------------';
PRINT 'Цикл создания завершен.';

PRINT 'Создание главной базы BD и таблицы Users...';

CREATE DATABASE [BD];
GO

USE [BD];
GO

CREATE TABLE [dbo].[Users] (
    [ID] [INT] IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [Username] [NVARCHAR](50) NOT NULL,
    [Password] [NVARCHAR](50) NOT NULL,
    [CreatedAt] [DATETIME] DEFAULT GETDATE()
);
GO

PRINT 'Заполнение таблицы Users...';
INSERT INTO [BD].[dbo].[Users] (Username, Password)
SELECT Username, PasswordHash FROM ##PasswordLog;
GO

DROP TABLE ##PasswordLog;
GO

PRINT '----------------------------------------';
PRINT 'ГОТОВО! Итоговая таблица пользователей:';
SELECT * FROM [BD].[dbo].[Users];
PRINT '----------------------------------------';
PRINT 'Скрипт выполнен успешно.';