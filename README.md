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
   ```

2. Dizine gidin:
   ```bash
   cd TS2HLS-Manager
   ```

3. Scripti çalıştırmadan önce gerekli bağımlılıkları kurun:
   ```bash
   sudo apt-get update
   sudo apt-get install -y ffmpeg nginx apache2-utils
   ```

4. Scripti çalıştırın:
   ```bash
   bash ts2hls_live_management.sh
   ```

---

## 🛠️ Kullanım

### 1. Base URL Yönetimi
- Yeni bir Base URL ekleyin.
- Mevcut URL'leri listeleyin.
- Gereksiz URL'leri silin.

### 2. Kullanıcı Yönetimi
- Kullanıcı ekleyerek onlara özel HLS akışları oluşturabilirsiniz.
- Kullanıcıların tüm yayınlarını ve dizinlerini kaldırabilirsiniz.

### 3. Yayın URL'lerini Görüntüleme
- Script, her kullanıcı için otomatik olarak yayın URL'lerini oluşturur:
  ```
  http://<server_ip>:8080/hls/<username>/<base_id>.m3u8
  ```

---

## 📝 Örnek Kullanım

### Base URL Ekleme
```bash
# Base URL ekleme işlemi sırasında:
Takma Ad: MyStream
URL: http://1.2.3.4:1234/live.ts
```

### Kullanıcı Ekleme
```bash
# Kullanıcı ekleme işlemi sırasında:
Kullanıcı adı: testuser
Base URL ID'leri: 1,2
```

Sonuç URL'ler:
- `http://<server_ip>:8080/hls/testuser/1.m3u8`
- `http://<server_ip>:8080/hls/testuser/2.m3u8`

---

## 🌐 Nginx Yapılandırması

Script, aşağıdaki yapılandırmayı `/etc/nginx/sites-available/hls` dizinine otomatik olarak ekler:
```nginx
server {
    listen 8080;

    location /hls/ {
        types {
            application/vnd.apple.mpegurl m3u8;
            video/mp2t ts;
        }
        root /var/www/html;
    }
}
```

---

## 🛡️ Lisans

Bu proje [MIT Lisansı](LICENSE) ile lisanslanmıştır.

---

## 🤝 Katkı

Katkıda bulunmak istiyorsanız:
1. Bu repository'yi fork edin.
2. Yeni bir özellik ekleyin veya hata düzeltin.
3. Pull Request gönderin.

---

## 📧 İletişim

Eğer herhangi bir sorunuz veya geri bildiriminiz varsa, GitHub üzerinden bir **Issue** oluşturabilirsiniz.
