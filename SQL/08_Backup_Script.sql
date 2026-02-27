-- Скрипт для резервного копирования
USE master;
GO

DECLARE @BackupPath NVARCHAR(500) = 'C:\Backup\GoodsAccounting_';
DECLARE @FileName NVARCHAR(500) = @BackupPath + 
    FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + '.bak';

-- Полное резервное копирование
BACKUP DATABASE GoodsAccounting
TO DISK = @FileName
WITH 
    NAME = N'GoodsAccounting-Full Backup',
    DESCRIPTION = N'Полное резервное копирование базы данных учета товаров',
    STATS = 10,
    CHECKSUM,
    CONTINUE_AFTER_ERROR,
    COMPRESSION;
GO

-- Создание скрипта для автоматического резервного копирования
-- Сохраните как SQL Agent Job или планировщик задач Windows

/*
-- Пример задания для SQL Agent
USE msdb;
GO

EXEC dbo.sp_add_job
    @job_name = N'GoodsAccounting_Backup',
    @enabled = 1,
    @description = N'Ежедневное резервное копирование';

EXEC dbo.sp_add_jobstep
    @job_name = N'GoodsAccounting_Backup',
    @step_name = N'Backup Database',
    @command = N'
        DECLARE @FileName NVARCHAR(500) = ''C:\Backup\GoodsAccounting_'' + 
            FORMAT(GETDATE(), ''yyyyMMdd'') + ''.bak'';
        
        BACKUP DATABASE GoodsAccounting TO DISK = @FileName
        WITH COMPRESSION, STATS = 10;';

EXEC dbo.sp_add_schedule
    @schedule_name = N'DailyBackup',
    @freq_type = 4,
    @freq_interval = 1,
    @active_start_time = 230000;

EXEC dbo.sp_attach_schedule
    @job_name = N'GoodsAccounting_Backup',
    @schedule_name = N'DailyBackup';

EXEC dbo.sp_add_jobserver @job_name = N'GoodsAccounting_Backup';
GO
*/

PRINT 'Скрипт резервного копирования создан';
GO