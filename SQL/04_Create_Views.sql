USE GoodsAccounting;
GO

-- Представление для просмотра товаров с полной информацией
CREATE VIEW vw_ProductDetails
AS
SELECT 
    p.ProductID,
    p.ProductCode,
    p.ProductName,
    c.CategoryName,
    s.SupplierName,
    p.Unit,
    p.Quantity,
    p.MinQuantity,
    p.MaxQuantity,
    p.PurchasePrice,
    p.SellingPrice,
    (p.SellingPrice - p.PurchasePrice) AS Margin,
    CASE 
        WHEN p.Quantity <= p.MinQuantity THEN 'Критический'
        WHEN p.Quantity <= p.MinQuantity * 1.5 THEN 'Низкий'
        WHEN p.Quantity >= p.MaxQuantity THEN 'Избыток'
        ELSE 'Норма'
    END AS StockStatus,
    p.IsActive,
    p.CreatedDate
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID;
GO

-- Представление для просмотра поставок
CREATE VIEW vw_DeliveryDetails
AS
SELECT 
    d.DeliveryID,
    d.DeliveryNumber,
    s.SupplierName,
    d.DeliveryDate,
    d.ReceivedDate,
    d.Status,
    d.TotalAmount,
    COUNT(dd.DeliveryDetailID) AS ItemsCount,
    SUM(dd.Quantity) AS TotalQuantity,
    d.Notes
FROM Deliveries d
INNER JOIN Suppliers s ON d.SupplierID = s.SupplierID
LEFT JOIN DeliveryDetails dd ON d.DeliveryID = dd.DeliveryID
GROUP BY d.DeliveryID, d.DeliveryNumber, s.SupplierName, 
         d.DeliveryDate, d.ReceivedDate, d.Status, d.TotalAmount, d.Notes;
GO

-- Представление для статистики по категориям
CREATE VIEW vw_CategoryStatistics
AS
SELECT 
    c.CategoryID,
    c.CategoryName,
    COUNT(DISTINCT p.ProductID) AS ProductsCount,
    ISNULL(SUM(p.Quantity), 0) AS TotalQuantity,
    ISNULL(SUM(p.Quantity * p.PurchasePrice), 0) AS TotalStockValue,
    ISNULL(AVG(p.SellingPrice), 0) AS AvgSellingPrice,
    COUNT(DISTINCT s.SupplierID) AS SuppliersCount
FROM Categories c
LEFT JOIN Products p ON c.CategoryID = p.CategoryID AND p.IsActive = 1
LEFT JOIN Suppliers s ON p.SupplierID = s.SupplierID
GROUP BY c.CategoryID, c.CategoryName;
GO

-- Представление для товаров с низким остатком
CREATE VIEW vw_LowStockProducts
AS
SELECT TOP 100 PERCENT
    p.ProductCode,
    p.ProductName,
    c.CategoryName,
    s.SupplierName,
    p.Quantity,
    p.MinQuantity,
    (p.MinQuantity - p.Quantity) AS RequiredQuantity,
    p.Unit
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
WHERE p.Quantity <= p.MinQuantity AND p.IsActive = 1
ORDER BY (p.MinQuantity - p.Quantity) DESC;
GO

-- Представление для аудита
CREATE VIEW vw_AuditLog
AS
SELECT 
    AuditID,
    TableName,
    Action,
    RecordID,
    OldData,
    NewData,
    ChangedBy,
    ChangedDate
FROM AuditLog
ORDER BY ChangedDate DESC;
GO

PRINT 'Все представления успешно созданы';
GO