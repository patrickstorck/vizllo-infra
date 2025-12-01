# 📄 **Vizllo – System Architecture Documentation**

# Vizllo – System Architecture Documentation

## 1. Overview

**Vizllo** is a global digital marketplace where independent photographers can sell event photos and complete albums.  
The platform is built with a modular architecture and designed for long-term scalability, internationalization, and high availability.

The initial deployment will run on a **Raspberry Pi (Docker + Cloudflare Tunnel)** for development and early-stage testing.  
Production will be deployed on **cloud infrastructure (MongoDB Atlas + Cloudflare R2 + external hosting)**.

Technology stack:

- **Frontend:** React (Next.js) + Tailwind CSS  
- **Backend:** FastAPI + Python  
- **Database:** MongoDB Atlas  
- **Storage:** Cloudflare R2 (preview images) + AWS S3 (originals, future)  
- **Messaging:** Brevo SMTP (transactional emails)  
- **CI/CD:** GitHub + Docker  
- **Authentication:** JWT (6h expiry)  
- **Internationalization:** Babel (backend), i18n (frontend)  
- **Timezone standard:** UTC everywhere  

---

## 2. Repository Structure

Two independent GitHub repositories:

### `vizllo-frontend`
- Next.js front-end application
- Tailwind UI
- Image gallery, albums, photographer pages
- Cart management (multi-item and multi-album)
- Payment initiation using backend
- Toast messages translated using i18n
- Public assets, components, services, hooks
- Integration with the backend via REST API

### `vizllo-backend`
- FastAPI modular backend
- MongoDB Atlas driver (motor)
- Cloudflare R2 integration
- Auth, Users, Events, Albums, Photos, Carts, Orders, Payments
- Audit logs
- Background tasks (image processing, watermarking)
- Babel for multi-language responses
- Centralized error handling and standard response builder

Local development structure on the Raspberry Pi:

```

projects/
vizllo/
backend/        ← git clone vizllo-backend.git
frontend/       ← git clone vizllo-frontend.git
docker-compose.yml
scripts/
dev_up.sh
dev_down.sh

```

---

## 3. Global Architecture Diagram (High-Level)

```

```
             ┌─────────────────────────┐
             │        Frontend         │
             │  Next.js + Tailwind     │
             │  (Cloudflare Tunnel)    │
             └─────────────┬───────────┘
                           │ REST API
                           ▼
             ┌─────────────────────────┐
             │         Backend         │
             │ FastAPI + Python        │
             │  Modular Architecture   │
             └──────┬──────────┬───────┘
                    │          │
        Logs (Mongo)│          │ Photos / Uploads
                    ▼          ▼
            ┌──────────────────────┐
            │    MongoDB Atlas     │
            └──────────────────────┘
            ┌──────────────────────┐
            │    Cloudflare R2     │
            └──────────────────────┘
```

```

---

## 4. Backend Architecture

### 4.1 Framework
- **FastAPI** with Pydantic v2
- Modular package-by-feature structure

### 4.2 Modules

```

app/
├── api/
│    ├── auth/
│    ├── users/
│    ├── events/
│    ├── albums/
│    ├── photos/
│    ├── carts/
│    ├── orders/
│    ├── payments/
│    └── system/
├── services/
├── models/
├── schemas/
├── utils/
├── core/
├── middlewares/
└── constants/

````

### 4.3 Module Responsibilities

#### **Auth**
- JWT tokens (6h expiry)
- Refresh token logic (future)
- Login, register, password reset
- Multi-language error messages (Babel)
- Email verification flows

#### **Users**
- Photographer profile
- Customer profile
- Language preference
- Notification preferences
- Account settings

#### **Events**
- Events created by photographers
- Metadata (location, date, tags)
- Access rules (public/private)

#### **Albums**
- Group of photos belonging to an event
- Public or private visibility
- Price configurations

#### **Photos**
- Original stored in S3 (future)
- Preview stored in Cloudflare R2
- Watermark pipeline
- Resolution management
- Lazy serving via CDN

#### **Carts**
- Multi-item, multi-album support
- Guest cart (future)
- Cart segmentation by photographer
- Pricing calculation service

#### **Orders**
- Finalized carts
- Payment status
- Download permissions
- License rules (full rights vs personal use)

#### **Payments**
- Stripe + Mercado Pago (phase 2)
- Local currency detection
- Exchange rate handling (future)
- Webhooks with secure HMAC validation
- Idempotent operations

#### **SMTP (Brevo)**
- Transactional emails:
  - Purchase confirmation  
  - Password reset  
  - Email verification  
  - Photographer notifications  

#### **Logs**
- All major routes produce:
  - timestamp (UTC)
  - user_id
  - route
  - payload summary
  - error if applicable
  - IP address
  - request_id (traceability)

Logs stored in MongoDB collection: `system_logs`.

---

## 5. Backend Global Rules

### 5.1 Internationalization (i18n)
- **Babel** used in backend for route messages
- All responses standardized using translation keys
- Frontend displays these using toast notifications

### 5.2 Timezone
- All stored timestamps → **UTC**
- Conversion handled only at frontend display layer

### 5.3 Security
- JWT access token: **6 hours**
- Sensitive actions require re-auth
- Passwords hashed with Argon2 or bcrypt

### 5.4 Standard API Response Shape

```json
{
  "success": true,
  "message": "photo.upload.success",
  "data": { ... }
}
````

