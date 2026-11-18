import { createServer } from 'node:http'
import { createReadStream, existsSync, statSync } from 'node:fs'
import { resolve, relative, extname } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('../dist/', import.meta.url))
const portArg = process.argv.indexOf('--port')
const port = portArg > -1 ? Number(process.argv[portArg + 1]) : 4173
if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid port')
const types = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml', '.woff2': 'font/woff2', '.woff': 'font/woff',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.webp': 'image/webp', '.ico': 'image/x-icon',
}
createServer((req, res) => {
  if (!['GET', 'HEAD'].includes(req.method)) {
    res.writeHead(405, { Allow: 'GET, HEAD' }); res.end(); return
  }
  let pathname
  try { pathname = decodeURIComponent(new URL(req.url, 'http://127.0.0.1').pathname) }
  catch { res.writeHead(400); res.end(); return }
  // Preview is deliberately local-only and does not proxy real API requests.
  if (pathname === '/api' || pathname.startsWith('/api/')) {
    res.writeHead(404); res.end(); return
  }
  const candidate = resolve(root, '.' + pathname)
  const rel = relative(root, candidate)
  if (rel === '..' || rel.startsWith('../') || rel.startsWith('..\\')) {
    res.writeHead(403); res.end(); return
  }
  const file = existsSync(candidate) && statSync(candidate).isFile()
    ? candidate : resolve(root, 'index.html')
  if (!existsSync(file)) { res.writeHead(404); res.end(); return }
  res.setHeader('Content-Type', types[extname(file)] || 'application/octet-stream')
  res.setHeader('Cache-Control', 'no-store')
  res.setHeader('X-Content-Type-Options', 'nosniff')
  res.statusCode = 200
  if (req.method === 'HEAD') { res.end(); return }
  createReadStream(file).pipe(res)
}).listen(port, '127.0.0.1', () => console.log('Local preview at http://127.0.0.1:' + port))
