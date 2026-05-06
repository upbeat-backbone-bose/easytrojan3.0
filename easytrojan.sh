#!/bin/bash
#
# Notes: EasyTrojan for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#        https://github.com/autotls/easytrojan
#
# How to use:
#
#        Install (Default)
#        chmod +x easytrojan.sh && bash easytrojan.sh password
#
#        Install (Custom Domain)
#        chmod +x easytrojan.sh && bash easytrojan.sh password yourdomain
# 
#        Uninstall (Only Service)
#        systemctl stop caddy.service && systemctl disable caddy.service
#
#        Uninstall (All Data)
#        systemctl stop caddy.service && systemctl disable caddy.service
#        rm -rf /etc/caddy /usr/local/bin/caddy /etc/systemd/system/caddy.service
#

# ==================== Configuration ====================
readonly CADDY_VERSION="2.11.2"
readonly CADDY_BASE_URL="https://github.com/upbeat-backbone-bose/easytrojan3.0/releases/download/${CADDY_VERSION}"
readonly CADDY_BIN="/usr/local/bin/caddy"
readonly CADDY_CONFIG_DIR="/etc/caddy"
readonly CADDY_SERVICE_FILE="/etc/systemd/system/caddy.service"
readonly TROJAN_DATA_DIR="/etc/caddy/trojan"
readonly PASSWD_FILE="/etc/caddy/trojan/passwd.txt"
readonly CADDY_USER="caddy"
readonly REQUIRED_PORTS=(80 443)
readonly SYSCTL_BEGIN_MARKER="# BEGIN EASYTROJAN SYSCTL"
readonly SYSCTL_END_MARKER="# END EASYTROJAN SYSCTL"

# ==================== Helper Functions ====================

# Check if a command exists
check_cmd() { command -v "$1" &>/dev/null; }

# Log error message and exit
log_error() {
    echo "Error: $1" >&2
    exit 1
}

# Log info message
log_info() {
    echo "[INFO] $1"
}

# Validate trojan password (reject control characters and empty value)
validate_password() {
    local passwd="$1"
    if [ -z "$passwd" ]; then
        log_error "Password must not be empty"
    fi
    if [[ "$passwd" =~ [[:cntrl:]] ]]; then
        log_error "Password must not contain control characters"
    fi
}

# Escape string for safe embedding in JSON value
json_escape() {
    local s="$1"
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    s=${s//$'\r'/\\r}
    s=${s//$'\t'/\\t}
    printf '%s' "$s"
}

url_encode() {
    local s="$1"
    local i
    local ch
    for ((i = 0; i < ${#s}; i++)); do
        ch="${s:i:1}"
        case "$ch" in
            [a-zA-Z0-9.~_-]) printf '%s' "$ch" ;;
            *) printf '%%%02X' "'$ch" ;;
        esac
    done
}

# Get Caddy binary URL based on architecture
get_caddy_url() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "${CADDY_BASE_URL}/caddy_amd64" ;;
        aarch64) echo "${CADDY_BASE_URL}/caddy_arm64" ;;
        *) log_error "Architecture $arch is not supported" ;;
    esac
}

