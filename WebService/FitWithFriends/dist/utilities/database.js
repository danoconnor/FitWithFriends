"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DatabaseConnectionPool = void 0;
const pg_1 = require("pg");
exports.DatabaseConnectionPool = new pg_1.Pool({
    host: process.env.PGHOST,
    port: parseInt(process.env.PGPORT),
    database: process.env.PGDATABASE,
    user: process.env.PGUSER,
    password: process.env.PGPASSWORD,
    ssl: process.env.PGUSESSL === "1"
});
