# Developer Policy - Limited access for development team
# Follows principle of least privilege for financial applications

# Read access to development secrets
path "secret/data/dev/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/dev/*" {
  capabilities = ["read", "list"]
}

# Write access to personal development secrets
path "secret/data/dev/personal/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/dev/personal/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Read access to shared development configuration
path "secret/data/dev/shared/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/dev/shared/*" {
  capabilities = ["read", "list"]
}

# Database credentials for development
path "database/creds/dev-readonly" {
  capabilities = ["read"]
}

path "database/creds/dev-readwrite" {
  capabilities = ["read"]
}

# PKI for development certificates
path "pki_dev/issue/dev-role" {
  capabilities = ["create", "update"]
}

path "pki_dev/cert/ca" {
  capabilities = ["read"]
}

# Transit encryption for development
path "transit/encrypt/dev-key" {
  capabilities = ["update"]
}

path "transit/decrypt/dev-key" {
  capabilities = ["update"]
}

# AWS credentials for development
path "aws/creds/dev-role" {
  capabilities = ["read"]
}

# Kubernetes auth for development
path "auth/kubernetes/role/dev-role" {
  capabilities = ["read"]
}

# Self-service capabilities
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

# System health check
path "sys/health" {
  capabilities = ["read"]
}

# Deny access to production secrets
path "secret/data/prod/*" {
  capabilities = ["deny"]
}

path "secret/metadata/prod/*" {
  capabilities = ["deny"]
}

# Deny access to staging secrets (unless specifically granted)
path "secret/data/staging/*" {
  capabilities = ["deny"]
}

path "secret/metadata/staging/*" {
  capabilities = ["deny"]
}

# Deny administrative functions
path "sys/auth/*" {
  capabilities = ["deny"]
}

path "sys/policies/*" {
  capabilities = ["deny"]
}

path "sys/mounts/*" {
  capabilities = ["deny"]
}

# Audit log access denied
path "sys/audit/*" {
  capabilities = ["deny"]
}

# Seal operations denied
path "sys/seal" {
  capabilities = ["deny"]
}

path "sys/unseal" {
  capabilities = ["deny"]
}
