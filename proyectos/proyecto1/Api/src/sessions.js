import crypto from 'node:crypto';
import { SESSION_TTL_MINUTES } from './config.js';
import { closePools } from './database/connection.js';

const sessions = new Map();
const maxSessions = 6;

// Las sesiones existen solamente mientras la API está encendida.

function getExpirationDate() {
	return new Date(Date.now() + SESSION_TTL_MINUTES * 60 * 1000);
}

export async function cleanExpiredSessions() {
	const now = Date.now();

	for (const [token, session] of sessions.entries()) {
		if (session.expiresAt.getTime() <= now) {
			sessions.delete(token);
			await closePools(session);
		}
	}
}

export async function createSession(user, corpPool, localPool) {
	await cleanExpiredSessions();

	if (sessions.size >= maxSessions) {
		const error = new Error('Se alcanzó el máximo de sesiones. Cierre una sesión e intente nuevamente.');
		error.status = 503;
		error.code = 'LIMITE_SESIONES';
		throw error;
	}

	const token = crypto.randomBytes(32).toString('hex');
	const expiresAt = getExpirationDate();
	const session = { token, user, expiresAt, corpPool, localPool };
	sessions.set(token, session);
	return session;
}

export async function getSession(token) {
	const session = sessions.get(token);

	if (!session) {
		return null;
	}

	if (session.expiresAt.getTime() <= Date.now()) {
		sessions.delete(token);
		await closePools(session);
		return null;
	}

	return session;
}

export async function removeSession(token) {
	const session = sessions.get(token);
	sessions.delete(token);

	if (session) {
		await closePools(session);
	}
}

function runSessionCleanup() {
	cleanExpiredSessions().catch((error) => {
		console.error('No se pudieron limpiar las sesiones:', error.message);
	});
}

setInterval(runSessionCleanup, 60000).unref();
