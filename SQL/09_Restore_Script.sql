-- Скрипт для восстановления базы данных
USE master;
GO

-- Проверяем существование базы и закрываем соединения
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'GoodsAccounting')
BEGIN
    ALTER DATABASE GoodsAccounting SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
END
GO

-- Восстановление из последней резервной копии
DECLARE @BackupFile NVARCHAR(500);
DECLARE @LastBackup TABLE (BackupPath NVARCHAR(500));

-- Получаем путь к последней резервной копии
INSERT INTO @LastBackup
SELECT TOP 1 
    'C:\Backup\' + name
FROM sys.master_files
WHERE database_id = DB_ID('master') -- заглушка, нужно заменить на реальный поиск файлов

SELECT @BackupFile = BackupPath FROM @LastBackup;

-- Восстановление базы данных
RESTORE DATABASE GoodsAccounting
FROM DISK = @BackupFile
WITH 
    REPLACE,
    RECOVERY,
    STATS = 10,
    MOVE 'GoodsAccounting_Data' TO 
        'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\GoodsAccounting_Data.mdf',
    MOVE 'GoodsAccounting_Log' TO 
        'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\GoodsAccounting_Log.ldf';
GO

-- Возвращаем базу в многопользовательский режим
ALTER DATABASE GoodsAccounting SET MULTI_USER;
GO

PRINT 'База данных успешно восстановлена';
GO