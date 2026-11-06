import { execFileSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { existsSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const envPath = resolve('.env');

if (existsSync(envPath)) {
    throw new Error('Ya existe proyecto2/.env. No se reemplazo.');
}

function createPassword(prefix) {
    return `${prefix}_${randomBytes(24).toString('hex')}!Aa9`;
}

function getContainerSaPassword() {
    const output = execFileSync(
        'docker',
        ['inspect', '--format', '{{range .Config.Env}}{{println .}}{{end}}', 'wwi-corp'],
        { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }
    );

    const line = output
        .split('\n')
        .find((value) => value.startsWith('MSSQL_SA_PASSWORD='));

    if (!line) {
        throw new Error('No se encontro MSSQL_SA_PASSWORD en wwi-corp.');
    }

    return line.slice('MSSQL_SA_PASSWORD='.length);
}

const values = {
    MSSQL_SA_PASSWORD: getContainerSaPassword(),
    OPERATOR_USER: 'sa',
    OPERATOR_PASSWORD: null,
    CORP_SERVER: 'localhost',
    CORP_PORT: '14331',
    SJ_SERVER: 'localhost',
    SJ_PORT: '14332',
    LI_SERVER: 'localhost',
    LI_PORT: '14333',
    DB_DATABASE: 'WideWorldImporters',
    DB_ENCRYPT: 'true',
    DB_TRUST_SERVER_CERTIFICATE: 'true',
    REPL_CORP_PASSWORD: createPassword('Rc'),
    REPL_SJ_PASSWORD: createPassword('Rs'),
    REPL_LI_PASSWORD: createPassword('Rl'),
    REPL_RECIBE_CATALOGOS_PASSWORD: createPassword('Rcat'),
    REPL_RECIBE_SJ_PASSWORD: createPassword('Rsj'),
    REPL_RECIBE_LI_PASSWORD: createPassword('Rli'),
    MASTER_KEY_PASSWORD: createPassword('Mkey'),
    ADMIN_SJ_PASSWORD: createPassword('Asj'),
    ADMIN_LIMON_PASSWORD: createPassword('Ali'),
    CORPORATIVO_PASSWORD: createPassword('Corp')
};

values.OPERATOR_PASSWORD = values.MSSQL_SA_PASSWORD;

const lines = [
    '# Generado localmente. No versionar ni compartir.',
    ...Object.entries(values).map(([name, value]) => `${name}=${value}`),
    ''
];

writeFileSync(envPath, lines.join('\n'), { encoding: 'utf8', mode: 0o600, flag: 'wx' });
console.log('proyecto2/.env creado con permisos 0600. No se mostraron secretos.');
