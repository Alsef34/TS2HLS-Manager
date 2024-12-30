#!/bin/bash

#-----------------------------------------------------
# Temel Değişkenler
#-----------------------------------------------------
VERSION="1.0.0"                               # Sürüm numarası
USER_MEDIA="/var/www/html/hls"                # Kullanıcı medya dizini
OUTPUT_BASE="/var/www/html"                   # HLS çıktı dizini
USER_FILE="users.txt"                         # Eklenen kullanıcıların listesi
BASE_URLS_FILE="base_urls.txt"                # Base URL'ler (ID|TakmaAd|URL)
USER_BASES_FILE="user_bases.txt"              # Kullanıcıya ait base ID listesi (username|1,2,3)
NGINX_CONFIG="/etc/nginx/sites-available/hls" # Nginx konfigürasyon dosyası
PID_DIR="/var/run"                            # ffmpeg PID dosyalarının saklanacağı dizin
SCRIPT_URL="https://raw.githubusercontent.com/livvaa/TS2HLS-Manager/main/ts2hls_live_management.sh"

DOMAIN=""
EMAIL=""                                      # Let's Encrypt için e-posta adresi

# Sunucu IP adresini al (ilk IPv4)
SERVER_IP=$(hostname -I | awk '{print $1}')

#-----------------------------------------------------
# İlk Kurulum: Gerekli Yazılımları Kur, Nginx ve SSL Yapılandır
#-----------------------------------------------------
initial_setup() {
    clear
    echo "Gerekli paketler kuruluyor..."

    sudo apt-get update
    sudo apt-get install -y ffmpeg nginx apache2-utils certbot python3-certbot-nginx

    # Kullanıcıdan domain ve e-posta adresi al
    echo "Alan adınızı (örnek: example.com) girin:"
    read -r DOMAIN
    echo "Let's Encrypt için e-posta adresinizi girin:"
    read -r EMAIL

    if [[ -z "$DOMAIN" || -z "$EMAIL" ]]; then
        echo "Alan adı ve e-posta adresi boş bırakılamaz!"
        exit 1
    fi

    echo "Nginx yapılandırılıyor..."
    # Nginx config (hls) oluştur
    echo "server {
    listen 80;
    server_name $DOMAIN;

    location /hls/ {
        types {
            application/vnd.apple.mpegurl m3u8;
            video/mp2t ts;
        }
        root $OUTPUT_BASE;

        # CORS Ayarları
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'Range';
        add_header 'Access-Control-Expose-Headers' 'Content-Length, Content-Range';

        # Preflight (OPTIONS) Requests
        if (\$request_method = OPTIONS) {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'Range';
            add_header 'Access-Control-Expose-Headers' 'Content-Length, Content-Range';
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            return 204;
        }
        # TS ve M3U8 İçin Ek Cache Ayarları
        add_header 'Cache-Control' 'no-cache' always;

    }
}" | sudo tee $NGINX_CONFIG >/dev/null

    sudo ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/hls
    sudo systemctl restart nginx

    # HLS çıktıları için dizini oluştur
    sudo mkdir -p "$OUTPUT_BASE"
    sudo chown -R www-data:www-data "$OUTPUT_BASE"
    sudo chmod -R 755 "$OUTPUT_BASE"

    # Gerekli dosyalar
    touch "$USER_FILE"
    touch "$BASE_URLS_FILE"
    touch "$USER_BASES_FILE"

    # Let's Encrypt ile SSL yapılandırması
    echo "Let's Encrypt ile SSL yapılandırılıyor..."
    sudo certbot --nginx -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive --redirect --staging

    # HTTP'den HTTPS'e yönlendirme ekle
    echo "server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://$host$request_uri;
}" | sudo tee /etc/nginx/sites-available/redirect >/dev/null

    sudo ln -sf /etc/nginx/sites-available/redirect /etc/nginx/sites-enabled/redirect
    sudo systemctl restart nginx

    clear
    echo "Kurulum tamamlandı."
    echo "Base URL ekleyebilir ve kullanıcı yönetimine geçebilirsiniz."
    echo "Devam etmek için bir tuşa basın..."
    read -n 1 -s

}

