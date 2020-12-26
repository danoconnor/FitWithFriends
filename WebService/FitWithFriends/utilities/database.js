const pgp = require('pg-promise')()

const cn = {
    host: process.env.PGHOST,
    port: process.env.PGPORT,
    database: process.env.PGDATABASE,
    user: process.env.PGUSER,
    password: process.env.PGPASSWORD,
    ssl: process.env.PGUSESSL === "1"
};

module.exports = pgp(cn)