:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

IF '$(NodeCode)' = 'CORP'
BEGIN
    EXEC(N'
    CREATE OR ALTER PROCEDURE Corporativo.usp_ObtenerEstadoFuentes
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @Rol nvarchar(20);
        DECLARE @SucursalUsuario int;

        SELECT @Rol = rol, @SucursalUsuario = SucursalID
        FROM Seguridad.Usuarios
        WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1;

        IF @Rol IS NULL
            THROW 50403, ''El usuario no puede consultar el estado.'', 1;

        SELECT
            S.SucursalID,
            CASE S.SucursalID WHEN 1 THEN N''San Jose'' ELSE N''Limon'' END AS SucursalNombre,
            COALESCE(E.DatosValidados, 0) AS inicializada,
            L.FechaUtc AS ultimoLatidoUtc,
            CASE
                WHEN COALESCE(E.DatosValidados, 0) = 0 THEN N''sin_inicializar''
                WHEN L.FechaUtc IS NULL THEN N''desconocido''
                WHEN DATEDIFF(SECOND, L.FechaUtc, SYSUTCDATETIME()) <= 60 THEN N''reciente''
                ELSE N''atrasado''
            END AS estado
        FROM (VALUES (1), (2)) AS S(SucursalID)
        LEFT JOIN Control.EstadoInicializacion AS E ON S.SucursalID = E.SucursalID
        LEFT JOIN
        (
            SELECT SucursalID, FechaUtc FROM sj.LatidoSucursal
            UNION ALL
            SELECT SucursalID, FechaUtc FROM limon.LatidoSucursal
        ) AS L ON S.SucursalID = L.SucursalID
        WHERE @Rol = N''CORPORATIVO'' OR S.SucursalID = @SucursalUsuario
        ORDER BY S.SucursalID;
    END;');

    EXEC(N'
    CREATE OR ALTER PROCEDURE Corporativo.usp_ObtenerEstadoMaterializacion
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NOT EXISTS
        (
            SELECT 1 FROM Seguridad.Usuarios
            WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1 AND rol = N''CORPORATIVO''
        )
            THROW 50403, ''Solo el usuario corporativo puede consultar la materializacion.'', 1;

        SELECT
            UltimoIntentoUtc,
            UltimoExitoUtc,
            EstadoUltimoIntento AS estado,
            UltimoError,
            LatidoSJUsadoUtc,
            LatidoLIUsadoUtc
        FROM Control.EstadoMaterializacion
        WHERE Id = 1;
    END;');
END
ELSE IF '$(NodeCode)' IN ('SJ', 'LI')
BEGIN
    EXEC(N'
    CREATE OR ALTER PROCEDURE dbo.usp_ObtenerEstadoLocal
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @SucursalUsuario int;
        DECLARE @SucursalNodo int;

        SELECT @SucursalUsuario = SucursalID
        FROM Seguridad.IdentidadesLocales
        WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1;

        SELECT @SucursalNodo = SucursalID FROM Control.Nodo WHERE Id = 1;

        IF @SucursalUsuario IS NULL OR @SucursalUsuario <> @SucursalNodo
            THROW 50403, ''El usuario no puede consultar el estado de esta sucursal.'', 1;

        SELECT
            @SucursalNodo AS SucursalID,
            E.DatosValidados AS inicializada,
            L.FechaUtc AS ultimoLatidoUtc,
            CASE
                WHEN E.DatosValidados = 0 THEN N''sin_inicializar''
                WHEN L.FechaUtc IS NULL THEN N''desconocido''
                WHEN DATEDIFF(SECOND, L.FechaUtc, SYSUTCDATETIME()) <= 60 THEN N''reciente''
                ELSE N''atrasado''
            END AS estado
        FROM Control.EstadoCatalogo AS E
        LEFT JOIN Control.LatidoCatalogo AS L ON L.Id = E.Id
        WHERE E.Id = 1;
    END;');
END
ELSE
    THROW 50403, 'NodeCode debe ser CORP, SJ o LI.', 1;
GO
