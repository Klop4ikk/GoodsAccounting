USE GoodsAccounting;
GO

-- Тестовые данные
-- Добавление категорий
INSERT INTO Categories (CategoryName, Description) VALUES
('Электроника', 'Товары электронной промышленности'),
('Одежда', 'Товары легкой промышленности'),
('Продукты питания', 'Продовольственные товары');
GO

-- Добавление поставщиков
INSERT INTO Suppliers (SupplierName, ContactPerson, Phone, Email, INN) VALUES
('ООО "ТехноПост"', 'Иванов Иван', '+7(495)123-45-67', 'info@technopost.ru', '7701234567'),
('АО "Модный Дом"', 'Петрова Анна', '+7(495)234-56-78', 'sales@fashionhouse.ru', '7702345678'),
('ИП "Продукты+', 'Сидоров Петр', '+7(495)345-67-89', 'sidorov@products.ru', '7703456789');
GO

-- Добавление товаров
DECLARE @ProductID INT;

EXEC sp_AddProduct 
    @ProductCode = 'ELEC001',
    @ProductName = 'Ноутбук Asus',
    @CategoryID = 1,
    @SupplierID = 1,
    @Unit = 'шт',
    @PurchasePrice = 45000,
    @SellingPrice = 55000,
    @MinQuantity = 5,
    @MaxQuantity = 20,
    @Quantity = 10,
    @NewProductID = @ProductID OUTPUT;

EXEC sp_AddProduct 
    @ProductCode = 'ELEC002',
    @ProductName = 'Смартфон Samsung',
    @CategoryID = 1,
    @SupplierID = 1,
    @Unit = 'шт',
    @PurchasePrice = 25000,
    @SellingPrice = 32000,
    @MinQuantity = 10,
    @MaxQuantity = 30,
    @Quantity = 15,
    @NewProductID = @ProductID OUTPUT;

EXEC sp_AddProduct 
    @ProductCode = 'CLOTH001',
    @ProductName = 'Футболка мужская',
    @CategoryID = 2,
    @SupplierID = 2,
    @Unit = 'шт',
    @PurchasePrice = 500,
    @SellingPrice = 1200,
    @MinQuantity = 20,
    @MaxQuantity = 100,
    @Quantity = 50,
    @NewProductID = @ProductID OUTPUT;
GO

-- Тестовая поставка
DECLARE @DeliveryID INT;
DECLARE @Items NVARCHAR(MAX) = N'
[
    {"ProductID": 1, "Quantity": 5, "Price": 45000},
    {"ProductID": 2, "Quantity": 10, "Price": 25000}
]';

EXEC sp_RegisterDelivery 
    @DeliveryNumber = 'DEL2024001',
    @SupplierID = 1,
    @DeliveryDate = '2024-01-15',
    @DeliveryItems = @Items,
    @NewDeliveryID = @DeliveryID OUTPUT;

PRINT 'Создана поставка с ID: ' + CAST(@DeliveryID AS NVARCHAR(10));

-- Подтверждение поставки
EXEC sp_ConfirmDelivery @DeliveryID = @DeliveryID;
GO

-- Тестовые запросы для анализа производительности

-- Запрос 1: Поиск товаров с фильтрацией
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

PRINT '=== Тестовый запрос 1: Поиск товаров ===';
EXEC sp_SearchProducts @SearchTerm = 'Ноут', @LowStockOnly = 0;

-- Запрос 2: Анализ остатков
PRINT '=== Тестовый запрос 2: Анализ остатков ===';
SELECT 
    CategoryName,
    COUNT(*) as ProductCount,
    SUM(Quantity) as TotalQuantity,
    AVG(Quantity) as AvgQuantity,
    SUM(CASE WHEN Quantity <= MinQuantity THEN 1 ELSE 0 END) as LowStockCount
FROM vw_ProductDetails
GROUP BY CategoryName;

-- Запрос 3: Статистика поставок
PRINT '=== Тестовый запрос 3: Статистика поставок ===';
SELECT 
    SupplierName,
    COUNT(*) as DeliveriesCount,
    SUM(TotalAmount) as TotalAmount,
    AVG(TotalAmount) as AvgAmount
FROM vw_DeliveryDetails
GROUP BY SupplierName;

-- Запрос 4: Сложный запрос с объединением
PRINT '=== Тестовый запрос 4: Детальный отчет ===';
SELECT 
    p.ProductName,
    c.CategoryName,
    s.SupplierName,
    p.Quantity,
    p.PurchasePrice,
    p.SellingPrice,
    ISNULL((
        SELECT SUM(dd.Quantity)
        FROM DeliveryDetails dd
        INNER JOIN Deliveries d ON dd.DeliveryID = d.DeliveryID
        WHERE dd.ProductID = p.ProductID AND d.Status = 'Принята'
    ), 0) as TotalDelivered
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
WHERE p.IsActive = 1;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO