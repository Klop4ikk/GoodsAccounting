USE GoodsAccounting;
GO

-- Таблица категорий товаров
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    ParentCategoryID INT NULL,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Categories_Parent FOREIGN KEY (ParentCategoryID) 
        REFERENCES Categories(CategoryID)
);
GO

-- Таблица поставщиков
CREATE TABLE Suppliers (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName NVARCHAR(200) NOT NULL,
    ContactPerson NVARCHAR(100) NULL,
    Phone NVARCHAR(20) NULL,
    Email NVARCHAR(100) NULL,
    Address NVARCHAR(500) NULL,
    INN NVARCHAR(12) NULL, -- ИНН
    KPP NVARCHAR(9) NULL,   -- КПП
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_Suppliers_INN UNIQUE (INN),
    CONSTRAINT UQ_Suppliers_Email UNIQUE (Email)
);
GO

-- Таблица товаров
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductCode NVARCHAR(50) NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    CategoryID INT NOT NULL,
    SupplierID INT NOT NULL,
    Unit NVARCHAR(20) NOT NULL, -- единица измерения
    Quantity DECIMAL(18, 3) DEFAULT 0,
    MinQuantity DECIMAL(18, 3) DEFAULT 0, -- минимальный остаток
    MaxQuantity DECIMAL(18, 3) DEFAULT 0, -- максимальный остаток
    PurchasePrice DECIMAL(18, 2) NOT NULL,
    SellingPrice DECIMAL(18, 2) NOT NULL,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Products_Category FOREIGN KEY (CategoryID) 
        REFERENCES Categories(CategoryID),
    CONSTRAINT FK_Products_Supplier FOREIGN KEY (SupplierID) 
        REFERENCES Suppliers(SupplierID),
    CONSTRAINT UQ_Products_Code UNIQUE (ProductCode),
    CONSTRAINT CHK_Price CHECK (PurchasePrice > 0 AND SellingPrice >= PurchasePrice),
    CONSTRAINT CHK_Quantity CHECK (Quantity >= 0)
);
GO

-- Таблица поставок
CREATE TABLE Deliveries (
    DeliveryID INT IDENTITY(1,1) PRIMARY KEY,
    DeliveryNumber NVARCHAR(50) NOT NULL,
    SupplierID INT NOT NULL,
    DeliveryDate DATE NOT NULL,
    ReceivedDate DATE NULL,
    Status NVARCHAR(20) DEFAULT 'Ожидание', -- Ожидание, Принята, Отменена
    TotalAmount DECIMAL(18, 2) DEFAULT 0,
    Notes NVARCHAR(500) NULL,
    CreatedBy NVARCHAR(100) NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Deliveries_Supplier FOREIGN KEY (SupplierID) 
        REFERENCES Suppliers(SupplierID),
    CONSTRAINT UQ_Deliveries_Number UNIQUE (DeliveryNumber),
    CONSTRAINT CHK_Delivery_Status CHECK (Status IN ('Ожидание', 'Принята', 'Отменена'))
);
GO

-- Таблица деталей поставок
CREATE TABLE DeliveryDetails (
    DeliveryDetailID INT IDENTITY(1,1) PRIMARY KEY,
    DeliveryID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity DECIMAL(18, 3) NOT NULL,
    Price DECIMAL(18, 2) NOT NULL,
    Amount AS (Quantity * Price) PERSISTED,
    CONSTRAINT FK_DeliveryDetails_Delivery FOREIGN KEY (DeliveryID) 
        REFERENCES Deliveries(DeliveryID) ON DELETE CASCADE,
    CONSTRAINT FK_DeliveryDetails_Product FOREIGN KEY (ProductID) 
        REFERENCES Products(ProductID),
    CONSTRAINT CHK_Delivery_Quantity CHECK (Quantity > 0),
    CONSTRAINT CHK_Delivery_Price CHECK (Price > 0)
);
GO

-- Таблица для логирования изменений
CREATE TABLE AuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(100) NOT NULL,
    Action NVARCHAR(20) NOT NULL, -- INSERT, UPDATE, DELETE
    RecordID INT NOT NULL,
    OldData NVARCHAR(MAX) NULL,
    NewData NVARCHAR(MAX) NULL,
    ChangedBy NVARCHAR(100) NULL,
    ChangedDate DATETIME DEFAULT GETDATE()
);
GO

PRINT 'Все таблицы успешно созданы';
GO