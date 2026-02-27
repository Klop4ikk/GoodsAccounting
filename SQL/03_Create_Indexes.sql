USE GoodsAccounting;
GO

-- Индексы для таблицы Products
CREATE INDEX IX_Products_CategoryID ON Products(CategoryID);
CREATE INDEX IX_Products_SupplierID ON Products(SupplierID);
CREATE INDEX IX_Products_ProductCode ON Products(ProductCode);
CREATE INDEX IX_Products_ProductName ON Products(ProductName);
CREATE INDEX IX_Products_Price ON Products(PurchasePrice, SellingPrice);
CREATE INDEX IX_Products_Quantity ON Products(Quantity) WHERE Quantity <= MinQuantity;
GO

-- Индексы для таблицы Deliveries
CREATE INDEX IX_Deliveries_SupplierID ON Deliveries(SupplierID);
CREATE INDEX IX_Deliveries_DeliveryDate ON Deliveries(DeliveryDate);
CREATE INDEX IX_Deliveries_Status ON Deliveries(Status);
CREATE INDEX IX_Deliveries_DeliveryNumber ON Deliveries(DeliveryNumber);
GO

-- Индексы для таблицы DeliveryDetails
CREATE INDEX IX_DeliveryDetails_DeliveryID ON DeliveryDetails(DeliveryID);
CREATE INDEX IX_DeliveryDetails_ProductID ON DeliveryDetails(ProductID);
GO

-- Индексы для таблицы Suppliers
CREATE INDEX IX_Suppliers_Name ON Suppliers(SupplierName);
CREATE INDEX IX_Suppliers_INN ON Suppliers(INN) WHERE INN IS NOT NULL;
CREATE INDEX IX_Suppliers_IsActive ON Suppliers(IsActive);
GO

-- Индексы для таблицы Categories
CREATE INDEX IX_Categories_Name ON Categories(CategoryName);
CREATE INDEX IX_Categories_ParentID ON Categories(ParentCategoryID);
GO

-- Полнотекстовый индекс для поиска
CREATE FULLTEXT CATALOG ftCatalog AS DEFAULT;
GO

CREATE FULLTEXT INDEX ON Products(ProductName, ProductCode)
    KEY INDEX PK_Products_ProductID
    WITH STOPLIST = SYSTEM;
GO

PRINT 'Все индексы успешно созданы';
GO