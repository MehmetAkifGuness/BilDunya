# BilDunya Backend

Konum tabanlı içerik paylaşım platformu için Spring Boot backend uygulaması.

## Teknik Yapı

- **Spring Boot 3.3.0**
- **Java 21**
- **PostgreSQL 16**
- **Docker & Docker Compose**
- **JWT Authentication**
- **Spring Security**
- **OpenAPI/Swagger**
- **JPA/Hibernate**

## Proje Yapısı

```
BilDunya/
├── src/
│   ├── main/
│   │   ├── java/com/bildunya/
│   │   │   ├── BilDunyaApplication.java
│   │   │   ├── config/                 # Spring konfigürasyonları
│   │   │   ├── controller/             # REST API endpoints
│   │   │   ├── service/                # İş mantığı
│   │   │   ├── repository/             # Veritabanı erişimi
│   │   │   ├── entity/                 # JPA entities
│   │   │   ├── dto/                    # Data Transfer Objects
│   │   │   ├── exception/              # Custom exceptions & handlers
│   │   │   └── security/               # JWT & Security
│   │   └── resources/
│   │       └── application.yml         # Konfigürasyon dosyası
│   └── test/
├── docker-compose.yml
├── Dockerfile
├── pom.xml
└── README.md
```

## Veritabanı Şeması

### Users
- `id` (PK)
- `username` (UNIQUE)
- `email` (UNIQUE)
- `password_hash`
- `full_name`
- `profile_photo_url`
- `bio`
- `is_anonymous`
- `is_active`
- `email_verified`
- `verification_token`
- `phone_number`
- `location_preferences` (JSONB)
- `created_at`, `updated_at`, `is_deleted`

### Contents
- `id` (PK)
- `user_id` (FK)
- `description`
- `content_type` (IMAGE, VIDEO, TEXT)
- `file_url`
- `latitude`, `longitude` (Lokasyon verileri)
- `location_name`
- `exif_data` (JSONB)
- `is_verified`
- `verification_status` (PENDING, VERIFIED, REJECTED)
- `rejection_reason`
- `view_count`
- `share_type` (PUBLIC, PRIVATE, ANONYMOUS)
- `tags`
- `created_at`, `updated_at`, `is_deleted`

### Comments
- `id` (PK)
- `content_id` (FK)
- `user_id` (FK)
- `parent_comment_id` (FK - nested comments için)
- `text`
- `is_anonymous`
- `like_count`
- `created_at`, `updated_at`, `is_deleted`

## Kurulum ve Çalıştırma

### Ön Koşullar
- Docker & Docker Compose
- Java 21 (lokal geliştirme için)
- Maven

### Docker ile Çalıştırma

```bash
cd BilDunya
docker-compose up -d
```

Veritabanı ve backend otomatik olarak başlayacaktır.

- Backend: `http://localhost:8080/api`
- API Dokümantasyonu: `http://localhost:8080/api/swagger-ui.html`
- PostgreSQL: `localhost:5432`

### Lokal Geliştirme (Standart)

```bash
# Veritabanını Docker'da başlat
docker-compose up postgresql -d

# Backend'i lokal olarak çalıştır
mvn spring-boot:run
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Yeni kullanıcı kaydı
- `POST /api/auth/login` - Giriş
- `GET /api/auth/user/{username}` - Kullanıcı bilgisi
- `GET /api/auth/health` - Sağlık kontrolü

### Content (İçerik)
- `POST /api/contents` - Yeni içerik oluştur
- `GET /api/contents/{id}` - İçerik detayı
- `GET /api/contents/nearby` - Yakın içerikleri listele (konum bazlı)
- `GET /api/contents/verified` - Doğrulanmış içerikleri listele
- `GET /api/contents/user/{userId}` - Kullanıcının içerikleri
- `DELETE /api/contents/{id}` - İçerik sil

## Konfigürasyon

`src/main/resources/application.yml` dosyasında ayarlar yapılabilir:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/bildunya_db
    username: bildunya_user
    password: bildunya_password

jwt:
  secret: "your-secret-key-min-32-chars"
  expiration: 86400000 # 24 saat

file:
  upload:
    directory: "uploads"
    max-size: 104857600 # 100MB
```

## İş Bölümü (Backend - Akif)

1. **Veritabanı Tasarımı & Mimarı** ✓
   - ER Diyagramı & Tablo Tasarımı
   - PostgreSQL Setup

2. **Kullanıcı Kayıt & Profil Sistemi** ✓
   - Kayıt API
   - Giriş & JWT Token
   - Profil yönetimi

3. **İçerik Yükleme Altyapısı** (Devam Edilecek)
   - Dosya Upload Service
   - EXIF Data Parsing
   - Storage Management (S3/Local)

4. **Sohbet & Yorum Sistemleri** (Devam Edilecek)
   - Comment CRUD Operations
   - Real-time Chat (WebSocket)

5. **Performans & Optimizasyonu** (Devam Edilecek)
   - Database Indexing
   - Caching Strategy
   - API Response Optimization

## Sonraki Adımlar

- [ ] File upload service (dosya saklama - S3 veya lokal)
- [ ] Comment & Chat API'leri
- [ ] Content verification workflow
- [ ] Location search optimization
- [ ] Caching (Redis)
- [ ] Logging & Monitoring
- [ ] Unit & Integration Tests
- [ ] CI/CD Pipeline

## Geliştirici Notları

### JWT Token Kullanımı
Tüm korumalı endpoint'ler için:
```
Authorization: Bearer {token}
```

### Hata Yanıtları
```json
{
  "status": 404,
  "message": "User not found",
  "error": "Resource Not Found",
  "timestamp": "2024-04-29T12:34:56",
  "path": "/api/auth/user/nonexistent"
}
```

### Pagination
Pek çok endpoint pagination destekler:
```
?page=0&size=20&sortBy=createdAt
```

## Kaynaklar

- [Spring Boot Docs](https://spring.io/projects/spring-boot)
- [Spring Security with JWT](https://spring.io/guides/gs/securing-web/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [OpenAPI/Swagger](https://swagger.io/specification/)

---

**Durum:** Aktif Geliştirme 🚀  
**Son Güncelleme:** 29 Nisan 2024  
**Backend Sorumlusu:** Mehmet Akif
