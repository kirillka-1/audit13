USE [BD];
GO

IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    EXEC('CREATE MASTER KEY ENCRYPTION BY PASSWORD = ''StrongMasterKey_P@ssw0rd_2024!''');
    PRINT 'Мастер-ключ базы данных создан';
END
ELSE
    PRINT 'Мастер-ключ уже существует';
GO

IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'Cert_PasswordProtection')
BEGIN
    EXEC('CREATE CERTIFICATE Cert_PasswordProtection WITH SUBJECT = ''Сертификат для защиты паролей пользователей''');
    PRINT 'Сертификат Cert_PasswordProtection создан';
END
ELSE
    PRINT 'Сертификат уже существует';
GO

IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'Key_PasswordEncryption')
BEGIN
    EXEC('CREATE SYMMETRIC KEY Key_PasswordEncryption WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE Cert_PasswordProtection');
    PRINT 'Симметричный ключ Key_PasswordEncryption создан';
END
ELSE
    PRINT 'Симметричный ключ уже существует';
GO

PRINT 'Инфраструктура шифрования готова';

GO


IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    PRINT 'Создаю таблицу Users...';
    CREATE TABLE [dbo].[Users] (
        [ID] [INT] IDENTITY(1,1) NOT NULL,
        [Username] [NVARCHAR](50) NOT NULL,
        [Password] [NVARCHAR](50) NULL,
        [CreatedAt] [DATETIME] DEFAULT GETDATE(),
        CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([ID] ASC)
    );
    PRINT 'Таблица Users создана';
    
    INSERT INTO [dbo].[Users] (Username, [Password]) VALUES 
        ('user1', 'A1b2C'),
        ('user2', 'D3e4F'),
        ('user3', 'G5h6I'),
        ('user4', 'J7k8L'),
        ('user5', 'M9n0P');
    PRINT 'Добавлены тестовые пользователи';
END
ELSE
    PRINT 'Таблица Users уже существует';
GO

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID('Users') 
               AND name = 'EncryptedPassword')
BEGIN
    ALTER TABLE [dbo].[Users] ADD EncryptedPassword VARBINARY(256) NULL;
    PRINT 'Поле EncryptedPassword добавлено в таблицу Users';
END
ELSE
    PRINT 'Поле EncryptedPassword уже существует';
GO

IF EXISTS (SELECT * FROM sys.columns 
           WHERE object_id = OBJECT_ID('Users') 
           AND name = 'Password')
BEGIN
    IF EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [Password] IS NOT NULL AND EncryptedPassword IS NULL)
    BEGIN

        OPEN SYMMETRIC KEY Key_PasswordEncryption
        DECRYPTION BY CERTIFICATE Cert_PasswordProtection;
        

        UPDATE [dbo].[Users]
        SET EncryptedPassword = EncryptByKey(Key_GUID('Key_PasswordEncryption'), [Password])
        WHERE [Password] IS NOT NULL AND EncryptedPassword IS NULL;
        
        DECLARE @RowsAffected INT = @@ROWCOUNT;
        

        CLOSE SYMMETRIC KEY Key_PasswordEncryption;
        
        PRINT 'Зашифровано строк: ' + CAST(@RowsAffected AS VARCHAR(10));
    END
    ELSE
        PRINT 'Нет незашифрованных паролей';
END
ELSE
    PRINT 'Поле Password не найдено, шифрование не требуется';
GO

PRINT 'Шифрование завершено';
GO

SELECT 
    ID,
    Username,
    CASE 
        WHEN EncryptedPassword IS NOT NULL THEN 'Зашифровано'
        ELSE 'Не зашифровано'
    END AS PasswordStatus,
    LEN(EncryptedPassword) AS EncryptedLength,
    CreatedAt
FROM [dbo].[Users];
GO