#-----------------------------------------------------
# Cronjob'u Kur
#-----------------------------------------------------
add_cronjob() {
    # Scriptin tam yolunu belirle
    SCRIPT_PATH=$(realpath $0)

    # Cronjob'un mevcut olup olmadığını kontrol et
    if crontab -l | grep -q "@reboot /bin/bash $SCRIPT_PATH restart_streams"; then
        echo "Cronjob zaten mevcut."
    else
        # Cronjob ekle
        (
            crontab -l
            echo "@reboot /bin/bash $SCRIPT_PATH restart_streams"
        ) | crontab -
        echo "Cronjob eklendi: @reboot /bin/bash $SCRIPT_PATH restart_streams"
    fi
}

# Cronjob'u çağır
add_cronjob

#-----------------------------------------------------
# Let's Encrypt SSL Sertifikası Yenileme için Cronjob Ekleme
#-----------------------------------------------------
setup_renewal_cron() {
    echo "Let's Encrypt SSL sertifikaları için cronjob ekleniyor..."

    # Cronjob komutunu tanımla
    CRON_CMD="0 3 */60 * * certbot renew --quiet && systemctl reload nginx"

    # Cronjob'un zaten ekli olup olmadığını kontrol et
    if crontab -l 2>/dev/null | grep -q "certbot renew"; then
        echo "Cronjob zaten mevcut."
    else
        # Cronjob'u ekle
        (
            crontab -l 2>/dev/null
            echo "$CRON_CMD"
        ) | crontab -
        echo "Cronjob başarıyla eklendi: $CRON_CMD"
    fi
}

#--------------------------------------------------------------
# DOMAIN Değişkenini Nginx server_name'den Güncelle (Tekrarlı Değer Sorunu Çözümü)
#--------------------------------------------------------------
update_domain_from_nginx() {
    # Nginx konfigürasyon dosyasından server_name'i al
    if [[ -f "$NGINX_CONFIG" ]]; then
        # server_name değerini çek ve fazladan karakterleri temizle
        DOMAIN=$(grep "server_name" "$NGINX_CONFIG" | awk '{print $2}' | sed 's/;//' | head -n 1 | tr -d '\n' | tr -d '\r')

        # Aynı değer iki kez eklenmiş mi kontrol et
        DOMAIN=$(echo "$DOMAIN" | sed 's/\(.*\)\1/\1/')

        if [[ -n "$DOMAIN" ]]; then
            # DOMAIN değişkenini scriptin kendisinde güncelle
            sed -i "s|^DOMAIN=.*|DOMAIN=\"$DOMAIN\"|" "$(realpath $0)"

            if [[ $? -eq 0 ]]; then
                echo "DOMAIN değişkeni başarıyla güncellendi: $DOMAIN"
            else
                echo "Hata: sed komutunda bir sorun oluştu!"
            fi
        else
            echo "Hata: Nginx config dosyasından server_name alınamadı."
        fi
    else
        echo "Hata: Nginx config dosyası ($NGINX_CONFIG) bulunamadı!"
    fi
}

#-----------------------------------------------------
# Base URL Ekle / Listele / Sil
#   base_urls.txt -> ID|TakmaAd|URL
#-----------------------------------------------------
add_base_url() {
    clear
    echo "Yeni Base URL ekleme"
    echo "===================="
    read -p "Base URL'nin Takma Adı (ör: CanliKaynak1): " NICK
    read -p "Base URL (örn: http://1.2.3.4:1234/live.ts): " URL

    if [[ -z "$NICK" || -z "$URL" ]]; then
        echo "Takma ad veya Base URL boş bırakılamaz!"
        read -n 1 -s
        return
    fi

    # Otomatik ID verme
    if [[ -s "$BASE_URLS_FILE" ]]; then
        LAST_ID=$(tail -n 1 "$BASE_URLS_FILE" | awk -F'|' '{print $1}')
        NEW_ID=$((LAST_ID + 1))
    else
        NEW_ID=1
    fi

    echo "${NEW_ID}|${NICK}|${URL}" >>"$BASE_URLS_FILE"
    echo "Base URL eklendi -> ID: $NEW_ID, Takma Ad: $NICK, URL: $URL"

    echo "Devam etmek için bir tuşa basın..."
    read -n 1 -s
}

