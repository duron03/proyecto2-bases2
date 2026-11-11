:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [master];
GO

DECLARE @AdminSjPassword nvarchar(128) =
    CONVERT(nvarchar(128), CONVERT(varchar(128), 0x$(AdminSjPasswordHex)));
DECLARE @AdminLimonPassword nvarchar(128) =
    CONVERT(nvarchar(128), CONVERT(varchar(128), 0x$(AdminLimonPasswordHex)));
DECLARE @CorporativoPassword nvarchar(128) =
    CONVERT(nvarchar(128), CONVERT(varchar(128), 0x$(CorporativoPasswordHex)));
DECLARE @Sql nvarchar(max);

IF SUSER_ID(N'admin_sj') IS NULL
BEGIN
    SET @Sql = N'CREATE LOGIN [admin_sj] WITH PASSWORD = '
        + QUOTENAME(@AdminSjPassword, '''')
        + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
    EXEC(@Sql);
END;

IF SUSER_ID(N'admin_limon') IS NULL
BEGIN
    SET @Sql = N'CREATE LOGIN [admin_limon] WITH PASSWORD = '
        + QUOTENAME(@AdminLimonPassword, '''')
        + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
    EXEC(@Sql);
END;

IF SUSER_ID(N'corporativo') IS NULL
BEGIN
    SET @Sql = N'CREATE LOGIN [corporativo] WITH PASSWORD = '
        + QUOTENAME(@CorporativoPassword, '''')
        + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
    EXEC(@Sql);
END;
GO

USE [WideWorldImporters];
GO

IF SCHEMA_ID(N'Seguridad') IS NULL
    EXEC(N'CREATE SCHEMA [Seguridad] AUTHORIZATION [dbo];');
GO

IF DATABASE_PRINCIPAL_ID(N'rol_admin_catalogos') IS NULL
    CREATE ROLE rol_admin_catalogos AUTHORIZATION dbo;

IF DATABASE_PRINCIPAL_ID(N'rol_corporativo') IS NULL
    CREATE ROLE rol_corporativo AUTHORIZATION dbo;

IF DATABASE_PRINCIPAL_ID(N'admin_sj') IS NULL
    CREATE USER [admin_sj] FOR LOGIN [admin_sj];

IF DATABASE_PRINCIPAL_ID(N'admin_limon') IS NULL
    CREATE USER [admin_limon] FOR LOGIN [admin_limon];

IF DATABASE_PRINCIPAL_ID(N'corporativo') IS NULL
    CREATE USER [corporativo] FOR LOGIN [corporativo];

IF IS_ROLEMEMBER(N'rol_admin_catalogos', N'admin_sj') <> 1
    ALTER ROLE rol_admin_catalogos ADD MEMBER [admin_sj];

IF IS_ROLEMEMBER(N'rol_admin_catalogos', N'admin_limon') <> 1
    ALTER ROLE rol_admin_catalogos ADD MEMBER [admin_limon];

IF IS_ROLEMEMBER(N'rol_corporativo', N'corporativo') <> 1
    ALTER ROLE rol_corporativo ADD MEMBER [corporativo];
GO

IF OBJECT_ID(N'Seguridad.Usuarios', N'U') IS NULL
BEGIN
    CREATE TABLE Seguridad.Usuarios
    (
        iduser int NOT NULL,
        username nvarchar(50) NOT NULL,
        [password] varbinary(8000) NOT NULL,
        fullname nvarchar(100) NOT NULL,
        active bit NOT NULL,
        rol nvarchar(20) NOT NULL,
        email nvarchar(254) NOT NULL,
        hiredate date NOT NULL,
        SucursalID int NULL,
        SqlLogin sysname NOT NULL,
        PersonID int NOT NULL,
        CONSTRAINT PK_Usuarios PRIMARY KEY (iduser),
        CONSTRAINT UQ_Usuarios_Username UNIQUE (username),
        CONSTRAINT UQ_Usuarios_SqlLogin UNIQUE (SqlLogin),
        CONSTRAINT CK_Usuarios_Rol CHECK (rol IN (N'ADMINISTRADOR', N'CORPORATIVO')),
        CONSTRAINT CK_Usuarios_RolSucursal CHECK
        (
            (rol = N'ADMINISTRADOR' AND SucursalID IN (1, 2))
            OR (rol = N'CORPORATIVO' AND SucursalID IS NULL)
        ),
        CONSTRAINT FK_Usuarios_Persona FOREIGN KEY (PersonID)
            REFERENCES Application.People(PersonID)
    );
END;
GO

DECLARE @MasterKeyPassword nvarchar(128) =
    CONVERT(nvarchar(128), CONVERT(varchar(128), 0x$(MasterKeyPasswordHex)));
DECLARE @Sql nvarchar(max);

IF NOT EXISTS
(
    SELECT 1
    FROM sys.symmetric_keys
    WHERE name = N'##MS_DatabaseMasterKey##'
)
BEGIN
    SET @Sql = N'CREATE MASTER KEY ENCRYPTION BY PASSWORD = '
        + QUOTENAME(@MasterKeyPassword, '''') + N';';
    EXEC(@Sql);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = N'CertUsuarios')
    CREATE CERTIFICATE CertUsuarios
        WITH SUBJECT = N'Cifrado de contrasenas de usuarios del proyecto';
GO

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = N'ClaveUsuarios')
    CREATE SYMMETRIC KEY ClaveUsuarios
        WITH ALGORITHM = AES_256
        ENCRYPTION BY CERTIFICATE CertUsuarios;
