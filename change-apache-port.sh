#!/data/data/com.termux/files/usr/bin/bash

# Apache Port Changer for Termux Localhost
# Script untuk mengganti port Apache dengan mudah

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

APACHE_CONF="/sdcard/localhost-config/apache/httpd.conf"
CONFIG_FILE="$HOME/.termux-localhost/config.env"

print_header() {
    clear
    echo -e "${CYAN}================================${NC}"
    echo -e "${WHITE}     APACHE PORT CHANGER${NC}"
    echo -e "${CYAN}================================${NC}\n"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Fungsi untuk mendapatkan port saat ini
get_current_port() {
    if [ -f "$APACHE_CONF" ]; then
        grep "^Listen " "$APACHE_CONF" | head -n1 | awk '{print $2}'
    else
        echo "8080"
    fi
}

# Fungsi untuk cek apakah port sedang digunakan
check_port_usage() {
    local port=$1
    if netstat -tuln 2>/dev/null | grep ":$port " >/dev/null; then
        return 0  # Port sedang digunakan
    else
        return 1  # Port bebas
    fi
}

# Fungsi untuk validate port number
validate_port() {
    local port=$1
    
    # Cek apakah numeric
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Cek range port (1024-65535 untuk user)
    if [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    
    return 0
}

# Fungsi untuk mengganti port
change_port() {
    local new_port=$1
    local current_port=$(get_current_port)
    
    print_info "Mengganti port dari $current_port ke $new_port..."
    
    # Backup konfigurasi
    cp "$APACHE_CONF" "$APACHE_CONF.backup.$(date +%s)"
    
    # Ganti port di konfigurasi Apache
    sed -i "s/^Listen .*/Listen $new_port/" "$APACHE_CONF"
    
    # Update ServerName jika ada
    sed -i "s/ServerName localhost:.*/ServerName localhost:$new_port/" "$APACHE_CONF"
    
    # Update config.env
    if [ -f "$CONFIG_FILE" ]; then
        sed -i "s/APACHE_PORT=.*/APACHE_PORT=$new_port/" "$CONFIG_FILE"
    fi
    
    print_success "Port berhasil diubah ke $new_port"
    print_info "Konfigurasi backup disimpan di: $APACHE_CONF.backup.*"
}

# Fungsi untuk show port recommendations
show_port_recommendations() {
    echo -e "${YELLOW}Port yang disarankan:${NC}"
    echo "  3000 - Umum untuk development"
    echo "  8000 - Alternative web server"
    echo "  8080 - Default Apache (current)"
    echo "  8888 - Popular alternative" 
    echo "  9000 - Another common choice"
    echo ""
    echo -e "${YELLOW}Hindari port:${NC}"
    echo "  80, 443 - Memerlukan root"
    echo "  22 - SSH"
    echo "  3306 - MySQL"
    echo "  < 1024 - System ports"
}

# Fungsi untuk interactive port change
interactive_change() {
    local current_port=$(get_current_port)
    
    echo -e "${CYAN}Port Apache saat ini: ${WHITE}$current_port${NC}"
    echo ""
    
    # Cek status Apache
    if pgrep -f httpd > /dev/null; then
        print_warning "Apache sedang berjalan di port $current_port"
        echo ""
    fi
    
    show_port_recommendations
    echo ""
    
    while true; do
        read -p "Masukkan port baru (1024-65535): " new_port
        
        # Validate input
        if [ -z "$new_port" ]; then
            print_error "Port tidak boleh kosong!"
            continue
        fi
        
        if ! validate_port "$new_port"; then
            print_error "Port tidak valid! Gunakan angka antara 1024-65535"
            continue
        fi
        
        if [ "$new_port" == "$current_port" ]; then
            print_warning "Port sama dengan port saat ini ($current_port)"
            continue
        fi
        
        # Cek apakah port sedang digunakan
        if check_port_usage "$new_port"; then
            print_warning "Port $new_port mungkin sedang digunakan aplikasi lain"
            read -p "Tetap lanjutkan? (y/n): " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                continue
            fi
        fi
        
        # Konfirmasi
        echo ""
        echo -e "${YELLOW}Akan mengganti port dari ${WHITE}$current_port${YELLOW} ke ${WHITE}$new_port${NC}"
        read -p "Lanjutkan? (y/n): " confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            change_port "$new_port"
            break
        else
            print_info "Perubahan dibatalkan"
            break
        fi
    done
}

# Fungsi untuk restart services setelah perubahan
restart_services() {
    if command -v termux-localhost &> /dev/null; then
        print_info "Restarting Apache services..."
        termux-localhost restart
        
        local new_port=$(get_current_port)
        echo ""
        print_success "Apache sekarang berjalan di port $new_port"
        echo -e "${CYAN}Akses web: ${WHITE}http://localhost:$new_port${NC}"
        echo -e "${CYAN}phpMyAdmin: ${WHITE}http://localhost:$new_port/phpmyadmin${NC}"
    else
        print_warning "Command 'termux-localhost' tidak ditemukan"
        print_info "Restart Apache manual dengan: httpd -k restart"
    fi
}

# Fungsi untuk show current status
show_status() {
    local current_port=$(get_current_port)
    
    echo -e "${CYAN}=== APACHE PORT STATUS ===${NC}"
    echo -e "${YELLOW}Current Port:${NC} $current_port"
    
    if pgrep -f httpd > /dev/null; then
        echo -e "${YELLOW}Apache Status:${NC} ${GREEN}RUNNING${NC}"
        echo -e "${YELLOW}Access URL:${NC} http://localhost:$current_port"
        echo -e "${YELLOW}phpMyAdmin:${NC} http://localhost:$current_port/phpmyadmin"
        
        if check_port_usage "$current_port"; then
            echo -e "${YELLOW}Port Status:${NC} ${GREEN}ACTIVE${NC}"
        else
            echo -e "${YELLOW}Port Status:${NC} ${RED}NOT LISTENING${NC}"
        fi
    else
        echo -e "${YELLOW}Apache Status:${NC} ${RED}STOPPED${NC}"
    fi
    
    echo ""
}

# Fungsi utama
main() {
    print_header
    
    # Cek apakah file konfigurasi ada
    if [ ! -f "$APACHE_CONF" ]; then
        print_error "File konfigurasi Apache tidak ditemukan!"
        print_info "Pastikan Termux Localhost sudah diinstall"
        print_info "File yang dicari: $APACHE_CONF"
        exit 1
    fi
    
    case "${1:-interactive}" in
        "status"|"-s"|"--status")
            show_status
            ;;
        "set"|"-p"|"--port")
            if [ -z "$2" ]; then
                print_error "Masukkan port number!"
                echo "Usage: $0 set <port_number>"
                exit 1
            fi
            
            if ! validate_port "$2"; then
                print_error "Port tidak valid! Gunakan angka antara 1024-65535"
                exit 1
            fi
            
            change_port "$2"
            restart_services
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [option] [port]"
            echo ""
            echo "Options:"
            echo "  (no args)    - Interactive mode"
            echo "  status       - Show current port status"
            echo "  set <port>   - Set specific port"
            echo "  help         - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0              # Interactive mode"
            echo "  $0 status       # Show current status"
            echo "  $0 set 3000     # Set port to 3000"
            ;;
        *)
            show_status
            echo ""
            interactive_change
            
            read -p "Restart Apache sekarang? (y/n): " restart_now
            if [[ $restart_now =~ ^[Yy]$ ]]; then
                restart_services
            else
                local new_port=$(get_current_port)
                print_info "Port telah diubah, restart Apache untuk mengaktifkan:"
                print_info "termux-localhost restart"
                echo ""
                print_info "Akses baru nanti: http://localhost:$new_port"
            fi
            ;;
    esac
}

# Jalankan fungsi utama
main "$@"
