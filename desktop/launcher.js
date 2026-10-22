const { spawn } = require('node:child_process');
const crypto = require('node:crypto');
const fs = require('node:fs');
const net = require('node:net');
const os = require('node:os');
const path = require('node:path');
const EmbeddedPostgres = require('embedded-postgres').default;

const root = path.resolve(__dirname, '..');

function getDataDir() {
  if (process.env.EVOLUTION_DATA_DIR) {
    return path.resolve(process.env.EVOLUTION_DATA_DIR);
  }

  const home = os.homedir();

  if (process.platform === 'win32') {
    return path.join(process.env.APPDATA || path.join(home, 'AppData', 'Roaming'), 'evolution-api');
  }

  if (process.platform === 'darwin') {
    return path.join(home, 'Library', 'Application Support', 'evolution-api');
  }

  return path.join(process.env.XDG_DATA_HOME || path.join(home, '.local', 'share'), 'evolution-api');
}

function readJson(file) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    return {};
  }
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(value, null, 2), { mode: 0o600 });
}

function getFreePort(startPort) {
  return new Promise((resolve) => {
    const server = net.createServer();

    server.once('error', () => resolve(getFreePort(startPort + 1)));
    server.once('listening', () => {
      const { port } = server.address();
      server.close(() => resolve(port));
    });

    server.listen(startPort, '127.0.0.1');
  });
}

async function ensureDatabase(pg) {
  const client = pg.getPgClient('postgres');

  await client.connect();

  try {
    const result = await client.query("SELECT 1 FROM pg_database WHERE datname = 'evolution'");

    if (result.rowCount === 0) {
      await pg.createDatabase('evolution');
    }
  } finally {
    await client.end();
  }
}

async function runMigrations(env) {
  const migrationsDir = path.join(root, 'prisma', 'migrations');
  const sourceDir = path.join(root, 'prisma', 'postgresql-migrations');

  if (!fs.existsSync(migrationsDir) && fs.existsSync(sourceDir)) {
    fs.cpSync(sourceDir, migrationsDir, { recursive: true });
  }

  await new Promise((resolve, reject) => {
    const child = spawn(
      process.execPath,
      [
        path.join(root, 'node_modules', 'prisma', 'build', 'index.js'),
        'migrate',
        'deploy',
        '--schema',
        path.join(root, 'prisma', 'postgresql-schema.prisma'),
      ],
      { cwd: root, env, stdio: 'inherit' },
    );

    child.once('error', reject);
    child.once('exit', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Prisma migrations failed with exit code ${code}`));
      }
    });
  });
}

async function main() {
  const dataDir = getDataDir();

  fs.mkdirSync(dataDir, { recursive: true });

  const configFile = path.join(dataDir, 'config.json');
  const config = readJson(configFile);

  if (!config.apiKey) {
    config.apiKey = crypto.randomBytes(24).toString('hex');
  }

  if (!config.databasePassword) {
    config.databasePassword = crypto.randomBytes(16).toString('hex');
  }

  writeJson(configFile, config);

  const apiPort = Number(process.env.EVOLUTION_PORT || 8080);
  const databasePort = Number(process.env.EVOLUTION_DATABASE_PORT || (await getFreePort(54329)));

  const pg = new EmbeddedPostgres({
    databaseDir: path.join(dataDir, 'pgdata'),
    user: 'evolution',
    password: config.databasePassword,
    port: databasePort,
    persistent: true,
    onLog: () => {},
    onError: (error) => console.error('[postgres]', error),
  });

  if (!fs.existsSync(path.join(dataDir, 'pgdata', 'PG_VERSION'))) {
    await pg.initialise();
  }

  await pg.start();
  await ensureDatabase(pg);

  const env = {
    ...process.env,
    NODE_ENV: 'production',
    DATABASE_PROVIDER: 'postgresql',
    DATABASE_CONNECTION_URI: `postgresql://evolution:${encodeURIComponent(config.databasePassword)}@127.0.0.1:${databasePort}/evolution?schema=evolution_api`,
    DATABASE_CONNECTION_CLIENT_NAME: 'evolution_desktop',
    CACHE_REDIS_ENABLED: 'false',
    CACHE_LOCAL_ENABLED: 'true',
    SERVER_NAME: 'evolution',
    SERVER_TYPE: 'http',
    SERVER_PORT: String(apiPort),
    SERVER_URL: process.env.SERVER_URL || `http://127.0.0.1:${apiPort}`,
    AUTHENTICATION_API_KEY: process.env.AUTHENTICATION_API_KEY || config.apiKey,
    AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES: 'true',
    OPENAI_ENABLED: process.env.OPENAI_ENABLED || 'true',
    TELEMETRY_ENABLED: 'false',
    LOG_LEVEL: process.env.LOG_LEVEL || 'ERROR,WARN,INFO',
    LOG_COLOR: 'true',
    LANGUAGE: process.env.LANGUAGE || 'pt-BR',
    CONFIG_SESSION_PHONE_CLIENT: 'Evolution API Desktop',
    DEL_INSTANCE: 'false',
  };

  await runMigrations(env);

  console.log('');
  console.log(`Evolution API: http://127.0.0.1:${apiPort}`);
  console.log(`Manager:       http://127.0.0.1:${apiPort}/manager`);
  console.log(`API key:       ${env.AUTHENTICATION_API_KEY}`);
  console.log(`Data:          ${dataDir}`);
  console.log('');

  const server = spawn(process.execPath, [path.join(root, 'dist', 'main.js')], {
    cwd: root,
    env,
    stdio: 'inherit',
  });

  let stopping = false;

  const stop = async (code) => {
    if (stopping) {
      return;
    }

    stopping = true;

    if (!server.killed) {
      server.kill('SIGTERM');
    }

    try {
      await pg.stop();
    } catch {}

    process.exit(code);
  };

  server.once('exit', (code) => stop(code ?? 0));
  process.once('SIGINT', () => stop(0));
  process.once('SIGTERM', () => stop(0));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
