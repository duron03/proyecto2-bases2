import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { basename, resolve } from 'node:path';

function readLocalEnv() {
    const content = readFileSync(resolve('.env'), 'utf8');
    const values = {};

    for (const line of content.split('\n')) {
        const cleanLine = line.trim();

        if (!cleanLine || cleanLine.startsWith('#')) {
            continue;
        }

        const separator = cleanLine.indexOf('=');

        if (separator > 0) {
            values[cleanLine.slice(0, separator)] = cleanLine.slice(separator + 1);
        }
    }

    return values;
}

function requireValue(values, name) {
    if (!values[name]) {
        throw new Error(`Falta ${name} en proyecto2/.env`);
    }

    return values[name];
}

function toHex(value) {
    return Buffer.from(value, 'utf8').toString('hex');
}

function executeSql(container, file, variables = {}) {
    const sqlcmdArguments = ['-I', '-i', file];

    for (const [name, value] of Object.entries(variables)) {
        sqlcmdArguments.push('-v', `${name}=${value}`);
    }

    try {
        execFileSync(
            'docker',
            [
                'exec', container, '/bin/bash', '-lc',
                '/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -b "$@"',
                'sqlcmd',
                ...sqlcmdArguments
            ],
            { stdio: 'inherit' }
        );
    } catch (error) {
        throw new Error(`Fallo ${basename(file)} en ${container} (codigo ${error.status ?? 'desconocido'}).`);
    }
}

function executeProjectOneSql(container, relativePath) {
    const source = resolve('..', 'proyecto1', 'Script', relativePath);
    const destination = `/tmp/proyecto1-${basename(relativePath)}`;

    execFileSync('docker', ['cp', source, `${container}:${destination}`], { stdio: 'inherit' });
    executeSql(container, destination);
}

function executeProjectTwoSql(container, relativePath, variables = {}) {
    const source = resolve('sql', relativePath);
    const destination = `/tmp/proyecto2-${basename(relativePath)}`;

    execFileSync('docker', ['cp', source, `${container}:${destination}`], { stdio: 'inherit' });
    executeSql(container, destination, variables);
}

function installSecurity(values) {
    console.log('Creando usuarios y cifrado en Corporativo...');
    executeProjectTwoSql('wwi-corp', 'seguridad/crear_usuarios_corporativo.sql', {
        AdminSjPasswordHex: toHex(requireValue(values, 'ADMIN_SJ_PASSWORD')),
        AdminLimonPasswordHex: toHex(requireValue(values, 'ADMIN_LIMON_PASSWORD')),
        CorporativoPasswordHex: toHex(requireValue(values, 'CORPORATIVO_PASSWORD')),
        MasterKeyPasswordHex: toHex(requireValue(values, 'MASTER_KEY_PASSWORD'))
    });

    console.log('Creando identidad local de San Jose...');
    executeProjectTwoSql('wwi-sj', 'seguridad/crear_identidad_sucursal.sql', {
        BranchCode: 'SJ',
        BranchID: '1',
        LoginName: 'admin_sj',
        LoginPasswordHex: toHex(requireValue(values, 'ADMIN_SJ_PASSWORD')),
        UserID: '1',
        PersonID: '3262'
    });

    console.log('Creando identidad local de Limon...');
    executeProjectTwoSql('wwi-limon', 'seguridad/crear_identidad_sucursal.sql', {
        BranchCode: 'LI',
        BranchID: '2',
        LoginName: 'admin_limon',
        LoginPasswordHex: toHex(requireValue(values, 'ADMIN_LIMON_PASSWORD')),
        UserID: '2',
        PersonID: '3263'
    });

    executeProjectTwoSql('wwi-corp', 'seguridad/crear_procedimiento_login.sql');
}

function installOperations() {
    const publicQueries = [
        'modulos/consultas/clientes.sql',
        'modulos/consultas/proveedores.sql'
    ];

    for (const container of ['wwi-corp', 'wwi-sj', 'wwi-limon']) {
        for (const file of publicQueries) {
            executeProjectOneSql(container, file);
        }
    }

    executeProjectOneSql('wwi-corp', 'modulos/consultas/ciudades.sql');
    executeProjectOneSql('wwi-corp', 'modulos/crud/clientes.sql');
    executeProjectOneSql('wwi-corp', 'modulos/crud/proveedores.sql');
    executeProjectOneSql('wwi-corp', 'modulos/crud/inventarios.sql');
    executeProjectTwoSql('wwi-corp', 'corporativo/consultas_privadas.sql');

    for (const container of ['wwi-sj', 'wwi-limon']) {
        executeProjectOneSql(container, 'modulos/consultas/inventarios.sql');
        executeProjectOneSql(container, 'modulos/consultas/ventas.sql');
        executeProjectOneSql(container, 'modulos/crud/existencias.sql');
        executeProjectOneSql(container, 'modulos/crud/ventas.sql');
    }
}

function installReports() {
    executeProjectTwoSql('wwi-corp', 'corporativo/crear_vistas_reportes.sql');
    executeProjectTwoSql('wwi-corp', 'corporativo/crear_materializacion.sql');
    executeProjectTwoSql('wwi-corp', 'corporativo/crear_soporte_reportes.sql');

    for (const report of [1, 2, 3, 4, 5, 6, 7, 8, 10]) {
        executeProjectOneSql('wwi-corp', `estadisticas/reporte${report}.sql`);
    }

    executeProjectTwoSql('wwi-corp', 'corporativo/crear_consultas_reportes.sql');
    executeProjectTwoSql('wwi-corp', 'comun/crear_consultas_estado.sql', {
        NodeCode: 'CORP'
    });
    executeProjectTwoSql('wwi-sj', 'comun/crear_consultas_estado.sql', {
        NodeCode: 'SJ'
    });
    executeProjectTwoSql('wwi-limon', 'comun/crear_consultas_estado.sql', {
        NodeCode: 'LI'
    });
}

function installSummaryJob() {
    executeProjectTwoSql('wwi-corp', 'corporativo/crear_job_resumen.sql');
}

function installPermissions() {
    executeProjectTwoSql('wwi-corp', 'seguridad/configurar_permisos.sql', {
        NodeCode: 'CORP'
    });
    executeProjectTwoSql('wwi-sj', 'seguridad/configurar_permisos.sql', {
        NodeCode: 'SJ'
    });
    executeProjectTwoSql('wwi-limon', 'seguridad/configurar_permisos.sql', {
        NodeCode: 'LI'
    });
}

const stage = process.argv[2];
const values = readLocalEnv();

if (stage === 'seguridad') {
    installSecurity(values);
} else if (stage === 'operaciones') {
    installOperations();
} else if (stage === 'reportes') {
    installReports();
} else if (stage === 'permisos') {
    installPermissions();
} else if (stage === 'job') {
    installSummaryJob();
} else if (stage === 'completo') {
    installSecurity(values);
    installOperations();
    installReports();
    installPermissions();
    installSummaryJob();
} else {
    throw new Error('Etapa invalida. Use seguridad, operaciones, reportes, permisos, job o completo.');
}

