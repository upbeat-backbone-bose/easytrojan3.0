#!/usr/bin/env bash
#
# EasyTrojan Quick Test Suite
#

set -e

readonly SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

echo "=== EasyTrojan Test Suite ==="
echo "Date: $(date)"
echo ""

# Test 1: Syntax validation
echo "[1/8] Syntax validation..."
bash -n "$PROJECT_ROOT/easytrojan.sh" && echo "  ✓ easytrojan.sh syntax OK"
bash -n "$PROJECT_ROOT/mytrojan.sh" && echo "  ✓ mytrojan.sh syntax OK"

# Test 2: Password URI character check
echo "[2/8] Password validation URI character check..."
if grep -F '[/?=#]' "$PROJECT_ROOT/easytrojan.sh" >/dev/null; then
    echo "  ✓ easytrojan.sh password validation OK"
else
    echo "  ✗ easytrojan.sh password validation FAIL"
    exit 1
fi

if grep -F '[/?=#]' "$PROJECT_ROOT/mytrojan.sh" >/dev/null; then
    echo "  ✓ mytrojan.sh password validation OK"
else
    echo "  ✗ mytrojan.sh password validation FAIL"
    exit 1
fi

# Test 3: No json_escape function
echo "[3/8] JSON escape function removed..."
if ! grep -q "^json_escape()" "$PROJECT_ROOT/easytrojan.sh"; then
    echo "  ✓ easytrojan.sh json_escape removed"
else
    echo "  ✗ easytrojan.sh json_escape should be removed"
    exit 1
fi

if ! grep -q "^json_escape()" "$PROJECT_ROOT/mytrojan.sh"; then
    echo "  ✓ mytrojan.sh json_escape removed"
else
    echo "  ✗ mytrojan.sh json_escape should be removed"
    exit 1
fi

# Test 4: Required functions
echo "[4/8] Required functions..."
for func in validate_password get_caddy_url check_ports add_trojan_user; do
    if grep -q "^${func}()" "$PROJECT_ROOT/easytrojan.sh"; then
        echo "  ✓ Function exists: $func"
    else
        echo "  ✗ Function missing: $func"
        exit 1
    fi
done

# Test 5: Configuration variables
echo "[5/8] Configuration variables..."
for var in CADDY_VERSION CADDY_BIN TROJAN_DATA_DIR PASSWD_FILE; do
    if grep -q "readonly ${var}=" "$PROJECT_ROOT/easytrojan.sh"; then
        echo "  ✓ Config defined: $var"
    else
        echo "  ✗ Config missing: $var"
        exit 1
    fi
done

# Test 6: Idempotency checks
echo "[6/8] Idempotency checks..."
if grep -q "limits_conf_already_configured" "$PROJECT_ROOT/easytrojan.sh"; then
    echo "  ✓ limits.conf idempotency check exists"
else
    echo "  ✗ limits.conf idempotency check missing"
    exit 1
fi

if grep -q "BEGIN EASYTROJAN SYSCTL" "$PROJECT_ROOT/easytrojan.sh"; then
    echo "  ✓ sysctl marker-based management exists"
else
    echo "  ✗ sysctl marker-based management missing"
    exit 1
fi

# Test 7: Retry logic
echo "[7/8] Retry logic..."
if grep -q "verify_max=" "$PROJECT_ROOT/easytrojan.sh"; then
    echo "  ✓ Installation verification retry logic exists"
else
    echo "  ✗ Installation verification retry logic missing"
    exit 1
fi

# Test 8: Documentation
echo "[8/8] Documentation..."
if grep -qE "密码允许包含特殊符号|@.*\*|URI 结构字符" "$PROJECT_ROOT/README.md"; then
    echo "  ✓ README password policy documented"
else
    echo "  ✗ README password policy documentation missing"
    exit 1
fi

if [ -f "$PROJECT_ROOT/CHANGELOG.md" ]; then
    echo "  ✓ CHANGELOG.md exists"
else
    echo "  ✗ CHANGELOG.md missing"
    exit 1
fi

echo ""
echo "==============================="
echo "All tests passed! ✓"
echo "==============================="