# Check if ports are available
check_ports() {
    local ports_in_use=()
    for port in "${REQUIRED_PORTS[@]}"; do
        if check_cmd ss; then
            if ss -Hlnp "sport = :$port" 2>/dev/null | grep -q .; then
                ports_in_use+=("$port")
            fi
        elif check_cmd netstat; then
            if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
                ports_in_use+=("$port")
            fi
        else
            log_error "Neither 'ss' nor 'netstat' command found"
        fi
    done
    
    if [ ${#ports_in_use[@]} -gt 0 ]; then
        log_error "Ports ${ports_in_use[*]} are already in use"
    fi
}

# Verify domain resolves to current server IPv4
verify_domain_ip() {
    local domain="$1"
    local server_ip="$2"
    local domain_ips

    domain_ips=$(getent ahostsv4 "$domain" 2>/dev/null | awk '{print $1}' | sort -u)

    if [ -z "$domain_ips" ]; then
        # Fallback to ping if getent is unavailable
        domain_ips=$(ping -c 1 -W 3 "$domain" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi

    if [ -z "$domain_ips" ] || ! echo "$domain_ips" | grep -Fxq "$server_ip"; then
        log_error "Domain $domain does not resolve to server IP $server_ip"
    fi
}

# Add trojan user via Caddy API (safe JSON construction)
add_trojan_user() {
    local password="$1"
    local escaped_password
    local response
    local http_code

    escaped_password=$(json_escape "$password")
    response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"password\":\"$escaped_password\"}" \
        "http://localhost:2019/trojan/users/add" 2>/dev/null)
    
    http_code=$(echo "$response" | tail -1)
    
    if [ "$http_code" != "200" ]; then
        log_error "Failed to add trojan user via Caddy API"
    fi
}

# Save password to file (with deduplication)
save_password() {
    local password="$1"
    echo "$password" >> "$PASSWD_FILE"
    sort "$PASSWD_FILE" | uniq > "${PASSWD_FILE}.tmp"
    mv -f "${PASSWD_FILE}.tmp" "$PASSWD_FILE"
}

# Backup system configuration files
backup_config() {
    local file="$1"
    if [ -f "$file" ]; then
        cp -f "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
        log_info "Backed up $file"
    fi
}

write_sysctl_block() {
    local tmp_file
    tmp_file=$(mktemp) || log_error "Failed to create temporary file"

    awk -v begin="$SYSCTL_BEGIN_MARKER" -v end="$SYSCTL_END_MARKER" '
    $0==begin {skip=1; next}
    $0==end {skip=0; next}
    !skip {print}
    ' /etc/sysctl.conf > "$tmp_file" || log_error "Failed to parse /etc/sysctl.conf"

    cat >> "$tmp_file" <<EOF
$SYSCTL_BEGIN_MARKER
fs.file-max = 1048576
fs.inotify.max_user_instances = 8192
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 16384 33554432
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 32768
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_frto = 0
net.ipv4.tcp_mtu_probing = 0
net.ipv4.tcp_rfc1337 = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.conf.all.route_localnet = 1
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
EOF

    modprobe tcp_bbr &>/dev/null
    if grep -qw bbr /proc/sys/net/ipv4/tcp_available_congestion_control; then
        cat >> "$tmp_file" <<EOF
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
    fi

    echo "$SYSCTL_END_MARKER" >> "$tmp_file"
    cat "$tmp_file" > /etc/sysctl.conf
    rm -f "$tmp_file"
}

# ==================== Main Script ====================

# Parse arguments
trojan_passwd="$1"
caddy_domain="$2"

# Validate inputs
[ -z "$trojan_passwd" ] && log_error "You must enter a trojan password to run this script"
validate_password "$trojan_passwd"
[ "$(id -u)" != "0" ] && log_error "You must be root to run this script"

# Get server IP
address_ip=$(curl -s -4 ipv4.ip.sb 2>/dev/null)
[ -z "$address_ip" ] && log_error "Failed to get server IP address"

# Generate default domain from IP
long_number=$(echo "$address_ip" | awk -F. '{printf "%u\n", $4 * 256^3 + $3 * 256^2 + $2 * 256 + $1}')
nip_domain="ip${long_number}.mobgslb.tbcache.com"

# Generate trojan connection link
trojan_link="trojan://$(url_encode "$trojan_passwd")@${address_ip}:443?security=tls&sni=${nip_domain}&alpn=h2%2Chttp%2F1.1&fp=chrome&type=tcp#easytrojan-${address_ip}"
base64_link=$(echo -n "$trojan_link" | base64 -w 0)

# Verify custom domain if provided
if [ -n "$caddy_domain" ]; then
    verify_domain_ip "$caddy_domain" "$address_ip"
fi

# Check port availability
check_ports

# Get Caddy binary URL
caddy_url=$(get_caddy_url)

# Download and install Caddy
log_info "Downloading Caddy server..."
curl -L "$caddy_url" -o "$CADDY_BIN" || log_error "Failed to download Caddy"
chmod +x "$CADDY_BIN"

# Verify Caddy installation
if ! "$CADDY_BIN" version &>/dev/null; then
    log_error "Caddy binary verification failed"
fi

# Create caddy system user if not exists
if ! id "$CADDY_USER" &>/dev/null; then
    groupadd --system "$CADDY_USER"
    useradd --system -g "$CADDY_USER" -s "$(command -v nologin)" "$CADDY_USER"
fi

# Create configuration directories
mkdir -p "$TROJAN_DATA_DIR"
chown -R "${CADDY_USER}:${CADDY_USER}" "$CADDY_CONFIG_DIR"
chmod 700 "$CADDY_CONFIG_DIR"

# Use custom domain if provided
if [ -n "$caddy_domain" ]; then
    nip_domain="$caddy_domain"
    rm -rf "$CADDY_CONFIG_DIR/certificates"
fi

# Generate Caddyfile
cat > "$CADDY_CONFIG_DIR/Caddyfile" <<EOF
{
    order trojan before respond
    https_port 443
    servers :443 {
        listener_wrappers {
            trojan
        }
        protocols h2 h1
    }
    servers :80 {
        protocols h1
    }
    trojan {
        caddy
        no_proxy
    }
}
:443, $nip_domain {
    tls $address_ip@tbcache.com {
        ciphers TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
    }
    log {
        level ERROR
    }
    trojan {
        websocket
    }
    respond "Service Unavailable" 503 {
        close
    }
}
:80 {
    redir https://{host}{uri} permanent
}
EOF

# Generate systemd service file
cat > "$CADDY_SERVICE_FILE" <<EOF
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=$CADDY_USER
Group=$CADDY_USER
Environment=XDG_CONFIG_HOME=$CADDY_CONFIG_DIR XDG_DATA_HOME=$CADDY_CONFIG_DIR
ExecStart=$CADDY_BIN run --environ --config $CADDY_CONFIG_DIR/Caddyfile
ExecReload=$CADDY_BIN reload --config $CADDY_CONFIG_DIR/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

# Ensure loopback interface is up
if ip link show lo | grep -q DOWN; then
    ip link set lo up
fi

# Start Caddy service
systemctl daemon-reload
systemctl restart caddy.service
systemctl enable caddy.service

# Add trojan user and save password
add_trojan_user "$trojan_passwd"
mkdir -p "$TROJAN_DATA_DIR"
save_password "$trojan_passwd"

# Wait for SSL certificate
log_info "Obtaining and installing SSL certificate..."
count=0
sslfail=0
until [ -d "$CADDY_CONFIG_DIR/certificates" ]; do
    count=$((count + 1))
    sleep 3
    if [ "$count" -gt 20 ]; then
        sslfail=1
        break
    fi
done

if [ "$sslfail" = "1" ]; then
    log_error "Certificate application failed. Please check your server firewall and network settings"
fi

# Backup and update system limits
backup_config "/etc/security/limits.conf"
sed -i '/^# End of file/,$d' /etc/security/limits.conf

cat >> /etc/security/limits.conf <<EOF
# End of file
*     soft   nofile    1048576
*     hard   nofile    1048576
*     soft   nproc     1048576
*     hard   nproc     1048576
*     soft   core      1048576
*     hard   core      1048576
*     hard   memlock   unlimited
*     soft   memlock   unlimited
EOF

# Backup and update sysctl configuration
backup_config "/etc/sysctl.conf"
write_sysctl_block

# Apply sysctl settings
sysctl -p > /dev/null 2>&1 || log_error "Failed to apply sysctl settings"

# Verify installation
check_http=$(curl -s -L "http://${nip_domain}" 2>/dev/null)
if [ "$check_http" != "Service Unavailable" ]; then
    log_error "Installation verification failed. Please ensure TCP ports 80 and 443 are open"
fi

# Display success message and connection details
clear
echo -e "You have successfully installed EasyTrojan 3.0"
echo -e "You can view your Trojan client configuration with the command 'cat $TROJAN_DATA_DIR/trojan.link'\n"
echo -e "Trojan Address:" | tee "$TROJAN_DATA_DIR/trojan.link"
echo -e "$nip_domain | Port: 443 | Password: $trojan_passwd | Alpn: h2,http/1.1\n" | tee -a "$TROJAN_DATA_DIR/trojan.link"
echo -e "Trojan Link:" | tee -a "$TROJAN_DATA_DIR/trojan.link"
echo -e "$trojan_link\n" | tee -a "$TROJAN_DATA_DIR/trojan.link"
echo -e "You can share your Trojan link securely with the website:" | tee -a "$TROJAN_DATA_DIR/trojan.link"
echo -e "https://autoxtls.github.io/base64.html#$base64_link\n" | tee -a "$TROJAN_DATA_DIR/trojan.link"
