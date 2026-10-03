// Aperçu de développement : sert la version web de l'application et relaie /api vers un backend,
// pour que l'application et l'API partagent la même origine (comme sur le site).
// Usage : flutter build web, puis node outils/apercu.mjs [adresse du backend]   (défaut : http://localhost:8080)
import { createReadStream, existsSync, statSync } from 'node:fs';
import http from 'node:http';
import { dirname, extname, join, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

const racine = join(dirname(fileURLToPath(import.meta.url)), '..', 'build', 'web');
const backend = new URL(process.argv[2] ?? 'http://localhost:8080');
const port = Number(process.env.PORT ?? 5180);
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.ico': 'image/x-icon', '.ttf': 'font/ttf', '.otf': 'font/otf', '.svg': 'image/svg+xml', '.css': 'text/css' };

http
  .createServer((requete, reponse) => {
    if (requete.url.startsWith('/api/')) {
      const relais = http.request({ hostname: backend.hostname, port: backend.port, path: requete.url, method: requete.method, headers: { ...requete.headers, host: requete.headers.host } }, (amont) => {
        reponse.writeHead(amont.statusCode ?? 502, amont.headers);
        amont.pipe(reponse);
      });
      relais.on('error', () => reponse.writeHead(502).end('Backend injoignable'));
      requete.pipe(relais);
      return;
    }
    const chemin = normalize(decodeURIComponent(requete.url.split('?')[0])).replace(/^[/\\]+/, '');
    let fichier = join(racine, chemin);
    if (!fichier.startsWith(racine) || !existsSync(fichier) || statSync(fichier).isDirectory()) fichier = join(racine, 'index.html');
    reponse.writeHead(200, { 'Content-Type': types[extname(fichier)] ?? 'application/octet-stream', 'Cache-Control': 'no-store' });
    createReadStream(fichier).pipe(reponse);
  })
  .listen(port, () => console.log(`Aperçu sur http://localhost:${port} (API relayée vers ${backend.origin})`));
