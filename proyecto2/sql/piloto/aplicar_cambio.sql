:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [PilotoReplicacion];
GO

IF N'$(NodeCode)' NOT IN (N'CORP', N'SJ', N'LI')
BEGIN
    THROW 51004, N'NodeCode debe ser CORP, SJ o LI.', 1;
END;

IF N'$(Action)' NOT IN (N'INSERT', N'UPDATE', N'DELETE')
BEGIN
    THROW 51005, N'Action debe ser INSERT, UPDATE o DELETE.', 1;
END;

IF N'$(NodeCode)' = N'CORP' AND N'$(Action)' = N'INSERT'
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.CatalogoPiloto WHERE Id = 2)
        THROW 51006, N'La fila INSERT de catalogo ya existe.', 1;

    INSERT INTO dbo.CatalogoPiloto
        (Id, Nombre, VersionCatalogo, Activo, LastEditedWhen)
    VALUES
        (2, N'INSERT catalogo piloto', 1, 1, SYSUTCDATETIME());
END;

IF N'$(NodeCode)' = N'CORP' AND N'$(Action)' = N'UPDATE'
BEGIN
    UPDATE dbo.CatalogoPiloto
    SET Nombre = N'UPDATE catalogo piloto',
        VersionCatalogo = 2,
        LastEditedWhen = SYSUTCDATETIME()
    WHERE Id = 2;

    IF @@ROWCOUNT <> 1
        THROW 51007, N'No se actualizo exactamente una fila de catalogo.', 1;
END;

IF N'$(NodeCode)' = N'CORP' AND N'$(Action)' = N'DELETE'
BEGIN
    DELETE FROM dbo.CatalogoPiloto WHERE Id = 2;

    IF @@ROWCOUNT <> 1
        THROW 51008, N'No se elimino exactamente una fila de catalogo.', 1;
END;

IF N'$(NodeCode)' IN (N'SJ', N'LI') AND N'$(Action)' = N'INSERT'
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.OperacionPiloto WHERE Id = 88)
        THROW 51009, N'La fila INSERT de operacion ya existe.', 1;

    INSERT INTO dbo.OperacionPiloto
        (Id, Descripcion, LastEditedWhen)
    VALUES
        (88, CONCAT(N'INSERT operacion ', N'$(NodeCode)'), SYSUTCDATETIME());
END;

IF N'$(NodeCode)' IN (N'SJ', N'LI') AND N'$(Action)' = N'UPDATE'
BEGIN
    UPDATE dbo.OperacionPiloto
    SET Descripcion = CONCAT(N'UPDATE operacion ', N'$(NodeCode)'),
        LastEditedWhen = SYSUTCDATETIME()
    WHERE Id = 88;

    IF @@ROWCOUNT <> 1
        THROW 51010, N'No se actualizo exactamente una fila de operacion.', 1;
END;

IF N'$(NodeCode)' IN (N'SJ', N'LI') AND N'$(Action)' = N'DELETE'
BEGIN
    DELETE FROM dbo.OperacionPiloto WHERE Id = 88;

    IF @@ROWCOUNT <> 1
        THROW 51011, N'No se elimino exactamente una fila de operacion.', 1;
END;

SELECT N'$(NodeCode)' AS NodeCode, N'$(Action)' AS ActionApplied, SYSUTCDATETIME() AS AppliedUtc;

