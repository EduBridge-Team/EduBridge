import { build } from 'esbuild'
import { mkdtemp, rm } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { pathToFileURL, fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('../../', import.meta.url))
const routeEntryPoints = ['src/AppRoutes.jsx', 'src/verification.jsx'].map(path => join(root, path))

export async function createServer() {
  const directory = await mkdtemp(join(root, '.qa-esbuild-'))
  const modules = new Map()
  const common = {
    bundle: true,
    platform: 'node',
    format: 'esm',
    packages: 'external',
    target: 'node22',
    jsx: 'automatic',
    loader: {
      '.css': 'empty', '.svg': 'empty', '.png': 'empty', '.jpg': 'empty',
      '.webp': 'empty', '.woff': 'empty', '.woff2': 'empty',
    },
    define: {
      'import.meta.env': JSON.stringify({
        VITE_API_URL: '/api', VITE_GOOGLE_CLIENT_ID: '', VITE_INSTITUTION_SLUG: '',
      }),
    },
    logLevel: 'silent',
  }
  return {
    async ssrLoadModule(name) {
      const source = resolve(root, '.' + name)
      if (!source.startsWith(join(root, 'src/'))) {
        throw new Error('Only web source modules may be loaded in SSR tests')
      }
      if (!modules.has(source)) {
        if (routeEntryPoints.includes(source)) {
          // The route tree and its verification Provider must share exactly
          // one React context module instance, including lazy route chunks.
          const outputDirectory = join(directory, 'route-graph')
          const compiled = await build({
            ...common, entryPoints: routeEntryPoints, outdir: outputDirectory,
            entryNames: '[name]', chunkNames: 'shared/[name]-[hash]',
            outExtension: { '.js': '.mjs' }, splitting: true, metafile: true,
          })
          for (const [outputPath, data] of Object.entries(compiled.metafile.outputs)) {
            if (!data.entryPoint) continue
            const input = resolve(root, data.entryPoint)
            modules.set(input, import(pathToFileURL(resolve(root, outputPath)).href))
          }
        } else {
          const target = join(directory, 'entry-' + modules.size + '.mjs')
          await build({ ...common, entryPoints: [source], outfile: target })
          modules.set(source, import(pathToFileURL(target).href))
        }
      }
      if (!modules.has(source)) throw new Error('Module output missing: ' + name)
      return modules.get(source)
    },
    async close() {
      await rm(directory, { recursive: true, force: true })
    },
  }
}
