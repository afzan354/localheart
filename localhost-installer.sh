#!/data/data/com.termux/files/usr/bin/bash

# Termux Localhost Auto Installer
# Script untuk menginstall Apache, PHP, MySQL, dan phpMyAdmin di Termux
# Author: Auto Generated
# Version: 1.0

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Paths
INSTALLER_DIR="$HOME/.termux-localhost"
HTDOCS_DIR="/sdcard/htdocs"
CONFIG_DIR="/sdcard/localhost-config"
LOG_FILE="$INSTALLER_DIR/install.log"

# Fungsi untuk logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Fungsi untuk print dengan warna
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO: $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "WARNING: $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR: $1"
}

print_header() {
    clear
    echo -e "${CYAN}================================${NC}"
    echo -e "${WHITE}   TERMUX LOCALHOST INSTALLER${NC}"
    echo -e "${CYAN}================================${NC}"
    echo -e "${YELLOW}Apache + PHP + MySQL + phpMyAdmin${NC}"
    echo -e "${CYAN}================================${NC}\n"
}

# Fungsi untuk membuat direktori yang diperlukan
create_directories() {
    print_info "Membuat direktori yang diperlukan..."
    
    mkdir -p "$INSTALLER_DIR"
    mkdir -p "$HTDOCS_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CONFIG_DIR/apache"
    mkdir -p "$CONFIG_DIR/mysql"
    mkdir -p "$CONFIG_DIR/php"
    
    # Set permission untuk sdcard directories
    chmod 755 "$HTDOCS_DIR" 2>/dev/null || true
    chmod 755 "$CONFIG_DIR" 2>/dev/null || true
    
    print_success "Direktori berhasil dibuat"
}

# Fungsi untuk cek storage permission
check_storage_permission() {
    if [ ! -w "/sdcard" ]; then
        print_error "Tidak dapat menulis ke /sdcard"
        print_info "Jalankan: termux-setup-storage"
        print_info "Lalu berikan izin storage ke Termux"
        exit 1
    fi
}

# Fungsi untuk update packages
update_packages() {
    print_info "Mengupdate package list..."
    if ! pkg update -y >> "$LOG_FILE" 2>&1; then
        print_error "Gagal mengupdate packages"
        print_info "Coba jalankan: pkg update"
        return 1
    fi
    print_success "Package list berhasil diupdate"
}

# Fungsi untuk install dependencies
install_dependencies() {
    print_info "Menginstall dependencies..."
    
    local deps=("wget" "curl" "unzip" "nano" "git")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_info "Installing $dep..."
            if ! pkg install "$dep" -y >> "$LOG_FILE" 2>&1; then
                print_error "Gagal menginstall $dep"
                return 1
            fi
        else
            print_info "$dep sudah terinstall"
        fi
    done
    
    print_success "Dependencies berhasil diinstall"
}

# Fungsi untuk install Apache
install_apache() {
    print_info "Menginstall Apache..."
    
    if command -v httpd &> /dev/null; then
        print_warning "Apache sudah terinstall"
        local current_version=$(httpd -v | head -n1 | cut -d'/' -f2 | cut -d' ' -f1)
        print_info "Versi saat ini: $current_version"
        
        read -p "Update Apache? (y/n): " update_apache
        if [[ $update_apache =~ ^[Yy]$ ]]; then
            pkg upgrade apache2 -y >> "$LOG_FILE" 2>&1
        fi
    else
        if ! pkg install apache2 -y >> "$LOG_FILE" 2>&1; then
            print_error "Gagal menginstall Apache"
            print_info "Coba: pkg install apache2"
            return 1
        fi
    fi
    
    # Konfigurasi Apache
    configure_apache
    print_success "Apache berhasil diinstall dan dikonfigurasi"
}

