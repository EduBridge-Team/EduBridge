export function preferredEncodings(header = '') {
  const qualities = new Map(header.toLowerCase().split(',').map((entry) => {
    const [name, ...parameters] = entry.trim().split(';')
    const q = parameters.find((parameter) => parameter.trim().startsWith('q='))
    return [name, q ? Number(q.trim().slice(2)) : 1]
  }))
  const quality = (name) => qualities.get(name) ?? qualities.get('*') ?? 0
  const identity = qualities.get('identity') ?? (qualities.get('*') === 0 ? 0 : 1)
  return ['br', 'gzip', 'identity']
    .map((name) => [name, name === 'identity' ? identity : quality(name)])
    .filter(([, q]) => Number.isFinite(q) && q > 0)
    .sort((a, b) => b[1] - a[1])
    .map(([name]) => name)
}
