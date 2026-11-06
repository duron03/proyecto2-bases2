import sql from 'mssql';
import { DB_USER, DB_PASSWORD, DB_SERVER, DB_DATABASE, DB_PORT } from '../config.js';

export const dbSettings = {
    user: DB_USER,
    password: DB_PASSWORD,
    server: DB_SERVER,
    database: DB_DATABASE,
    port: DB_PORT,
    options: { encrypt: false, trustServerCertificate: true }
};

export const getConnection = async () => {
    try {
        const pool = await sql.connect(dbSettings);
        return pool;
        
    } catch (error) {
        console.error(error);
        throw error;
    }
};

export { sql };
