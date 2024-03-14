import { Pool } from 'pg';

export const DatabaseConnectionPool = new Pool({
    host: process.env.PGHOST,
    port: parseInt(process.env.PGPORT),
    database: process.env.PGDATABASE,
    user: process.env.PGUSER,
    password: process.env.PGPASSWORD,
    ssl: process.env.PGUSESSL === "1"
});