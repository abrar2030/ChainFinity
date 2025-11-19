# Application Service Policy - For automated services and applications
# Highly restricted access following zero-trust principles

# Application-specific secret access
path "secret/data/app/{{identity.entity.name}}/*" {
  capabilities = ["read"]
}

path "secret/metadata/app/{{identity.entity.name}}/*" {
  capabilities = ["read"]
}

# Database credentials for specific applications
path "database/creds/{{identity.entity.name}}-role" {
  capabilities = ["read"]
}

# PKI certificate issuance for application
path "pki_int/issue/{{identity.entity.name}}-role" {
  capabilities = ["create", "update"]
}

# Transit encryption/decryption for application data
path "transit/encrypt/{{identity.entity.name}}-key" {
  capabilities = ["update"]
}

path "transit/decrypt/{{identity.entity.name}}-key" {
  capabilities = ["update"]
}

path "transit/datakey/plaintext/{{identity.entity.name}}-key" {
  capabilities = ["update"]
}

path "transit/datakey/wrapped/{{identity.entity.name}}-key" {
  capabilities = ["update"]
}

# AWS IAM credentials for application
path "aws/creds/{{identity.entity.name}}-role" {
  capabilities = ["read"]
}

# GCP service account credentials
path "gcp/key/{{identity.entity.name}}-role" {
  capabilities = ["read"]
}

# Azure service principal credentials
path "azure/creds/{{identity.entity.name}}-role" {
  capabilities = ["read"]
}

# Kubernetes service account tokens
path "kubernetes/creds/{{identity.entity.name}}-role" {
  capabilities = ["read"]
}

# SSH certificates for secure access
path "ssh-client-signer/sign/{{identity.entity.name}}-role" {
  capabilities = ["create", "update"]
}

# Token self-management
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

# Cubbyhole for temporary storage
path "cubbyhole/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# System health for monitoring
path "sys/health" {
  capabilities = ["read"]
}

# Deny all other access
path "*" {
  capabilities = ["deny"]
}

# Explicitly deny administrative access
path "sys/auth/*" {
  capabilities = ["deny"]
}

path "sys/policies/*" {
  capabilities = ["deny"]
}

path "sys/mounts/*" {
  capabilities = ["deny"]
}

path "sys/audit/*" {
  capabilities = ["deny"]
}

path "sys/seal" {
  capabilities = ["deny"]
}

path "sys/unseal" {
  capabilities = ["deny"]
}

# Deny access to other applications' secrets
path "secret/data/app/*" {
  capabilities = ["deny"]
}

# Allow only specific application path
path "secret/data/app/{{identity.entity.name}}/*" {
  capabilities = ["read"]
}

# Deny root token creation
path "auth/token/create" {
  capabilities = ["deny"]
}

path "auth/token/create-orphan" {
  capabilities = ["deny"]
}

# Deny wrapping token creation for security
path "sys/wrapping/wrap" {
  capabilities = ["deny"]
}

# Deny response wrapping lookup
path "sys/wrapping/lookup" {
  capabilities = ["deny"]
}

# Deny unwrapping
path "sys/wrapping/unwrap" {
  capabilities = ["deny"]
}
