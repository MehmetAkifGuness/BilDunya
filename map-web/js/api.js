/**
 * BilDünya REST — `custom-locations` = kullanıcı pinleri (userPins).
 * Auth: Bearer JWT (`localStorage.bildunya_jwt` veya UI alanından set).
 */

const TOKEN_KEY = 'bildunya_jwt';

function apiBase() {
  return (window.BilDunyaMapConfig && window.BilDunyaMapConfig.apiBaseUrl) || 'http://localhost:8080/api';
}

function getToken() {
  return localStorage.getItem(TOKEN_KEY) || '';
}

function setToken(token) {
  if (token) localStorage.setItem(TOKEN_KEY, token.trim());
  else localStorage.removeItem(TOKEN_KEY);
}

function authHeaders() {
  const t = getToken();
  const h = { Accept: 'application/json' };
  if (t) h.Authorization = 'Bearer ' + t;
  return h;
}

/**
 * @returns {Promise<{ id: number, username?: string }>}
 */
async function fetchCurrentUser() {
  const r = await fetch(`${apiBase()}/users/me`, { headers: authHeaders() });
  if (!r.ok) {
    const txt = await r.text();
    throw new Error(txt || r.statusText);
  }
  return r.json();
}

/**
 * Spring `Page<CustomLocationDto>`
 * @param {number} lat
 * @param {number} lon
 * @param {number} [radiusKm]
 * @returns {Promise<any[]>}
 */
async function fetchUserPinsNearby(lat, lon, radiusKm = 80) {
  const q = new URLSearchParams({
    latitude: String(lat),
    longitude: String(lon),
    radiusKm: String(radiusKm),
    page: '0',
    size: '200',
  });
  const r = await fetch(`${apiBase()}/custom-locations/nearby?${q}`, {
    headers: authHeaders(),
  });
  if (!r.ok) {
    const txt = await r.text();
    throw new Error(txt || r.statusText);
  }
  const page = await r.json();
  return Array.isArray(page.content) ? page.content : [];
}

/**
 * Multipart: `data` (JSON) + `files` (0..n görsel)
 * @param {{ name: string, description?: string|null, latitude: number, longitude: number, tags?: string[] }} body
 * @param {File[]} files
 */
async function createUserPin(body, files) {
  const fd = new FormData();
  fd.append(
    'data',
    new Blob([JSON.stringify(body)], { type: 'application/json' }),
  );
  for (const f of files || []) {
    if (f && f.size) fd.append('files', f);
  }
  const r = await fetch(`${apiBase()}/custom-locations`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      ...(getToken() ? { Authorization: 'Bearer ' + getToken() } : {}),
    },
    body: fd,
  });
  if (!r.ok) {
    const txt = await r.text();
    throw new Error(txt || r.statusText);
  }
  return r.json();
}

/**
 * @param {number} id
 */
async function deleteUserPin(id) {
  const r = await fetch(`${apiBase()}/custom-locations/${id}`, {
    method: 'DELETE',
    headers: authHeaders(),
  });
  if (!r.ok && r.status !== 204) {
    const txt = await r.text();
    throw new Error(txt || r.statusText);
  }
}

/**
 * API gövdesini dahili `userPin` modeline çevirir.
 * @param {any} dto
 */
function normalizeUserPinFromApi(dto) {
  const photos = Array.isArray(dto.photo_urls)
    ? dto.photo_urls
    : Array.isArray(dto.photoUrls)
      ? dto.photoUrls
      : [];
  const img = dto.image_url || dto.imageUrl || photos[0] || '';
  return {
    id: dto.id,
    userId: dto.user_id ?? dto.userId,
    title: dto.name || 'Konum',
    description: dto.description || '',
    latitude: dto.latitude,
    longitude: dto.longitude,
    imageUrl: img,
    photoUrls: photos,
    tags: Array.isArray(dto.tags) ? dto.tags : [],
    raw: dto,
  };
}

window.BilDunyaApi = {
  TOKEN_KEY,
  apiBase,
  getToken,
  setToken,
  authHeaders,
  fetchCurrentUser,
  fetchUserPinsNearby,
  createUserPin,
  deleteUserPin,
  normalizeUserPinFromApi,
};
