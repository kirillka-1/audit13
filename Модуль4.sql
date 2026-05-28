USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'DairyEnterprise')
BEGIN
    ALTER DATABASE DairyEnterprise SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DairyEnterprise;
END
GO

CREATE DATABASE DairyEnterprise;
GO

USE DairyEnterprise;
GO


CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductCode NVARCHAR(50) NOT NULL UNIQUE,
    ProductName NVARCHAR(200) NOT NULL,
    Unit NVARCHAR(20) NOT NULL
);


CREATE TABLE Material (
    MaterialID INT IDENTITY(1,1) PRIMARY KEY,
    MaterialCode NVARCHAR(50) NOT NULL UNIQUE,
    MaterialName NVARCHAR(200) NOT NULL,
    Unit NVARCHAR(20) NOT NULL
);


CREATE TABLE ProductPrice (
    ProductPriceID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    EffectiveDate DATE NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_ProductPrice_Product 
        FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);


CREATE TABLE MaterialPrice (
    MaterialPriceID INT IDENTITY(1,1) PRIMARY KEY,
    MaterialID INT NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    EffectiveDate DATE NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_MaterialPrice_Material 
        FOREIGN KEY (MaterialID) REFERENCES Material(MaterialID)
);


CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerCode NVARCHAR(20) NOT NULL UNIQUE,
    CustomerName NVARCHAR(200) NOT NULL,
    INN NVARCHAR(20) NULL,
    Address NVARCHAR(500) NULL,
    Phone NVARCHAR(50) NULL,
    IsSalesman BIT NOT NULL DEFAULT 0,
    IsBuyer BIT NOT NULL DEFAULT 0
);


CREATE TABLE SalesOrder (
    SalesOrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderNumber NVARCHAR(50) NOT NULL,
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    Executor NVARCHAR(200) NOT NULL,
    
    CONSTRAINT FK_SalesOrder_Customer 
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);


CREATE TABLE SalesOrderItem (
    SalesOrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity DECIMAL(18,3) NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    TotalAmount DECIMAL(18,2) NOT NULL,
    
    CONSTRAINT FK_SalesOrderItem_SalesOrder 
        FOREIGN KEY (SalesOrderID) REFERENCES SalesOrder(SalesOrderID),
    CONSTRAINT FK_SalesOrderItem_Product 
        FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);


CREATE TABLE Specification (
    SpecificationID INT IDENTITY(1,1) PRIMARY KEY,
    SpecificationName NVARCHAR(200) NOT NULL,
    ProductID INT NOT NULL,
    Manufacturer NVARCHAR(200) NOT NULL,
    
    CONSTRAINT FK_Specification_Product 
        FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);


CREATE TABLE SpecificationDetail (
    SpecificationDetailID INT IDENTITY(1,1) PRIMARY KEY,
    SpecificationID INT NOT NULL,
    MaterialID INT NOT NULL,
    Quantity DECIMAL(18,3) NOT NULL,
    
    CONSTRAINT FK_SpecificationDetail_Specification 
        FOREIGN KEY (SpecificationID) REFERENCES Specification(SpecificationID),
    CONSTRAINT FK_SpecificationDetail_Material 
        FOREIGN KEY (MaterialID) REFERENCES Material(MaterialID)
);


CREATE TABLE Production (
    ProductionID INT IDENTITY(1,1) PRIMARY KEY,
    ProductionNumber NVARCHAR(50) NOT NULL,
    ProductionDate DATE NOT NULL,
    ProductID INT NOT NULL,
    Quantity DECIMAL(18,3) NOT NULL,
    
    CONSTRAINT FK_Production_Product 
        FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);


CREATE TABLE ProductionMaterial (
    ProductionMaterialID INT IDENTITY(1,1) PRIMARY KEY,
    ProductionID INT NOT NULL,
    MaterialID INT NOT NULL,
    QuantityUsed DECIMAL(18,3) NOT NULL,
    
    CONSTRAINT FK_ProductionMaterial_Production 
        FOREIGN KEY (ProductionID) REFERENCES Production(ProductionID),
    CONSTRAINT FK_ProductionMaterial_Material 
        FOREIGN KEY (MaterialID) REFERENCES Material(MaterialID)
);

