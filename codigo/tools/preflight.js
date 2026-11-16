import { config } from 'dotenv';
import sql from 'mssql';

config();

function getBoolean(value, defaultValue) {
	if (value === undefined) {
		return defaultValue;
	}

	return value === 'true';
}

function getRequired(name) {
	const value = process.env[name];

	if (!value) {
		throw new Error(`Falta la variable ${name} en codigo/.env`);
	}

	return value;
}

function getNodeSettings(name, serverVariable, portVariable) {
	return {
		name,
		connection: {
			user: getRequired('OPERATOR_USER'),
			password: getRequired('OPERATOR_PASSWORD'),
			server: getRequired(serverVariable),
			port: Number(getRequired(portVariable)),
			database: process.env.DB_DATABASE || 'master',
			connectionTimeout: 5000,
			requestTimeout: 15000,
			options: {
				encrypt: getBoolean(process.env.DB_ENCRYPT, true),
				trustServerCertificate: getBoolean(process.env.DB_TRUST_SERVER_CERTIFICATE, true)
			}
		}
	};
}

async function inspectNode(node) {
	const pool = new sql.ConnectionPool(node.connection);

	try {
		await pool.connect();

		const result = await pool.request().query(`
			SELECT
				CAST(SERVERPROPERTY('ServerName') AS nvarchar(128)) AS ServerName,
				CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128)) AS ProductVersion,
				CAST(SERVERPROPERTY('ProductLevel') AS nvarchar(128)) AS ProductLevel,
				CAST(SERVERPROPERTY('Edition') AS nvarchar(128)) AS Edition,
				DB_NAME() AS DatabaseName,
				CASE WHEN EXISTS (
					SELECT 1
					FROM sys.databases
					WHERE name = N'distribution'
				) THEN 1 ELSE 0 END AS HasDistributionDatabase;
		`);

		const data = result.recordset[0];
		return {
			node: node.name,
			ok: true,
			ServerName: data.ServerName,
			ProductVersion: data.ProductVersion,
			ProductLevel: data.ProductLevel,
			Edition: data.Edition,
			DatabaseName: data.DatabaseName,
			HasDistributionDatabase: data.HasDistributionDatabase
		};
	} catch (error) {
		return {
			node: node.name,
			ok: false,
			error: error.code || 'CONNECTION_ERROR'
		};
	} finally {
		await pool.close();
	}
}

async function main() {
	const nodes = [
		getNodeSettings('CORP', 'CORP_SERVER', 'CORP_PORT'),
		getNodeSettings('SJ', 'SJ_SERVER', 'SJ_PORT'),
		getNodeSettings('LI', 'LI_SERVER', 'LI_PORT')
	];

	const results = [];

	for (const node of nodes) {
		results.push(await inspectNode(node));
	}

	console.table(results);

	let hasError = false;
	for (const result of results) {
		if (!result.ok) {
			hasError = true;
		}
	}

	if (hasError) {
		process.exitCode = 1;
	}
}

main().catch((error) => {
	console.error(error.message);
	process.exitCode = 1;
});

