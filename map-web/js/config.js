/**
 * BilDünya harita web — backend kökü (Spring `context-path=/api`).
 * Yerel: http://localhost:8080/api
 */
window.BilDunyaMapConfig = {
  /** @type {string} */
  apiBaseUrl: window.BILDUNYA_API_BASE || 'http://localhost:8080/api',
};

/**
 * `file_url` / `image_url` gibi path'leri tam URL yapar (Cloudinary tam URL ise dokunmaz).
 * @param {string} [path]
 * @returns {string}
 */
function resolveMediaUrl(path) {
  if (!path || typeof path !== 'string') return '';
  const t = path.trim();
  if (!t) return '';
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  let root = window.BilDunyaMapConfig.apiBaseUrl.replace(/\/$/, '');
  if (root.endsWith('/api')) root = root.slice(0, -4);
  return root + (t.startsWith('/') ? t : '/' + t);
}
