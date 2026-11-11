:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

IF '$(NodeCode)' = 'CORP'
BEGIN
    GRANT EXECUTE ON OBJECT::Seguridad.usp_IniciarSesion TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::Seguridad.usp_IniciarSesion TO rol_corporativo;

    GRANT EXECUTE ON OBJECT::dbo.usp_Clientes_Listar TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Clientes_ObtenerDetalle TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Clientes_ObtenerCatalogos TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Clientes_ObtenerPrivados TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Clientes_ObtenerDatosEdicion TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Clientes_ObtenerCatalogosEdicion TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Ciudades_Buscar TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Clientes_Crear TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Clientes_Actualizar TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Clientes_Eliminar TO rol_admin_catalogos;

    GRANT EXECUTE ON OBJECT::dbo.usp_Proveedores_Listar TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Proveedores_ObtenerDetalle TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Proveedores_ObtenerCatalogos TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Proveedores_ObtenerPrivados TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Proveedores_ObtenerDatosEdicion TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Proveedores_ObtenerCatalogosEdicion TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Proveedores_Crear TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Proveedores_Actualizar TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Proveedores_Eliminar TO rol_admin_catalogos;

    GRANT EXECUTE ON OBJECT::dbo.usp_Inventarios_ObtenerCatalogoCentral TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Inventarios_ObtenerCatalogosEdicion TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Inventarios_Crear TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Inventarios_Actualizar TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Inventarios_Eliminar TO rol_admin_catalogos;

    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte1 TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte2 TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte3 TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte4 TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte5 TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte6 TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte7 TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte8 TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte10 TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::Corporativo.usp_ObtenerCatalogosReportes TO rol_admin_catalogos;
    GRANT EXECUTE ON OBJECT::Corporativo.usp_ObtenerEstadoFuentes TO rol_admin_catalogos;

    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte1 TO rol_corporativo;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte2 TO rol_corporativo;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte3 TO rol_corporativo;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte4 TO rol_corporativo;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte5 TO rol_corporativo;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte6 TO rol_corporativo;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte7 TO rol_corporativo;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte8 TO rol_corporativo;
    GRANT EXECUTE ON OBJECT::dbo.usp_Estadisticas_Reporte10 TO rol_corporativo;
    GRANT EXECUTE ON OBJECT::Corporativo.usp_ObtenerCatalogosReportes TO rol_corporativo;
    GRANT EXECUTE ON OBJECT::Corporativo.usp_ObtenerResumenVentas TO rol_corporativo;
    GRANT EXECUTE ON OBJECT::Corporativo.usp_ObtenerEstadoFuentes TO rol_corporativo;
    GRANT EXECUTE ON OBJECT::Corporativo.usp_ObtenerEstadoMaterializacion TO rol_corporativo;
END
ELSE IF '$(NodeCode)' IN ('SJ', 'LI')
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_Clientes_Listar TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Clientes_ObtenerDetalle TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Clientes_ObtenerCatalogos TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Proveedores_Listar TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Proveedores_ObtenerDetalle TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Proveedores_ObtenerCatalogos TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Inventarios_Listar TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Inventarios_ObtenerDetalle TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Inventarios_ObtenerCatalogos TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Inventarios_GuardarExistencias TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Ventas_Listar TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Ventas_ObtenerDetalle TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Ventas_ObtenerCatalogos TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Ventas_Crear TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Ventas_Actualizar TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_Ventas_Eliminar TO rol_admin_sucursal;
    GRANT EXECUTE ON OBJECT::dbo.usp_ObtenerEstadoLocal TO rol_admin_sucursal;
END
ELSE
    THROW 50403, 'NodeCode debe ser CORP, SJ o LI.', 1;
GO

SELECT '$(NodeCode)' AS NodeCode, N'PERMISOS_CONFIGURADOS' AS Result;
GO
