import { build } from 'esbuild'
import { mkdtemp, rm } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { pathToFileURL, fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('../../', import.meta.url))

/**
 * Minimal SSR test compiler for component tests (not a Vite runtime mock).
 * Each test server owns its own output directory; packages resolve from the
 * repository node_modules and only explicitly requested source modules run.
 */
export async function createServer() {
  const directory = await mkdtemp(join(root, '.qa-esbuild-'))
  const modules = new Map()
  return {
    async ssrLoadModule(name) {
      const source = resolve(root, '.' + name)
      if (!source.startsWith(join(root, 'src/'))) {
        throw new Error('Only web source modules may be loaded in SSR tests')
      }
      if (!modules.has(source)) {
        const target = join(directory, 'entry-' + modules.size + '.mjs')
        await build({
          entryPoints: [source],
          outfile: target,
          bundle: true,
          platform: 'node',
          format: 'esm',
          packages: 'external',
          target: 'node22',
          jsx: 'automatic',
          loader: {
            '.css': 'empty',
            '.svg': 'empty', '.png': 'empty', '.jpg': 'empty',
            '.webp': 'empty', '.woff': 'empty', '.woff2': 'empty',
          },
          define: {
            'import.meta.env': JSON.stringify({
              VITE_API_URL: '/api',
              VITE_GOOGLE_CLIENT_ID: '',
              VITE_INSTITUTION_SLUG: '',
            }),
          },
          logLevel: 'silent',
        })
        modules.set(source, import(pathToFileURL(target).href))
      }
      return modules.get(source)
    },
    async close() {
      await rm(directory, { recursive: true, force: true })
    },
  }
}