list_base_urls() {
    clear
    echo "=========================================="
    echo "Mevcut Base URL Listesi (ID|TakmaAd|URL)"
    echo "=========================================="
    if [[ -s "$BASE_URLS_FILE" ]]; then
        cat "$BASE_URLS_FILE"
    else
        echo "Henüz bir Base URL eklemediniz."
    fi
    echo "------------------------------------------"
    echo "Devam etmek için bir tuşa basın..."
    read -n 1 -s
}

remove_base_url() {
    clear
    echo "Base URL silme"
    echo "================"

    if [[ ! -s "$BASE_URLS_FILE" ]]; then
        echo "Base URL kaydı bulunamadı!"
        read -n 1 -s
        return
    fi

    echo "Mevcut Base URL'ler:"
    cat "$BASE_URLS_FILE"
    echo "---------------------"
    read -p "Silmek istediğiniz ID: " DEL_ID

    if ! grep -q "^${DEL_ID}|" "$BASE_URLS_FILE"; then
        echo "Geçersiz ID!"
    else
        sed -i "/^${DEL_ID}|/d" "$BASE_URLS_FILE"
        echo "Silindi: ID=$DEL_ID"
        # Bu ID'yi kullanan kullanıcıların user_bases.txt kaydından çıkarmak:
        sed -i "s/|${DEL_ID},/|/g; s/,${DEL_ID},/,/g; s/,${DEL_ID}$//g" "$USER_BASES_FILE"
    fi

    echo "Devam etmek için bir tuşa basın..."
    read -n 1 -s
}

#-----------------------------------------------------
# Kullanıcı Ekle (Birden Fazla Base URL Seçilir)
#   HLS çıktısı: <USER_DIR>/<BASE_ID>.m3u8
#-----------------------------------------------------
add_user() {
    clear
    if [[ ! -s "$BASE_URLS_FILE" ]]; then
        echo "Henüz Base URL kaydı bulunmuyor! Önce Base URL eklemelisiniz."
        read -n 1 -s
        return
    fi

    echo "Kullanıcı ekleme"
    echo "================"
    read -p "Kullanıcı adı: " USERNAME
    if [[ -z "$USERNAME" ]]; then
        echo "Kullanıcı adı boş bırakılamaz!"
        read -n 1 -s
        return
    fi

    if grep -q "^$USERNAME$" "$USER_FILE"; then
        echo "Kullanıcı zaten mevcut: $USERNAME"
        read -n 1 -s
        return
    fi

    echo "Mevcut Base URL'ler (ID|TakmaAd|URL)"
    echo "-------------------------------------"
    cat "$BASE_URLS_FILE"
    echo "-------------------------------------"
    echo "Birden fazla ID seçebilirsiniz (örn: 1,2,4)"
    read -p "Seçim: " SELECTED_IDS

    if [[ -z "$SELECTED_IDS" ]]; then
        echo "En az bir ID girmelisiniz!"
        read -n 1 -s
        return
    fi

    # Kullanıcı dizini
    USER_DIR="$USER_MEDIA/$USERNAME"
    sudo mkdir -p "$USER_DIR"
    sudo chown -R www-data:www-data "$USER_DIR"
    sudo chmod -R 755 "$USER_DIR"

    # users.txt'ye ekle
    echo "$USERNAME" >>"$USER_FILE"

    # user_bases.txt'ye kullanıcı|id1,id2,id3 formatıyla ekleyelim
    NORMALIZED_IDS=$(echo "$SELECTED_IDS" | sed 's/[[:space:]]//g')
    echo "${USERNAME}|${NORMALIZED_IDS}" >>"$USER_BASES_FILE"

    echo "------------------------------------"
    echo "Seçilen Base URL ID'leri: $NORMALIZED_IDS"
    echo "FFmpeg işlemleri başlatılıyor..."
    echo

    # Kullanıcıya gösterilecek URL'leri tutacağımız dizi
    declare -a USER_URLS

    IFS=',' read -ra ID_ARRAY <<<"$NORMALIZED_IDS"
    for BASE_ID in "${ID_ARRAY[@]}"; do
        LINE=$(grep "^${BASE_ID}|" "$BASE_URLS_FILE")
        if [[ -z "$LINE" ]]; then
            echo "Uyarı: ID=$BASE_ID bulunamadı, atlanıyor..."
            continue
        fi

        B_ID=$(echo "$LINE" | awk -F'|' '{print $1}')
        B_NICK=$(echo "$LINE" | awk -F'|' '{print $2}')
        B_URL=$(echo "$LINE" | awk -F'|' '{print $3}')

        # ffmpeg
        nohup ffmpeg -re -i "$B_URL" -c:v libx264 -preset ultrafast -crf 23 -c:a aac -b:a 128k -f hls -hls_time 5 -hls_list_size 12 -hls_flags delete_segments+discont_start -max_delay 5000000 "$USER_DIR/$B_ID.m3u8" >"$USER_DIR/ffmpeg-$B_ID.log" 2>&1 &

        echo $! >"$PID_DIR/ffmpeg_${USERNAME}_${BASE_ID}.pid"
        echo "Başlatıldı: Kullanıcı=$USERNAME, Kaynak=$B_NICK, ID=$B_ID"

        # Bu kaynağın yayın URL'sini bir diziye ekleyelim
        USER_URLS+=("http://$SERVER_IP:8080/hls/$USERNAME/$B_ID.m3u8")
    done

    echo
    echo "=== Kullanıcı ve yayın(lar) başlatıldı: $USERNAME ==="
    echo " Menüde '6) Kullanıcıları Listele' kısmında yayın adreslerine ulaşabilirsiniz."

    echo
    echo "Devam etmek için bir tuşa basın..."
    read -n 1 -s
}

