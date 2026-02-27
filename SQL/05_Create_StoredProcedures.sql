USE GoodsAccounting;
GO

-- Процедура добавления нового товара
CREATE PROCEDURE sp_AddProduct
    @ProductCode NVARCHAR(50),
    @ProductName NVARCHAR(200),
    @CategoryID INT,
    @SupplierID INT,
    @Unit NVARCHAR(20),
    @PurchasePrice DECIMAL(18,2),
    @SellingPrice DECIMAL(18,2),
    @MinQuantity DECIMAL(18,3) = 0,
    @MaxQuantity DECIMAL(18,3) = 0,
    @Quantity DECIMAL(18,3) = 0,
    @NewProductID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Проверка существования категории
        IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryID = @CategoryID)
        BEGIN
            RAISERROR('Категория не существует', 16, 1);
            RETURN;
        END
        
        -- Проверка существования поставщика
        IF NOT EXISTS (SELECT 1 FROM Suppliers WHERE SupplierID = @SupplierID)
        BEGIN
            RAISERROR('Поставщик не существует', 16, 1);
            RETURN;
        END
        
        -- Проверка уникальности кода товара
        IF EXISTS (SELECT 1 FROM Products WHERE ProductCode = @ProductCode)
        BEGIN
            RAISERROR('Товар с таким кодом уже существует', 16, 1);
            RETURN;
        END
        
        -- Вставка товара
        INSERT INTO Products (
            ProductCode, ProductName, CategoryID, SupplierID, Unit,
            PurchasePrice, SellingPrice, MinQuantity, MaxQuantity, Quantity
        )
        VALUES (
            @ProductCode, @ProductName, @CategoryID, @SupplierID, @Unit,
            @PurchasePrice, @SellingPrice, @MinQuantity, @MaxQuantity, @Quantity
        );
        
        SET @NewProductID = SCOPE_IDENTITY();
        
        -- Логирование
        INSERT INTO AuditLog (TableName, Action, RecordID, NewData, ChangedBy)
        VALUES ('Products', 'INSERT', @NewProductID, 
                (SELECT * FROM Products WHERE ProductID = @NewProductID FOR JSON AUTO),
                SUSER_NAME());
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END;
GO

-- Процедура регистрации поставки
CREATE PROCEDURE sp_RegisterDelivery
    @DeliveryNumber NVARCHAR(50),
    @SupplierID INT,
    @DeliveryDate DATE,
    @DeliveryItems NVARCHAR(MAX), -- JSON массив с товарами
    @NewDeliveryID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Проверка существования поставщика
        IF NOT EXISTS (SELECT 1 FROM Suppliers WHERE SupplierID = @SupplierID)
        BEGIN
            RAISERROR('Поставщик не существует', 16, 1);
            RETURN;
        END
        
        -- Проверка уникальности номера поставки
        IF EXISTS (SELECT 1 FROM Deliveries WHERE DeliveryNumber = @DeliveryNumber)
        BEGIN
            RAISERROR('Поставка с таким номером уже существует', 16, 1);
            RETURN;
        END
        
        -- Создание поставки
        INSERT INTO Deliveries (DeliveryNumber, SupplierID, DeliveryDate, Status)
        VALUES (@DeliveryNumber, @SupplierID, @DeliveryDate, 'Ожидание');
        
        SET @NewDeliveryID = SCOPE_IDENTITY();
        
        -- Вставка деталей поставки из JSON
        INSERT INTO DeliveryDetails (DeliveryID, ProductID, Quantity, Price)
        SELECT 
            @NewDeliveryID,
            JSON_VALUE(item.value, '$.ProductID') AS ProductID,
            JSON_VALUE(item.value, '$.Quantity') AS Quantity,
            JSON_VALUE(item.value, '$.Price') AS Price
        FROM OPENJSON(@DeliveryItems) AS item;
        
        -- Обновление общей суммы поставки
        UPDATE Deliveries
        SET TotalAmount = (SELECT SUM(Amount) FROM DeliveryDetails WHERE DeliveryID = @NewDeliveryID)
        WHERE DeliveryID = @NewDeliveryID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END;
GO

-- Процедура подтверждения поставки
CREATE PROCEDURE sp_ConfirmDelivery
    @DeliveryID INT,
    @ReceivedDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Проверка существования поставки
        IF NOT EXISTS (SELECT 1 FROM Deliveries WHERE DeliveryID = @DeliveryID)
        BEGIN
            RAISERROR('Поставка не существует', 16, 1);
            RETURN;
        END
        
        -- Проверка статуса
        IF EXISTS (SELECT 1 FROM Deliveries WHERE DeliveryID = @DeliveryID AND Status != 'Ожидание')
        BEGIN
            RAISERROR('Поставка уже обработана', 16, 1);
            RETURN;
        END
        
        -- Обновление остатков товаров
        UPDATE p
        SET 
            p.Quantity = p.Quantity + dd.Quantity,
            p.ModifiedDate = GETDATE()
        FROM Products p
        INNER JOIN DeliveryDetails dd ON p.ProductID = dd.ProductID
        WHERE dd.DeliveryID = @DeliveryID;
        
        -- Обновление статуса поставки
        UPDATE Deliveries
        SET 
            Status = 'Принята',
            ReceivedDate = ISNULL(@ReceivedDate, GETDATE()),
            ModifiedDate = GETDATE()
        WHERE DeliveryID = @DeliveryID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END;
GO

-- Процедура поиска товаров
CREATE PROCEDURE sp_SearchProducts
    @SearchTerm NVARCHAR(200) = NULL,
    @CategoryID INT = NULL,
    @SupplierID INT = NULL,
    @MinPrice DECIMAL(18,2) = NULL,
    @MaxPrice DECIMAL(18,2) = NULL,
    @LowStockOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.ProductID,
        p.ProductCode,
        p.ProductName,
        c.CategoryName,
        s.SupplierName,
        p.Quantity,
        p.MinQuantity,
        p.PurchasePrice,
        p.SellingPrice,
        CASE 
            WHEN p.Quantity <= p.MinQuantity THEN 'Критический'
            ELSE 'Норма'
        END AS StockStatus
    FROM Products p
    INNER JOIN Categories c ON p.CategoryID = c.CategoryID
    INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
    WHERE p.IsActive = 1
        AND (@SearchTerm IS NULL OR 
             p.ProductName LIKE '%' + @SearchTerm + '%' OR 
             p.ProductCode LIKE '%' + @SearchTerm + '%')
        AND (@CategoryID IS NULL OR p.CategoryID = @CategoryID)
        AND (@SupplierID IS NULL OR p.SupplierID = @SupplierID)
        AND (@MinPrice IS NULL OR p.SellingPrice >= @MinPrice)
        AND (@MaxPrice IS NULL OR p.SellingPrice <= @MaxPrice)
        AND (@LowStockOnly = 0 OR p.Quantity <= p.MinQuantity)
    ORDER BY 
        CASE WHEN p.Quantity <= p.MinQuantity THEN 0 ELSE 1 END,
        p.ProductName;
END;
GO

PRINT 'Все хранимые процедуры успешно созданы';
GO