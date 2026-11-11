import { config } from 'dotenv';
import sql from 'mssql';

config();

function required(name) {
    const value = process.env[name];

    if (!value) {
        throw new Error(`Falta ${name} en proyecto2/.env`);
    }

    return value;
}

function settings(serverName, portName, user, password) {
    return {
        server: required(serverName),
        port: Number(required(portName)),
        database: process.env.DB_DATABASE || 'WideWorldImporters',
        user,
        password,
        connectionTimeout: 10000,
        requestTimeout: 120000,
        pool: { max: 3, min: 0, idleTimeoutMillis: 30000 },
        options: {
            encrypt: process.env.DB_ENCRYPT !== 'false',
            trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE !== 'false'
        }
    };
}

async function connect(serverName, portName, user, password) {
    const pool = new sql.ConnectionPool(settings(serverName, portName, user, password));
    await pool.connect();
    return pool;
}

function errorNumber(error) {
    return error.number || error.originalError?.info?.number;
}

async function expectError(action, allowedNumbers, label) {
    try {
        await action();
    } catch (error) {
        const number = errorNumber(error);
        const code = error.code;

        if (allowedNumbers.includes(number) || allowedNumbers.includes(code)) {
            return;
        }

        throw new Error(`${label}: error inesperado ${number || error.code || 'desconocido'}`);
    }

    throw new Error(`${label}: la operacion debio fallar`);
}

async function executeLogin(pool, username, password) {
    const result = await pool.request()
        .input('username', sql.NVarChar(50), username)
        .input('password', sql.NVarChar(128), password)
        .execute('Seguridad.usp_IniciarSesion');

    return result.recordset[0];
}

async function executeReport(pool, reportNumber, branchId) {
    const request = pool.request();
    request.input('SucursalID', sql.Int, branchId);
    const result = await request.execute(`dbo.usp_Estadisticas_Reporte${reportNumber}`);
    return result.recordset.length;
}

