:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

IF N'$(NodeCode)' NOT IN (N'SJ', N'LI')
BEGIN
    THROW 51130, N'NodeCode debe ser SJ o LI.', 1;
END;

IF N'$(NodeCode)' = N'SJ'
BEGIN
    IF OBJECT_ID(N'Sequences.InvoiceID', N'SO') IS NULL
        CREATE SEQUENCE Sequences.InvoiceID AS int
            START WITH 1000000000
            INCREMENT BY 1
            MINVALUE 1000000000
            MAXVALUE 1499999999
            NO CYCLE
            CACHE 50;

    IF OBJECT_ID(N'Sequences.InvoiceLineID', N'SO') IS NULL
        CREATE SEQUENCE Sequences.InvoiceLineID AS int
            START WITH 1000000000
            INCREMENT BY 1
            MINVALUE 1000000000
            MAXVALUE 1499999999
            NO CYCLE
            CACHE 50;

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Invoices_DistributedRange')
        ALTER TABLE Sales.Invoices ADD CONSTRAINT CK_Invoices_DistributedRange
            CHECK (InvoiceID > 0 AND (InvoiceID < 1000000000 OR InvoiceID BETWEEN 1000000000 AND 1499999999));

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_InvoiceLines_DistributedRange')
        ALTER TABLE Sales.InvoiceLines ADD CONSTRAINT CK_InvoiceLines_DistributedRange
            CHECK (InvoiceLineID > 0 AND (InvoiceLineID < 1000000000 OR InvoiceLineID BETWEEN 1000000000 AND 1499999999));
END;

IF N'$(NodeCode)' = N'LI'
BEGIN
    IF OBJECT_ID(N'Sequences.InvoiceID', N'SO') IS NULL
        CREATE SEQUENCE Sequences.InvoiceID AS int
            START WITH 1500000000
            INCREMENT BY 1
            MINVALUE 1500000000
            MAXVALUE 1999999999
            NO CYCLE
            CACHE 50;

    IF OBJECT_ID(N'Sequences.InvoiceLineID', N'SO') IS NULL
        CREATE SEQUENCE Sequences.InvoiceLineID AS int
            START WITH 1500000000
            INCREMENT BY 1
            MINVALUE 1500000000
            MAXVALUE 1999999999
            NO CYCLE
            CACHE 50;

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Invoices_DistributedRange')
        ALTER TABLE Sales.Invoices ADD CONSTRAINT CK_Invoices_DistributedRange
            CHECK (InvoiceID > 0 AND (InvoiceID < 1000000000 OR InvoiceID BETWEEN 1500000000 AND 1999999999));

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_InvoiceLines_DistributedRange')
        ALTER TABLE Sales.InvoiceLines ADD CONSTRAINT CK_InvoiceLines_DistributedRange
            CHECK (InvoiceLineID > 0 AND (InvoiceLineID < 1000000000 OR InvoiceLineID BETWEEN 1500000000 AND 1999999999));
END;

SELECT
    sequenceObject.name AS SequenceName,
    CONVERT(bigint, sequenceObject.start_value) AS StartValue,
    CONVERT(bigint, sequenceObject.minimum_value) AS MinimumValue,
    CONVERT(bigint, sequenceObject.maximum_value) AS MaximumValue,
    sequenceObject.is_cycling AS IsCycling
FROM sys.sequences AS sequenceObject
WHERE sequenceObject.name IN (N'InvoiceID', N'InvoiceLineID')
ORDER BY sequenceObject.name;
GO

USE [master];
GO
EXEC sys.sp_configure N'show advanced options', 1;
RECONFIGURE;
EXEC sys.sp_configure N'max text repl size (B)', -1;
RECONFIGURE;
GO

USE [WideWorldImporters];

