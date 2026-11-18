import { build, context } from 'esbuild'
import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('../', import.meta.url))
const dist = join(root, 'dist')
const dev = process.argv.includes('--dev')
const env = {
  VITE_API_URL: process.env.VITE_API_URL || '/api',
  VITE_GOOGLE_CLIENT_ID: process.env.VITE_GOOGLE_CLIENT_ID || '',
  VITE_INSTITUTION_SLUG: process.env.VITE_INSTITUTION_SLUG || '',
}
const shared = {
  entryPoints: [join(root, 'src/main.jsx')],
  outdir: dist,
  bundle: true,
  splitting: true,
  format: 'esm',
  platform: 'browser',
  target: 'es2020',
  jsx: 'automatic',
  entryNames: 'assets/[name]-[hash]',
  chunkNames: 'assets/[name]-[hash]',
  assetNames: 'assets/[name]-[hash]',
  loader: { '.png': 'file', '.jpg': 'file', '.jpeg': 'file', '.svg': 'file', '.woff': 'file', '.woff2': 'file', '.webp': 'file', '.gif': 'file' },
  define: { 'import.meta.env': JSON.stringify(env), 'process.env.NODE_ENV': JSON.stringify(dev ? 'development' : 'production') },
  // Absolute / URLs inside CSS refer to files copied unchanged from public/.
  plugins: [{
    name: 'public-root-urls',
    setup(builder) {
      builder.onResolve({ filter: /^\\// }, args =>
        args.kind === 'url-token' ? { path: args.path, external: true } : undefined)
    },
  }],
  metafile: true,
  minify: !dev,
  logLevel: 'info',
}
async function prepare() {
  await rm(dist, { recursive: true, force: true })
  await mkdir(dist, { recursive: true })
  await cp(join(root, 'public'), dist, { recursive: true })
}
async function html(result) {
  const js = Object.entries(result.metafile.outputs).find(([, meta]) => meta.entryPoint?.endsWith('src/main.jsx'))
  if (!js) throw new Error('The main JavaScript entry was not generated')
  const jsPath = '/' + resolve(root, js[0]).slice(dist.length + 1).replaceAll('\\', '/')
  const cssPath = js[1].cssBundle
    ? '/' + resolve(root, js[1].cssBundle).slice(dist.length + 1).replaceAll('\\', '/')
    : null
  const source = await readFile(join(root, 'index.html'), 'utf8')
  const document = source.replace('<script type="module" src="/src/main.jsx"></script>',
    (cssPath ? '<link rel="stylesheet" href="' + cssPath + '">\n    ' : '') +
    '<script type="module" src="' + jsPath + '"></script>')
  if (document === source) throw new Error('HTML entry replacement failed')
  await writeFile(join(dist, 'index.html'), document)
}
await prepare()
if (dev) {
  // Development mode keeps the same origin and /api paths as production;
  // it is for local usage only, not an Oracle deployment.
  const ctx = await context({ ...shared, write: true, plugins: [...shared.plugins, {
    name: 'html-entry',
    setup(build) {
      build.onEnd(async result => {
        if (result.errors.length === 0) await html(result)
      })
    },
  }] })
  await ctx.watch()
  const server = await ctx.serve({ servedir: dist, host: '127.0.0.1', port: 5173, fallback: join(dist, 'index.html') })
  console.log('EduBridge dev: http://' + server.host + ':' + server.port)
} else {
  const result = await build(shared)
  await html(result)
  if (!result.metafile.outputs || Object.keys(result.metafile.outputs).length === 0) {
    throw new Error('No production assets generated')
  }
}
