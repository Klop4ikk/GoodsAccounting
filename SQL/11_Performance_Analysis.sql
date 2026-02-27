USE GoodsAccounting;
GO

-- Анализ производительности запросов

-- 1. Просмотр статистики использования индексов
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates,
    s.last_user_seek,
    s.last_user_scan,
    s.last_user_lookup,
    s.last_user_update
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID('GoodsAccounting')
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;
GO

-- 2. Поиск неиспользуемых индексов
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s 
    ON i.object_id = s.object_id AND i.index_id = s.index_id
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
    AND i.name IS NOT NULL
    AND s.index_id IS NULL
ORDER BY OBJECT_NAME(i.object_id), i.name;
GO

-- 3. Анализ фрагментации индексов
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.fragment_count,
    ips.avg_fragment_size_in_pages,
    ips.page_count
FROM sys.dm_db_index_physical_stats(
    DB_ID('GoodsAccounting'), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 5
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

-- 4. Мониторинг длительности запросов
SELECT TOP 10
    qs.total_worker_time/qs.execution_count AS AvgCPU,
    qs.total_elapsed_time/qs.execution_count AS AvgDuration,
    qs.total_logical_reads/qs.execution_count AS AvgReads,
    qs.execution_count,
    SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS QueryText,
    qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY AvgDuration DESC;
GO

-- 5. Анализ планов выполнения для ключевых запросов
DBCC SHOW_STATISTICS('Products', 'IX_Products_ProductName');
DBCC SHOW_STATISTICS('Products', 'IX_Products_CategoryID');
GO

-- 6. Проверка пропущенных индексов
SELECT 
    mid.statement AS Database_Table,
    migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) AS Improvement_Measure,
    migs.avg_total_user_cost,
    migs.avg_user_impact,
    migs.user_seeks,
    migs.user_scans,
    'CREATE INDEX IX_' + OBJECT_NAME(mid.object_id) + '_' +
    REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,''), ', ', '_'), '[', ''), ']', '') +
    CASE WHEN mid.inequality_columns IS NOT NULL 
         THEN '_' + REPLACE(REPLACE(REPLACE(mid.inequality_columns, ', ', '_'), '[', ''), ']', '')
         ELSE '' 
    END + ' ON ' + mid.statement + ' (' + ISNULL(mid.equality_columns,'') +
    CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END +
    ISNULL(mid.inequality_columns, '') + ')' +
    ISNULL(' INCLUDE (' + mid.included_columns + ')', '') AS ProposedIndex
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID('GoodsAccounting')
ORDER BY Improvement_Measure DESC;
GO