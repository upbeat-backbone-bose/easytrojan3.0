#!/bin/bash
#
# Notes: EasyMyTrojan for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#        https://github.com/autoxtls/easytrojan
#

# ==================== Configuration ====================
readonly TROJAN_DATA_DIR="/etc/caddy/trojan"
readonly PASSWD_FILE="/etc/caddy/trojan/passwd.txt"
readonly CADDY_API="http://localhost:2019/trojan/users"

# ==================== Helper Functions ====================

# Check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "Error: You must be root to run this script" >&2
        exit 1
    fi
}

# Validate password format (only letters, numbers, underscores)
validate_password() {
    local passwd="$1"
    if [[ ! "$passwd" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "Error: Password '$passwd' must contain only letters, numbers, and underscores" >&2
        return 1
    fi
    return 0
}

# Add trojan user via Caddy API
add_user() {
    local password="$1"
    local response
    local http_code

    response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"password\": \"$password\"}" \
        "$CADDY_API/add" 2>/dev/null)
    
    http_code=$(echo "$response" | tail -1)

    if [ "$http_code" = "200" ]; then
        echo "$password" >> "$PASSWD_FILE"
        sort "$PASSWD_FILE" | uniq > "${PASSWD_FILE}.tmp"
        mv -f "${PASSWD_FILE}.tmp" "$PASSWD_FILE"
        echo "Add Succeeded: $password"
    else
        echo "Add Failed: $password (HTTP $http_code)"
    fi
}

# Delete trojan user via Caddy API
del_user() {
    local password="$1"
    local response
    local http_code

    response=$(curl -s -w "\n%{http_code}" -X DELETE \
        -H "Content-Type: application/json" \
        -d "{\"password\": \"$password\"}" \
        "$CADDY_API/delete" 2>/dev/null)
    
    http_code=$(echo "$response" | tail -1)

    if [ "$http_code" = "200" ]; then
        sed -i "/^${password}$/d" "$PASSWD_FILE"
        echo "Delete Succeeded: $password"
    else
        echo "Delete Failed: $password (HTTP $http_code)"
    fi
}

# Show data usage for a user
show_status() {
    local password="$1"
    local hash
    local data_file

    hash=$(echo -n "$password" | sha224sum | cut -d ' ' -f1)
    data_file="$TROJAN_DATA_DIR/$hash"

    if [ -f "$data_file" ]; then
        echo "$password data usage: $(cat "$data_file")"
    else
        echo "$password: no data record"
    fi
}

# Rotate all data usage records
rotate_data() {
    local mkdate
    local cpdate
    local alldate

    mkdate=$(date +%Y%m%d-%H%M%S)
    mkdir -p "$TROJAN_DATA_DIR/data/$mkdate"

    # Find all data files (excluding passwd.txt)
    cpdate=$(find "$TROJAN_DATA_DIR" -maxdepth 1 -type f -not -name "passwd.txt" 2>/dev/null)

    if [ -z "$cpdate" ]; then
        echo "No data records to rotate"
        return
    fi

    for alldate in $cpdate; do
        cp -f "$alldate" "$TROJAN_DATA_DIR/data/$mkdate/" &&
        sed -i -r -e "s|[0-9]+|0|g" "$alldate"
    done

    echo "Clear all data usage successful"
}

# List all passwords
list_passwords() {
    if [ -f "$PASSWD_FILE" ]; then
        cat "$PASSWD_FILE"
    else
        echo "No password file found"
    fi
}

# Show usage information
show_usage() {
    echo "Command Examples:"
    echo "  $0 add passwd1 passwd2 ...      - Add one or more passwords"
    echo "  $0 del passwd1 passwd2 ...      - Delete one or more passwords"
    echo "  $0 status passwd1 passwd2 ...   - Show data usage for passwords"
    echo "  $0 rotate                       - Reset all data usage to zero"
    echo "  $0 list                         - List all passwords"
}

# ==================== Main Script ====================

check_root

case $1 in
    add)
        shift
        if [ $# -eq 0 ]; then
            echo "Error: Please provide at least one password" >&2
            exit 1
        fi
        for i in "$@"; do
            if validate_password "$i"; then
                add_user "$i"
            fi
        done
        ;;
    del)
        shift
        if [ $# -eq 0 ]; then
            echo "Error: Please provide at least one password" >&2
            exit 1
        fi
        for i in "$@"; do
            if validate_password "$i"; then
                del_user "$i"
            fi
        done
        ;;
    status)
        shift
        if [ $# -eq 0 ]; then
            echo "Error: Please provide at least one password" >&2
            exit 1
        fi
        for i in "$@"; do
            show_status "$i"
        done
        ;;
    rotate)
        rotate_data
        ;;
    list)
        list_passwords
        ;;
    *)
        show_usage
        ;;
esac
