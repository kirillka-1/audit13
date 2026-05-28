USE DairyEnterprise;
GO

DECLARE @MonthName NVARCHAR(20);
DECLARE @Year INT;
DECLARE @Month INT;
DECLARE @StartDate DATE;
DECLARE @EndDate DATE;
DECLARE @ArchiveTableName NVARCHAR(100);
DECLARE @Sql NVARCHAR(MAX);
DECLARE @SqlInsert NVARCHAR(MAX);
DECLARE @SqlDeleteItems NVARCHAR(MAX);
DECLARE @SqlDeleteOrders NVARCHAR(MAX);

SET @Year = 2025;
SET @Month = 6;

SET @MonthName = DATENAME(MONTH, DATEFROMPARTS(@Year, @Month, 1));
SET @StartDate = DATEFROMPARTS(@Year, @Month, 1);
SET @EndDate = EOMONTH(@StartDate);
SET @ArchiveTableName = 'SalesOrder_' + LOWER(@MonthName) + '_' + CAST(@Year AS NVARCHAR(4));

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = @ArchiveTableName)
BEGIN
    SET @Sql = 'DROP TABLE [' + @ArchiveTableName + '];';
    EXEC sp_executesql @Sql;
    PRINT 'Старая архивная таблица удалена';
END

SET @Sql = '
CREATE TABLE [' + @ArchiveTableName + '] (
    SalesOrderID INT PRIMARY KEY,
    OrderNumber NVARCHAR(50) NOT NULL,
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    Executor NVARCHAR(200) NOT NULL,
    TotalAmount DECIMAL(18,2) NULL,
    ArchivedDate DATETIME DEFAULT GETDATE()
);';
EXEC sp_executesql @Sql;
PRINT 'Архивная таблица ' + @ArchiveTableName + ' создана заново';

SET @SqlInsert = '
INSERT INTO [' + @ArchiveTableName + '] (SalesOrderID, OrderNumber, OrderDate, CustomerID, Executor, TotalAmount, ArchivedDate)
SELECT SalesOrderID, OrderNumber, OrderDate, CustomerID, Executor, TotalAmount, GETDATE()
FROM SalesOrder
WHERE OrderDate BETWEEN ''' + CAST(@StartDate AS NVARCHAR(10)) + ''' AND ''' + CAST(@EndDate AS NVARCHAR(10)) + ''';';

EXEC sp_executesql @SqlInsert;

PRINT 'Перенесено заказов в архив: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

SET @SqlDeleteItems = '
DELETE FROM SalesOrderItem
WHERE SalesOrderID IN (
    SELECT SalesOrderID FROM SalesOrder
    WHERE OrderDate BETWEEN ''' + CAST(@StartDate AS NVARCHAR(10)) + ''' AND ''' + CAST(@EndDate AS NVARCHAR(10)) + '''
);';

EXEC sp_executesql @SqlDeleteItems;

PRINT 'Удалено строк из SalesOrderItem: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

SET @SqlDeleteOrders = '
DELETE FROM SalesOrder
WHERE OrderDate BETWEEN ''' + CAST(@StartDate AS NVARCHAR(10)) + ''' AND ''' + CAST(@EndDate AS NVARCHAR(10)) + ''';';

EXEC sp_executesql @SqlDeleteOrders;

PRINT 'Удалено заказов из SalesOrder: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
PRINT '========================================';
PRINT 'Архивирование за ' + @MonthName + ' ' + CAST(@Year AS VARCHAR(4)) + ' завершено';
PRINT '========================================';

PRINT '=== ОСТАВШИЕСЯ ЗАКАЗЫ ===';
SELECT * FROM SalesOrder;

PRINT '=== АРХИВНАЯ ТАБЛИЦА ===';
SET @Sql = 'SELECT * FROM [' + @ArchiveTableName + '];';
EXEC sp_executesql @Sql;