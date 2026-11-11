:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

-- Los reportes llaman este procedimiento antes de consultar cualquier hecho.
CREATE OR ALTER PROCEDURE Seguridad.usp_ValidarAlcanceReporte
    @SucursalID int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Rol nvarchar(20);
    DECLARE @SucursalUsuario int;

    SELECT
        @Rol = rol,
        @SucursalUsuario = SucursalID
    FROM Seguridad.Usuarios
    WHERE SqlLogin = ORIGINAL_LOGIN()
      AND active = 1;

    IF @Rol IS NULL
        THROW 50403, 'El usuario no puede consultar reportes.', 1;

    IF @Rol = N'ADMINISTRADOR'
    BEGIN
        IF @SucursalID IS NULL
            SET @SucursalID = @SucursalUsuario;

        IF @SucursalID <> @SucursalUsuario
            THROW 50403, 'El administrador solo puede consultar su sucursal.', 1;
    END
    ELSE IF @Rol = N'CORPORATIVO'
    BEGIN
        IF @SucursalID IS NOT NULL AND @SucursalID NOT IN (1, 2)
            THROW 50403, 'La sucursal solicitada no es valida.', 1;
    END
    ELSE
        THROW 50403, 'El usuario no puede consultar reportes.', 1;
END;
GO
