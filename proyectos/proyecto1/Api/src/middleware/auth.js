import { createHttpError, sendError } from '../errors.js';
import { getSession } from '../sessions.js';

export async function requireSession(req, res, next) {
	try {
		const authorization = req.headers.authorization || '';
		const parts = authorization.split(' ');

		if (parts.length !== 2 || parts[0] !== 'Bearer' || !parts[1]) {
			throw createHttpError(401, 'SESION_INVALIDA', 'La sesión no es válida.');
		}

		const session = await getSession(parts[1]);

		if (!session) {
			throw createHttpError(401, 'SESION_INVALIDA', 'La sesión no es válida o venció.');
		}

		req.session = session;
		req.sessionToken = parts[1];
		next();
	} catch (error) {
		sendError(res, error);
	}
}

function denyAccess(res) {
	const error = createHttpError(403, 'ACCESO_DENEGADO', 'No tiene permiso para realizar esta operación.');
	return sendError(res, error);
}

export function requireAdministrator(req, res, next) {
	if (!req.session || req.session.user.rol !== 'ADMINISTRADOR') {
		return denyAccess(res);
	}

	next();
}

export function requireCorporate(req, res, next) {
	if (!req.session || req.session.user.rol !== 'CORPORATIVO') {
		return denyAccess(res);
	}

	next();
}
