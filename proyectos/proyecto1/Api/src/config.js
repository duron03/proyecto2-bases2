import { config } from 'dotenv';

config();

export const PORT = Number(process.env.PORT || 3000);
export const DB_DATABASE = process.env.DB_DATABASE;
export const CORP_SERVER = process.env.CORP_SERVER || 'localhost';
export const CORP_PORT = Number(process.env.CORP_PORT || 14331);
export const SJ_SERVER = process.env.SJ_SERVER || 'localhost';
export const SJ_PORT = Number(process.env.SJ_PORT || 14332);
export const LI_SERVER = process.env.LI_SERVER || 'localhost';
export const LI_PORT = Number(process.env.LI_PORT || 14333);
export const DB_ENCRYPT = process.env.DB_ENCRYPT !== 'false';
export const DB_TRUST_SERVER_CERTIFICATE = process.env.DB_TRUST_SERVER_CERTIFICATE !== 'false';
export const SESSION_TTL_MINUTES = Number(process.env.SESSION_TTL_MINUTES || 30);
