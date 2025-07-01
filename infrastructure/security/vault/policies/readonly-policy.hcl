# Read-Only Policy - For monitoring, auditing, and compliance systems
# Provides visibility without modification capabilities

# Read-only access to secret metadata (not data)
path "secret/metadata/*" {
  capabilities = ["read", "list"]
}

# System health and status
path "sys/health" {
  capabilities = ["read"]
}

path "sys/seal-status" {
  capabilities = ["read"]
}

path "sys/leader" {
  capabilities = ["read"]
}

# Metrics for monitoring
path "sys/metrics" {
  capabilities = ["read"]
}

# Auth method information
path "sys/auth" {
  capabilities = ["read", "list"]
}

path "sys/auth/*" {
  capabilities = ["read", "list"]
}

# Policy information for compliance
path "sys/policies/acl" {
  capabilities = ["read", "list"]
}

path "sys/policies/acl/*" {
  capabilities = ["read"]
}

# Mount information
path "sys/mounts" {
  capabilities = ["read", "list"]
}

path "sys/mounts/*" {
  capabilities = ["read"]
}

# Audit device information
path "sys/audit" {
  capabilities = ["read", "list"]
}

# License information (Enterprise)
path "sys/license" {
  capabilities = ["read"]
}

# Capabilities information
path "sys/capabilities" {
  capabilities = ["read"]
}

path "sys/capabilities-self" {
  capabilities = ["read"]
}

# Token information (limited)
path "auth/token/lookup" {
  capabilities = ["read"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Namespace information (Enterprise)
path "sys/namespaces" {
  capabilities = ["read", "list"]
}

path "sys/namespaces/*" {
  capabilities = ["read"]
}

# Control group information (Enterprise)
path "sys/control-group" {
  capabilities = ["read", "list"]
}

# Replication status
path "sys/replication/status" {
  capabilities = ["read"]
}

# Storage information
path "sys/storage/raft/configuration" {
  capabilities = ["read"]
}

# Key status
path "sys/key-status" {
  capabilities = ["read"]
}

# Rotate information
path "sys/rotate" {
  capabilities = ["read"]
}

# Internal counters for compliance reporting
path "sys/internal/counters/*" {
  capabilities = ["read"]
}

# Deny all write operations
path "*" {
  capabilities = ["read", "list"]
  denied_parameters = {
    "*" = []
  }
}

# Explicitly deny dangerous operations
path "sys/seal" {
  capabilities = ["deny"]
}

path "sys/unseal" {
  capabilities = ["deny"]
}

path "sys/step-down" {
  capabilities = ["deny"]
}

path "sys/rekey/*" {
  capabilities = ["deny"]
}

path "sys/rotate" {
  capabilities = ["deny"]
}

# Deny secret data access
path "secret/data/*" {
  capabilities = ["deny"]
}

# Deny token creation
path "auth/token/create*" {
  capabilities = ["deny"]
}

# Deny policy modifications
path "sys/policies/acl/*" {
  capabilities = ["read"]
  denied_parameters = {
    "policy" = []
  }
}

# Deny mount modifications
path "sys/mounts/*" {
  capabilities = ["read"]
  denied_parameters = {
    "*" = []
  }
}

# Deny auth method modifications
path "sys/auth/*" {
  capabilities = ["read", "list"]
  denied_parameters = {
    "*" = []
  }
}

# Deny audit modifications
path "sys/audit/*" {
  capabilities = ["read", "list"]
  denied_parameters = {
    "*" = []
  }
}

