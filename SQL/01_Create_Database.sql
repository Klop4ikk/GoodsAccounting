-- Создание базы данных GoodsAccounting
USE master;
GO

-- Проверяем существование БД и удаляем если есть
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'GoodsAccounting')
BEGIN
    ALTER DATABASE GoodsAccounting SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GoodsAccounting;
END
GO

-- Создаем базу данных с оптимальными настройками
CREATE DATABASE GoodsAccounting
ON PRIMARY
(
    NAME = N'GoodsAccounting_Data',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\GoodsAccounting_Data.mdf',
    SIZE = 10MB,
    MAXSIZE = 1GB,
    FILEGROWTH = 10MB
)
LOG ON
(
    NAME = N'GoodsAccounting_Log',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\GoodsAccounting_Log.ldf',
    SIZE = 5MB,
    MAXSIZE = 500MB,
    FILEGROWTH = 5MB
);
GO

USE GoodsAccounting;
GO

-- Устанавливаем параметры базы данных
ALTER DATABASE GoodsAccounting SET RECOVERY FULL;
ALTER DATABASE GoodsAccounting SET AUTO_CREATE_STATISTICS ON;
ALTER DATABASE GoodsAccounting SET AUTO_UPDATE_STATISTICS ON;
ALTER DATABASE GoodsAccounting SET AUTO_SHRINK OFF;
GO

PRINT 'База данных GoodsAccounting успешно создана';
GO