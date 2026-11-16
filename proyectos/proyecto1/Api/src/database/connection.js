import sql from 'mssql';
import {
	CORP_PORT,
	CORP_SERVER,
	DB_DATABASE,
	DB_ENCRYPT,
	DB_TRUST_SERVER_CERTIFICATE,
	LI_PORT,
	LI_SERVER,
	SJ_PORT,
	SJ_SERVER
} from '../config.js';

const nodes = {
	CORP: { server: CORP_SERVER, port: CORP_PORT },
	SJ: { server: SJ_SERVER, port: SJ_PORT },
	LI: { server: LI_SERVER, port: LI_PORT }
};

function getSettings(user, password, nodeCode) {
	const node = nodes[nodeCode];

	if (!node) {
		throw new Error('El nodo solicitado no existe.');
	}

	return {
		user,
		password,
		server: node.server,
		port: node.port,
		database: DB_DATABASE || 'WideWorldImporters',
		connectionTimeout: 5000,
		requestTimeout: 15000,
		pool: { max: 3, min: 0, idleTimeoutMillis: 30000 },
		options: {
			encrypt: DB_ENCRYPT,
			trustServerCertificate: DB_TRUST_SERVER_CERTIFICATE
		}
	};
}

export function createPool(user, password, nodeCode) {
	const pool = new sql.ConnectionPool(getSettings(user, password, nodeCode));

	pool.on('error', (error) => {
		console.error(`Error de conexión en ${nodeCode}:`, error.message);
	});

	return pool;
}

export async function connectPool(pool) {
	if (!pool.connected) {
		await pool.connect();
	}

	return pool;
}

export async function getConnection(session, destination) {
	if (destination === 'CORP') {
		return connectPool(session.corpPool);
	}

	if (destination === 'LOCAL' && session.user.rol === 'ADMINISTRADOR' && session.localPool) {
		return connectPool(session.localPool);
	}

	const error = new Error('El usuario no tiene un nodo local disponible.');
	error.status = 403;
	error.code = 'ACCESO_DENEGADO';
	throw error;
}

export async function closePools(session) {
	if (session.corpPool) {
		try {
			await session.corpPool.close();
		} catch (error) {
			console.error('No se pudo cerrar la conexión corporativa:', error.message);
		}
	}

	if (session.localPool) {
		try {
			await session.localPool.close();
		} catch (error) {
			console.error('No se pudo cerrar la conexión local:', error.message);
		}
	}
}

export { sql };
