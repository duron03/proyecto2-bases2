:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [master];
GO

DECLARE @LoginName sysname = N'$(LoginName)';
DECLARE @LoginPassword nvarchar(128) =
    CONVERT(nvarchar(128), CONVERT(varchar(128), 0x$(LoginPasswordHex)));

IF SUSER_ID(@LoginName) IS NULL
BEGIN
    DECLARE @CreateLogin nvarchar(max);
    SET @CreateLogin = N'CREATE LOGIN '
        + QUOTENAME(@LoginName)
        + N' WITH PASSWORD = ' + QUOTENAME(@LoginPassword, '''')
        + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';

    EXEC(@CreateLogin);
END;
GO

USE [WideWorldImporters];
GO

IF NOT EXISTS
(
    SELECT 1
    FROM Control.Nodo
    WHERE Id = 1
      AND Codigo = '$(BranchCode)'
      AND SucursalID = $(BranchID)
)
    THROW 50403, 'La identidad no corresponde a este nodo.', 1;
GO

IF SCHEMA_ID(N'Seguridad') IS NULL
    EXEC(N'CREATE SCHEMA [Seguridad] AUTHORIZATION [dbo];');

IF OBJECT_ID(N'Seguridad.IdentidadesLocales', N'U') IS NULL
BEGIN
    CREATE TABLE Seguridad.IdentidadesLocales
    (
        SqlLogin sysname NOT NULL,
        iduser int NOT NULL,
        PersonID int NOT NULL,
        SucursalID int NOT NULL,
        active bit NOT NULL,
        CONSTRAINT PK_IdentidadesLocales PRIMARY KEY (SqlLogin),
        CONSTRAINT UQ_IdentidadesLocales_IdUser UNIQUE (iduser),
        CONSTRAINT FK_IdentidadesLocales_Persona FOREIGN KEY (PersonID)
            REFERENCES Application.People(PersonID),
        CONSTRAINT CK_IdentidadesLocales_Sucursal CHECK (SucursalID IN (1, 2))
    );
END;

IF DATABASE_PRINCIPAL_ID(N'rol_admin_sucursal') IS NULL
    CREATE ROLE rol_admin_sucursal AUTHORIZATION dbo;
GO

DECLARE @LoginName sysname = N'$(LoginName)';

IF DATABASE_PRINCIPAL_ID(@LoginName) IS NULL
BEGIN
    DECLARE @CreateUser nvarchar(max);
    SET @CreateUser = N'CREATE USER '
        + QUOTENAME(@LoginName) + N' FOR LOGIN ' + QUOTENAME(@LoginName) + N';';
    EXEC(@CreateUser);
END;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    INNER JOIN sys.database_principals AS rolePrincipal
        ON drm.role_principal_id = rolePrincipal.principal_id
    INNER JOIN sys.database_principals AS memberPrincipal
        ON drm.member_principal_id = memberPrincipal.principal_id
    WHERE rolePrincipal.name = N'rol_admin_sucursal'
      AND memberPrincipal.name = @LoginName
)
BEGIN
    DECLARE @AddRole nvarchar(max);
    SET @AddRole = N'ALTER ROLE rol_admin_sucursal ADD MEMBER '
        + QUOTENAME(@LoginName) + N';';
    EXEC(@AddRole);
END;

DELETE FROM Seguridad.IdentidadesLocales
WHERE SucursalID = $(BranchID)
  AND SqlLogin <> @LoginName;

IF EXISTS (SELECT 1 FROM Seguridad.IdentidadesLocales WHERE SqlLogin = @LoginName)
BEGIN
    UPDATE Seguridad.IdentidadesLocales
    SET iduser = $(UserID),
        PersonID = $(PersonID),
        SucursalID = $(BranchID),
        active = 1
    WHERE SqlLogin = @LoginName;
END
ELSE
BEGIN
    INSERT INTO Seguridad.IdentidadesLocales
        (SqlLogin, iduser, PersonID, SucursalID, active)
    VALUES
        (@LoginName, $(UserID), $(PersonID), $(BranchID), 1);
END;
GO

