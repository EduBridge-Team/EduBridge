import { readdir, readFile, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import { brotliCompressSync, gzipSync, constants } from 'node:zlib'

async function compress(directory) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name)
    if (entry.isDirectory()) await compress(path)
    else if (/\.(html|js|css|json|svg)$/.test(path)) {
      const contents = await readFile(path)
      if (contents.length < 1024) continue
      await writeFile(`${path}.gz`, gzipSync(contents, { level: 9 }))
      await writeFile(`${path}.br`, brotliCompressSync(contents, {
        params: { [constants.BROTLI_PARAM_QUALITY]: 11 },
      }))
    }
  }
}

await compress(new URL('../dist/', import.meta.url).pathname)
