# BilDunya Backend - Quick Start Guide

## 🚀 30 Saniyede Başlayın

### Seçenek 1: Docker (En Kolay)

```bash
cd BilDunya
docker-compose up -d
```

✓ PostgreSQL başlayacak  
✓ Backend otomatik derlenecek  
✓ http://localhost:8080/api adresinde hazır olacak

### Seçenek 2: Lokal (Geliştirme İçin)

**Ön koşullar:** Java 21+ gerekli

```bash
# 1. PostgreSQL'i Docker'da başlat
docker-compose up postgresql -d

# 2. Backend'i çalıştır
./mvnw spring-boot:run
```

---

## 📚 API Test Etme

### Swagger UI (Tarayıcı)
```
http://localhost:8080/api/swagger-ui.html
```

### cURL ile Test

**1. Kayıt Ol:**
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "akif",
    "email": "akif@bildunya.com",
    "password": "password123",
    "fullName": "Mehmet Akif",
    "isAnonymous": false
  }'
```

**2. Giriş Yap:**
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "akif",
    "password": "password123"
  }'
```

Cevaptan `access_token` kopyalayın.

**3. İçerik Oluştur (Token ile):**
```bash
curl -X POST http://localhost:8080/api/contents \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Güzel bir gün batımı",
    "contentType": "IMAGE",
    "latitude": 41.0382,
    "longitude": 28.9753,
    "locationName": "Taksim Meydanı",
    "shareType": "PUBLIC",
    "tags": "sunset,istanbul"
  }'
```

**4. Yakın İçerikleri Listele:**
```bash
curl "http://localhost:8080/api/contents/nearby?latitude=41.0382&longitude=28.9753&radiusKm=5"
```

---

## 🛠️ Yapılandırma

### Environment Değişkenleri

`src/main/resources/application.yml` içinde değiştirebilirsiniz:

```yaml
# Veritabanı
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/bildunya_db
    username: bildunya_user
    password: bildunya_password

# JWT Token
jwt:
  secret: "en-az-32-karakter-uzunluğu-olan-secret"
  expiration: 86400000  # 24 saat (ms cinsinden)

# Dosya Yükleme
file:
  upload:
    directory: "uploads"
    max-size: 104857600  # 100MB
```

---

## 📁 Proje Yapısı

```
BilDunya/
├── src/main/java/com/bildunya/
│   ├── controller/          → REST endpoints
│   ├── service/             → İş mantığı
│   ├── repository/          → Veritabanı sorguları
│   ├── entity/              → Database modelleri
│   ├── dto/                 → API request/response modelleri
│   ├── security/            → JWT & Authentication
│   ├── config/              → Spring konfigürasyonu
│   └── exception/           → Error handling
│
├── pom.xml                  → Maven dependencies
├── Dockerfile               → Container image
├── docker-compose.yml       → Services orchestration
├── mvnw / mvnw.cmd         → Maven wrapper (Maven kurulmasına gerek yok)
└── README.md               → Detaylı dokümantasyon
```

---

## 🧪 Development Tips

### IDE Setup (IntelliJ IDEA / VS Code)

**IntelliJ IDEA:**
1. File → Open → BilDunya klasörünü seç
2. Trust Project dialog'unda "Trust Project" tıkla
3. Proje otomatik sync olacak

**VS Code:**
1. Extension: "Extension Pack for Java" kur
2. Klasörü aç
3. Maven projects auto-discover olacak

### Debug Mode

```bash
# Spring Boot debug mode'de çalıştır
./mvnw spring-boot:run -Dspring-boot.run.arguments="--debug"
```

### Database Console

PostgreSQL'e bağlan:
```bash
docker exec -it bildunya_postgres psql -U bildunya_user -d bildunya_db
```

Tablolara bak:
```sql
\dt                    -- Tüm tabloları listele
\d users               -- users tablo şemasını göster
SELECT * FROM users;   -- Kullanıcıları listele
```

---

## 🚨 Sorun Giderme

### Port 8080 Kullanımda
```bash
# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Mac/Linux
lsof -i :8080
kill -9 <PID>
```

### Docker Hatası
```bash
# Tüm container'ları durdur ve sil
docker-compose down -v

# Yeniden başlat
docker-compose up -d
```

### Maven Hataları
```bash
# Cache temizle
./mvnw clean

# Dependency tekrar yükle
./mvnw install
```

---

## 📊 Database Oluşturma (İlk Başlatma)

Docker'da otomatik oluşturulur, ancak manuel kurulum gerekirse:

```sql
-- 1. Database oluştur
CREATE DATABASE bildunya_db;

-- 2. Kullanıcı oluştur
CREATE USER bildunya_user WITH PASSWORD 'bildunya_password';

-- 3. Yetkileri ver
GRANT ALL PRIVILEGES ON DATABASE bildunya_db TO bildunya_user;
```

---

## ✅ Kontrol Listesi - İlk Setup

- [ ] Docker kurulu mu? (`docker --version`)
- [ ] Java 21+ kurulu mu? (`java -version`)
- [ ] Portu 8080 açık mı?
- [ ] PostgreSQL çalışıyor mu?
- [ ] Backend başladı mı?
- [ ] Swagger UI açılıyor mu?

---

## 🔗 Faydalı Linkler

- **Local API:** http://localhost:8080/api
- **Swagger UI:** http://localhost:8080/api/swagger-ui.html
- **API Docs:** http://localhost:8080/api/v3/api-docs
- **PostgreSQL:** localhost:5432

---

## 📝 Sonraki Adımlar

1. ✅ Basic Backend Infrastructure
2. ➡️ File Upload Service (S3 / Local Storage)
3. ➡️ Comment & Chat APIs
4. ➡️ Content Verification System
5. ➡️ WebSocket Real-time Chat
6. ➡️ Performance Optimization
7. ➡️ Unit & Integration Tests

---

**Sorular mı var? Backend modülünün Akif'i ile iletişime geç!** 🎉
