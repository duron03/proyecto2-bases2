:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

IF N'$(NodeCode)' NOT IN (N'CORP', N'SJ', N'LI')
BEGIN
    THROW 51120, N'NodeCode debe ser CORP, SJ o LI.', 1;
END;

IF SCHEMA_ID(N'Control') IS NULL EXEC(N'CREATE SCHEMA [Control] AUTHORIZATION [dbo];');

IF OBJECT_ID(N'Control.Nodo', N'U') IS NULL
BEGIN
    CREATE TABLE Control.Nodo
    (
        Id tinyint NOT NULL,
        Codigo varchar(4) NOT NULL,
        SucursalID int NULL,
        CONSTRAINT PK_Control_Nodo PRIMARY KEY (Id),
        CONSTRAINT CK_Control_Nodo_Id CHECK (Id = 1),
        CONSTRAINT CK_Control_Nodo_Codigo CHECK (Codigo IN ('CORP', 'SJ', 'LI')),
        CONSTRAINT CK_Control_Nodo_Sucursal CHECK
        (
            (Codigo = 'CORP' AND SucursalID IS NULL)
            OR (Codigo = 'SJ' AND SucursalID = 1)
            OR (Codigo = 'LI' AND SucursalID = 2)
        )
    );
END;

IF EXISTS (SELECT 1 FROM Control.Nodo)
BEGIN
    IF NOT EXISTS
    (
        SELECT 1
        FROM Control.Nodo
        WHERE Id = 1
          AND Codigo = N'$(NodeCode)'
          AND
          (
              (N'$(NodeCode)' = N'CORP' AND SucursalID IS NULL)
              OR (N'$(NodeCode)' = N'SJ' AND SucursalID = 1)
              OR (N'$(NodeCode)' = N'LI' AND SucursalID = 2)
          )
    )
        THROW 51121, N'Control.Nodo ya contiene otra identidad. No se reemplaza.', 1;
END;
ELSE
BEGIN
    INSERT INTO Control.Nodo (Id, Codigo, SucursalID)
    SELECT
        1,
        N'$(NodeCode)',
        CASE N'$(NodeCode)' WHEN N'SJ' THEN 1 WHEN N'LI' THEN 2 ELSE NULL END;
END;

IF OBJECT_ID(N'Control.LatidoCatalogo', N'U') IS NULL
BEGIN
    CREATE TABLE Control.LatidoCatalogo
    (
        Id tinyint NOT NULL,
        FechaUtc datetime2(7) NOT NULL,
        CONSTRAINT PK_Control_LatidoCatalogo PRIMARY KEY (Id),
        CONSTRAINT CK_Control_LatidoCatalogo_Id CHECK (Id = 1)
    );
END;

IF N'$(NodeCode)' = N'CORP'
   AND NOT EXISTS (SELECT 1 FROM Control.LatidoCatalogo WHERE Id = 1)
BEGIN
    INSERT INTO Control.LatidoCatalogo (Id, FechaUtc)
    VALUES (1, SYSUTCDATETIME());
END;

IF N'$(NodeCode)' IN (N'SJ', N'LI')
BEGIN
    IF OBJECT_ID(N'Control.LatidoSucursal', N'U') IS NULL
    BEGIN
        CREATE TABLE Control.LatidoSucursal
        (
            SucursalID int NOT NULL,
            FechaUtc datetime2(7) NOT NULL,
            CONSTRAINT PK_Control_LatidoSucursal PRIMARY KEY (SucursalID),
            CONSTRAINT CK_Control_LatidoSucursal_Rango CHECK (SucursalID IN (1, 2))
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM Control.LatidoSucursal)
    BEGIN
        INSERT INTO Control.LatidoSucursal (SucursalID, FechaUtc)
        VALUES
        (
            CASE N'$(NodeCode)' WHEN N'SJ' THEN 1 ELSE 2 END,
            SYSUTCDATETIME()
        );
    END;

    IF OBJECT_ID(N'Control.EstadoCatalogo', N'U') IS NULL
    BEGIN
        CREATE TABLE Control.EstadoCatalogo
        (
            Id tinyint NOT NULL,
            DatosValidados bit NOT NULL,
            ValidadoUtc datetime2(7) NULL,
            CONSTRAINT PK_Control_EstadoCatalogo PRIMARY KEY (Id),
            CONSTRAINT CK_Control_EstadoCatalogo_Id CHECK (Id = 1)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM Control.EstadoCatalogo WHERE Id = 1)
    BEGIN
        INSERT INTO Control.EstadoCatalogo (Id, DatosValidados, ValidadoUtc)
        VALUES (1, 0, NULL);
    END;
END;

IF N'$(NodeCode)' = N'CORP'
BEGIN
    IF OBJECT_ID(N'Control.EstadoInicializacion', N'U') IS NULL
    BEGIN
        CREATE TABLE Control.EstadoInicializacion
        (
            SucursalID int NOT NULL,
            DatosValidados bit NOT NULL,
            ValidadoUtc datetime2(7) NULL,
            CONSTRAINT PK_Control_EstadoInicializacion PRIMARY KEY (SucursalID),
            CONSTRAINT CK_Control_EstadoInicializacion_Sucursal CHECK (SucursalID IN (1, 2))
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM Control.EstadoInicializacion)
    BEGIN
        INSERT INTO Control.EstadoInicializacion
            (SucursalID, DatosValidados, ValidadoUtc)
        VALUES
            (1, 0, NULL),
            (2, 0, NULL);
    END;
END;

SELECT Codigo, SucursalID
FROM Control.Nodo;
GO

/* Limite explicito para que los cuatro motores puedan convivir en Docker Desktop. */
USE [master];
GO
DECLARE @MaxMemoryMb int =
    CASE N'$(NodeCode)' WHEN N'CORP' THEN 2000 ELSE 900 END;

EXEC sys.sp_configure N'show advanced options', 1;
RECONFIGURE;
EXEC sys.sp_configure N'max server memory (MB)', @MaxMemoryMb;
RECONFIGURE;
GO

USE [WideWorldImporters];