#-----------------------------------------------------
# Kullanıcı Kaldır (Tüm Base URL süreçlerini durdurur)
#-----------------------------------------------------
remove_user() {
    clear
    if [[ ! -s "$USER_FILE" ]]; then
        echo "Kayıtlı kullanıcı yok!"
        read -n 1 -s
        return
    fi

    echo "Mevcut kullanıcılar:"
    cat -n "$USER_FILE"
    echo "----------------------------------------"
    read -p "Kaldırmak istediğiniz kullanıcı adı: " USERNAME

    if ! grep -q "^$USERNAME$" "$USER_FILE"; then
        echo "Kullanıcı bulunamadı: $USERNAME"
        read -n 1 -s
        return
    fi

    # 1) user_file'dan sil
    sed -i "/^$USERNAME$/d" "$USER_FILE"

    # 2) user_bases.txt içinden bu kullanıcıya ait satırı çek, Base ID’leri öğren
    LINE=$(grep "^${USERNAME}|" "$USER_BASES_FILE")
    if [[ -n "$LINE" ]]; then
        BASE_IDS=$(echo "$LINE" | awk -F'|' '{print $2}')
        # satırı sil
        sed -i "/^${USERNAME}|/d" "$USER_BASES_FILE"

        # 3) Tüm bu base ID'ler için ffmpeg süreçlerini öldür
        IFS=',' read -ra ID_ARRAY <<<"$BASE_IDS"
        for BASE_ID in "${ID_ARRAY[@]}"; do
            PID_FILE="$PID_DIR/ffmpeg_${USERNAME}_${BASE_ID}.pid"
            if [[ -f "$PID_FILE" ]]; then
                kill "$(cat "$PID_FILE")" 2>/dev/null
                rm -f "$PID_FILE"
            fi
        done
    fi

    # 4) Kullanıcının dizinini sil
    USER_DIR="$OUTPUT_BASE/$USERNAME"
    sudo rm -rf "$USER_DIR"

    echo "Kullanıcı ve tüm yayınları kaldırıldı: $USERNAME"
    read -n 1 -s
}

