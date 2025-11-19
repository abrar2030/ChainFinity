#!/bin/bash
# ChainFinity Vault Initialization Script
# Financial Grade Security Setup

set -euo pipefail

# Configuration variables
VAULT_ADDR="${VAULT_ADDR:-https://vault.chainfinity.internal:8200}"
VAULT_NAMESPACE="${VAULT_NAMESPACE:-}"
VAULT_TOKEN_FILE="${VAULT_TOKEN_FILE:-/opt/vault/tokens/root-token}"
VAULT_UNSEAL_KEYS_FILE="${VAULT_UNSEAL_KEYS_FILE:-/opt/vault/keys/unseal-keys}"
VAULT_CONFIG_DIR="${VAULT_CONFIG_DIR:-/opt/vault/config}"
VAULT_POLICIES_DIR="${VAULT_POLICIES_DIR:-/opt/vault/policies}"
VAULT_TLS_DIR="${VAULT_TLS_DIR:-/opt/vault/tls}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Vault is running
check_vault_status() {
    log "Checking Vault status..."
    if ! vault status &>/dev/null; then
        error "Vault is not running or not accessible at $VAULT_ADDR"
        exit 1
    fi
    success "Vault is accessible"
}

# Initialize Vault if not already initialized
initialize_vault() {
    log "Checking if Vault is initialized..."

    if vault status | grep -q "Initialized.*true"; then
        warning "Vault is already initialized"
        return 0
    fi

    log "Initializing Vault with 5 key shares and threshold of 3..."

    # Initialize Vault with key shares
    vault operator init \
        -key-shares=5 \
        -key-threshold=3 \
        -recovery-shares=5 \
        -recovery-threshold=3 \
        -format=json > "${VAULT_UNSEAL_KEYS_FILE}.json"

    # Extract root token
    jq -r '.root_token' "${VAULT_UNSEAL_KEYS_FILE}.json" > "$VAULT_TOKEN_FILE"

    # Extract unseal keys
    jq -r '.unseal_keys_b64[]' "${VAULT_UNSEAL_KEYS_FILE}.json" > "$VAULT_UNSEAL_KEYS_FILE"

    # Set secure permissions
    chmod 600 "$VAULT_TOKEN_FILE" "$VAULT_UNSEAL_KEYS_FILE" "${VAULT_UNSEAL_KEYS_FILE}.json"

    success "Vault initialized successfully"
}

# Unseal Vault
unseal_vault() {
    log "Checking if Vault needs to be unsealed..."

    if vault status | grep -q "Sealed.*false"; then
        success "Vault is already unsealed"
        return 0
    fi

    log "Unsealing Vault..."

    # Read unseal keys and unseal
    local key_count=0
    while IFS= read -r key && [ $key_count -lt 3 ]; do
        vault operator unseal "$key"
        ((key_count++))
    done < "$VAULT_UNSEAL_KEYS_FILE"

    success "Vault unsealed successfully"
}

# Authenticate with root token
authenticate_vault() {
    log "Authenticating with Vault..."

    if [ -f "$VAULT_TOKEN_FILE" ]; then
        export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
        success "Authenticated with root token"
    else
        error "Root token file not found: $VAULT_TOKEN_FILE"
        exit 1
    fi
}

# Enable audit logging
enable_audit_logging() {
    log "Enabling audit logging..."

    # Enable file audit device
    vault audit enable file file_path=/var/log/vault/vault-audit.log || true

    # Enable syslog audit device for redundancy
    vault audit enable -path=syslog syslog facility=AUTH tag=vault || true

    success "Audit logging enabled"
}

# Configure auth methods
configure_auth_methods() {
    log "Configuring authentication methods..."

    # Enable userpass auth method
    vault auth enable -path=userpass userpass || true

    # Enable LDAP auth method for enterprise integration
    vault auth enable -path=ldap ldap || true

    # Enable Kubernetes auth method
    vault auth enable -path=kubernetes kubernetes || true

    # Enable AWS auth method
    vault auth enable -path=aws aws || true

    # Enable JWT/OIDC auth method
    vault auth enable -path=oidc oidc || true

    # Enable AppRole auth method for applications
    vault auth enable -path=approle approle || true

    success "Authentication methods configured"
}

# Configure secret engines
configure_secret_engines() {
    log "Configuring secret engines..."

    # Enable KV v2 secret engine
    vault secrets enable -path=secret kv-v2 || true

    # Enable database secret engine
    vault secrets enable -path=database database || true

    # Enable PKI secret engine for certificates
    vault secrets enable -path=pki pki || true
    vault secrets enable -path=pki_int pki || true

    # Configure PKI root CA
    vault secrets tune -max-lease-ttl=87600h pki || true
    vault secrets tune -max-lease-ttl=43800h pki_int || true

    # Enable transit secret engine for encryption
    vault secrets enable -path=transit transit || true

    # Enable AWS secret engine
    vault secrets enable -path=aws aws || true

    # Enable SSH secret engine
    vault secrets enable -path=ssh ssh || true

    success "Secret engines configured"
}

