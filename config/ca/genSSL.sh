#!/usr/bin/env bash
set -euo pipefail

MODULE="SSL-GENERATOR"

# ==========================
# Constants
# ==========================
RESET='\033[0m'
RED='\033[38;5;1m'
GREEN='\033[38;5;2m'
YELLOW='\033[38;5;3m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'

# ==========================
# Logging
# ==========================
stderr_print() {
    local bool="${BITNAMI_QUIET:-false}"
    shopt -s nocasematch
    if ! [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
        printf "%b\n" "${*}" >&2
    fi
}

log() {
    local color_bool="${BITNAMI_COLOR:-true}"
    shopt -s nocasematch
    if [[ "$color_bool" = 1 || "$color_bool" =~ ^(yes|true)$ ]]; then
        stderr_print "${CYAN}${MODULE:-} ${MAGENTA}$(date "+%T.%2N ")${RESET}${*}"
    else
        stderr_print "${MODULE:-} $(date "+%T.%2N ")${*}"
    fi
}

info() {
    local msg_color=""
    [[ "${BITNAMI_COLOR:-true}" =~ ^(1|yes|true)$ ]] && msg_color="$GREEN"
    log "${msg_color}INFO ${RESET} ==> $*"
}

warn() {
    local msg_color=""
    [[ "${BITNAMI_COLOR:-true}" =~ ^(1|yes|true)$ ]] && msg_color="$YELLOW"
    log "${msg_color}WARN ${RESET} ==> $*"
}

error() {
    local msg_color=""
    [[ "${BITNAMI_COLOR:-true}" =~ ^(1|yes|true)$ ]] && msg_color="$RED"
    log "${msg_color}ERROR${RESET} ==> $*"
    exit 1
}

# ==========================
# Helpers
# ==========================

check_openssl() {
    command -v openssl >/dev/null 2>&1 || error "openssl not installed"
}

ask_required() {
    local prompt="$1"
    local value=""
    while true; do
        read -p "$prompt: " value
        if [[ -n "${value// }" ]]; then
            echo "$value"
            return
        fi
        warn "Value cannot be empty. Please try again."
    done
}

ask_san() {
    local value=""
    while true; do
        read -p "SAN domains (comma separated): " value
        if [[ -z "${value// }" ]]; then
            warn "At least one SAN domain is required."
            continue
        fi

        IFS=',' read -ra DOMAINS <<< "$value"
        if [[ "${#DOMAINS[@]}" -lt 1 ]]; then
            warn "Invalid SAN format."
            continue
        fi

        echo "$value"
        return
    done
}

# ==========================
# Start
# ==========================

check_openssl
info "Starting interactive SSL generation"

CA_COUNTRY=$(ask_required "CA Country (RU)")
CA_ORG=$(ask_required "CA Organization (Example LLC)")
CA_CN=$(ask_required "CA Common Name (Example-Root-CA)")

SERVER_COUNTRY=$(ask_required "Server Country (RU)")
SERVER_STATE=$(ask_required "Server State (Moscow)")
SERVER_LOCALITY=$(ask_required "Server Locality (Moscow)")
SERVER_ORG=$(ask_required "Server Organization (Example LLC)")
SERVER_CN=$(ask_required "Server Common Name (wiki.example.com)")
SAN_DOMAINS=$(ask_san)

info "Generating Root CA key"
openssl genrsa -out RCA.key 4096 >/dev/null 2>&1

info "Generating Root CA certificate"
openssl req -x509 -new -nodes -key RCA.key -sha256 -days 3650 -out RCA.crt -subj "/C=${CA_COUNTRY}/O=${CA_ORG}/CN=${CA_CN}" >/dev/null 2>&1

info "Generating server private key"
openssl genrsa -out ssl.key 4096 >/dev/null 2>&1

info "Creating SAN config"

cat > server.cnf <<EOF
[req]
distinguished_name=req_distinguished_name
req_extensions=req_ext
prompt=no

[req_distinguished_name]
C=${SERVER_COUNTRY}
ST=${SERVER_STATE}
L=${SERVER_LOCALITY}
O=${SERVER_ORG}
CN=${SERVER_CN}

[req_ext]
subjectAltName=@alt_names

[alt_names]
$(i=1; IFS=','; for domain in $SAN_DOMAINS; do
echo "DNS.$i=$(echo "$domain" | xargs)"
i=$((i+1))
done)
EOF

info "Generating CSR"
openssl req -new -key ssl.key -out ssl.csr -config server.cnf >/dev/null 2>&1

info "Signing server certificate"
openssl x509 -req -in ssl.csr -CA RCA.crt -CAkey RCA.key -CAcreateserial -out ssl.crt -days 825 -sha256 -extensions req_ext -extfile server.cnf >/dev/null 2>&1

info "Building full chain"
cat ssl.crt RCA.crt > ssl.fullchain.crt
mv ssl.fullchain.crt ssl.crt

rm -f ssl.csr RCA.srl server.cnf

info "Certificates successfully generated:"
info "  RCA.key"
info "  RCA.crt"
info "  ssl.key"
info "  ssl.crt (includes Root CA)"