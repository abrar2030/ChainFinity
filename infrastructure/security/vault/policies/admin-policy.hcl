# ChainFinity Vault Policies
# Financial Grade Access Control Policies

# Admin Policy - Full access for system administrators
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/auth" {
  capabilities = ["read"]
}

path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/policies/acl" {
  capabilities = ["list"]
}

path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/mounts" {
  capabilities = ["read"]
}

# Audit log access for compliance
path "sys/audit/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/audit" {
  capabilities = ["read", "list"]
}

# System health and metrics
path "sys/health" {
  capabilities = ["read", "list"]
}

path "sys/metrics" {
  capabilities = ["read"]
}

# Seal/unseal operations
path "sys/seal" {
  capabilities = ["update", "sudo"]
}

path "sys/unseal" {
  capabilities = ["update", "sudo"]
}

# Key management
path "sys/rotate" {
  capabilities = ["update", "sudo"]
}

path "sys/rekey/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# License management (Enterprise)
path "sys/license" {
  capabilities = ["read", "update"]
}

# Namespaces (Enterprise)
path "sys/namespaces/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Control groups (Enterprise)
path "sys/control-group/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
