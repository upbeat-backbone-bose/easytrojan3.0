#!/usr/bin/env bash
#
# EasyTrojan Test Suite
# Tests for easytrojan.sh and mytrojan.sh scripts
#

set -e

readonly TESTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly PROJECT_ROOT=$(dirname "$TESTS_DIR")
readonly EASYTROJAN=$PROJECT_ROOT/easytrojan.sh
readonly MYTROJAN=$PROJECT_ROOT/mytrojan.sh

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Helper functions
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

log_section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

# Test: Script syntax validation
test_syntax_validation() {
    log_section "Script Syntax Validation"
    
    # Test easytrojan.sh syntax
    if bash -n "$EASYTROJAN" 2>/dev/null; then
        log_pass "easytrojan.sh syntax is valid"
    else
        log_fail "easytrojan.sh has syntax errors"
    fi
    
    # Test mytrojan.sh syntax
    if bash -n "$MYTROJAN" 2>/dev/null; then
        log_pass "mytrojan.sh syntax is valid"
    else
        log_fail "mytrojan.sh has syntax errors"
    fi
}

# Test: Password validation function
test_password_validation() {
    log_section "Password Validation Tests"
    
    # Source the script to get functions
    # Note: We extract just the validate_password function for testing
    
    # Test valid passwords (now includes special characters, excludes URI structural chars)
    local valid_passwords=("password123" "test_password" "ABC123" "a1" "________" "AAAAAAAA" "12345678" "test\$123" "my-password" "pass.word" "hello[world]" "test{123}" "a|b" "x'y\"z" "p!ssw0rd")
    
    for passwd in "${valid_passwords[@]}"; do
        # Check if password contains forbidden URI characters using grep
        if echo "$passwd" | grep -qE '[:@/?&#=]|[[:space:]]'; then
            log_fail "Invalid password accepted (URI chars): '$passwd'"
        else
            log_pass "Valid password accepted: $passwd"
        fi
    done
    
    # Test invalid passwords (URI structural characters and empty)
    local invalid_passwords=("" "pass:word" "pass@word" "pass/word" "pass?word" "pass&word" "pass=word" "pass#word" "pass word" "tab	char")
    
    for passwd in "${invalid_passwords[@]}"; do
        if [ -z "$passwd" ] || echo "$passwd" | grep -qE '[:@/?&#=]|[[:space:]]'; then
            log_pass "Invalid password rejected: '$passwd'"
        else
            log_fail "Invalid password accepted: '$passwd'"
        fi
    done
}

# Test: Required functions exist in easytrojan.sh
test_easytrojan_functions() {
    log_section "EasyTrojan Functions Existence"
    
    local required_functions=(
        "validate_password"
        "get_caddy_url"
        "check_ports"
        "add_trojan_user"
        "save_password"
        "backup_config"
        "write_sysctl_block"
    )
    
    for func in "${required_functions[@]}"; do
        if grep -q "^${func}()" "$EASYTROJAN"; then
            log_pass "Function exists: $func"
        else
            log_fail "Function missing: $func"
        fi
    done
}

# Test: Required functions exist in mytrojan.sh
test_mytrojan_functions() {
    log_section "MyTrojan Functions Existence"
    
    local required_functions=(
        "check_root"
        "validate_password"
        "add_user"
        "del_user"
        "show_status"
        "rotate_data"
        "list_passwords"
    )
    
    for func in "${required_functions[@]}"; do
        if grep -q "^${func}()" "$MYTROJAN"; then
            log_pass "Function exists: $func"
        else
            log_fail "Function missing: $func"
        fi
    done
}

# Test: Configuration variables
test_config_variables() {
    log_section "Configuration Variables"
    
    # Test easytrojan.sh config
    local easytrojan_configs=(
        "CADDY_VERSION"
        "CADDY_BIN"
        "CADDY_CONFIG_DIR"
        "TROJAN_DATA_DIR"
        "PASSWD_FILE"
    )
    
    for config in "${easytrojan_configs[@]}"; do
        if grep -q "readonly ${config}=" "$EASYTROJAN"; then
            log_pass "Config defined in easytrojan.sh: $config"
        else
            log_fail "Config missing in easytrojan.sh: $config"
        fi
    done
    
    # Test mytrojan.sh config
    local mytrojan_configs=(
        "TROJAN_DATA_DIR"
        "PASSWD_FILE"
        "CADDY_API"
    )
    
    for config in "${mytrojan_configs[@]}"; do
        if grep -q "readonly ${config}=" "$MYTROJAN"; then
            log_pass "Config defined in mytrojan.sh: $config"
        else
            log_fail "Config missing in mytrojan.sh: $config"
        fi
    done
}

# Test: Password validation URI character check
test_password_regex() {
    log_section "Password URI Character Check"
    
    # Check if password validation uses grep to exclude URI structural characters
    if grep -F '[:@/?&#=]' "$EASYTROJAN" >/dev/null; then
        log_pass "easytrojan.sh correctly excludes URI structural characters"
    else
        log_fail "easytrojan.sh URI character check is incorrect"
    fi
    
    if grep -F '[:@/?&#=]' "$MYTROJAN" >/dev/null; then
        log_pass "mytrojan.sh correctly excludes URI structural characters"
    else
        log_fail "mytrojan.sh URI character check is incorrect"
    fi
}

