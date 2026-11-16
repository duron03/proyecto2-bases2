export function getDatabaseErrorNumber(error) {
	if (error.number) {
		return error.number;
	}

	if (error.originalError && error.originalError.info) {
		return error.originalError.info.number;
	}

	return null;
}

export function sendError(res, error, isWrite = false) {
	if (error.status) {
		return res.status(error.status).json({
			error: error.message,
			code: error.code || 'ERROR_SOLICITUD'
		});
	}

	const number = getDatabaseErrorNumber(error);

	if ([50001, 50101, 50203, 50303, 50304].includes(number)) {
		return res.status(400).json({ error: error.message, code: 'DATOS_INVALIDOS' });
	}

	if ([50002, 50102, 50201, 50301, 50302].includes(number)) {
		return res.status(404).json({ error: error.message, code: 'NO_ENCONTRADO' });
	}

	if (number === 50401) {
		return res.status(409).json({ error: error.message, code: 'VERSION_OBSOLETA' });
	}

	if (number === 50402) {
		return res.status(409).json({ error: error.message, code: 'REGISTRO_INACTIVO' });
	}

	if (number === 50403) {
		return res.status(403).json({ error: error.message, code: 'ACCESO_DENEGADO' });
	}

	if (number === 50404) {
		return res.status(409).json({ error: error.message, code: 'CATALOGO_PENDIENTE' });
	}

	if (number === 50501 || number === 50502) {
		return res.status(503).json({ error: error.message, code: 'SIN_INICIALIZAR' });
	}

	if (number === 547) {
		return res.status(409).json({
			error: 'No se puede realizar la operación porque existen registros relacionados.',
			code: 'CONFLICTO_INTEGRIDAD'
		});
	}

	if (number === 2601 || number === 2627) {
		return res.status(409).json({
			error: 'Ya existe un registro con esos datos.',
			code: 'CONFLICTO_INTEGRIDAD'
		});
	}

	const connectionCodes = ['ELOGIN', 'ESOCKET', 'ECONNCLOSED', 'ENOTOPEN', 'EALREADYCONNECTING'];

	if (connectionCodes.includes(error.code)) {
		return res.status(503).json({
			error: 'No fue posible conectar con el nodo solicitado.',
			code: 'NODO_NO_DISPONIBLE'
		});
	}

	if (error.code === 'ETIMEOUT') {
		let code = 'NODO_NO_DISPONIBLE';
		let message = 'El nodo tardó demasiado en responder.';

		if (isWrite) {
			code = 'RESULTADO_DESCONOCIDO';
			message = 'No se recibió respuesta. Verifique el registro antes de intentar de nuevo.';
		}

		return res.status(503).json({ error: message, code });
	}

	console.error('Error no esperado:', error.message);
	return res.status(500).json({
		error: 'Ocurrió un error interno al procesar la solicitud.',
		code: 'ERROR_INTERNO'
	});
}

export function createHttpError(status, code, message) {
	const error = new Error(message);
	error.status = status;
	error.code = code;
	return error;
}
