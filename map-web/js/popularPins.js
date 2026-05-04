/**
 * Sistem / popüler pinler (backend dışı, statik).
 * Flutter `popular_locations.dart` ile aynı veri kümesinin bir alt kümesi.
 * @typedef {{ key: string, name: string, latitude: number, longitude: number, description: string, tags: string[] }} PopularPinDef
 */

/** @type {PopularPinDef[]} */
window.POPULAR_PINS = [
  {
    key: 'goreme',
    name: 'Göreme Milli Parkı',
    latitude: 38.6431,
    longitude: 34.8282,
    description:
      'Balonların sabah ışığıyla dansı. Kesinlikle görülmesi gereken eşsiz bir doğa harikası.',
    tags: ['doğa', 'kapadokya', 'manzara'],
  },
  {
    key: 'uchisar',
    name: 'Uçhisar Kalesi',
    latitude: 38.6294,
    longitude: 34.802,
    description:
      'Bölgenin en yüksek noktası. Tarih kokan taş merdivenlerden zirveye çıkmak yorucu ama değiyor.',
    tags: ['tarih', 'uçhisar', 'manzara'],
  },
  {
    key: 'avanos',
    name: 'Avanos Çanak Çömlek',
    latitude: 38.7204,
    longitude: 34.8467,
    description:
      "Kızılırmak'ın çamuruyla sanata dönüşen toprak. Harika bir kültür deneyimi.",
    tags: ['kültür', 'sanat', 'avanos'],
  },
  {
    key: 'ihlara',
    name: 'Ihlara Vadisi',
    latitude: 38.2435,
    longitude: 34.298,
    description:
      'Yüzlerce basamak inip doğanın kalbine ulaşıyorsunuz. Yürüyüş için muazzam bir doğa rotası.',
    tags: ['doğa', 'yürüyüş', 'kanyon'],
  },
  {
    key: 'anitkabir',
    name: 'Anıtkabir',
    latitude: 39.925,
    longitude: 32.836,
    description: "Ata'mızın huzuru. Ankara'ya gelip de burayı ziyaret etmemek olmaz.",
    tags: ['tarih', 'ankara', 'atatürk'],
  },
  {
    key: 'ayasofya',
    name: 'Ayasofya-i Kebir Cami-i Şerifi',
    latitude: 41.0086,
    longitude: 28.98,
    description: 'İstanbul’un kalbinde, medeniyetlerin izlerini taşıyan eşsiz bir yapı.',
    tags: ['tarih', 'istanbul', 'mimari'],
  },
];