# Fungsi untuk konfigurasi Apache
configure_apache() {
    print_info "Mengkonfigurasi Apache..."
    
    local apache_conf="$PREFIX/etc/apache2/httpd.conf"
    local apache_backup="$CONFIG_DIR/apache/httpd.conf.backup"
    
    # Backup konfigurasi original
    if [ ! -f "$apache_backup" ]; then
        cp "$apache_conf" "$apache_backup"
    fi
    
    # Copy konfigurasi ke sdcard untuk mudah diedit
    cp "$apache_conf" "$CONFIG_DIR/apache/httpd.conf"
    
    # Konfigurasi dasar Apache
    sed -i 's/#ServerName www.example.com:8080/ServerName localhost:8080/' "$apache_conf"
    sed -i "s|$PREFIX/share/apache2/default-site/htdocs|$HTDOCS_DIR|g" "$apache_conf"
    sed -i 's/Listen 8080/Listen 8080/' "$apache_conf"
    
    # Enable PHP module
    echo "LoadModule php_module $PREFIX/lib/php/modules/libphp.so" >> "$apache_conf"
    echo "AddType application/x-httpd-php .php" >> "$apache_conf"
    echo "DirectoryIndex index.php index.html" >> "$apache_conf"
    
    # Buat symlink ke konfigurasi di sdcard
    ln -sf "$CONFIG_DIR/apache/httpd.conf" "$apache_conf"
    
    # Buat index.php default
    cat > "$HTDOCS_DIR/index.php" << 'EOF'
<?php
echo "<h1>Welcome to Termux Localhost!</h1>";
echo "<h2>Server Info:</h2>";
phpinfo();
?>
EOF
}

# Fungsi untuk install PHP
install_php() {
    print_info "Menginstall PHP..."
    
    if command -v php &> /dev/null; then
        print_warning "PHP sudah terinstall"
        local current_version=$(php -v | head -n1 | cut -d' ' -f2)
        print_info "Versi saat ini: $current_version"
        
        read -p "Update PHP? (y/n): " update_php
        if [[ $update_php =~ ^[Yy]$ ]]; then
            pkg upgrade php php-apache -y >> "$LOG_FILE" 2>&1
        fi
    else
        if ! pkg install php php-apache -y >> "$LOG_FILE" 2>&1; then
            print_error "Gagal menginstall PHP"
            print_info "Coba: pkg install php php-apache"
            return 1
        fi
    fi
    
    # Install PHP extensions
    local php_extensions=("php-mysql" "php-pdo-mysql" "php-mbstring" "php-curl" "php-xml")
    
    for ext in "${php_extensions[@]}"; do
        print_info "Installing $ext..."
        pkg install "$ext" -y >> "$LOG_FILE" 2>&1 || print_warning "Gagal install $ext"
    done
    
    # Konfigurasi PHP
    configure_php
    print_success "PHP berhasil diinstall dan dikonfigurasi"
}

# Fungsi untuk konfigurasi PHP
configure_php() {
    print_info "Mengkonfigurasi PHP..."
    
    local php_ini="$PREFIX/lib/php.ini"
    local php_backup="$CONFIG_DIR/php/php.ini.backup"
    
    # Backup konfigurasi original
    if [ ! -f "$php_backup" ]; then
        cp "$php_ini" "$php_backup" 2>/dev/null || true
    fi
    
    # Copy konfigurasi ke sdcard
    cp "$php_ini" "$CONFIG_DIR/php/php.ini" 2>/dev/null || true
    
    # Konfigurasi dasar PHP
    sed -i 's/;extension=pdo_mysql/extension=pdo_mysql/' "$php_ini" 2>/dev/null || true
    sed -i 's/;extension=mysqli/extension=mysqli/' "$php_ini" 2>/dev/null || true
    sed -i 's/;extension=mbstring/extension=mbstring/' "$php_ini" 2>/dev/null || true
    sed -i 's/;extension=curl/extension=curl/' "$php_ini" 2>/dev/null || true
    
    # Buat symlink ke konfigurasi di sdcard
    ln -sf "$CONFIG_DIR/php/php.ini" "$php_ini" 2>/dev/null || true
}

# Fungsi untuk install MySQL (MariaDB)
install_mysql() {
    print_info "Menginstall MySQL (MariaDB)..."
    
    if command -v mysql &> /dev/null; then
        print_warning "MySQL sudah terinstall"
        read -p "Update MySQL? (y/n): " update_mysql
        if [[ $update_mysql =~ ^[Yy]$ ]]; then
            pkg upgrade mariadb -y >> "$LOG_FILE" 2>&1
        fi
    else
        if ! pkg install mariadb -y >> "$LOG_FILE" 2>&1; then
            print_error "Gagal menginstall MySQL"
            print_info "Coba: pkg install mariadb"
            return 1
        fi
    fi
    
    # Inisialisasi MySQL
    initialize_mysql
    print_success "MySQL berhasil diinstall dan dikonfigurasi"
}

