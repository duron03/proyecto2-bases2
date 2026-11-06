:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF N'$(NodeCode)' NOT IN (N'CORP', N'SJ', N'LI')
BEGIN
    THROW 51000, N'NodeCode debe ser CORP, SJ o LI.', 1;
END;

USE [master];
GO

IF DB_ID(N'PilotoReplicacion') IS NULL
BEGIN
    CREATE DATABASE [PilotoReplicacion];
END;
GO

ALTER DATABASE [PilotoReplicacion] SET RECOVERY SIMPLE;
GO

USE [PilotoReplicacion];
GO

IF N'$(NodeCode)' = N'CORP'
BEGIN
    IF SCHEMA_ID(N'sj') IS NULL
        EXEC(N'CREATE SCHEMA [sj] AUTHORIZATION [dbo];');

    IF SCHEMA_ID(N'limon') IS NULL
        EXEC(N'CREATE SCHEMA [limon] AUTHORIZATION [dbo];');

    IF OBJECT_ID(N'dbo.CatalogoPiloto', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.CatalogoPiloto
        (
            Id int NOT NULL,
            Nombre nvarchar(100) NOT NULL,
            VersionCatalogo int NOT NULL,
            Activo bit NOT NULL,
            LastEditedWhen datetime2(7) NOT NULL,
            CONSTRAINT PK_CatalogoPiloto PRIMARY KEY (Id)
        );
    END;

    IF OBJECT_ID(N'sj.OperacionPiloto', N'U') IS NULL
    BEGIN
        CREATE TABLE sj.OperacionPiloto
        (
            Id int NOT NULL,
            Descripcion nvarchar(100) NOT NULL,
            LastEditedWhen datetime2(7) NOT NULL,
            CONSTRAINT PK_sj_OperacionPiloto PRIMARY KEY (Id)
        );
    END;

    IF OBJECT_ID(N'limon.OperacionPiloto', N'U') IS NULL
    BEGIN
        CREATE TABLE limon.OperacionPiloto
        (
            Id int NOT NULL,
            Descripcion nvarchar(100) NOT NULL,
            LastEditedWhen datetime2(7) NOT NULL,
            CONSTRAINT PK_limon_OperacionPiloto PRIMARY KEY (Id)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoPiloto WHERE Id = 1)
    BEGIN
        INSERT INTO dbo.CatalogoPiloto
            (Id, Nombre, VersionCatalogo, Activo, LastEditedWhen)
        VALUES
            (1, N'Catalogo inicial del piloto', 1, 1, SYSUTCDATETIME());
    END;
END;

IF N'$(NodeCode)' IN (N'SJ', N'LI')
BEGIN
    IF OBJECT_ID(N'dbo.CatalogoPiloto', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.CatalogoPiloto
        (
            Id int NOT NULL,
            Nombre nvarchar(100) NOT NULL,
            VersionCatalogo int NOT NULL,
            Activo bit NOT NULL,
            LastEditedWhen datetime2(7) NOT NULL,
            CONSTRAINT PK_CatalogoPiloto PRIMARY KEY (Id)
        );
    END;

    IF OBJECT_ID(N'dbo.OperacionPiloto', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.OperacionPiloto
        (
            Id int NOT NULL,
            Descripcion nvarchar(100) NOT NULL,
            LastEditedWhen datetime2(7) NOT NULL,
            CONSTRAINT PK_OperacionPiloto PRIMARY KEY (Id)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.OperacionPiloto WHERE Id = 77)
    BEGIN
        INSERT INTO dbo.OperacionPiloto
            (Id, Descripcion, LastEditedWhen)
        VALUES
            (77, CONCAT(N'Fila inicial ', N'$(NodeCode)'), SYSUTCDATETIME());
    END;
END;
GO

SELECT N'$(NodeCode)' AS NodeCode, DB_NAME() AS DatabaseName, @@SERVERNAME AS ServerName;

