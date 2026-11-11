:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

IF SCHEMA_ID(N'Privado') IS NOT NULL
    THROW 51650, 'La sucursal no debe contener el esquema Privado.', 1;

IF OBJECT_ID(N'Seguridad.Usuarios', N'U') IS NOT NULL
    THROW 51651, 'La sucursal no debe contener la tabla corporativa de usuarios.', 1;

IF OBJECT_ID(N'Seguridad.IdentidadesLocales', N'U') IS NULL
    THROW 51652, 'Falta la identidad minima local de la sucursal.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'Application.People')
      AND name IN
      (
          N'PhoneNumber', N'FaxNumber', N'EmailAddress',
          N'UserPreferences', N'LogonName', N'HashedPassword'
      )
)
    THROW 51653, 'People contiene columnas privadas en la sucursal.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.tables
    WHERE temporal_type <> 0
)
    THROW 51654, 'La sucursal contiene tablas temporales no autorizadas.', 1;

SELECT
    (SELECT COUNT(*) FROM Seguridad.IdentidadesLocales) AS IdentidadesLocales,
    (SELECT COUNT(*) FROM Application.People) AS PersonasPublicas,
    N'PRIVACIDAD_SUCURSAL_VALIDADA' AS Result;
GO