PRINT '========================================';
PRINT 'ВСЕ 11 ТАБЛИЦ СОЗДАНЫ СО СВЯЗЯМИ!';
PRINT '========================================';
GO



SELECT 
    'ProductPrice' AS TableName,
    'Product' AS ReferencedTable,
    'Есть связь ✓' AS Status
WHERE EXISTS (
    SELECT 1 FROM sys.foreign_keys 
    WHERE name = 'FK_ProductPrice_Product'
)
UNION ALL
SELECT 
    'MaterialPrice' AS TableName,
    'Material' AS ReferencedTable,
    'Есть связь ✓' AS Status
WHERE EXISTS (
    SELECT 1 FROM sys.foreign_keys 
    WHERE name = 'FK_MaterialPrice_Material'
);

PRINT '========================================';
PRINT 'ТЕСТОВЫЕ ДАННЫЕ';
PRINT '========================================';
GO

INSERT INTO Product (ProductCode, ProductName, Unit) VALUES
('НФ-00000001', N'Кефир 2,5% 900г.', N'шт'),
('НФ-00000002', N'Кефир 3,2% 900г.', N'шт'),
('НФ-00000003', N'Молоко 2,5% 900г.', N'шт'),
('НФ-00000006', N'Сметана классическая 15% 540г.', N'шт');

INSERT INTO Material (MaterialCode, MaterialName, Unit) VALUES
('НФ-00000004', N'Молоко нормализованное', N'кг'),
('НФ-00000005', N'Закваска сметанная', N'кг');

INSERT INTO ProductPrice (ProductID, Price, EffectiveDate) VALUES
(1, 80, '2025-01-01'),
(2, 82, '2025-01-01'),
(3, 79, '2025-01-01'),
(4, 89, '2025-01-01');

INSERT INTO MaterialPrice (MaterialID, Price, EffectiveDate) VALUES
(1, 40, '2025-01-01'),
(2, 45, '2025-01-01');

INSERT INTO Customer (CustomerCode, CustomerName, INN, Address, Phone, IsSalesman, IsBuyer) VALUES
('000000001', N'ООО "Поставка"', N'', N'г.Пятигорск', N'+79198634592', 1, 1),
('000000002', N'ООО "Кинотеатр Квант"', N'26320045123', N'г. Железноводск, ул. Мира, 123', N'+79884581555', 1, 0),
('000000003', N'ООО "Ромашка"', N'4140784214', N'г. Омск, ул. Строителей, 294', N'+79882584546', 0, 1),
('000000009', N'ООО "Ипподром"', N'5874045632', N'г. Уфа, ул. Набережная, 37', N'+79627486389', 1, 1),
('000000010', N'ООО "Ассоль"', N'2629011278', N'г. Калуга, ул. Пушкина, 94', N'+79184572398', 0, 1);

INSERT INTO Specification (SpecificationName, ProductID, Manufacturer) VALUES
(N'Основная Сметана 15%', 4, N'ООО Молочный комбинат "Полесье"');

INSERT INTO SpecificationDetail (SpecificationID, MaterialID, Quantity) VALUES
(1, 1, 0.9),
(1, 2, 0.07);

INSERT INTO SalesOrder (OrderNumber, OrderDate, CustomerID, Executor) VALUES
(N'2', '2025-06-06', 5, N'ООО Молочный комбинат "Полесье"');

INSERT INTO SalesOrderItem (SalesOrderID, ProductID, Quantity, UnitPrice, TotalAmount) VALUES
(1, 1, 12, 80, 960),
(1, 2, 9, 82, 738),
(1, 3, 10, 79, 790);

INSERT INTO Production (ProductionNumber, ProductionDate, ProductID, Quantity) VALUES
(N'1', '2025-06-09', 4, 1);

INSERT INTO ProductionMaterial (ProductionID, MaterialID, QuantityUsed) VALUES
(1, 1, 0.9),
(1, 2, 0.07);

