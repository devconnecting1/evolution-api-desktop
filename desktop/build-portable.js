const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const platform = `${process.platform}-${process.arch}`;
const stage = path.resolve(process.env.STAGE_DIR || path.join(root, 'portable', `evolution-api-${platform}`));
const runtimeDir = path.join(stage, 'runtime');
const nodeBinary = process.platform === 'win32' ? 'node.exe' : 'node';

function copy(source, destination) {
  fs.cpSync(source, destination, { recursive: true, dereference: true });
}

function write(file, content, mode) {
  fs.writeFileSync(file, content, { mode });
}

function fail(message) {
  console.error(message);
  process.exit(1);
}

if (!fs.existsSync(path.join(root, 'dist', 'main.js'))) {
  fail('dist/main.js not found. Run npm run build first.');
}

fs.rmSync(stage, { recursive: true, force: true });
fs.mkdirSync(stage, { recursive: true });
fs.mkdirSync(runtimeDir, { recursive: true });

for (const entry of ['dist', 'public', 'manager', 'node_modules', 'desktop']) {
  copy(path.join(root, entry), path.join(stage, entry));
}

for (const entry of ['package.json', 'package-lock.json', 'runWithProvider.js', '.env.example']) {
  fs.copyFileSync(path.join(root, entry), path.join(stage, entry));
}

copy(path.join(root, 'prisma'), path.join(stage, 'prisma'));
fs.rmSync(path.join(stage, 'prisma', 'migrations'), { recursive: true, force: true });
copy(path.join(root, 'prisma', 'postgresql-migrations'), path.join(stage, 'prisma', 'migrations'));

fs.copyFileSync(process.execPath, path.join(runtimeDir, nodeBinary));

if (process.platform !== 'win32') {
  fs.chmodSync(path.join(runtimeDir, nodeBinary), 0o755);
}

const unixLauncher = `#!/bin/sh
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "$(uname)" = "Darwin" ]; then
  xattr -d com.apple.quarantine "$DIR/runtime/node" 2>/dev/null || true
fi
exec "$DIR/runtime/node" "$DIR/desktop/launcher.js"
`;

const windowsLauncher = `@echo off
title Evolution API
cd /d "%~dp0"
"%~dp0runtime\\node.exe" "%~dp0desktop\\launcher.js"
if errorlevel 1 pause
`;

const readme = `Evolution API - pacote portatil

Como usar:
1. Extraia todo o conteudo do arquivo.
2. Linux/macOS: execute ./start.sh (ou Iniciar.command no macOS).
   Windows: execute start-hidden.vbs para iniciar sem console e abrir o manager.
   Para diagnostico, use start.bat (modo console).
3. O manager abre automaticamente em http://127.0.0.1:8080/manager.
   Se precisar, abra a URL manualmente no navegador.
4. A chave da API fica salva em config.json na pasta de dados.
   No Windows, execute mostrar-chave.vbs para exibir e copiar a chave.
   Para encerrar o app no Windows, execute stop.vbs.

Atalhos criados pelo instalador no Windows:
- Evolution API: inicia sem console e abre o manager.
- Evolution API Manager: abre o manager no navegador.
- Chave da API: mostra e copia a chave.
- Parar Evolution API: encerra o app.
- Evolution API (console): modo diagnostico com a janela preta.

O pacote inclui Node.js, Evolution API e PostgreSQL. Nao e necessario instalar npm, Docker ou banco de dados.
Redis nao e necessario; o cache local e usado automaticamente.

Integracao OpenAI:
- A integracao oficial usa uma API key da OpenAI (platform.openai.com), faturada separadamente da assinatura ChatGPT.
- ChatGPT Plus/Pro nao inclui uso da API. Nao existe forma oficial de usar o plano ChatGPT como API neste aplicativo.
- Configure a chave em OPENAI_API_KEY_GLOBAL ou crie credenciais pelo endpoint /openai/creds.

Dados persistidos:
- Linux: ~/.local/share/evolution-api
- macOS: ~/Library/Application Support/evolution-api
- Windows: %APPDATA%\\evolution-api
`;

if (process.platform === 'win32') {
  for (const file of ['start-hidden.vbs', 'stop.vbs', 'mostrar-chave.vbs']) {
    fs.copyFileSync(path.join(__dirname, 'windows', file), path.join(stage, file));
  }

  write(path.join(stage, 'start.bat'), windowsLauncher);
} else {
  write(path.join(stage, 'start.sh'), unixLauncher, 0o755);
  write(path.join(stage, 'Iniciar.command'), unixLauncher, 0o755);
}

write(path.join(stage, 'LEIA-ME.txt'), readme);

console.log(stage);