#-----------------------------------------------------
# Kullanıcıları Listeleme
#   Her kullanıcı için, user_bases.txt dosyasından
#   hangi Base ID’lere sahip olduğu bulunur.
#   URL => http://<IP>:8080/hls/<USERNAME>/<ID>.m3u8
#-----------------------------------------------------
list_users() {
    clear
    echo "========================================"
    echo "Mevcut Kullanıcılar ve Yayın URL'leri"
    echo "========================================"
    if [[ -s "$USER_FILE" ]]; then
        while read -r USERNAME; do
            echo "Kullanıcı: $USERNAME"
            LINE=$(grep "^${USERNAME}|" "$USER_BASES_FILE")
            if [[ -n "$LINE" ]]; then
                BASE_IDS=$(echo "$LINE" | awk -F'|' '{print $2}')
                IFS=',' read -ra ID_ARRAY <<<"$BASE_IDS"
                for BASE_ID in "${ID_ARRAY[@]}"; do
                    echo "  - ID=$BASE_ID: https://$DOMAIN/hls/$USERNAME/$BASE_ID.m3u8"
                done
            else
                echo "  Henüz bu kullanıcıya ait Base URL eklenmemiş."
            fi
            echo "----------------------------------------"
        done <"$USER_FILE"
    else
        echo "Henüz kullanıcı yok."
    fi

    echo "Devam etmek için bir tuşa basın..."
    read -n 1 -s
}

#-----------------------------------------------------
# Yayınları Yeniden Başlat (restart_streams)
#-----------------------------------------------------
restart_streams() {
    echo "Mevcut kullanıcı ve yayınlar yeniden başlatılıyor..."

    # Kullanıcıları kontrol et
    if [[ -s "$USER_FILE" && -s "$USER_BASES_FILE" && -s "$BASE_URLS_FILE" ]]; then
        while read -r USERNAME; do
            echo "Kullanıcı: $USERNAME için yayınlar yeniden başlatılıyor..."

            # Kullanıcının Base URL'lerini al
            LINE=$(grep "^${USERNAME}|" "$USER_BASES_FILE")
            if [[ -n "$LINE" ]]; then
                BASE_IDS=$(echo "$LINE" | awk -F'|' '{print $2}')
                IFS=',' read -ra ID_ARRAY <<<"$BASE_IDS"
                for BASE_ID in "${ID_ARRAY[@]}"; do
                    LINE=$(grep "^${BASE_ID}|" "$BASE_URLS_FILE")
                    if [[ -z "$LINE" ]]; then
                        echo "Uyarı: ID=$BASE_ID bulunamadı, atlanıyor..."
                        continue
                    fi

                    B_URL=$(echo "$LINE" | awk -F'|' '{print $3}')
                    USER_DIR="$USER_MEDIA/$USERNAME"
                    sudo mkdir -p "$USER_DIR"
                    nohup ffmpeg -re -i "$B_URL" \
                        -c:v libx264 -preset ultrafast -crf 23 \
                        -c:a aac -b:a 128k \
                        -f hls \
                        -hls_time 5 \
                        -hls_list_size 12 \
                        -hls_flags delete_segments+discont_start \
                        -max_delay 5000000 \
                        "$USER_DIR/$BASE_ID.m3u8" >"$USER_DIR/ffmpeg-$BASE_ID.log" 2>&1 &

                    echo $! >"$PID_DIR/ffmpeg_${USERNAME}_${BASE_ID}.pid"
                    echo "Yayın başlatıldı: Kullanıcı=$USERNAME, ID=$BASE_ID"
                done
            fi
        done <"$USER_FILE"
    else
        echo "Yeniden başlatılacak kullanıcı bulunamadı."
    fi
}

#-----------------------------------------------------
# Cron Yeniden Başlatma Fonksiyonu
#-----------------------------------------------------
if [[ "$1" == "restart_streams" ]]; then
    restart_streams
fi

