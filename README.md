
# [Türkçe](#türkçe) / [English](#english)

## Türkçe

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

- **Linux** veya **macOS*** (Windows için Bash simülasyon araçları gereklidir. WSL ile çalışabilir)
- AlmaLinux >= 8  
- Arch Linux  
- CentOS Stream >= 8  
- Debian >= 10  
- Fedora >= 30  
- Oracle Linux >= 8  
- Rocky Linux >= 8  
- Ubuntu >= 20.04  
- Pardus >= 19  
- Linux Mint >= 20  

  *Not: macOS'ta scriptin çalışması için Homebrew ile `ffmpeg`, `nginx`, ve `apache2` kurulmalı, dizinler `/usr/local/var/www` olarak değiştirilip IP alma komutu `ipconfig getifaddr en0` ile güncellenmelidir.
---

## 🔧 Kurulum

Komut dosyasını indirin ve çalıştırın. Tüm gerekli olan paketleri otomatik kuracaktır.
```bash
curl -O https://raw.githubusercontent.com/livvaa/TS2HLS-Manager/main/ts2hls_live_management.sh
chmod +x ts2hls_live_management.sh
./ts2hls_live_management.sh
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

---

## English

# TS2HLS-Manager

TS2HLS-Manager is a **Bash Script** tool developed for managing HLS (HTTP Live Streaming). This tool provides user and Base URL management and automatically creates and manages HLS streams using **FFmpeg**.

---

## 🚀 Features

- **Base URL Management**
  - Add, list, and delete Base URLs.
  - Easy resource management with IDs and aliases.

- **User Management**
  - Create and delete users.
  - Customized streaming URLs for each user.

- **Live Stream Processing**
  - Create streams in HLS format using FFmpeg.
  - Supports segment durations and automatic deletion.

- **Nginx Configuration**
  - Automatically configures Nginx to serve the HLS directory.

---

## 📦 Requirements

- **Linux** or **macOS*** (Windows requires Bash simulation tools. It can work with WSL.)  
- AlmaLinux >= 8  
- Arch Linux  
- CentOS Stream >= 8  
- Debian >= 10  
- Fedora >= 30  
- Oracle Linux >= 8  
- Rocky Linux >= 8  
- Ubuntu >= 20.04  
- Pardus >= 19  
- Linux Mint >= 20  

  *Note: For macOS, the script requires `ffmpeg`, `nginx`, and `apache2` to be installed via Homebrew, directories to be adjusted to `/usr/local/var/www`, and the IP retrieval command to be updated to `ipconfig getifaddr en0`.

---

## 🔧 Installation

Download and run the script. It will automatically install all the necessary packages.
```bash
curl -O https://raw.githubusercontent.com/livvaa/TS2HLS-Manager/main/ts2hls_live_management.sh
chmod +x ts2hls_live_management.sh
./ts2hls_live_management.sh
```

---

## 🛠️ Usage

### 1. Base URL Management
- Add new Base URLs.
- List existing URLs.
- Remove unnecessary URLs.

### 2. User Management
- Add users to create dedicated HLS streams for them.
- Remove all streams and directories for users.

### 3. Viewing Streaming URLs
- The script automatically generates streaming URLs for each user:
  ```
  http://<server_ip>:8080/hls/<username>/<base_id>.m3u8
  ```

---

## 📝 Example Usage

### Adding a Base URL
```bash
# During Base URL addition:
Alias: MyStream
URL: http://1.2.3.4:1234/live.ts
```

### Adding a User
```bash
# During user addition:
Username: testuser
Base URL IDs: 1,2
```

Resulting URLs:
- `http://<server_ip>:8080/hls/testuser/1.m3u8`
- `http://<server_ip>:8080/hls/testuser/2.m3u8`

---

## 🌐 Nginx Configuration

The script automatically adds the following configuration to `/etc/nginx/sites-available/hls`:
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

## 🛡️ License

This project is licensed under the [MIT License](LICENSE).

---

## 🤝 Contribution

If you want to contribute:
1. Fork this repository.
2. Add a new feature or fix a bug.
3. Submit a Pull Request.

---

## 📧 Contact

If you have any questions or feedback, you can create an **Issue** on GitHub.
