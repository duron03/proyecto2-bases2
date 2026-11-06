import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

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

function executeSql(container, file, variables) {
    const sqlcmdArguments = ['-i', file];

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
        throw new Error(`Fallo ${file} en ${container} (codigo ${error.status ?? 'desconocido'}).`);
    }
}

function installDistributors(values) {
    const common = {
        ReceiverCatalogPasswordHex: toHex(requireValue(values, 'REPL_RECIBE_CATALOGOS_PASSWORD')),
        ReceiverSjPasswordHex: toHex(requireValue(values, 'REPL_RECIBE_SJ_PASSWORD')),
        ReceiverLiPasswordHex: toHex(requireValue(values, 'REPL_RECIBE_LI_PASSWORD'))
    };

    const nodes = [
        ['wwi-corp', 'CORP', 'wwi-corp', 'REPL_CORP_PASSWORD'],
        ['wwi-sj', 'SJ', 'wwi-sj', 'REPL_SJ_PASSWORD'],
        ['wwi-limon', 'LI', 'wwi-limon', 'REPL_LI_PASSWORD']
    ];

    for (const [container, nodeCode, serverName, passwordName] of nodes) {
        console.log(`Configurando distribuidor ${nodeCode}...`);
        executeSql(container, '/opt/proyecto2/sql/replicacion/configurar_distribuidores.sql', {
            NodeCode: nodeCode,
            ServerName: serverName,
            PublisherPasswordHex: toHex(requireValue(values, passwordName)),
            ...common
        });
    }
}

function installCatalogPublication(values) {
    console.log('Configurando P2_Catalogos...');
    executeSql('wwi-corp', '/opt/proyecto2/sql/replicacion/publicar_catalogos.sql', {
        PublisherPasswordHex: toHex(requireValue(values, 'REPL_CORP_PASSWORD')),
        ReceiverPasswordHex: toHex(requireValue(values, 'REPL_RECIBE_CATALOGOS_PASSWORD'))
    });
}

function installFactPublications(values) {
    const requestedBranch = process.argv[3];
    const branches = [
        ['wwi-sj', 'SJ', 'sj', 'REPL_SJ_PASSWORD', 'REPL_RECIBE_SJ_PASSWORD'],
        ['wwi-limon', 'LI', 'limon', 'REPL_LI_PASSWORD', 'REPL_RECIBE_LI_PASSWORD']
    ];

    if (requestedBranch && !branches.some((branch) => branch[1] === requestedBranch)) {
        throw new Error('Sucursal invalida. Use SJ o LI.');
    }

    for (const [container, branchCode, owner, publisherName, receiverName] of branches) {
        if (requestedBranch && requestedBranch !== branchCode) {
            continue;
        }

        console.log(`Configurando P2_Operacion_${branchCode}...`);
        executeSql(container, '/opt/proyecto2/sql/replicacion/publicar_hechos.sql', {
            BranchCode: branchCode,
            DestinationOwner: owner,
            PublisherPasswordHex: toHex(requireValue(values, publisherName)),
            ReceiverPasswordHex: toHex(requireValue(values, receiverName))
        });
    }
}

const stage = process.argv[2];
const values = readLocalEnv();

if (stage === 'distribuidores') {
    installDistributors(values);
} else if (stage === 'catalogo') {
    installCatalogPublication(values);
} else if (stage === 'hechos') {
    installFactPublications(values);
} else {
    throw new Error('Etapa invalida. Use distribuidores, catalogo o hechos.');
}
