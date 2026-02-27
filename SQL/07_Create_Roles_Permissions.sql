USE GoodsAccounting;
GO

-- Создание ролей
CREATE ROLE db_Manager;
CREATE ROLE db_Operator;
CREATE ROLE db_Analyst;
GO

-- Предоставление прав менеджерам (полный доступ)
GRANT SELECT, INSERT, UPDATE, DELETE ON Products TO db_Manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON Categories TO db_Manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON Suppliers TO db_Manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON Deliveries TO db_Manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON DeliveryDetails TO db_Manager;
GRANT SELECT ON AuditLog TO db_Manager;
GRANT EXECUTE TO db_Manager;
GO

-- Предоставление прав операторам (ограниченный доступ)
GRANT SELECT, INSERT, UPDATE ON Products TO db_Operator;
GRANT SELECT ON Categories TO db_Operator;
GRANT SELECT ON Suppliers TO db_Operator;
GRANT SELECT, INSERT, UPDATE ON Deliveries TO db_Operator;
GRANT SELECT, INSERT ON DeliveryDetails TO db_Operator;
GRANT EXECUTE ON sp_SearchProducts TO db_Operator;
GRANT EXECUTE ON sp_RegisterDelivery TO db_Operator;
GRANT EXECUTE ON sp_ConfirmDelivery TO db_Operator;
DENY DELETE ON Products TO db_Operator;
DENY DELETE ON Suppliers TO db_Operator;
GO

-- Предоставление прав аналитикам (только чтение)
GRANT SELECT ON Products TO db_Analyst;
GRANT SELECT ON Categories TO db_Analyst;
GRANT SELECT ON Suppliers TO db_Analyst;
GRANT SELECT ON Deliveries TO db_Analyst;
GRANT SELECT ON DeliveryDetails TO db_Analyst;
GRANT SELECT ON vw_ProductDetails TO db_Analyst;
GRANT SELECT ON vw_DeliveryDetails TO db_Analyst;
GRANT SELECT ON vw_CategoryStatistics TO db_Analyst;
GRANT SELECT ON vw_LowStockProducts TO db_Analyst;
GRANT EXECUTE ON sp_SearchProducts TO db_Analyst;
GO

-- Создание пользователей (пример)
CREATE LOGIN Manager_Login WITH PASSWORD = 'StrongPassword123!';
CREATE USER Manager_User FOR LOGIN Manager_Login;
ALTER ROLE db_Manager ADD MEMBER Manager_User;
GO

CREATE LOGIN Operator_Login WITH PASSWORD = 'OperatorPass123!';
CREATE USER Operator_User FOR LOGIN Operator_Login;
ALTER ROLE db_Operator ADD MEMBER Operator_User;
GO

CREATE LOGIN Analyst_Login WITH PASSWORD = 'AnalystPass123!';
CREATE USER Analyst_User FOR LOGIN Analyst_Login;
ALTER ROLE db_Analyst ADD MEMBER Analyst_User;
GO

-- Ограничение доступа на уровне строк (RLS)
-- Создаем функцию для фильтрации
CREATE FUNCTION fn_ProductSecurityPredicate(@IsActive BIT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_securitypredicate_result
WHERE @IsActive = 1 OR USER_NAME() = 'Manager_User';
GO

-- Создаем политику безопасности
CREATE SECURITY POLICY ProductFilterPolicy
ADD FILTER PREDICATE dbo.fn_ProductSecurityPredicate(IsActive)
ON dbo.Products
WITH (STATE = ON);
GO

PRINT 'Роли и права доступа успешно настроены';
GO