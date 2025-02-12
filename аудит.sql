USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = 'ServerAudit')
BEGIN
    ALTER SERVER AUDIT ServerAudit WITH (STATE = OFF);
    DROP SERVER AUDIT ServerAudit;
END
GO

CREATE SERVER AUDIT ServerAudit
TO FILE 
(
    FILEPATH = '___', -- Укажите путь к папке для аудита
    MAXSIZE = 100 MB,          
    MAX_ROLLOVER_FILES = 10    
)
WITH (ON_FAILURE = CONTINUE);   
GO

ALTER SERVER AUDIT ServerAudit
WITH (STATE = ON);
GO

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = 'ServerAuditSpec')
BEGIN
    ALTER SERVER AUDIT SPECIFICATION ServerAuditSpec WITH (STATE = OFF);
    DROP SERVER AUDIT SPECIFICATION ServerAuditSpec;
END
GO

CREATE SERVER AUDIT SPECIFICATION ServerAuditSpec
FOR SERVER AUDIT ServerAudit
ADD (FAILED_LOGIN_GROUP),          
ADD (BACKUP_RESTORE_GROUP),       
ADD (USER_CHANGE_PASSWORD_GROUP) 
WITH (STATE = ON);               
GO

USE ПроектнаяОрганизация; 
GO

IF EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = 'DatabaseAuditSpec')
BEGIN
    ALTER DATABASE AUDIT SPECIFICATION DatabaseAuditSpec WITH (STATE = OFF);
    DROP DATABASE AUDIT SPECIFICATION DatabaseAuditSpec;
END
GO

CREATE DATABASE AUDIT SPECIFICATION DatabaseAuditSpec
FOR SERVER AUDIT ServerAudit
ADD (INSERT, UPDATE, DELETE ON Сотрудники BY dbo)
WITH (STATE = ON);                                 
GO

USE ПроектнаяОрганизация;
GO

INSERT INTO Сотрудники (ФИО, Должность, Номер_отдела, Пол, Адрес, Дата_рождения)
VALUES ('Иванов Иван Иванович', 'инженеры', 1, 'М', 'ул. Ленина, 10', '1980-01-01');
GO

UPDATE Сотрудники
SET Адрес = 'ул. Пушкина, 15'
WHERE ФИО = 'Иванов Иван Иванович';
GO

DELETE FROM Сотрудники
WHERE ФИО = 'Иванов Иван Иванович';
GO

USE master;
GO

SELECT *
FROM sys.fn_get_audit_file('C:\AuditLogs\*', DEFAULT, DEFAULT);
GO

BACKUP DATABASE ПроектнаяОрганизация
TO DISK = 'C:\Backup\ПроектнаяОрганизация.bak'
WITH INIT,
     NAME = 'Full Backup of ПроектнаяОрганизация',
     DESCRIPTION = 'This is a full backup of the database', 
     STATS = 10; 
GO