# Fungsi untuk inisialisasi MySQL
initialize_mysql() {
    print_info "Menginisialisasi MySQL..."
    
    # Install database MySQL
    if [ ! -d "$PREFIX/var/lib/mysql/mysql" ]; then
        mysql_install_db >> "$LOG_FILE" 2>&1
    fi
    
    # Start MySQL untuk setup
    mysqld_safe --datadir="$PREFIX/var/lib/mysql" --socket="$PREFIX/tmp/mysqld.sock" &
    MYSQL_PID=$!
    sleep 5
    
    # Setup root password
    print_info "Setup password root MySQL..."
    echo "Masukkan password untuk root MySQL (kosongkan untuk 'root'):"
    read -s mysql_root_pass
    mysql_root_pass=${mysql_root_pass:-root}
    
    mysql -u root << EOF
UPDATE mysql.user SET Password=PASSWORD('$mysql_root_pass') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
EOF
    
    # Stop MySQL
    kill $MYSQL_PID 2>/dev/null || true
    sleep 2
    
    # Simpan konfigurasi
    echo "MYSQL_ROOT_PASSWORD=$mysql_root_pass" > "$CONFIG_DIR/mysql/config.env"
    chmod 600 "$CONFIG_DIR/mysql/config.env"
}

# Fungsi untuk install phpMyAdmin
install_phpmyadmin() {
    print_info "Menginstall phpMyAdmin..."
    
    local phpmyadmin_dir="$HTDOCS_DIR/phpmyadmin"
    local phpmyadmin_url="https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip"
    
    if [ -d "$phpmyadmin_dir" ]; then
        print_warning "phpMyAdmin sudah terinstall"
        read -p "Update phpMyAdmin? (y/n): " update_pma
        if [[ $update_pma =~ ^[Yy]$ ]]; then
            rm -rf "$phpmyadmin_dir"
        else
            return 0
        fi
    fi
    
    print_info "Downloading phpMyAdmin..."
    cd /tmp
    
    if ! wget "$phpmyadmin_url" -O phpmyadmin.zip >> "$LOG_FILE" 2>&1; then
        print_error "Gagal download phpMyAdmin"
        print_info "Periksa koneksi internet"
        return 1
    fi
    
    print_info "Mengekstrak phpMyAdmin..."
    if ! unzip -q phpmyadmin.zip; then
        print_error "Gagal ekstrak phpMyAdmin"
        return 1
    fi
    
    mv phpMyAdmin-* "$phpmyadmin_dir"
    rm -f phpmyadmin.zip
    
    # Konfigurasi phpMyAdmin
    configure_phpmyadmin
    print_success "phpMyAdmin berhasil diinstall"
}

# Fungsi untuk konfigurasi phpMyAdmin
configure_phpmyadmin() {
    print_info "Mengkonfigurasi phpMyAdmin..."
    
    local phpmyadmin_dir="$HTDOCS_DIR/phpmyadmin"
    local config_file="$phpmyadmin_dir/config.inc.php"
    
    # Load MySQL password
    source "$CONFIG_DIR/mysql/config.env" 2>/dev/null || MYSQL_ROOT_PASSWORD="root"
    
    cat > "$config_file" << EOF
<?php
\$cfg['blowfish_secret'] = '$(openssl rand -base64 32)';
\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['host'] = 'localhost';
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['UploadDir'] = '';
\$cfg['SaveDir'] = '';
\$cfg['TempDir'] = '/tmp';
?>
EOF
    
    # Copy konfigurasi ke sdcard untuk mudah diedit
    cp "$config_file" "$CONFIG_DIR/phpmyadmin-config.inc.php"
    ln -sf "$CONFIG_DIR/phpmyadmin-config.inc.php" "$config_file"
}

