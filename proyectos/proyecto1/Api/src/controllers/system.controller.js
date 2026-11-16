import { getConnection } from '../database/connection.js';

async function getLocalStatus(session) {
	const pool = await getConnection(session, 'LOCAL');
	const result = await pool.request().execute('dbo.usp_ObtenerEstadoLocal');
	return result.recordset[0] || null;
}

async function getSourcesStatus(session) {
	const pool = await getConnection(session, 'CORP');
	const result = await pool.request().execute('Corporativo.usp_ObtenerEstadoFuentes');
	return result.recordset;
}

async function getMaterializationStatus(session) {
	const pool = await getConnection(session, 'CORP');
	const result = await pool.request().execute('Corporativo.usp_ObtenerEstadoMaterializacion');
	return result.recordset[0] || null;
}

export async function getSystemStatus(req, res) {
	if (req.session.user.rol === 'CORPORATIVO') {
		let sources = [];
		let materialization = { UltimoExitoUtc: null, estado: 'desconocido' };

		try {
			sources = await getSourcesStatus(req.session);
		} catch (error) {
			console.error('No se pudo consultar el estado de las sedes:', error.message);
		}

		try {
			materialization = await getMaterializationStatus(req.session);
		} catch (error) {
			console.error('No se pudo consultar el resumen:', error.message);
		}

		return res.json({
			catalogo: { ultimoLatidoUtc: null, estado: 'desconocido' },
			sources,
			materializacion: materialization
		});
	}

	let localStatus = { ultimoLatidoUtc: null, estado: 'desconocido' };
	let sources = [];

	try {
		localStatus = await getLocalStatus(req.session);
	} catch (error) {
		console.error('No se pudo consultar el estado local:', error.message);
	}

	try {
		sources = await getSourcesStatus(req.session);
	} catch (error) {
		console.error('No se pudo consultar Corporativo:', error.message);
	}

	res.json({
		catalogo: localStatus,
		sources,
		materializacion: { UltimoExitoUtc: null, estado: 'desconocido' }
	});
}

export function getApiHealth(req, res) {
	res.json({ message: 'API disponible' });
}

