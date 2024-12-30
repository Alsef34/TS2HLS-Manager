#!/bin/bash

# TS2HLS Installer Script with Auto-Update and MIT License Option
# Version: 1.0.0

# Betik versiyonları
ts2hls_version="1.0.0"
ts2hls_installer_version="1.0.0"

# Betiğin kendisini güncellemesi
echo "Betiğin güncel sürümü kontrol ediliyor..."
curl -s -o "ts2hls_install_latest.sh" "https://raw.githubusercontent.com/livvaa/TS2HLS-Manager/main/ts2hls.sh" || {
    echo "Güncelleme başarısız oldu! Eski sürüm çalıştırılıyor..."
    sleep 2
    clear
}
if [ -f "ts2hls_install_latest.sh" ]; then
    # Yeni sürüm mevcutsa kendisini günceller
    mv ts2hls_install_latest.sh ts2hls.sh
    chmod +x ts2hls.sh
    echo "Güncelleme tamamlandı. Yeni sürüm çalıştırılıyor..."
    exec ./ts2hls.sh
    exit 0
fi

# Mevcut ts2hls_package.sh kontrolü
if [ -f "ts2hls_package.sh" ]; then
    echo "ts2hls_package.sh zaten mevcut. Çalıştırılıyor..."
    ./ts2hls_package.sh
    exit 0
fi

while true; do
    # Kullanıcıya menüyü ve sürüm bilgisini göster
    clear
    echo "========================="
    echo " TS2HLS Installer Script"
    echo " Installer Version: $ts2hls_installer_version"
    echo "========================="
    echo "Hangi işlemi yapmak istersiniz?"
    echo "0) MIT lisansını görüntüle"
    echo "1) ts2hls_live_management.sh kur"
    echo "2) ts2hls_live_pro.sh kur"
    echo "3) Çıkış"
    echo "========================="
    read -p "Seçiminizi yapın (0, 1, 2 veya 3): " selection

    if [ "$selection" == "0" ]; then
        # MIT lisansını göster
        clear
        echo "MIT License"
        echo "Copyright (c) 2024 Livvaa"
        echo ""
        echo "Permission is hereby granted, free of charge, to any person obtaining a copy"
        echo "of this software and associated documentation files (the \"Software\"), to deal"
        echo "in the Software without restriction, including without limitation the rights"
        echo "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell"
        echo "copies of the Software, and to permit persons to whom the Software is"
        echo "furnished to do so, subject to the following conditions:"
        echo ""
        echo "The above copyright notice and this permission notice shall be included in all"
        echo "copies or substantial portions of the Software."
        echo ""
        echo "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR"
        echo "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,"
        echo "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE"
        echo "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER"
        echo "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,"
        echo "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE"
        echo "SOFTWARE."
        echo ""
        read -p "Menüye geri dönmek için herhangi bir tuşa basın..."
        continue
    elif [ "$selection" == "1" ]; then
        # ts2hls_live_management.sh kurulumu
        script_url="https://raw.githubusercontent.com/livvaa/TS2HLS-Manager/main/ts2hls_live_management.sh"
    elif [ "$selection" == "2" ]; then
        # ts2hls_live_pro.sh kurulumu
        script_url="https://raw.githubusercontent.com/livvaa/TS2HLS-Manager/main/ts2hls_live_pro.sh"
    elif [ "$selection" == "3" ]; then
        # Çıkış seçeneği
        echo "Çıkılıyor..."
        exit 0
    else
        # Geçersiz seçim
        echo "Geçersiz seçim! Lütfen 0, 1, 2 veya 3 girin."
        continue
    fi

    # Betiği indir
    echo "Betiği indiriyor..."
    curl -O "$script_url" || { echo "Betiği indirme başarısız oldu!"; exit 1; }

    # İndirilen dosya adını tespit et
    if [ "$selection" == "1" ]; then
        downloaded_file="ts2hls_live_management.sh"
    else
        downloaded_file="ts2hls_live_pro.sh"
    fi

    # Betik adını ts2hls_package.sh olarak değiştir
    mv "$downloaded_file" ts2hls_package.sh || { echo "Ad değişikliği başarısız oldu!"; exit 1; }

    # Çalıştırma izni ver
    chmod +x ts2hls_package.sh
    echo "Betiğe çalıştırma izni verildi."

    # Kullanıcıyı bilgilendir ve çalıştırmayı öner
    echo "Kurulum tamamlandı! Betiği çalıştırmak için aşağıdaki komutu kullanabilirsiniz:"
    echo "./ts2hls_package.sh"
    break
done