#-----------------------------------------------------
# Sistem Kaldırma Fonksiyonu
#-----------------------------------------------------
remove_system() {
    clear
    echo "Bu işlem, script tarafından kurulan her şeyi kaldırır ve geri alınamaz."
    read -p "Devam etmek istediğinize emin misiniz? (y/N): " CONFIRM

    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "İşlem iptal edildi."
        read -n 1 -s
        return
    fi

    echo "Kaldırma işlemi başlatılıyor..."

    # 1. Kullanıcı ve Base URL dosyalarını sil
    echo "Kullanıcı ve Base URL dosyaları siliniyor..."
    rm -f "$USER_FILE" "$BASE_URLS_FILE" "$USER_BASES_FILE"

    # 2. HLS çıktı dizinini temizle
    echo "HLS çıktı dizini temizleniyor..."
    sudo rm -rf "$OUTPUT_BASE"

    # 3. FFmpeg PID dosyalarını sil ve süreçleri öldür
    echo "FFmpeg süreçleri durduruluyor..."
    if [[ -d "$PID_DIR" ]]; then
        for PID_FILE in "$PID_DIR"/ffmpeg_*.pid; do
            if [[ -f "$PID_FILE" ]]; then
                kill "$(cat "$PID_FILE")" 2>/dev/null
                rm -f "$PID_FILE"
            fi
        done
    fi

    # 4. Log dosyalarını sil
    echo "Log dosyaları temizleniyor..."
    sudo rm -f "$USER_MEDIA"/*/ffmpeg-*.log

    # 5. Cron job'ları kaldır
    echo "Cron job'ları temizleniyor..."
    crontab -l 2>/dev/null | grep -v "certbot renew" | grep -v "@reboot /bin/bash $(realpath $0) restart_streams" | crontab -

    # 6. Nginx yapılandırmasını kaldır
    echo "Nginx yapılandırması temizleniyor..."
    sudo rm -f "$NGINX_CONFIG" /etc/nginx/sites-enabled/hls
    sudo systemctl stop nginx
    sudo apt-get purge -y nginx nginx-common
    sudo apt-get autoremove -y

    # 7. FFmpeg'i kaldır
    echo "FFmpeg kaldırılıyor..."
    sudo apt-get purge -y ffmpeg
    sudo apt-get autoremove -y

    # 8. Script dosyasını kaldır
    echo "Script dosyası temizleniyor..."
    sudo rm -f "$(realpath $0)"

    clear
    echo "Sistem tamamen kaldırıldı. Gerekirse Nginx ve FFmpeg yedeklerini yeniden yükleyebilirsiniz."
    read -n 1 -s
    clear
    exit 0
}

#-----------------------------------------------------
# Yedekten dosya ve dizinleri geri yükle
#-----------------------------------------------------
FILES=("$USER_FILE" "$BASE_URLS_FILE" "$USER_BASES_FILE")
DIRS=("$OUTPUT_BASE")

for FILE in "${FILES[@]}"; do
    if [[ ! -f "$FILE" && -f "${FILE}_backup" ]]; then
        mv "${FILE}_backup" "$FILE"
        echo "Yedekten geri yüklendi: ${FILE}_backup -> $FILE"
    elif [[ -f "$FILE" ]]; then
        echo "Dosya zaten mevcut: $FILE"
    else
        echo "Yedek dosya bulunamadı: ${FILE}_backup"
    fi
done

for DIR in "${DIRS[@]}"; do
    if [[ ! -d "$DIR" && -d "${DIR}_backup" ]]; then
        mv "${DIR}_backup" "$DIR"
        echo "Yedekten geri yüklendi: ${DIR}_backup -> $DIR"
    elif [[ -d "$DIR" ]]; then
        echo "Dizin zaten mevcut: $DIR"
    else
        echo "Yedek dizin bulunamadı: ${DIR}_backup"
    fi
done

#-----------------------------------------------------
# Ana Akış
#-----------------------------------------------------
if [[ ! -f "$USER_FILE" || ! -f "$BASE_URLS_FILE" || ! -f "$USER_BASES_FILE" || ! -d "$OUTPUT_BASE" ]]; then
    initial_setup
else
    add_cronjob
    setup_renewal_cron
fi

#-----------------------------------------------------
# Yazılım Güncelleme Fonksiyonu (9)
#-----------------------------------------------------
update_software() {
    clear
    echo "Yazılım güncelleme işlemi başlatılıyor..."

    # Gerekli dosyaların yedeklenmesi
    echo "Mevcut dosyalar yedekleniyor..."
    BACKUP_SUFFIX="_backup"

    for FILE in "$USER_FILE" "$BASE_URLS_FILE" "$USER_BASES_FILE"; do
        if [[ -f "$FILE" ]]; then
            cp "$FILE" "${FILE}${BACKUP_SUFFIX}"
            echo "Yedeklendi: ${FILE} -> ${FILE}${BACKUP_SUFFIX}"
        else
            echo "Yedeklenecek dosya bulunamadı: $FILE"
        fi
    done

    if [[ -d "$OUTPUT_BASE" ]]; then
        tar -czf "${OUTPUT_BASE}${BACKUP_SUFFIX}.tar.gz" "$OUTPUT_BASE"
        echo "HLS çıktı dizini yedeklendi: ${OUTPUT_BASE}${BACKUP_SUFFIX}.tar.gz"
    else
        echo "HLS çıktı dizini bulunamadı."
    fi

    # 2. HLS çıktı dizinini temizle
    echo "HLS çıktı dizini temizleniyor..."
    sudo rm -rf "$OUTPUT_BASE"

    # 3. FFmpeg PID dosyalarını sil ve süreçleri öldür
    echo "FFmpeg süreçleri durduruluyor..."
    if [[ -d "$PID_DIR" ]]; then
        for PID_FILE in "$PID_DIR"/ffmpeg_*.pid; do
            if [[ -f "$PID_FILE" ]]; then
                kill "$(cat "$PID_FILE")" 2>/dev/null
                rm -f "$PID_FILE"
            fi
        done
    fi

    # 5. Cron job'ları kaldır
    echo "Cron job'ları temizleniyor..."
    crontab -l 2>/dev/null | grep -v "certbot renew" | grep -v "@reboot /bin/bash $(realpath $0) restart_streams" | crontab -

    # 6. Nginx yapılandırmasını kaldır
    echo "Nginx yapılandırması temizleniyor..."
    sudo rm -f "$NGINX_CONFIG" /etc/nginx/sites-enabled/hls
    sudo systemctl stop nginx
    sudo apt-get purge -y nginx nginx-common
    sudo apt-get autoremove -y

    # 7. FFmpeg'i kaldır
    echo "FFmpeg kaldırılıyor..."
    sudo apt-get purge -y ffmpeg
    sudo apt-get autoremove -y

    # 8. Script dosyasını kaldır
    echo "Script dosyası temizleniyor..."
    sudo rm -f "$(realpath $0)"

    # Yeni scriptin indirilmesi
    echo "Yeni script indiriliyor..."
    wget -O ts2hls_package.sh "$SCRIPT_URL"

    if [[ $? -ne 0 ]]; then
        echo "Yeni script indirilirken bir hata oluştu!"
        return
    fi

    # İzinlerin ayarlanması ve scriptin çalıştırılması
    echo "TS2HLS izni ayarlanıyor ve çalıştırılıyor..."
    chmod +x ts2hls.sh

    echo "Yeni script çalıştırılıyor..."
    ./ts2hls.sh

    exit 0
}

#-----------------------------------------------------
# Ana Menü
#-----------------------------------------------------
menu() {
    clear
    update_domain_from_nginx
    ts2hls_live_management_version=$(grep -E '^ts2hls_live_management_version=' /path/to/ts2hls.sh | cut -d'=' -f2 | tr -d '"')
    echo "========================================================="
    echo " HLS Yönetim Scripti SSL - NO-ENC / v$VERSION" - vU$ts2hls_live_management_version
    echo "========================================================="
    echo "1) Base URL Ekle"
    echo "2) Base URL Listele"
    echo "3) Base URL Sil"
    echo "4) Kullanıcı Ekle (Çoklu Base URL)"
    echo "5) Kullanıcı Kaldır"
    echo "6) Kullanıcıları Listele"
    echo "7) Yayınları Yeniden başlat"
    echo "8) Çıkış"
    echo "9) Yazılım Güncelle"
    echo "0) Sistemi Kaldır"
    echo "========================================================="
    read -p "Seçiminiz: " CHOICE

    case $CHOICE in
    1) add_base_url ;;
    2) list_base_urls ;;
    3) remove_base_url ;;
    4) add_user ;;
    5) remove_user ;;
    6) list_users ;;
    7) restart_streams ;;
    8)
        echo "Çıkış yapılıyor..."
        exit 0
        ;;
    9) update_software ;;
    0) remove_system ;;
    *)
        echo "Geçersiz seçim!"
        read -n 1 -s
        ;;
    esac
}

while true; do
    menu
done