GO

DECLARE @AdminSjPassword nvarchar(128) =
    CONVERT(nvarchar(128), CONVERT(varchar(128), 0x$(AdminSjPasswordHex)));
DECLARE @AdminLimonPassword nvarchar(128) =
    CONVERT(nvarchar(128), CONVERT(varchar(128), 0x$(AdminLimonPasswordHex)));
DECLARE @CorporativoPassword nvarchar(128) =
    CONVERT(nvarchar(128), CONVERT(varchar(128), 0x$(CorporativoPasswordHex)));

OPEN SYMMETRIC KEY ClaveUsuarios
    DECRYPTION BY CERTIFICATE CertUsuarios;

IF EXISTS (SELECT 1 FROM Seguridad.Usuarios WHERE iduser = 1)
BEGIN
    UPDATE Seguridad.Usuarios
    SET username = N'admin_sj',
        [password] = ENCRYPTBYKEY(
            KEY_GUID(N'ClaveUsuarios'),
            CONVERT(varbinary(8000), @AdminSjPassword),
            1,
            CONVERT(nvarchar(20), 1)
        ),
        fullname = N'Administrador San Jose',
        active = 1,
        rol = N'ADMINISTRADOR',
        email = N'admin_sj@wideworldimporters.local',
        hiredate = CONVERT(date, '2026-11-05'),
        SucursalID = 1,
        SqlLogin = N'admin_sj',
        PersonID = 3262
    WHERE iduser = 1;
END
ELSE
BEGIN
    INSERT INTO Seguridad.Usuarios
    (
        iduser, username, [password], fullname, active, rol, email,
        hiredate, SucursalID, SqlLogin, PersonID
    )
    VALUES
    (
        1, N'admin_sj',
        ENCRYPTBYKEY(
            KEY_GUID(N'ClaveUsuarios'),
            CONVERT(varbinary(8000), @AdminSjPassword),
            1,
            CONVERT(nvarchar(20), 1)
        ),
        N'Administrador San Jose', 1, N'ADMINISTRADOR',
        N'admin_sj@wideworldimporters.local', CONVERT(date, '2026-11-05'),
        1, N'admin_sj', 3262
    );
END;

IF EXISTS (SELECT 1 FROM Seguridad.Usuarios WHERE iduser = 2)
BEGIN
    UPDATE Seguridad.Usuarios
    SET username = N'admin_limon',
        [password] = ENCRYPTBYKEY(
            KEY_GUID(N'ClaveUsuarios'),
            CONVERT(varbinary(8000), @AdminLimonPassword),
            1,
            CONVERT(nvarchar(20), 2)
        ),
        fullname = N'Administrador Limon',
        active = 1,
        rol = N'ADMINISTRADOR',
        email = N'admin_limon@wideworldimporters.local',
        hiredate = CONVERT(date, '2026-11-05'),
        SucursalID = 2,
        SqlLogin = N'admin_limon',
        PersonID = 3263
    WHERE iduser = 2;
END
ELSE
BEGIN
    INSERT INTO Seguridad.Usuarios
    (
        iduser, username, [password], fullname, active, rol, email,
        hiredate, SucursalID, SqlLogin, PersonID
    )
    VALUES
    (
        2, N'admin_limon',
        ENCRYPTBYKEY(
            KEY_GUID(N'ClaveUsuarios'),
            CONVERT(varbinary(8000), @AdminLimonPassword),
            1,
            CONVERT(nvarchar(20), 2)
        ),
        N'Administrador Limon', 1, N'ADMINISTRADOR',
        N'admin_limon@wideworldimporters.local', CONVERT(date, '2026-11-05'),
        2, N'admin_limon', 3263
    );
END;

IF EXISTS (SELECT 1 FROM Seguridad.Usuarios WHERE iduser = 3)
BEGIN
    UPDATE Seguridad.Usuarios
    SET username = N'corporativo',
        [password] = ENCRYPTBYKEY(
            KEY_GUID(N'ClaveUsuarios'),
            CONVERT(varbinary(8000), @CorporativoPassword),
            1,
            CONVERT(nvarchar(20), 3)
        ),
        fullname = N'Usuario Corporativo',
        active = 1,
        rol = N'CORPORATIVO',
        email = N'corporativo@wideworldimporters.local',
        hiredate = CONVERT(date, '2026-11-05'),
        SucursalID = NULL,
        SqlLogin = N'corporativo',
        PersonID = 3264
    WHERE iduser = 3;
END
ELSE
BEGIN
    INSERT INTO Seguridad.Usuarios
    (
        iduser, username, [password], fullname, active, rol, email,
        hiredate, SucursalID, SqlLogin, PersonID
    )
    VALUES
    (
        3, N'corporativo',
        ENCRYPTBYKEY(
            KEY_GUID(N'ClaveUsuarios'),
            CONVERT(varbinary(8000), @CorporativoPassword),
            1,
            CONVERT(nvarchar(20), 3)
        ),
        N'Usuario Corporativo', 1, N'CORPORATIVO',
        N'corporativo@wideworldimporters.local', CONVERT(date, '2026-11-05'),
        NULL, N'corporativo', 3264
    );
END;

CLOSE SYMMETRIC KEY ClaveUsuarios;
GO

