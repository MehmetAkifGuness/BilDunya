/**
 * Basit store: `popularPins` (statik) + `userPins` (API + yerel).
 * İstediğiniz gibi Redux / Zustand ile değiştirilebilir; burada minimal subscribe pattern.
 */

/** @type {any[]} */
let popularPins = [];

/** @type {any[]} */
let userPins = [];

/** @type {number|null} */
let currentUserId = null;

/** @type {Set<() => void>} */
const listeners = new Set();

function subscribe(fn) {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

function notify() {
  listeners.forEach((fn) => {
    try {
      fn();
    } catch (e) {
      console.error(e);
    }
  });
}

function getState() {
  return {
    popularPins: [...popularPins],
    userPins: [...userPins],
    currentUserId,
  };
}

function initPopularPins(defs) {
  popularPins = (defs || []).map((p) => ({
    kind: 'popular',
    key: p.key,
    title: p.name,
    description: p.description,
    latitude: p.latitude,
    longitude: p.longitude,
    tags: p.tags || [],
  }));
  notify();
}

function setCurrentUserId(id) {
  currentUserId = id != null ? Number(id) : null;
  notify();
}

function setUserPins(pins) {
  userPins = Array.isArray(pins) ? [...pins] : [];
  notify();
}

function upsertUserPin(pin) {
  const id = pin.id;
  const i = userPins.findIndex((p) => p.id === id);
  if (i >= 0) userPins[i] = pin;
  else userPins.push(pin);
  notify();
}

function removeUserPinById(id) {
  userPins = userPins.filter((p) => p.id !== id);
  notify();
}

window.BilDunyaPinStore = {
  subscribe,
  getState,
  initPopularPins,
  setCurrentUserId,
  setUserPins,
  upsertUserPin,
  removeUserPinById,
};
