# TS2HLS-Manager

TS2HLS-Manager, HLS (HTTP Live Streaming) yönetimi için geliştirilmiş bir **Bash Script** aracıdır. Bu araç, kullanıcı ve Base URL yönetimi sağlar, ayrıca **FFmpeg** kullanarak HLS akışları oluşturur ve otomatik olarak yönetir.

---

## 🚀 Özellikler

- **Base URL Yönetimi**
  - Base URL ekleme, listeleme ve silme.
  - ID ve takma adlarla kolay kaynak yönetimi.

- **Kullanıcı Yönetimi**
  - Kullanıcı oluşturma ve kaldırma.
  - Her kullanıcı için özelleştirilmiş yayın URL'leri.

- **Canlı Akış İşleme**
  - FFmpeg ile HLS formatında akış oluşturma.
  - Segment sürelerini ve otomatik silme özelliklerini destekler.

- **Nginx Yapılandırması**
  - HLS dizinini sunmak için Nginx yapılandırmasını otomatik olarak ayarlar.

---

## 📦 Gereksinimler

- **Linux** veya **macOS** (Windows için Bash simülasyon araçları gerekebilir)
- **FFmpeg** (Video işleme için)
- **Nginx** (HLS yayını için)
- **Git** (Opsiyonel, kaynak kontrol için)

---

## 🔧 Kurulum

1. Repository'yi klonlayın:
   ```bash
   git clone https://github.com/livvaa/TS2HLS-Manager.git
