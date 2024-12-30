#!/bin/bash

# TS2HLS Installer Script with Auto-Update and MIT License Option
# Version: 1.0.0

# Betik versiyonları
ts2hls_version="1.0.0"
ts2hls_installer_version="1.0.0"

# Geçici güncelleme kontrolü için dosya
update_marker="/tmp/ts2hls_update_done"

# Betiğin kendisini güncellemesi
if [ ! -f "$update_marker" ]; then
    echo "Betiğin güncel sürümü kontrol ediliyor..."
    curl -s -o "ts2hls_install_latest.sh" "https://raw.githubusercontent.com/livvaa/TS2HLS-Manager/main/ts2hls.sh" || {
        echo "Güncelleme başarısız oldu! Eski sürüm çalıştırılıyor..."
        sleep 2
        clear
    }
    if [ -f "ts2hls_install_latest.sh" ]; then
        mv ts2hls_install_latest.sh ts2hls.sh
        chmod +x ts2hls.sh
        echo "Güncelleme tamamlandı. Yeni sürüm çalıştırılıyor..."
        touch "$update_marker" # Güncelleme tamamlandı işareti
        exec ./ts2hls.sh
        exit 0
    fi
else
    rm -f "$update_marker" # İşaret dosyasını kaldır
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
        # AGPL-3.0 Lisansını Göster
        clear
        echo "GNU AFFERO GENERAL PUBLIC LICENSE"
        echo "Version 3, 19 November 2007"
        echo ""
        echo "Copyright (C) 2024 Livvaa"
        echo ""
        echo "This program is free software: you can redistribute it and/or modify"
        echo "it under the terms of the GNU Affero General Public License as published"
        echo "by the Free Software Foundation, either version 3 of the License, or"
        echo "(at your option) any later version."
        echo ""
        echo "This program is distributed in the hope that it will be useful,"
        echo "but WITHOUT ANY WARRANTY; without even the implied warranty of"
        echo "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the"
        echo "GNU Affero General Public License for more details."
        echo ""
        echo "You should have received a copy of the GNU Affero General Public License"
        echo "along with this program. If not, see <https://www.gnu.org/licenses/>."
        echo ""
        echo "---"
        echo ""
        echo "### Third-Party Dependencies"
        echo ""
        echo "This software uses the following third-party dependencies, which are licensed under their respective open-source licenses:"
        echo "- **Nginx**: BSD-2-Clause License (https://opensource.org/licenses/BSD-2-Clause)"
        echo "- **Certbot**: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)"
        echo "- **FFmpeg**: GPL or LGPL (https://ffmpeg.org/legal.html)"
        echo ""
        echo "Please refer to the above links for the respective licenses of these dependencies. Users are required to comply with these licenses in addition to this license."
        echo ""
        echo "---"
        echo ""
        echo "### Network Usage Clause (AGPL Requirement)"
        echo ""
        echo "If this software is used to provide a network service, you are required to make the complete source code of the modified version accessible to all users of the service."
        echo ""
        echo "For detailed terms, see the full AGPL v3 license text here: [https://www.gnu.org/licenses/agpl-3.0.html]."
        echo ""
        echo "---"
        echo ""
        echo "**Note**: This license requires that any modified versions of this software, when used to provide services over a network, must make the source code available to the users of those services."
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
    curl -O "$script_url" || {
        echo "Betiği indirme başarısız oldu!"
        exit 1
    }

    # İndirilen dosya adını tespit et
    if [ "$selection" == "1" ]; then
        downloaded_file="ts2hls_live_management.sh"
    else
        downloaded_file="ts2hls_live_pro.sh"
    fi

    # Betik adını ts2hls_package.sh olarak değiştir
    mv "$downloaded_file" ts2hls_package.sh || {
        echo "Ad değişikliği başarısız oldu!"
        exit 1
    }

    # Çalıştırma izni ver
    chmod +x ts2hls_package.sh
    echo "Betiğe çalıştırma izni verildi."

    # Kullanıcıyı bilgilendir ve çalıştırmayı öner
    echo "Kurulum tamamlandı! Betiği çalıştırmak için aşağıdaki komutu kullanabilirsiniz:"
    echo "./ts2hls_package.sh"
    break
done
