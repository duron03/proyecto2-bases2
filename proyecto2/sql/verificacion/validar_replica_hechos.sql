:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

DECLARE @NodeCode varchar(2) = '$(NodeCode)';
DECLARE @Action varchar(8) = '$(Action)';
DECLARE @InvoiceID int = CASE @NodeCode WHEN 'SJ' THEN 1499999998 ELSE 1999999998 END;
DECLARE @ExpectedComment nvarchar(50) = N'P2_REPLICA_' + @NodeCode + N'_UPDATE';

IF @@SERVERNAME <> N'wwi-corp'
    THROW 51370, N'La validacion se ejecuta solamente en CORP.', 1;

IF @NodeCode = 'SJ'
BEGIN
    IF @Action = 'INSERT'
       AND
       (
           NOT EXISTS (SELECT 1 FROM sj.Invoices WHERE InvoiceID = @InvoiceID AND VersionVenta = 1)
           OR NOT EXISTS (SELECT 1 FROM sj.InvoiceLines WHERE InvoiceLineID = @InvoiceID AND InvoiceID = @InvoiceID)
           OR EXISTS (SELECT 1 FROM limon.Invoices WHERE InvoiceID = @InvoiceID)
       )
        THROW 51371, N'El INSERT de SJ no llego aislado a su esquema.', 1;

    IF @Action = 'UPDATE'
       AND NOT EXISTS
       (
           SELECT 1 FROM sj.Invoices
           WHERE InvoiceID = @InvoiceID
             AND VersionVenta = 2
             AND Comments = @ExpectedComment
       )
        THROW 51372, N'El UPDATE de SJ no llego a CORP.', 1;

    IF @Action = 'DELETE'
       AND
       (
           EXISTS (SELECT 1 FROM sj.Invoices WHERE InvoiceID = @InvoiceID)
           OR EXISTS (SELECT 1 FROM sj.InvoiceLines WHERE InvoiceLineID = @InvoiceID)
       )
        THROW 51373, N'El DELETE de SJ no llego a CORP.', 1;
END;

IF @NodeCode = 'LI'
BEGIN
    IF @Action = 'INSERT'
       AND
       (
           NOT EXISTS (SELECT 1 FROM limon.Invoices WHERE InvoiceID = @InvoiceID AND VersionVenta = 1)
           OR NOT EXISTS (SELECT 1 FROM limon.InvoiceLines WHERE InvoiceLineID = @InvoiceID AND InvoiceID = @InvoiceID)
           OR EXISTS (SELECT 1 FROM sj.Invoices WHERE InvoiceID = @InvoiceID)
       )
        THROW 51374, N'El INSERT de LI no llego aislado a su esquema.', 1;

    IF @Action = 'UPDATE'
       AND NOT EXISTS
       (
           SELECT 1 FROM limon.Invoices
           WHERE InvoiceID = @InvoiceID
             AND VersionVenta = 2
             AND Comments = @ExpectedComment
       )
        THROW 51375, N'El UPDATE de LI no llego a CORP.', 1;

    IF @Action = 'DELETE'
       AND
       (
           EXISTS (SELECT 1 FROM limon.Invoices WHERE InvoiceID = @InvoiceID)
           OR EXISTS (SELECT 1 FROM limon.InvoiceLines WHERE InvoiceLineID = @InvoiceID)
       )
        THROW 51376, N'El DELETE de LI no llego a CORP.', 1;
END;

SELECT
    @NodeCode AS NodeCode,
    @Action AS ActionName,
    @InvoiceID AS InvoiceID,
    N'REPLICATION_CHANGE_PASS' AS Result;