# Fungsi untuk membuat script management
create_management_scripts() {
    print_info "Membuat script management..."
    
    # Script untuk start services
    cat > "$INSTALLER_DIR/start-services.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
source ~/.termux-localhost/config.env 2>/dev/null

echo "Starting MySQL..."
mysqld_safe --datadir="$PREFIX/var/lib/mysql" --socket="$PREFIX/tmp/mysqld.sock" &
MYSQL_PID=$!
echo $MYSQL_PID > ~/.termux-localhost/mysql.pid
sleep 3

echo "Starting Apache..."
httpd -D FOREGROUND &
APACHE_PID=$!
echo $APACHE_PID > ~/.termux-localhost/apache.pid
sleep 2

echo "Services started!"
echo "Apache: http://localhost:8080"
echo "phpMyAdmin: http://localhost:8080/phpmyadmin"
echo "MySQL Socket: $PREFIX/tmp/mysqld.sock"
EOF
    
    # Script untuk stop services
    cat > "$INSTALLER_DIR/stop-services.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "Stopping services..."

if [ -f ~/.termux-localhost/apache.pid ]; then
    kill $(cat ~/.termux-localhost/apache.pid) 2>/dev/null
    rm -f ~/.termux-localhost/apache.pid
fi

if [ -f ~/.termux-localhost/mysql.pid ]; then
    kill $(cat ~/.termux-localhost/mysql.pid) 2>/dev/null
    rm -f ~/.termux-localhost/mysql.pid
fi

pkill -f mysqld 2>/dev/null
pkill -f httpd 2>/dev/null

echo "Services stopped!"
EOF
    
    # Script untuk status services
    cat > "$INSTALLER_DIR/status-services.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "=== Service Status ==="

if pgrep -f httpd > /dev/null; then
    echo "Apache: RUNNING (Port 8080)"
else
    echo "Apache: STOPPED"
fi

if pgrep -f mysqld > /dev/null; then
    echo "MySQL: RUNNING"
else
    echo "MySQL: STOPPED"
fi

echo ""
echo "=== Useful URLs ==="
echo "Apache: http://localhost:8080"
echo "phpMyAdmin: http://localhost:8080/phpmyadmin"
echo ""
echo "=== File Locations ==="
echo "htdocs: /sdcard/htdocs"
echo "Config: /sdcard/localhost-config"
EOF
    
    # Buat script utama termux-localhost
    cat > "$PREFIX/bin/termux-localhost" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

INSTALLER_DIR="$HOME/.termux-localhost"

case $1 in
    start)
        bash "$INSTALLER_DIR/start-services.sh"
        ;;
    stop)
        bash "$INSTALLER_DIR/stop-services.sh"
        ;;
    restart)
        bash "$INSTALLER_DIR/stop-services.sh"
        sleep 2
        bash "$INSTALLER_DIR/start-services.sh"
        ;;
    status)
        bash "$INSTALLER_DIR/status-services.sh"
        ;;
    *)
        echo "Usage: termux-localhost {start|stop|restart|status}"
        echo ""
        echo "Commands:"
        echo "  start     - Start Apache and MySQL"
        echo "  stop      - Stop Apache and MySQL"
        echo "  restart   - Restart services"
        echo "  status    - Show service status"
        echo ""
        echo "Files:"
        echo "  htdocs: /sdcard/htdocs"
        echo "  Config: /sdcard/localhost-config"
        ;;
