Saya telah buatkan script auto installer lengkap untuk setup localhost di Termux! Berikut fitur-fitur yang disediakan:
✨ Fitur Utama:

Auto Install & Update: Otomatis cek versi dan update jika diperlukan
Error Handling: Petunjuk jelas jika ada error
Management Commands: Mudah start/stop/restart services
File di SD Card: htdocs dan config ada di /sdcard untuk mudah diedit
Uninstaller: Hapus semua yang diinstall

🚀 Cara Menggunakan:

Simpan script dengan nama localhost-installer.sh
Berikan permission: chmod +x localhost-installer.sh
Jalankan: ./localhost-installer.sh

📱 Commands Setelah Install:
bash# Start services
termux-localhost start

# Stop services  
termux-localhost stop

# Restart services
termux-localhost restart

# Cek status
termux-localhost status

# Uninstall semua
termux-localhost-uninstall
📂 Lokasi File Penting:

htdocs: /sdcard/htdocs - Taruh file web disini
Config Apache: /sdcard/localhost-config/apache/httpd.conf
Config PHP: /sdcard/localhost-config/php/php.ini
Config phpMyAdmin: /sdcard/localhost-config/phpmyadmin-config.inc.php

🌐 Akses Web:

Apache: http://localhost:8080
phpMyAdmin: http://localhost:8080/phpmyadmin

🛠 Fitur Troubleshooting:

Log detail di ~/.termux-localhost/install.log
Error handling dengan pesan jelas
Auto backup konfigurasi original
Cek permission storage otomatis

Script ini akan otomatis handle semua instalasi, konfigurasi, dan setup management yang Anda butuhkan. Semua file konfigurasi yang sering diedit sudah dipindah ke /sdcard agar mudah diakses dan diedit!
