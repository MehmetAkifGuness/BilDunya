/* global L, BilDunyaMapConfig, BilDunyaApi, BilDunyaPinStore, POPULAR_PINS, resolveMediaUrl */

(function () {
  const defaultCenter = [38.6431, 34.8282];
  const defaultZoom = 9;

  /** @type {L.Map|null} */
  let map = null;
  /** @type {L.LayerGroup|null} */
  let popularLayer = null;
  /** @type {L.LayerGroup|null} */
  let userLayer = null;

  /** @type {Map<number, L.Marker>} */
  const userMarkers = new Map();

  const el = {
    jwt: document.getElementById('jwtInput'),
    apiBase: document.getElementById('apiBaseInput'),
    saveToken: document.getElementById('saveTokenBtn'),
    refreshPins: document.getElementById('refreshPinsBtn'),
    loadMe: document.getElementById('loadMeBtn'),
    meLabel: document.getElementById('meLabel'),
    modal: document.getElementById('addPinModal'),
    formTitle: document.getElementById('pinTitle'),
    formDesc: document.getElementById('pinDesc'),
    formFiles: document.getElementById('pinFiles'),
    formCoord: document.getElementById('pinCoordLabel'),
    formCancel: document.getElementById('pinFormCancel'),
    formSubmit: document.getElementById('pinFormSubmit'),
  };

  /** @type {{ lat: number, lng: number }|null} */
  let pendingLatLng = null;

  function readConfigFromInputs() {
    const base = (el.apiBase && el.apiBase.value.trim()) || 'http://localhost:8080/api';
    window.BilDunyaMapConfig = window.BilDunyaMapConfig || {};
    window.BilDunyaMapConfig.apiBaseUrl = base.replace(/\/$/, '');
  }

  function syncTokenInput() {
    if (el.jwt) el.jwt.value = BilDunyaApi.getToken();
  }

  function openModal(lat, lng) {
    pendingLatLng = { lat, lng };
    if (el.formCoord) {
      el.formCoord.textContent =
        lat.toFixed(5) + ', ' + lng.toFixed(5);
    }
    if (el.formTitle) el.formTitle.value = '';
    if (el.formDesc) el.formDesc.value = '';
    if (el.formFiles) el.formFiles.value = '';
    if (el.modal) el.modal.classList.add('open');
  }

  function closeModal() {
    pendingLatLng = null;
    if (el.modal) el.modal.classList.remove('open');
  }

  function popularPopupHtml(pin) {
    const tags = (pin.tags || []).join(', ');
    return (
      '<div class="pin-popup">' +
      '<h3>' +
      escapeHtml(pin.title) +
      '</h3>' +
      '<p>' +
      escapeHtml(pin.description) +
      '</p>' +
      (tags
        ? '<div class="tags">' + escapeHtml(tags) + '</div>'
        : '') +
      '<div class="tags">Popüler konum</div>' +
      '</div>'
    );
  }

  function userPopupHtml(pin) {
    const imgUrl = resolveMediaUrl(pin.imageUrl || (pin.photoUrls && pin.photoUrls[0]) || '');
    const imgBlock = imgUrl
      ? '<img src=' +
        JSON.stringify(imgUrl) +
        ' alt="" crossorigin="anonymous"/>'
      : '';
    const state = BilDunyaPinStore.getState();
    const mine =
      state.currentUserId != null &&
      pin.userId != null &&
      Number(pin.userId) === Number(state.currentUserId);
    const delBtn = mine
      ? '<button type="button" class="delete" data-pin-id="' +
        escapeAttr(String(pin.id)) +
        '">Pinimi sil</button>'
      : '';
    return (
      '<div class="pin-popup">' +
      '<h3>' +
      escapeHtml(pin.title) +
      '</h3>' +
      '<p>' +
      escapeHtml(pin.description || '') +
      '</p>' +
      imgBlock +
      delBtn +
      '</div>'
    );
  }

  function escapeHtml(s) {
    return String(s || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function escapeAttr(s) {
    return escapeHtml(s).replace(/'/g, '&#39;');
  }

  const popularIcon = L.divIcon({
    className: 'bd-pin bd-pin--popular',
    html: '<span aria-hidden="true">★</span>',
    iconSize: [28, 28],
    iconAnchor: [14, 28],
    popupAnchor: [0, -26],
  });

  const userIcon = L.divIcon({
    className: 'bd-pin bd-pin--user',
    html: '<span aria-hidden="true">●</span>',
    iconSize: [26, 26],
    iconAnchor: [13, 26],
    popupAnchor: [0, -24],
  });

  function renderPopularPins() {
    if (!popularLayer) return;
    popularLayer.clearLayers();
    const state = BilDunyaPinStore.getState();
    state.popularPins.forEach((pin) => {
      const m = L.marker([pin.latitude, pin.longitude], {
        title: pin.title,
        icon: popularIcon,
      });
      m.bindPopup(popularPopupHtml(pin), { maxWidth: 280 });
      m.addTo(popularLayer);
    });
  }

  function renderUserPins() {
    if (!userLayer) return;
    userLayer.clearLayers();
    userMarkers.clear();
    const state = BilDunyaPinStore.getState();
    state.userPins.forEach((pin) => {
      if (pin.latitude == null || pin.longitude == null || pin.id == null) return;
      const m = L.marker([pin.latitude, pin.longitude], {
        title: pin.title,
        icon: userIcon,
      });
      m.bindPopup(userPopupHtml(pin), { maxWidth: 280 });
      m.on('popupopen', () => {
        const node = m.getPopup() && m.getPopup().getElement();
        if (!node) return;
        const btn = node.querySelector('button.delete');
        if (btn) {
          btn.onclick = async () => {
            const id = Number(btn.getAttribute('data-pin-id'));
            if (!id || !confirm('Bu pini silmek istediğinize emin misiniz?')) return;
            try {
              await BilDunyaApi.deleteUserPin(id);
              BilDunyaPinStore.removeUserPinById(id);
              m.closePopup();
            } catch (err) {
              alert(err.message || String(err));
            }
          };
        }
      });
      m.addTo(userLayer);
      userMarkers.set(pin.id, m);
    });
  }

  async function reloadUserPinsFromApi() {
    if (!map || !BilDunyaApi.getToken()) {
      BilDunyaPinStore.setUserPins([]);
      return;
    }
    const c = map.getCenter();
    try {
      const list = await BilDunyaApi.fetchUserPinsNearby(c.lat, c.lng, 80);
      const normalized = list.map(BilDunyaApi.normalizeUserPinFromApi);
      BilDunyaPinStore.setUserPins(normalized);
    } catch (e) {
      console.warn('userPins yüklenemedi', e);
      BilDunyaPinStore.setUserPins([]);
    }
  }

  function onStoreChange() {
    renderPopularPins();
    renderUserPins();
  }

  function initMap() {
    map = L.map('map', { zoomControl: true }).setView(defaultCenter, defaultZoom);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap',
    }).addTo(map);

    popularLayer = L.layerGroup().addTo(map);
    userLayer = L.layerGroup().addTo(map);

    BilDunyaPinStore.initPopularPins(window.POPULAR_PINS || []);

    map.on('click', (ev) => {
      if (!BilDunyaApi.getToken()) {
        alert('Önce JWT kaydedin (giriş token\'ı). Haritaya pin eklemek için oturum gerekir.');
        return;
      }
      openModal(ev.latlng.lat, ev.latlng.lng);
    });

    let moveTimer = null;
    map.on('moveend', () => {
      if (moveTimer) clearTimeout(moveTimer);
      moveTimer = setTimeout(() => reloadUserPinsFromApi(), 450);
    });

    BilDunyaPinStore.subscribe(onStoreChange);
    onStoreChange();
    reloadUserPinsFromApi();
  }

  async function submitNewPin() {
    if (!pendingLatLng) return;
    const title = (el.formTitle && el.formTitle.value.trim()) || '';
    if (!title) {
      alert('Başlık zorunludur.');
      return;
    }
    const desc = (el.formDesc && el.formDesc.value.trim()) || '';
    const files = el.formFiles && el.formFiles.files ? Array.from(el.formFiles.files) : [];
    const body = {
      name: title,
      description: desc || null,
      latitude: pendingLatLng.lat,
      longitude: pendingLatLng.lng,
      tags: [],
    };
    try {
      el.formSubmit.disabled = true;
      const dto = await BilDunyaApi.createUserPin(body, files);
      const pin = BilDunyaApi.normalizeUserPinFromApi(dto);
      BilDunyaPinStore.upsertUserPin(pin);
      closeModal();
    } catch (err) {
      alert(err.message || String(err));
    } finally {
      el.formSubmit.disabled = false;
    }
  }

  function wireUi() {
    if (el.saveToken) {
      el.saveToken.addEventListener('click', () => {
        readConfigFromInputs();
        BilDunyaApi.setToken(el.jwt ? el.jwt.value : '');
        syncTokenInput();
        reloadUserPinsFromApi();
      });
    }
    if (el.refreshPins) {
      el.refreshPins.addEventListener('click', () => reloadUserPinsFromApi());
    }
    if (el.loadMe) {
      el.loadMe.addEventListener('click', async () => {
        readConfigFromInputs();
        BilDunyaApi.setToken(el.jwt ? el.jwt.value : '');
        try {
          const me = await BilDunyaApi.fetchCurrentUser();
          BilDunyaPinStore.setCurrentUserId(me.id);
          if (el.meLabel) {
            el.meLabel.textContent =
              'Giriş: @' + (me.username || '') + ' (id ' + me.id + ')';
          }
        } catch (e) {
          BilDunyaPinStore.setCurrentUserId(null);
          if (el.meLabel) el.meLabel.textContent = 'Profil yüklenemedi';
          alert(e.message || String(e));
        }
      });
    }
    if (el.formCancel) el.formCancel.addEventListener('click', closeModal);
    if (el.formSubmit) el.formSubmit.addEventListener('click', submitNewPin);
    if (el.modal) {
      el.modal.addEventListener('click', (ev) => {
        if (ev.target === el.modal) closeModal();
      });
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    readConfigFromInputs();
    if (el.apiBase) el.apiBase.value = window.BilDunyaMapConfig.apiBaseUrl;
    syncTokenInput();
    wireUi();
    initMap();
  });
})();