esac
EOF
    
    # Set executable permissions
    chmod +x "$INSTALLER_DIR"/*.sh
    chmod +x "$PREFIX/bin/termux-localhost"
    
    print_success "Management scripts berhasil dibuat"
}

# Fungsi untuk uninstaller
create_uninstaller() {
    print_info "Membuat uninstaller..."
    
    cat > "$INSTALLER_DIR/uninstall.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}TERMUX LOCALHOST UNINSTALLER${NC}"
echo -e "${RED}PERINGATAN: Ini akan menghapus semua yang diinstall!${NC}"
echo ""
echo "Yang akan dihapus:"
echo "- Apache, PHP, MySQL packages"
echo "- File konfigurasi"
echo "- Management scripts"
echo ""
echo -e "${YELLOW}File di /sdcard akan dipertahankan kecuali diminta${NC}"
echo ""

read -p "Lanjutkan uninstall? (y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Uninstall dibatalkan"
    exit 0
fi

echo "Stopping services..."
bash ~/.termux-localhost/stop-services.sh 2>/dev/null || true

echo "Removing packages..."
pkg uninstall apache2 php php-apache mariadb -y 2>/dev/null || true

echo "Removing scripts..."
rm -f $PREFIX/bin/termux-localhost
rm -rf ~/.termux-localhost

read -p "Hapus juga file di /sdcard? (y/n): " remove_sdcard
if [[ $remove_sdcard =~ ^[Yy]$ ]]; then
    rm -rf /sdcard/htdocs
    rm -rf /sdcard/localhost-config
    echo "File di /sdcard dihapus"
fi

echo -e "${GREEN}Uninstall selesai!${NC}"
EOF
    
    chmod +x "$INSTALLER_DIR/uninstall.sh"
    
    # Buat shortcut uninstaller
    cat > "$PREFIX/bin/termux-localhost-uninstall" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
bash ~/.termux-localhost/uninstall.sh
EOF
    
    chmod +x "$PREFIX/bin/termux-localhost-uninstall"
    print_success "Uninstaller berhasil dibuat"
}

# Fungsi untuk membuat file konfigurasi
create_config() {
    print_info "Membuat file konfigurasi..."
    
    cat > "$INSTALLER_DIR/config.env" << EOF
# Termux Localhost Configuration
APACHE_PORT=8080
MYSQL_PORT=3306
HTDOCS_DIR=$HTDOCS_DIR
CONFIG_DIR=$CONFIG_DIR
INSTALLER_DIR=$INSTALLER_DIR
INSTALL_DATE=$(date)
VERSION=1.0
EOF
    
    print_success "File konfigurasi berhasil dibuat"
}

# Fungsi untuk membuat README
create_readme() {
    cat > "$CONFIG_DIR/README.md" << 'EOF'
# Termux Localhost Setup

## Perintah Management

```bash
# Start services
termux-localhost start

# Stop services
termux-localhost stop

# Restart services
termux-localhost restart

# Check status
termux-localhost status

# Uninstall
termux-localhost-uninstall
```

## Akses Web

- **Apache**: http://localhost:8080
- **phpMyAdmin**: http://localhost:8080/phpmyadmin

## File Locations

- **htdocs**: `/sdcard/htdocs` - Letakkan file web disini
- **Apache Config**: `/sdcard/localhost-config/apache/httpd.conf`
- **PHP Config**: `/sdcard/localhost-config/php/php.ini`
- **phpMyAdmin Config**: `/sdcard/localhost-config/phpmyadmin-config.inc.php`

## MySQL Info

- **Username**: root
- **Password**: Sesuai yang diset saat install
- **Socket**: `$PREFIX/tmp/mysqld.sock`

## Troubleshooting

1. **Port sudah digunakan**: Ubah port di konfigurasi Apache
2. **Permission denied**: Pastikan storage permission sudah diberikan
3. **Service tidak start**: Check log di `~/.termux-localhost/install.log`

## File Penting

- Log: `~/.termux-localhost/install.log`
- Config: `~/.termux-localhost/config.env`
- Scripts: `~/.termux-localhost/`

Semua konfigurasi utama ada di `/sdcard/localhost-config` untuk mudah diedit.
EOF
}

# Fungsi utama installer
main_install() {
    print_header
    
    print_info "Memulai instalasi Termux Localhost..."
    print_info "Ini akan menginstall: Apache, PHP, MySQL, phpMyAdmin"
    echo ""
    
    read -p "Lanjutkan instalasi? (y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Instalasi dibatalkan"
        exit 0
    fi
    
    # Cek permission storage
    check_storage_permission
    
    # Buat direktori
    create_directories
    
    # Update packages
    if ! update_packages; then
        print_error "Gagal update packages. Instalasi dihentikan."
        exit 1
    fi
    
    # Install dependencies
    if ! install_dependencies; then
        print_error "Gagal install dependencies. Instalasi dihentikan."
        exit 1
    fi
    
    # Install Apache
    if ! install_apache; then
        print_error "Gagal install Apache. Instalasi dihentikan."
        exit 1
    fi
    
    # Install PHP
    if ! install_php; then
        print_error "Gagal install PHP. Instalasi dihentikan."
        exit 1
    fi
    
    # Install MySQL
    if ! install_mysql; then
        print_error "Gagal install MySQL. Instalasi dihentikan."
        exit 1
    fi
    
    # Install phpMyAdmin
    if ! install_phpmyadmin; then
        print_warning "phpMyAdmin gagal diinstall, tapi instalasi dilanjutkan"
    fi
    
    # Buat management scripts
    create_management_scripts
    
    # Buat uninstaller
    create_uninstaller
    
    # Buat konfigurasi
    create_config
    
    # Buat README
    create_readme
    
    # Selesai
    print_header
    print_success "INSTALASI SELESAI!"
    echo ""
    echo -e "${GREEN}=== INFORMASI PENTING ===${NC}"
    echo -e "${YELLOW}Commands:${NC}"
    echo "  termux-localhost start    - Start services"
    echo "  termux-localhost stop     - Stop services"
    echo "  termux-localhost status   - Check status"
    echo "  termux-localhost-uninstall - Uninstall"
    echo ""
    echo -e "${YELLOW}Access URLs:${NC}"
    echo "  Apache: http://localhost:8080"
    echo "  phpMyAdmin: http://localhost:8080/phpmyadmin"
    echo ""
    echo -e "${YELLOW}File Locations:${NC}"
    echo "  htdocs: /sdcard/htdocs"
    echo "  Config: /sdcard/localhost-config"
    echo ""
    echo -e "${CYAN}Jalankan 'termux-localhost start' untuk memulai!${NC}"
    echo ""
    
    read -p "Start services sekarang? (y/n): " start_now
    if [[ $start_now =~ ^[Yy]$ ]]; then
        termux-localhost start
    fi
}

# Cek jika script dijalankan langsung
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_install
fi
