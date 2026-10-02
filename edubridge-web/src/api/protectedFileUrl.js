export function protectedFileUrl(baseUrl, url) {
  return `${baseUrl.replace(/\/$/, '')}${url.slice('/api'.length)}`
}

export function safeFileBlob(blob) {
  const type = blob.type.split(';')[0].trim().toLowerCase()
  if (['application/pdf', 'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/avif', 'text/plain'].includes(type)) return blob
  // Blob navigation does not inherit the API response's CSP. Never open active
  // HTML/SVG as a document in the application's origin.
  return new Blob([blob], { type: ['text/html', 'application/xhtml+xml', 'image/svg+xml'].includes(type) ? 'text/plain' : 'application/octet-stream' })
}

export function privateMediaCrossOrigin(url) {
  return typeof url === 'string' && url.includes('/api/private-files/lesson/') ? 'anonymous' : undefined
}
