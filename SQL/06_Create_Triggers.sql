USE GoodsAccounting;
GO

-- Триггер для обновления даты модификации в Products
CREATE TRIGGER trg_Products_UpdateModified
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE p
    SET ModifiedDate = GETDATE()
    FROM Products p
    INNER JOIN inserted i ON p.ProductID = i.ProductID;
    
    -- Логирование изменений
    INSERT INTO AuditLog (TableName, Action, RecordID, OldData, NewData, ChangedBy)
    SELECT 
        'Products',
        'UPDATE',
        i.ProductID,
        (SELECT * FROM deleted d WHERE d.ProductID = i.ProductID FOR JSON AUTO),
        (SELECT * FROM inserted i2 WHERE i2.ProductID = i.ProductID FOR JSON AUTO),
        SUSER_NAME()
    FROM inserted i
    INNER JOIN deleted d ON i.ProductID = d.ProductID;
END;
GO

-- Триггер для проверки минимального остатка
CREATE TRIGGER trg_Products_CheckMinQuantity
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE i.Quantity <= i.MinQuantity 
          AND i.Quantity > 0
    )
    BEGIN
        PRINT 'Внимание: некоторые товары достигли минимального остатка';
    END
END;
GO

-- Триггер для обновления общей суммы поставки
CREATE TRIGGER trg_DeliveryDetails_UpdateTotal
ON DeliveryDetails
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE d
    SET TotalAmount = (
        SELECT ISNULL(SUM(Amount), 0)
        FROM DeliveryDetails
        WHERE DeliveryID = d.DeliveryID
    )
    FROM Deliveries d
    WHERE d.DeliveryID IN (
        SELECT DeliveryID FROM inserted
        UNION
        SELECT DeliveryID FROM deleted
    );
END;
GO

-- Триггер для защиты от удаления поставщиков с товарами
CREATE TRIGGER trg_Suppliers_PreventDelete
ON Suppliers
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 
        FROM deleted d
        INNER JOIN Products p ON d.SupplierID = p.SupplierID
    )
    BEGIN
        -- Вместо удаления деактивируем поставщика
        UPDATE s
        SET IsActive = 0
        FROM Suppliers s
        INNER JOIN deleted d ON s.SupplierID = d.SupplierID;
        
        PRINT 'Поставщик деактивирован вместо удаления';
    END
    ELSE
    BEGIN
        -- Если нет связанных товаров, удаляем
        DELETE FROM Suppliers
        WHERE SupplierID IN (SELECT SupplierID FROM deleted);
    END
END;
GO

-- Триггер для валидации данных при вставке в DeliveryDetails
CREATE TRIGGER trg_DeliveryDetails_Validate
ON DeliveryDetails
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Проверяем существование товаров и поставок
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        LEFT JOIN Products p ON i.ProductID = p.ProductID
        LEFT JOIN Deliveries d ON i.DeliveryID = d.DeliveryID
        WHERE p.ProductID IS NULL OR d.DeliveryID IS NULL
    )
    BEGIN
        RAISERROR('Неверный ProductID или DeliveryID', 16, 1);
        RETURN;
    END
    
    -- Вставляем валидные данные
    INSERT INTO DeliveryDetails (DeliveryID, ProductID, Quantity, Price)
    SELECT DeliveryID, ProductID, Quantity, Price
    FROM inserted;
END;
GO

PRINT 'Все триггеры успешно созданы';
GO