async function main() {
    const adminSjPassword = required('ADMIN_SJ_PASSWORD');
    const adminLimonPassword = required('ADMIN_LIMON_PASSWORD');
    const corporativoPassword = required('CORPORATIVO_PASSWORD');

    const pools = [];

    try {
        await expectError(
            async () => {
                const wrongPool = await connect(
                    'CORP_SERVER', 'CORP_PORT', 'admin_sj', `${adminSjPassword}x`
                );
                await wrongPool.close();
            },
            [18456, 'ELOGIN'],
            'Password SQL incorrecta'
        );

        const corpAdminSj = await connect(
            'CORP_SERVER', 'CORP_PORT', 'admin_sj', adminSjPassword
        );
        const corpAdminLimon = await connect(
            'CORP_SERVER', 'CORP_PORT', 'admin_limon', adminLimonPassword
        );
        const corpCorporate = await connect(
            'CORP_SERVER', 'CORP_PORT', 'corporativo', corporativoPassword
        );
        const localSj = await connect(
            'SJ_SERVER', 'SJ_PORT', 'admin_sj', adminSjPassword
        );
        const localLimon = await connect(
            'LI_SERVER', 'LI_PORT', 'admin_limon', adminLimonPassword
        );

        pools.push(corpAdminSj, corpAdminLimon, corpCorporate, localSj, localLimon);

        const sjSession = await executeLogin(corpAdminSj, 'admin_sj', adminSjPassword);
        const limonSession = await executeLogin(
            corpAdminLimon, 'admin_limon', adminLimonPassword
        );
        const corporateSession = await executeLogin(
            corpCorporate, 'corporativo', corporativoPassword
        );

        if (sjSession.rol !== 'ADMINISTRADOR' || sjSession.SucursalID !== 1) {
            throw new Error('La sesion de San Jose no tiene el alcance esperado');
        }

        if (limonSession.rol !== 'ADMINISTRADOR' || limonSession.SucursalID !== 2) {
            throw new Error('La sesion de Limon no tiene el alcance esperado');
        }

        if (corporateSession.rol !== 'CORPORATIVO' || corporateSession.SucursalID !== null) {
            throw new Error('La sesion corporativa no tiene el alcance esperado');
        }

        const sjLogin = await localSj.request().query('SELECT ORIGINAL_LOGIN() AS LoginName;');
        const limonLogin = await localLimon.request().query('SELECT ORIGINAL_LOGIN() AS LoginName;');

        if (sjLogin.recordset[0].LoginName !== 'admin_sj'
            || limonLogin.recordset[0].LoginName !== 'admin_limon') {
            throw new Error('ORIGINAL_LOGIN no identifica al administrador local');
        }

        await expectError(
            () => corpAdminSj.request().query('SELECT iduser FROM Seguridad.Usuarios;'),
            [229],
            'Lectura directa de Usuarios'
        );
        await expectError(
            () => corpAdminSj.request().query('SELECT CustomerID FROM Privado.Clientes;'),
            [229],
            'Lectura directa de privados'
        );
        await expectError(
            () => corpAdminSj.request().query(
                'UPDATE Warehouse.StockItems SET UnitPrice = UnitPrice WHERE StockItemID = 1;'
            ),
            [229],
            'Escritura directa de catalogo'
        );
        await expectError(
            () => corpCorporate.request().query(
                'EXEC dbo.usp_Inventarios_Eliminar @StockItemID = 1, @VersionEsperada = 1;'
            ),
            [229],
            'CRUD con rol corporativo'
        );
        await expectError(
            () => corpAdminSj.request()
                .input('SucursalID', sql.Int, 2)
                .execute('dbo.usp_Estadisticas_Reporte3'),
            [50403],
            'Reporte de otra sucursal para admin SJ'
        );
        await expectError(
            () => corpAdminLimon.request()
                .input('SucursalID', sql.Int, null)
                .execute('Corporativo.usp_ObtenerResumenVentas'),
            [229],
            'Resumen corporativo desde administrador'
        );

        const reports = [1, 2, 3, 4, 5, 6, 7, 8, 10];
        const reportResults = [];

        for (const reportNumber of reports) {
            const sjRows = await executeReport(corpAdminSj, reportNumber, 1);
            const limonRows = await executeReport(corpAdminLimon, reportNumber, 2);
            const totalRows = await executeReport(corpCorporate, reportNumber, null);

            reportResults.push({
                reporte: reportNumber,
                sanJose: sjRows,
                limon: limonRows,
                consolidado: totalRows
            });
        }

        const summary = await corpCorporate.request()
            .input('SucursalID', sql.Int, null)
            .input('Year', sql.Int, null)
            .input('Month', sql.Int, null)
            .execute('Corporativo.usp_ObtenerResumenVentas');

        const operator = await connect(
            'CORP_SERVER', 'CORP_PORT', required('OPERATOR_USER'), required('OPERATOR_PASSWORD')
        );
        pools.push(operator);

        const encrypted = await operator.request().query(`
            SELECT COUNT(*) AS UserCount,
                MIN(DATALENGTH([password])) AS MinEncryptedBytes,
                SUM(CASE WHEN [password] IS NULL THEN 1 ELSE 0 END) AS NullPasswords
            FROM Seguridad.Usuarios;
        `);

        const encryptionState = encrypted.recordset[0];

        if (encryptionState.UserCount !== 3
            || encryptionState.MinEncryptedBytes <= 0
            || encryptionState.NullPasswords !== 0) {
            throw new Error('La tabla de usuarios no conserva tres contrasenas cifradas');
        }

        console.log('PASS: autenticacion, ORIGINAL_LOGIN y permisos negativos');
        console.table(reportResults);
        console.log(`PASS: resumen corporativo con ${summary.recordset.length} periodos`);
        console.log('PASS: tres contrasenas almacenadas como VARBINARY cifrado');
    } finally {
        for (const pool of pools.reverse()) {
            await pool.close().catch(() => {});
        }
    }
}

main().catch((error) => {
    console.error(`FAIL: ${error.message}`);
    process.exitCode = 1;
});

