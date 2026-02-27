# 📦 GoodsAccounting

**База данных для учета товаров, категорий и поставщиков**

[![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-CC2927?logo=microsoft-sql-server)](https://www.microsoft.com/sql-server)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## 📋 О проекте

Проект представляет собой полноценную базу данных для автоматизации складского учета. Разработан в рамках учебной практики по администрированию и оптимизации баз данных.

**Функционал:**
- 🏷️ Управление категориями товаров
- 🚚 Работа с поставщиками
- 📦 Учет товаров и остатков
- 📝 Регистрация поставок
- 🔍 Поиск и фильтрация
- 📊 Отчеты и аналитика

---

## 🚀 Быстрый старт

### Требования
- SQL Server 2019/2022
- SQL Server Management Studio (SSMS)

### Установка за 5 минут

```sql
-- 1. Создать базу
CREATE DATABASE GoodsAccounting;
GO

USE GoodsAccounting;
GO

-- 2. Запустить все скрипты по порядку:
-- 01_Create_Database.sql
-- 02_Create_Tables.sql
-- 03_Create_Indexes.sql
-- ... и так далее до 11
