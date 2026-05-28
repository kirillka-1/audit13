USE DairyEnterprise;
GO

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID('Product') 
               AND name = 'CostPrice')
BEGIN
    ALTER TABLE Product ADD CostPrice DECIMAL(18,2) NULL;
END

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID('SalesOrder') 
               AND name = 'TotalAmount')
BEGIN
    ALTER TABLE SalesOrder ADD TotalAmount DECIMAL(18,2) NULL;
END
GO

UPDATE Product
SET CostPrice = (
    SELECT ISNULL(SUM(sd.Quantity * mp.Price), 0)
    FROM Specification s
    JOIN SpecificationDetail sd ON s.SpecificationID = sd.SpecificationID
    JOIN MaterialPrice mp ON sd.MaterialID = mp.MaterialID
    WHERE s.ProductID = Product.ProductID
);
GO

DROP TRIGGER IF EXISTS trg_CalculateOrderTotal;
GO

CREATE TRIGGER trg_CalculateOrderTotal
ON SalesOrderItem
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @OrdersToUpdate TABLE (SalesOrderID INT);
    
    INSERT INTO @OrdersToUpdate (SalesOrderID)
    SELECT DISTINCT SalesOrderID FROM inserted
    UNION
    SELECT DISTINCT SalesOrderID FROM deleted;
    
    UPDATE so
    SET TotalAmount = (
        SELECT ISNULL(SUM(soi.Quantity * p.CostPrice), 0)
        FROM SalesOrderItem soi
        INNER JOIN Product p ON soi.ProductID = p.ProductID
        WHERE soi.SalesOrderID = so.SalesOrderID
    )
    FROM SalesOrder so
    INNER JOIN @OrdersToUpdate otu ON so.SalesOrderID = otu.SalesOrderID;
END;
GO

DROP PROCEDURE IF EXISTS sp_GetOrderReport;
GO

CREATE PROCEDURE sp_GetOrderReport
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @StartDate IS NULL OR @EndDate IS NULL
    BEGIN
        RAISERROR('Ошибка: Даты начала и конца периода обязательны', 16, 1);
        RETURN;
    END
    
    IF @StartDate > @EndDate
    BEGIN
        RAISERROR('Ошибка: Дата начала не может быть позже даты окончания', 16, 1);
        RETURN;
    END
    
    SELECT 
        c.CustomerName AS [Заказчик],
        COUNT(DISTINCT so.SalesOrderID) AS [Количество заказов],
        ISNULL(SUM(soi.Quantity), 0) AS [Общее количество продукции],
        ISNULL(SUM(soi.TotalAmount), 0) AS [Общая сумма (руб)],
        @StartDate AS [Период с],
        @EndDate AS [По]
    FROM Customer c
    LEFT JOIN SalesOrder so ON c.CustomerID = so.CustomerID 
        AND so.OrderDate BETWEEN @StartDate AND @EndDate
    LEFT JOIN SalesOrderItem soi ON so.SalesOrderID = soi.SalesOrderID
    GROUP BY c.CustomerID, c.CustomerName
    HAVING COUNT(so.SalesOrderID) > 0 OR SUM(soi.TotalAmount) > 0
    ORDER BY SUM(soi.TotalAmount) DESC;
    
    SELECT 
        @StartDate AS [Дата начала],
        @EndDate AS [Дата окончания],
        COUNT(DISTINCT so.SalesOrderID) AS [Всего заказов],
        ISNULL(SUM(soi.Quantity), 0) AS [Всего продукции],
        ISNULL(SUM(soi.TotalAmount), 0) AS [Общая сумма (руб)]
    FROM SalesOrder so
    LEFT JOIN SalesOrderItem soi ON so.SalesOrderID = soi.SalesOrderID
    WHERE so.OrderDate BETWEEN @StartDate AND @EndDate;
END;
GO

UPDATE SalesOrderItem SET Quantity = Quantity WHERE SalesOrderItemID > 0;
GO