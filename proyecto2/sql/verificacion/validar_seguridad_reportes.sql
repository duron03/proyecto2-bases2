:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

IF (SELECT COUNT(*) FROM Seguridad.Usuarios) <> 3
    THROW 51630, 'Deben existir exactamente tres usuarios de demostracion.', 1;

IF EXISTS
(
    SELECT 1
    FROM Seguridad.Usuarios
    WHERE [password] IS NULL OR DATALENGTH([password]) = 0
)
    THROW 51631, 'Existe una contrasena sin cifrado almacenado.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = N'CertUsuarios')
   OR NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = N'ClaveUsuarios')
    THROW 51632, 'Falta el certificado o la clave simetrica de usuarios.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS RM
    INNER JOIN sys.database_principals AS R ON RM.role_principal_id = R.principal_id
    INNER JOIN sys.database_principals AS U ON RM.member_principal_id = U.principal_id
    WHERE U.name IN (N'admin_sj', N'admin_limon', N'corporativo')
      AND R.name IN (N'db_owner', N'db_datareader', N'db_datawriter')
)
    THROW 51633, 'Un usuario de la aplicacion tiene un rol general prohibido.', 1;

IF (SELECT COUNT(*) FROM sys.procedures WHERE name LIKE N'usp_Estadisticas_Reporte%') <> 9
    THROW 51634, 'No estan instalados los nueve reportes existentes.', 1;

IF (SELECT COUNT(*) FROM sys.views WHERE schema_id = SCHEMA_ID(N'Corporativo')) < 7
    THROW 51635, 'Faltan vistas corporativas de hechos.', 1;

IF (SELECT COUNT_BIG(*) FROM Corporativo.v_Invoices)
   <> (SELECT COUNT_BIG(*) FROM sj.Invoices) + (SELECT COUNT_BIG(*) FROM limon.Invoices)
    THROW 51636, 'La vista de facturas no reconstruye las dos sucursales.', 1;

IF (SELECT COUNT_BIG(*) FROM Corporativo.v_InvoiceLines)
   <> (SELECT COUNT_BIG(*) FROM sj.InvoiceLines) + (SELECT COUNT_BIG(*) FROM limon.InvoiceLines)
    THROW 51637, 'La vista de lineas no reconstruye las dos sucursales.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM Control.EstadoMaterializacion
    WHERE Id = 1
      AND EstadoUltimoIntento = 'correcto'
      AND UltimoExitoUtc IS NOT NULL
      AND DATEDIFF(SECOND, UltimoExitoUtc, SYSUTCDATETIME()) <= 180
)
    THROW 51638, 'La materializacion no tiene un exito reciente.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM msdb.dbo.sysjobs AS J
    WHERE J.name = N'P2_Resumen_Ventas_Mensuales'
      AND J.enabled = 1
)
    THROW 51639, 'El job de resumen no existe o esta deshabilitado.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM msdb.dbo.sysjobhistory AS H
    INNER JOIN msdb.dbo.sysjobs AS J ON H.job_id = J.job_id
    WHERE J.name = N'P2_Resumen_Ventas_Mensuales'
      AND H.step_id = 0
      AND H.run_status = 1
)
    THROW 51640, 'El job de resumen no registra una ejecucion exitosa.', 1;

SELECT
    (SELECT COUNT(*) FROM Seguridad.Usuarios) AS Usuarios,
    (SELECT COUNT(*) FROM sys.procedures WHERE name LIKE N'usp_Estadisticas_Reporte%') AS Reportes,
    (SELECT COUNT(*) FROM Corporativo.ResumenVentasMensuales) AS FilasResumen,
    (SELECT UltimoExitoUtc FROM Control.EstadoMaterializacion WHERE Id = 1) AS UltimoExitoUtc;
GO

SELECT N'SEGURIDAD_Y_REPORTES_VALIDADOS' AS Result;
GO

