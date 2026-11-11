:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

CREATE OR ALTER PROCEDURE Seguridad.usp_IniciarSesion
    @username nvarchar(50),
    @password nvarchar(128)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdUser int;
    DECLARE @PasswordCifrado varbinary(8000);
    DECLARE @PasswordIngresado varbinary(8000) = CONVERT(varbinary(8000), @password);
    DECLARE @PasswordDescifrado varbinary(8000);

    BEGIN TRY
        SELECT
            @IdUser = U.iduser,
            @PasswordCifrado = U.[password]
        FROM Seguridad.Usuarios AS U
        WHERE U.username = @username
          AND U.SqlLogin = ORIGINAL_LOGIN()
          AND U.active = 1;

        IF @IdUser IS NULL
            THROW 50403, 'Credenciales invalidas.', 1;

        OPEN SYMMETRIC KEY ClaveUsuarios
            DECRYPTION BY CERTIFICATE CertUsuarios;

        SET @PasswordDescifrado = DECRYPTBYKEY(
            @PasswordCifrado,
            1,
            CONVERT(nvarchar(20), @IdUser)
        );

        CLOSE SYMMETRIC KEY ClaveUsuarios;

        IF @PasswordDescifrado IS NULL OR @PasswordDescifrado <> @PasswordIngresado
            THROW 50403, 'Credenciales invalidas.', 1;

        SELECT
            U.iduser,
            U.username,
            U.fullname,
            U.rol,
            U.SucursalID,
            CASE U.SucursalID
                WHEN 1 THEN N'San Jose'
                WHEN 2 THEN N'Limon'
                ELSE N'Corporativo'
            END AS sucursalNombre,
            U.PersonID
        FROM Seguridad.Usuarios AS U
        WHERE U.iduser = @IdUser;
    END TRY
    BEGIN CATCH
        IF EXISTS
        (
            SELECT 1
            FROM sys.openkeys
            WHERE key_name = N'ClaveUsuarios'
        )
            CLOSE SYMMETRIC KEY ClaveUsuarios;

        THROW;
    END CATCH;
END;
GO
