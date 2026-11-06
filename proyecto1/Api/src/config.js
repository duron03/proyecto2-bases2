import { config } from 'dotenv';

config();

export const PORT = Number(process.env.PORT || 3000);
export const DB_USER = process.env.DB_USER;
export const DB_PASSWORD = process.env.DB_PASSWORD;
export const DB_SERVER = process.env.DB_SERVER;
export const DB_DATABASE = process.env.DB_DATABASE;
export const DB_PORT = Number(process.env.DB_PORT || 1433);
