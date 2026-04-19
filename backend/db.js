const mysql = require('mysql2/promise');
require('dotenv').config();

function parseDatabaseUrl(databaseUrl) {
  try {
    const url = new URL(databaseUrl);
    const user = url.username ? decodeURIComponent(url.username) : undefined;
    const password = url.password ? decodeURIComponent(url.password) : undefined;
    const host = url.hostname || undefined;
    const port = url.port ? Number(url.port) : undefined;
    const database = url.pathname ? url.pathname.replace(/^\//, '') : undefined;

    const config = {};
    if (host) config.host = host;
    if (port) config.port = port;
    if (user) config.user = user;
    if (password) config.password = password;
    if (database) config.database = database;

    // Support a simple `?ssl=true` query param in the URL if present
    if (url.searchParams && url.searchParams.has('ssl')) {
      const sslVal = url.searchParams.get('ssl');
      if (sslVal === 'true' || sslVal === '1') {
        config.ssl = { rejectUnauthorized: false };
      }
    }

    return config;
  } catch (err) {
    return null;
  }
}

const poolConfig = process.env.DATABASE_URL
  ? parseDatabaseUrl(process.env.DATABASE_URL)
  : {
      host: process.env.DB_HOST,
      port: process.env.DB_PORT ? Number(process.env.DB_PORT) : undefined,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
    };

const pool = mysql.createPool({
  ...poolConfig,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

module.exports = pool;
