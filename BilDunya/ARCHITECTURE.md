## ER Diyagramı (Varlık-İlişki)

```
┌─────────────────┐
│     USERS       │
├─────────────────┤
│ id (PK)         │
│ username (UQ)   │
│ email (UQ)      │
│ password_hash   │
│ full_name       │
│ profile_photo   │
│ bio             │
│ is_anonymous    │
│ is_active       │
│ phone_number    │
│ created_at      │
│ updated_at      │
└────────┬────────┘
         │ 1
         │
         │ N
    ┌────▼────────────────┐
    │    CONTENTS         │
    ├─────────────────────┤
    │ id (PK)             │
    │ user_id (FK)        │
    │ description         │
    │ content_type        │
    │ file_url            │
    │ latitude (INDEX)    │
    │ longitude (INDEX)   │
    │ location_name       │
    │ exif_data (JSONB)   │
    │ is_verified         │
    │ verification_status │
    │ view_count          │
    │ share_type          │
    │ tags                │
    │ created_at (INDEX)  │
    │ updated_at          │
    └────┬───────────────┬┘
         │ 1             │ 1
         │               │
         │ N             │ N
    ┌────▼──────────┐    │
    │   COMMENTS    │    │
    ├───────────────┤    │
    │ id (PK)       │    │
    │ content_id(FK)├────┘
    │ user_id (FK)  │
    │ parent_id(FK) │ (Self-join)
    │ text          │
    │ is_anonymous  │
    │ like_count    │
    │ created_at    │
    │ updated_at    │
    └───────────────┘
         │
         └─→ (M:M relationship for replies)

Legend:
PK = Primary Key
FK = Foreign Key
UQ = Unique
INDEX = Indexed column
JSONB = PostgreSQL JSON type
```

## Sistemin İş Akışı

```
1. USER REGISTRATION & AUTH
   ┌──────────────┐
   │  Kullanıcı   │
   │  Kayıt Yap   │
   └──────┬───────┘
          │
          ▼
   ┌──────────────────┐
   │  Validasyon      │ (Email, Username unique)
   │  Password Hash   │ (BCrypt)
   └──────┬───────────┘
          │
          ▼
   ┌──────────────────┐
   │  DB'ye Kaydet    │
   │  JWT Token Ver   │
   └──────┬───────────┘
          │
          ▼
   ┌──────────────────┐
   │  Login Yap       │
   │  (Token Kullan)  │
   └──────────────────┘

2. CONTENT CREATION & VERIFICATION
   ┌──────────────────┐
   │  İçerik Yükle    │
   │  (Foto/Video)    │
   └──────┬───────────┘
          │
          ▼
   ┌──────────────────┐
   │  Konum Bilgisi   │
   │  EXIF Parse      │
   │  Doğrulama       │
   └──────┬───────────┘
          │
          ▼
   ┌──────────────────┐
   │  İçerik Duruşu:  │ PENDING
   │  Nisa'nın Onayı  │ (Kontrol)
   │  İçin Bekle      │
   └──────┬───────────┘
          │
    ┌─────┴──────┐
    │             │
    ▼             ▼
 VERIFIED    REJECTED
 (Herkese    (Nedenle)
  Görün)

3. LOCATION-BASED CONTENT DISCOVERY
   ┌──────────────────┐
   │  Harita Aç       │
   │  Konumumu Gönder │
   └──────┬───────────┘
          │
          ▼
   ┌──────────────────┐
   │  Yakındaki İçerik│
   │  5km içinde Ara  │
   │  (Geo Query)     │
   └──────┬───────────┘
          │
          ▼
   ┌──────────────────┐
   │  Sonuçları       │
   │  Göster          │
   └──────────────────┘

4. INTERACTION (COMMENTS & LIKES)
   ┌──────────────────┐
   │  İçeriği Aç      │
   │  View Count +1   │
   └──────┬───────────┘
          │
          ▼
   ┌──────────────────┐
   │  Yorum Yap       │
   │  (Isimli/Anonim) │
   └──────┬───────────┘
          │
          ▼
   ┌──────────────────┐
   │  Cevap Yap       │
   │  (Parent Comment)│
   └──────┬───────────┘
          │
          ▼
   ┌──────────────────┐
   │  Beğen (Like)    │
   │  Like Count +1   │
   └──────────────────┘
```

## API Response Examples

### Login Başarılı
```json
{
  "access_token": "eyJhbGciOiJIUzUxMiJ9...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "user": {
    "id": 1,
    "username": "akif",
    "email": "akif@bildunya.com",
    "full_name": "Mehmet Akif",
    "is_anonymous": false,
    "is_active": true,
    "created_at": "2024-04-29T12:34:56"
  }
}
```

### Content Retrieve
```json
{
  "id": 1,
  "description": "Taksim meydanında muhteşem gün batımı",
  "content_type": "IMAGE",
  "file_url": "https://s3.amazonaws.com/uploads/content_1.jpg",
  "latitude": 41.0382,
  "longitude": 28.9753,
  "location_name": "Taksim Meydanı, İstanbul",
  "is_verified": true,
  "verification_status": "VERIFIED",
  "view_count": 1205,
  "share_type": "PUBLIC",
  "tags": "sunset,istanbul,travel",
  "user": {
    "id": 1,
    "username": "akif",
    "full_name": "Mehmet Akif",
    "profile_photo_url": "https://...",
    "is_anonymous": false
  },
  "created_at": "2024-04-29T10:00:00"
}
```

## Performance Optimization Strategy

### Indexes
- `latitude, longitude` - Location-based queries
- `created_at` - Sorting & pagination
- `user_id, content_id` - Foreign key queries

### Caching (Future)
- User profiles (Redis)
- Content listings (Redis)
- Location-based queries (Memcached)

### Database
- Connection pooling (HikariCP)
- Query optimization
- Pagination (always)

### API
- Response compression (Gzip)
- Lazy loading
- DTO projections