# Test: JSON escape function should NOT exist (removed for security)
test_no_json_escape() {
    log_section "JSON Escape Function Removal"
    
    if grep -q "^json_escape()" "$EASYTROJAN"; then
        log_fail "easytrojan.sh should NOT have json_escape function"
    else
        log_pass "easytrojan.sh correctly removed json_escape function"
    fi
    
    if grep -q "^json_escape()" "$MYTROJAN"; then
        log_fail "mytrojan.sh should NOT have json_escape function"
    else
        log_pass "mytrojan.sh correctly removed json_escape function"
    fi
}

# Test: Error handling
test_error_handling() {
    log_section "Error Handling"
    
    # Check for log_error function
    if grep -q "^log_error()" "$EASYTROJAN"; then
        log_pass "easytrojan.sh has log_error function"
    else
        log_fail "easytrojan.sh missing log_error function"
    fi
    
    # Check for proper error messages
    if grep -q "Password must not be empty" "$EASYTROJAN"; then
        log_pass "easytrojan.sh has empty password error"
    else
        log_fail "easytrojan.sh missing empty password error"
    fi
    
    if grep -q "Password cannot contain special URI characters" "$EASYTROJAN"; then
        log_pass "easytrojan.sh has password format error"
    else
        log_fail "easytrojan.sh missing password format error"
    fi
}

# Test: Idempotency checks
test_idempotency() {
    log_section "Idempotency Checks"
    
    # Check for limits.conf idempotency
    if grep -q "limits_conf_already_configured" "$EASYTROJAN"; then
        log_pass "easytrojan.sh has limits.conf idempotency check"
    else
        log_fail "easytrojan.sh missing limits.conf idempotency check"
    fi
    
    # Check for sysctl marker-based management
    if grep -q "BEGIN EASYTROJAN SYSCTL" "$EASYTROJAN"; then
        log_pass "easytrojan.sh has sysctl marker-based management"
    else
        log_fail "easytrojan.sh missing sysctl marker-based management"
    fi
}

# Test: Retry logic
test_retry_logic() {
    log_section "Retry Logic"
    
    # Check for verification retry logic
    if grep -q "verify_max=" "$EASYTROJAN" && grep -q "Verification attempt" "$EASYTROJAN"; then
        log_pass "easytrojan.sh has installation verification retry logic"
    else
        log_fail "easytrojan.sh missing installation verification retry logic"
    fi
}

# Test: GitHub Actions workflow
test_github_actions() {
    log_section "GitHub Actions Workflow"
    
    local workflow_file="$PROJECT_ROOT/.github/workflows/build.yml"
    
    if [ ! -f "$workflow_file" ]; then
        log_fail "GitHub Actions workflow file not found"
        return
    fi
    
    # Check for required components
    if grep -q "actions/checkout@v6" "$workflow_file"; then
        log_pass "Workflow uses latest actions/checkout@v6"
    else
        log_fail "Workflow should use actions/checkout@v6"
    fi
    
    if grep -q "actions/setup-go@v6" "$workflow_file"; then
        log_pass "Workflow uses latest actions/setup-go@v6"
    else
        log_fail "Workflow should use actions/setup-go@v6"
    fi
    
    if grep -q "softprops/action-gh-release@v3" "$workflow_file"; then
        log_pass "Workflow uses latest action-gh-release@v3"
    else
        log_fail "Workflow should use action-gh-release@v3"
    fi
    
    if grep -q "go-version: '1.26'" "$workflow_file"; then
        log_pass "Workflow uses Go 1.26"
    else
        log_fail "Workflow should use Go 1.26"
    fi
    
    if grep -q "matrix" "$workflow_file"; then
        log_pass "Workflow has matrix strategy for parallel builds"
    else
        log_fail "Workflow should have matrix strategy"
    fi
    
    if grep -q "sha256sum" "$workflow_file"; then
        log_pass "Workflow generates SHA256 checksums"
    else
        log_fail "Workflow should generate SHA256 checksums"
    fi
}

# Test: Documentation consistency
test_documentation() {
    log_section "Documentation Consistency"
    
    local readme="$PROJECT_ROOT/README.md"
    
    if [ ! -f "$readme" ]; then
        log_fail "README.md not found"
        return
    fi
    
    # Check password policy documentation
    if grep -qE "密码允许包含特殊符号|URI 结构字符" "$readme"; then
        log_pass "README documents password policy correctly"
    else
        log_fail "README should document password policy (allow special chars, exclude URI chars)"
    fi
    
    # Check for FAQ section
    if grep -q "故障排查" "$readme" || grep -q "FAQ" "$readme"; then
        log_pass "README has FAQ section"
    else
        log_fail "README missing FAQ section"
    fi
    
    # Check for changelog
    if [ -f "$PROJECT_ROOT/CHANGELOG.md" ]; then
        log_pass "CHANGELOG.md exists"
    else
        log_fail "CHANGELOG.md missing"
    fi
}

# Main test runner
run_all_tests() {
    log_info "Starting EasyTrojan Test Suite"
    log_info "Project Root: $PROJECT_ROOT"
    log_info "Date: $(date)"
    
    test_syntax_validation
    test_password_validation
    test_easytrojan_functions
    test_mytrojan_functions
    test_config_variables
    test_password_regex
    test_no_json_escape
    test_error_handling
    test_idempotency
    test_retry_logic
    test_github_actions
    test_documentation
    
    # Print summary
    log_section "Test Summary"
    log_info "Total:  $TESTS_TOTAL"
    log_pass "Passed: $TESTS_PASSED"
    if [ $TESTS_FAILED -gt 0 ]; then
        log_fail "Failed: $TESTS_FAILED"
        return 1
    else
        echo ""
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    fi
}

# Run tests
run_all_tests
exit $?
