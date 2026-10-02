export function protectedFileUrl(baseUrl, url) {
  return `${baseUrl.replace(/\/$/, '')}${url.slice('/api'.length)}`
}