Errors:

```json
{
  "success": false,
  "error_code": "ALBUM_NOT_FOUND",
  "message": "album.not.found"
}
```

### 5.5 Standard Logging Format

```json
{
  "timestamp": "2025-01-05T14:32:11Z",
  "level": "INFO",
  "route": "/albums/create",
  "user_id": "67fabddf",
  "request_id": "uuid4",
  "ip": "203.0.113.52",
  "payload_summary": { "event_id": "123" }
}
```

---

## 6. Frontend Architecture

### 6.1 Tech Stack

* **Next.js (React)**
* **Tailwind CSS**
* **TypeScript**
* **i18n** for translations
* **React Query** for API caching
* **Framer Motion** for animations
* **Cloudflare images CDN optimized rendering**

### 6.2 Key Pages

```
/               → homepage
/explore        → category browsing
/photo/:id      → photo detail + purchase options
/album/:id      → album detail
/event/:id      → event listing
/cart           → cart view
/login
/register
/profile
/photographer/:id
```

### 6.3 Cart Behavior

* Persistent cart stored in localStorage + backend sync
* Supports:

  * multiple photos
  * full albums
  * mixed items
* Recalculation done server-side for accuracy

---

## 7. Database Structure (Conceptual)

### Collections

```
users
photographers
events
albums
photos
carts
orders
payments
system_logs
```

Photos link to:

```
event_id
album_id
photographer_id
formats
pricing
```

Orders include:

```
items[]
user_id
total
currency
payment_status
download_links
```

---

## 8. Media Storage Architecture

### Cloudflare R2

* Lightweight preview images (optimized)
* Watermarked images
* Public CDN URLs

### AWS S3 (future)

* Original photographer uploads
* Provision for RAW files

### Processing Pipeline

* Upload → Resize → Watermark → R2
* Original stored separately (non-public)

---

## 9. Folder Structure (Backend)

```
vizllo-backend/
  app/
    api/
    models/
    schemas/
    services/
    utils/
    core/
    constants/
    middlewares/
  tests/
  Dockerfile
  requirements.txt
  README.md
```

---

## 10. Deployment Architecture

### Development (Raspberry Pi)

* Docker Compose runs:

  * `vizllo-backend`
  * `vizllo-frontend`
* Cloudflare Tunnel exposes local services securely
* Local images stored in R2

### Production

* Backend on cloud server/container service
* Frontend on Cloudflare Pages / Vercel / EC2
* MongoDB Atlas cluster
* R2 + S3 storage
* Managed SMTP via Brevo

---

## 11. Future Roadmap

* Photographer dashboard (analytics)
* AI-assisted tagging and image classification
* Multi-currency support
* Multiple payment gateways
* Album auto-generation using EXIF timestamps
* Progressive Web App mode (PWA)
* Photographer subscription plans
* Refund pipeline
* Referral program

---

## 12. Coding Guidelines (Global)

* Codebase fully in **English**
* Always use **UTC** for timestamps
* Everything must be modular
* Typed everywhere (Python typing + TypeScript)
* Consistent naming:

  * `snake_case` for Python
  * `camelCase` for frontend
* Standardized logs and errors
* Avoid business logic inside routes → always in `services/`
* Use feature-based folder grouping

---

## 13. Status of this Document

This architecture blueprint is the **official baseline for Vizllo**.
All future development must follow the standards defined here.