# Load policies
load_policies() {
    log "Loading Vault policies..."

    if [ ! -d "$VAULT_POLICIES_DIR" ]; then
        warning "Policies directory not found: $VAULT_POLICIES_DIR"
        return 0
    fi

    for policy_file in "$VAULT_POLICIES_DIR"/*.hcl; do
        if [ -f "$policy_file" ]; then
            policy_name=$(basename "$policy_file" .hcl)
            log "Loading policy: $policy_name"
            vault policy write "$policy_name" "$policy_file"
        fi
    done

    success "Policies loaded successfully"
}

# Configure PKI certificates
configure_pki() {
    log "Configuring PKI certificates..."

    # Generate root CA
    vault write -field=certificate pki/root/generate/internal \
        common_name="ChainFinity Root CA" \
        ttl=87600h > /tmp/CA_cert.crt || true

    # Configure CA and CRL URLs
    vault write pki/config/urls \
        issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
        crl_distribution_points="$VAULT_ADDR/v1/pki/crl" || true

    # Generate intermediate CA
    vault write -format=json pki_int/intermediate/generate/internal \
        common_name="ChainFinity Intermediate Authority" \
        | jq -r '.data.csr' > /tmp/pki_intermediate.csr || true

    # Sign intermediate certificate
    vault write -format=json pki/root/sign-intermediate \
        csr=@/tmp/pki_intermediate.csr \
        format=pem_bundle ttl="43800h" \
        | jq -r '.data.certificate' > /tmp/intermediate.cert.pem || true

    # Set intermediate certificate
    vault write pki_int/intermediate/set-signed \
        certificate=@/tmp/intermediate.cert.pem || true

    # Create role for certificate issuance
    vault write pki_int/roles/chainfinity-dot-com \
        allowed_domains="chainfinity.com,chainfinity.internal" \
        allow_subdomains=true \
        max_ttl="720h" || true

    success "PKI configured successfully"
}

# Configure database secrets
configure_database_secrets() {
    log "Configuring database secret engine..."

    # Configure PostgreSQL connection
    vault write database/config/postgresql \
        plugin_name=postgresql-database-plugin \
        connection_url="postgresql://{{username}}:{{password}}@postgres.chainfinity.internal:5432/chainfinity?sslmode=require" \
        allowed_roles="readonly,readwrite,admin" \
        username="vault" \
        password="vault-db-password" || true

    # Create database roles
    vault write database/roles/readonly \
        db_name=postgresql \
        creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
        default_ttl="1h" \
        max_ttl="24h" || true

    vault write database/roles/readwrite \
        db_name=postgresql \
        creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
        default_ttl="1h" \
        max_ttl="24h" || true

    success "Database secrets configured"
}

# Configure transit encryption
configure_transit() {
    log "Configuring transit encryption..."

    # Create encryption keys
    vault write -f transit/keys/chainfinity-app || true
    vault write -f transit/keys/chainfinity-data || true
    vault write -f transit/keys/chainfinity-pii || true

    # Configure key policies
    vault write transit/keys/chainfinity-pii/config \
        deletion_allowed=false \
        exportable=false \
        allow_plaintext_backup=false || true

    success "Transit encryption configured"
}

# Create initial users and roles
create_initial_users() {
    log "Creating initial users and roles..."

    # Create admin user
    vault write auth/userpass/users/admin \
        password="$(openssl rand -base64 32)" \
        policies="admin-policy" || true

    # Create developer user
    vault write auth/userpass/users/developer \
        password="$(openssl rand -base64 32)" \
        policies="developer-policy" || true

    # Create monitoring user
    vault write auth/userpass/users/monitoring \
        password="$(openssl rand -base64 32)" \
        policies="readonly-policy" || true

    success "Initial users created"
}

# Configure AppRole for applications
configure_approle() {
    log "Configuring AppRole authentication..."

    # Create AppRole for ChainFinity application
    vault write auth/approle/role/chainfinity-app \
        token_policies="application-policy" \
        token_ttl=1h \
        token_max_ttl=4h \
        bind_secret_id=true \
        secret_id_ttl=24h || true

    # Get role ID and secret ID
    vault read -field=role_id auth/approle/role/chainfinity-app/role-id > /opt/vault/tokens/chainfinity-role-id || true
    vault write -field=secret_id auth/approle/role/chainfinity-app/secret-id > /opt/vault/tokens/chainfinity-secret-id || true

    chmod 600 /opt/vault/tokens/chainfinity-* || true

    success "AppRole configured"
}

# Main execution
main() {
    log "Starting ChainFinity Vault initialization..."

    # Create necessary directories
    mkdir -p "$(dirname "$VAULT_TOKEN_FILE")" "$(dirname "$VAULT_UNSEAL_KEYS_FILE")" /var/log/vault

    check_vault_status
    initialize_vault
    unseal_vault
    authenticate_vault
    enable_audit_logging
    configure_auth_methods
    configure_secret_engines
    load_policies
    configure_pki
    configure_database_secrets
    configure_transit
    create_initial_users
    configure_approle

    success "ChainFinity Vault initialization completed successfully!"

    log "Important files created:"
    log "  Root token: $VAULT_TOKEN_FILE"
    log "  Unseal keys: $VAULT_UNSEAL_KEYS_FILE"
    log "  Application role ID: /opt/vault/tokens/chainfinity-role-id"
    log "  Application secret ID: /opt/vault/tokens/chainfinity-secret-id"

    warning "Please secure these files and remove them from the server after copying to a secure location!"
}

# Run main function
main "$@"
