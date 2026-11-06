:on error exit
SET NOCOUNT ON;

USE [PilotoReplicacion];
GO

IF N'$(NodeCode)' NOT IN (N'CORP', N'SJ', N'LI')
BEGIN
    THROW 51012, N'NodeCode debe ser CORP, SJ o LI.', 1;
END;

IF N'$(Expected)' NOT IN (N'INSERT', N'UPDATE', N'DELETE')
BEGIN
    THROW 51013, N'Expected debe ser INSERT, UPDATE o DELETE.', 1;
END;

IF N'$(NodeCode)' IN (N'SJ', N'LI') AND N'$(Expected)' = N'INSERT'
BEGIN
    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.CatalogoPiloto
        WHERE Id = 2
          AND Nombre = N'INSERT catalogo piloto'
          AND VersionCatalogo = 1
    )
        THROW 51014, N'El INSERT de catalogo no llego a la sucursal.', 1;
END;

IF N'$(NodeCode)' IN (N'SJ', N'LI') AND N'$(Expected)' = N'UPDATE'
BEGIN
    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.CatalogoPiloto
        WHERE Id = 2
          AND Nombre = N'UPDATE catalogo piloto'
          AND VersionCatalogo = 2
    )
        THROW 51015, N'El UPDATE de catalogo no llego a la sucursal.', 1;
END;

IF N'$(NodeCode)' IN (N'SJ', N'LI') AND N'$(Expected)' = N'DELETE'
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.CatalogoPiloto WHERE Id = 2)
        THROW 51016, N'El DELETE de catalogo no llego a la sucursal.', 1;
END;

IF N'$(NodeCode)' = N'CORP' AND N'$(Expected)' = N'INSERT'
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sj.OperacionPiloto WHERE Id = 88 AND Descripcion = N'INSERT operacion SJ')
        THROW 51017, N'El INSERT de SJ no llego a CORP.', 1;

    IF NOT EXISTS (SELECT 1 FROM limon.OperacionPiloto WHERE Id = 88 AND Descripcion = N'INSERT operacion LI')
        THROW 51018, N'El INSERT de LI no llego a CORP.', 1;
END;

IF N'$(NodeCode)' = N'CORP' AND N'$(Expected)' = N'UPDATE'
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sj.OperacionPiloto WHERE Id = 88 AND Descripcion = N'UPDATE operacion SJ')
        THROW 51019, N'El UPDATE de SJ no llego a CORP.', 1;

    IF NOT EXISTS (SELECT 1 FROM limon.OperacionPiloto WHERE Id = 88 AND Descripcion = N'UPDATE operacion LI')
        THROW 51020, N'El UPDATE de LI no llego a CORP.', 1;
END;

IF N'$(NodeCode)' = N'CORP' AND N'$(Expected)' = N'DELETE'
BEGIN
    IF EXISTS (SELECT 1 FROM sj.OperacionPiloto WHERE Id = 88)
        THROW 51021, N'El DELETE de SJ no llego a CORP.', 1;

    IF EXISTS (SELECT 1 FROM limon.OperacionPiloto WHERE Id = 88)
        THROW 51022, N'El DELETE de LI no llego a CORP.', 1;
END;

SELECT N'$(NodeCode)' AS NodeCode, N'$(Expected)' AS ExpectedChange, N'PASS' AS Result;

