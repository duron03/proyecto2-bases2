USE [WideWorldImporters];
GO

-- Las ciudades se consultan en Corporativo porque las direcciones son privadas.
CREATE OR ALTER PROCEDURE dbo.usp_Ciudades_Buscar
    @CityName nvarchar(50) = NULL,
    @CityID int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (50)
        C.CityID AS [Value],
        CONCAT(C.CityName, N', ', SP.StateProvinceName, N', ', CO.CountryName) AS [Label]
    FROM Application.Cities AS C
    INNER JOIN Application.StateProvinces AS SP
        ON C.StateProvinceID = SP.StateProvinceID
    INNER JOIN Application.Countries AS CO
        ON SP.CountryID = CO.CountryID
    WHERE (@CityID IS NULL OR C.CityID = @CityID)
      AND (@CityName IS NULL OR C.CityName LIKE N'%' + @CityName + N'%')
    ORDER BY C.CityName;
END;
GO

