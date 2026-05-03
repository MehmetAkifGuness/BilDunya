class PopularLocation {
  const PopularLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.tags,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final List<String> tags;
}

const List<PopularLocation> popularLocations = <PopularLocation>[
  // Kapadokya & İç Anadolu
  PopularLocation(
    name: "Göreme Milli Parkı",
    latitude: 38.6431,
    longitude: 34.8282,
    description:
        "Balonların sabah ışığıyla dansı. Kesinlikle görülmesi gereken eşsiz bir doğa harikası.",
    tags: <String>["doğa", "kapadokya", "manzara"],
  ),
  PopularLocation(
    name: "Uçhisar Kalesi",
    latitude: 38.6294,
    longitude: 34.8020,
    description:
        "Bölgenin en yüksek noktası. Tarih kokan taş merdivenlerden zirveye çıkmak yorucu ama değiyor.",
    tags: <String>["tarih", "uçhisar", "manzara"],
  ),
  PopularLocation(
    name: "Avanos Çanak Çömlek",
    latitude: 38.7204,
    longitude: 34.8467,
    description:
        "Kızılırmak'ın çamuruyla sanata dönüşen toprak. Harika bir kültür deneyimi.",
    tags: <String>["kültür", "sanat", "avanos"],
  ),
  PopularLocation(
    name: "Ihlara Vadisi",
    latitude: 38.2435,
    longitude: 34.2980,
    description:
        "Yüzlerce basamak inip doğanın kalbine ulaşıyorsunuz. Yürüyüş için muazzam bir doğa rotası.",
    tags: <String>["doğa", "yürüyüş", "kanyon"],
  ),
  PopularLocation(
    name: "Derinkuyu Yeraltı Şehri",
    latitude: 38.3735,
    longitude: 34.7349,
    description:
        "Yerin kat kat altına inen gizemli bir tarih. Klostrofobisi olanlar dikkat etsin!",
    tags: <String>["tarih", "müze", "gizem"],
  ),
  PopularLocation(
    name: "Paşabağları",
    latitude: 38.6775,
    longitude: 34.8550,
    description:
        "Peri bacalarının en karakteristik, mantar formlu olanları burada. Harika fotoğraflar çıkıyor.",
    tags: <String>["doğa", "peribacaları", "fotoğraf"],
  ),
  PopularLocation(
    name: "Aşk Vadisi",
    latitude: 38.6600,
    longitude: 34.8250,
    description:
        "Gün batımı izlemek için en favori noktam. Doğa tüm güzelliğini sergiliyor.",
    tags: <String>["doğa", "günbatımı", "trekking"],
  ),
  PopularLocation(
    name: "Anıtkabir",
    latitude: 39.9250,
    longitude: 32.8360,
    description: "Ata'mızın huzuru. Ankara'ya gelip de burayı ziyaret etmemek olmaz.",
    tags: <String>["tarih", "ankara", "atatürk"],
  ),
  PopularLocation(
    name: "Tuz Gölü",
    latitude: 37.7500,
    longitude: 33.3300,
    description:
        "Türkiye'nin Maldivleri! Bembeyaz kumsalı andıran tuz tabakası ve gökyüzünün yansıması.",
    tags: <String>["doğa", "göl", "manzara"],
  ),
  PopularLocation(
    name: "Odunpazarı Evleri",
    latitude: 41.2442,
    longitude: 32.6931,
    description:
        "Safranbolu'un tarihi ahşap evleri arasında kaybolmak. Nostaljik bir kültür gezisi.",
    tags: <String>["tarih", "mimari", "kültür"],
  ),

  // İstanbul
  PopularLocation(
    name: "Ayasofya Camii",
    latitude: 41.0082,
    longitude: 28.9784,
    description:
        "İki büyük dinin izlerini taşıyan muazzam bir mimari. Tarih adeta duvarlara kazınmış.",
    tags: <String>["tarih", "istanbul", "mimari"],
  ),
  PopularLocation(
    name: "Galata Kulesi",
    latitude: 41.0256,
    longitude: 28.9741,
    description:
        "İstanbul'u 360 derece izlemek için en iyi nokta. Hezarfen'in izinde bir keşif.",
    tags: <String>["şehir", "manzara", "tarih"],
  ),
  PopularLocation(
    name: "Topkapı Sarayı",
    latitude: 41.0086,
    longitude: 28.9802,
    description:
        "Osmanlı'nın kalbi. Avlular arasında gezerken kendinizi padişah gibi hissediyorsunuz.",
    tags: <String>["tarih", "müze", "saray"],
  ),
  PopularLocation(
    name: "Yerebatan Sarnıcı",
    latitude: 41.0084,
    longitude: 28.9779,
    description:
        "Medusa başı ve loş ışıklar altındaki sütunlar. Büyüleyici bir yeraltı tarihi.",
    tags: <String>["tarih", "müze", "sarnıç"],
  ),
  PopularLocation(
    name: "Kız Kulesi",
    latitude: 41.0211,
    longitude: 29.0041,
    description:
        "Salacak sahilinde çay yudumlarken bu zarif yapıyı izlemek şehrin en iyi aktivitesi.",
    tags: <String>["şehir", "deniz", "manzara"],
  ),
  PopularLocation(
    name: "İstiklal Caddesi",
    latitude: 41.0339,
    longitude: 28.9778,
    description:
        "Kırmızı tramvay, kalabalık ve nostalji. Şehrin hiç uyumayan kalbi.",
    tags: <String>["şehir", "sokak", "kültür"],
  ),
  PopularLocation(
    name: "Dolmabahçe Sarayı",
    latitude: 41.0115,
    longitude: 28.9833,
    description:
        "Boğazın kenarına inci gibi dizilmiş, zarafet ve tarihin buluştuğu nokta.",
    tags: <String>["tarih", "saray", "müze"],
  ),
  PopularLocation(
    name: "Kapalıçarşı",
    latitude: 41.0107,
    longitude: 28.9680,
    description:
        "Dünyanın en eski alışveriş merkezi. Labirent gibi sokaklarında kültür fışkırıyor.",
    tags: <String>["kültür", "alışveriş", "tarih"],
  ),
  PopularLocation(
    name: "Pierre Loti Tepesi",
    latitude: 41.0534,
    longitude: 28.9341,
    description:
        "Haliç'e karşı kahve keyfi. Özellikle sonbaharda doğa ve manzara harika oluyor.",
    tags: <String>["manzara", "doğa", "şehir"],
  ),
  PopularLocation(
    name: "Gülhane Parkı",
    latitude: 41.0122,
    longitude: 28.9810,
    description:
        "Tarihi yarımadanın içinde yeşil bir nefes. Baharda lalelerle tam bir doğa şöleni.",
    tags: <String>["doğa", "park", "istanbul"],
  ),

  // Ege & Akdeniz
  PopularLocation(
    name: "Efes Antik Kenti",
    latitude: 37.9400,
    longitude: 27.3400,
    description:
        "Celsus Kütüphanesi tek kelimeyle efsane! Antik çağın sokaklarında bir tarih yürüyüşü.",
    tags: <String>["tarih", "antik", "arkeoloji"],
  ),
  PopularLocation(
    name: "Pamukkale Travertenleri",
    latitude: 37.9250,
    longitude: 29.1200,
    description:
        "Bembeyaz travertenler ve sıcak termal sular. Eşi benzeri olmayan bir doğa mucizesi.",
    tags: <String>["doğa", "traverten", "şifa"],
  ),
  PopularLocation(
    name: "Şirince Köyü",
    latitude: 37.9430,
    longitude: 27.4330,
    description:
        "Arnavut kaldırımlı sokakları ve tarihi Rum evleriyle şirin bir kültür noktası.",
    tags: <String>["köy", "kültür", "doğa"],
  ),
  PopularLocation(
    name: "Ölüdeniz",
    latitude: 36.5450,
    longitude: 29.1150,
    description:
        "Babadağ'dan yamaç paraşütüyle atlayıp bu muazzam maviliği izlemek şart.",
    tags: <String>["doğa", "deniz", "macera"],
  ),
  PopularLocation(
    name: "Saklıkent Kanyonu",
    latitude: 36.4750,
    longitude: 29.4000,
    description:
        "Buz gibi sularda yürüyüş yapmak. Yaz sıcağında harika bir doğa aktivitesi.",
    tags: <String>["doğa", "kanyon", "yürüyüş"],
  ),
  PopularLocation(
    name: "Olympos Antik Kenti",
    latitude: 36.3980,
    longitude: 30.4700,
    description:
        "Ormanın içinde denizle buluşan gizli bir tarih. Likya medeniyetinin izleri.",
    tags: <String>["tarih", "antik", "doğa"],
  ),
  PopularLocation(
    name: "Antalya Kaleiçi",
    latitude: 36.8840,
    longitude: 30.7040,
    description:
        "Hadrian Kapısı'ndan geçip tarihi evlerin arasında kaybolmak.",
    tags: <String>["şehir", "tarih", "mimari"],
  ),
  PopularLocation(
    name: "Salda Gölü",
    latitude: 37.5500,
    longitude: 29.6800,
    description:
        "Turkuazın en güzel tonu ve bembeyaz kumlar. Doğa harikası bu gölü korumalıyız.",
    tags: <String>["doğa", "göl", "manzara"],
  ),
  PopularLocation(
    name: "Bodrum Sualtı Müzesi",
    latitude: 37.0310,
    longitude: 27.4290,
    description:
        "Tarihi bir kalenin içinde dünyanın en zengin sualtı buluntuları.",
    tags: <String>["tarih", "müze", "deniz"],
  ),
  PopularLocation(
    name: "Kaputaş Plajı",
    latitude: 36.2250,
    longitude: 29.4500,
    description:
        "Merdivenlerden inerken görünen o muazzam mavi. Dünyanın en iyi plajlarından biri.",
    tags: <String>["doğa", "deniz", "yaz"],
  ),

  // Güneydoğu Anadolu
  PopularLocation(
    name: "Diyarbakır Surları",
    latitude: 37.9100,
    longitude: 40.2350,
    description:
        "Çin Seddi'nden sonraki en uzun surlar. Şehrin ortasında devasa bir tarih.",
    tags: <String>["tarih", "diyarbakır", "sur"],
  ),
  PopularLocation(
    name: "Hevsel Bahçeleri",
    latitude: 37.9020,
    longitude: 40.2380,
    description:
        "Dicle'nin bereket verdiği binlerce yıllık doğa mirası. Kuş sesleri arasında yürüyüş.",
    tags: <String>["doğa", "diyarbakır", "UNESCO"],
  ),
  PopularLocation(
    name: "Göbeklitepe",
    latitude: 37.2232,
    longitude: 38.9224,
    description:
        "Tarihin sıfır noktası! İnsanlığın bilinen en eski tapınağı, tüyler ürpertici.",
    tags: <String>["tarih", "arkeoloji", "müze"],
  ),
  PopularLocation(
    name: "Balıklıgöl",
    latitude: 37.1480,
    longitude: 38.7845,
    description:
        "Şanlıurfa'nın mistik kalbi. Hikayesi ve atmosferiyle insanı büyülüyor.",
    tags: <String>["kültür", "mistik", "tarih"],
  ),
  PopularLocation(
    name: "Zeugma Mozaik Müzesi",
    latitude: 37.0750,
    longitude: 37.3850,
    description:
        "Çingene Kızı mozaiğinin gözleriyle göz göze gelmek... Eşsiz bir müze deneyimi.",
    tags: <String>["tarih", "müze", "sanat"],
  ),
  PopularLocation(
    name: "Mardin Eski Şehir",
    latitude: 37.3130,
    longitude: 40.7380,
    description:
        "Taşın şiire dönüştüğü şehir. Mezopotamya ovasına karşı çay içmek çok keyifli.",
    tags: <String>["kültür", "mimari", "manzara"],
  ),
  PopularLocation(
    name: "Deyrulzafaran Manastırı",
    latitude: 37.2990,
    longitude: 40.7930,
    description:
        "Süryani kültürünün yüzyıllardır ayakta kalan kalesi. Taş işçiliği muazzam.",
    tags: <String>["tarih", "inanç", "kültür"],
  ),
  PopularLocation(
    name: "Halfeti",
    latitude: 37.2470,
    longitude: 37.8700,
    description:
        "Fırat nehrinin suları altında kalan batık şehir. Tekne turu harika bir deneyim.",
    tags: <String>["doğa", "tarih", "nehir"],
  ),
  PopularLocation(
    name: "Nemrut Dağı",
    latitude: 38.0329,
    longitude: 38.7618,
    description:
        "Güneşin doğuşunu dev tanrı heykelleriyle izlemek. Unutulmaz bir doğa ve tarih buluşması.",
    tags: <String>["tarih", "doğa", "macera"],
  ),
  PopularLocation(
    name: "Hasankeyf",
    latitude: 37.7120,
    longitude: 41.4130,
    description:
        "Dicle kıyısında mağara evleri ve binlerce yıllık kültürel miras.",
    tags: <String>["tarih", "kültür", "nehir"],
  ),

  // Karadeniz & Doğu Anadolu
  PopularLocation(
    name: "Sümela Manastırı",
    latitude: 40.6900,
    longitude: 39.6580,
    description:
        "Altındere Vadisi'nin sarp kayalıklarına tutunmuş, inanılmaz bir tarihi yapı.",
    tags: <String>["tarih", "doğa", "trabzon"],
  ),
  PopularLocation(
    name: "Uzungöl",
    latitude: 40.6150,
    longitude: 40.2800,
    description:
        "Sislerin ardında saklı çam ormanları ve serin bir göl manzarası.",
    tags: <String>["doğa", "göl", "orman"],
  ),
  PopularLocation(
    name: "Ayder Yaylası",
    latitude: 40.9630,
    longitude: 41.1000,
    description:
        "Yeşilin binbir tonu ve tulum sesleri. Karadeniz'in vahşi doğası.",
    tags: <String>["doğa", "yayla", "yeşil"],
  ),
  PopularLocation(
    name: "Ani Harabeleri",
    latitude: 40.5070,
    longitude: 43.5720,
    description:
        "Kars'ta sınırın hemen dibindeki hayalet şehir. Binlerce yıllık tarih kışın bembeyaz.",
    tags: <String>["tarih", "kars", "antik"],
  ),
  PopularLocation(
    name: "İshak Paşa Sarayı",
    latitude: 39.5200,
    longitude: 44.1290,
    description:
        "Ağrı Dağı'nın eteklerinde, masallardan fırlamış gibi duran muazzam bir saray.",
    tags: <String>["tarih", "saray", "doğa"],
  ),
  PopularLocation(
    name: "Çıldır Gölü",
    latitude: 39.0200,
    longitude: 43.2500,
    description:
        "Kışın tamamen donan gölün üzerinde atlı kızaklarla gezmek harika bir keşif.",
    tags: <String>["doğa", "kış", "göl"],
  ),
  PopularLocation(
    name: "Yedigöller",
    latitude: 40.8500,
    longitude: 31.7500,
    description:
        "Sonbaharda yaprakların sarıdan kızıla dönüşünü izlemek için Türkiye'deki en iyi doğa rotası.",
    tags: <String>["doğa", "orman", "kamp"],
  ),
  PopularLocation(
    name: "İğneada Longoz Ormanları",
    latitude: 41.8760,
    longitude: 27.9880,
    description:
        "Avrupa'nın en büyük longoz ormanı. Kanoyla yeşilliklerin içinde kaybolmak.",
    tags: <String>["doğa", "orman", "macera"],
  ),
  PopularLocation(
    name: "Tortum Şelalesi",
    latitude: 40.5500,
    longitude: 41.6700,
    description:
        "Su sesinin gürültüsüyle arınmak. Gerçekten devasa bir doğa harikası.",
    tags: <String>["doğa", "şelale", "erzurum"],
  ),
  PopularLocation(
    name: "Karagöl (Artvin)",
    latitude: 41.3700,
    longitude: 41.8600,
    description:
        "Ormanın kalbinde saklı kalmış, suya yansıyan çam ağaçlarıyla huzur dolu bir yer.",
    tags: <String>["doğa", "göl", "huzur"],
  ),
];

