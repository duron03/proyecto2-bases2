import { createPool, sql } from '../database/connection.js';
import { createHttpError, getDatabaseErrorNumber, sendError } from '../errors.js';
import { createSession, removeSession } from '../sessions.js';

function publicUser(user) {
	return {
		iduser: user.iduser,
		username: user.username,
		fullname: user.fullname,
		rol: user.rol,
		SucursalID: user.SucursalID,
		sucursalNombre: user.sucursalNombre
	};
}

export async function login(req, res) {
	let corpPool = null;

	try {
		let username = '';
		let password = '';

		if (typeof req.body.username === 'string') {
			username = req.body.username.trim();
		}

		if (typeof req.body.password === 'string') {
			password = req.body.password;
		}

		if (!username || !password || username.length > 50 || password.length > 128) {
			throw createHttpError(400, 'DATOS_INVALIDOS', 'Debe indicar usuario y contraseña.');
		}

		corpPool = createPool(username, password, 'CORP');
		await corpPool.connect();

		const result = await corpPool.request()
			.input('username', sql.NVarChar(50), username)
			.input('password', sql.NVarChar(128), password)
			.execute('Seguridad.usp_IniciarSesion');

		const user = result.recordset[0];

		if (!user) {
			throw createHttpError(401, 'CREDENCIALES_INVALIDAS', 'Las credenciales no son válidas.');
		}

		let localPool = null;

		if (user.SucursalID === 1) {
			localPool = createPool(username, password, 'SJ');
		} else if (user.SucursalID === 2) {
			localPool = createPool(username, password, 'LI');
		}

		const session = await createSession(user, corpPool, localPool);
		corpPool = null;

		res.json({
			token: session.token,
			user: publicUser(user),
			expiresAt: session.expiresAt.toISOString()
		});
	} catch (error) {
		if (corpPool) {
			try {
				await corpPool.close();
			} catch (closeError) {
				console.error('No se pudo cerrar la conexión:', closeError.message);
			}
		}

		const number = getDatabaseErrorNumber(error);

		if (number === 18456 || number === 50403 || error.code === 'ELOGIN') {
			return res.status(401).json({
				error: 'Las credenciales no son válidas.',
				code: 'CREDENCIALES_INVALIDAS'
			});
		}

		sendError(res, error);
	}
}

export function getCurrentSession(req, res) {
	res.json({
		user: publicUser(req.session.user),
		expiresAt: req.session.expiresAt.toISOString()
	});
}

export async function logout(req, res) {
	await removeSession(req.sessionToken);
	res.json({ message: 'Sesión cerrada correctamente.' });
}
