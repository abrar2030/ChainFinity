# HashiCorp Vault Configuration for ChainFinity
# Financial Grade Security Configuration

# Storage backend configuration with encryption at rest
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"

  # Enable TLS for Consul communication
  scheme = "https"
  tls_ca_file = "/opt/vault/tls/consul-ca.pem"
  tls_cert_file = "/opt/vault/tls/consul-cert.pem"
  tls_key_file = "/opt/vault/tls/consul-key.pem"
  tls_skip_verify = false
}

# Alternative storage for high availability
storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-node-1"

  # Retry configuration for network resilience
  retry_join {
    leader_api_addr = "https://vault-node-2:8200"
    leader_ca_cert_file = "/opt/vault/tls/vault-ca.pem"
    leader_client_cert_file = "/opt/vault/tls/vault-cert.pem"
    leader_client_key_file = "/opt/vault/tls/vault-key.pem"
  }

  retry_join {
    leader_api_addr = "https://vault-node-3:8200"
    leader_ca_cert_file = "/opt/vault/tls/vault-ca.pem"
    leader_client_cert_file = "/opt/vault/tls/vault-cert.pem"
    leader_client_key_file = "/opt/vault/tls/vault-key.pem"
  }
}

# Listener configuration with strict TLS
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/opt/vault/tls/vault-cert.pem"
  tls_key_file  = "/opt/vault/tls/vault-key.pem"
  tls_ca_file   = "/opt/vault/tls/vault-ca.pem"

  # Financial grade TLS configuration
  tls_min_version = "tls12"
  tls_cipher_suites = "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
  tls_prefer_server_cipher_suites = true
  tls_require_and_verify_client_cert = true

  # Security headers
  tls_disable_client_certs = false
  x_forwarded_for_authorized_addrs = "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
  x_forwarded_for_hop_skips = 1
  x_forwarded_for_reject_not_authorized = true
  x_forwarded_for_reject_not_present = true
}

# API address for cluster communication
api_addr = "https://vault.chainfinity.internal:8200"
cluster_addr = "https://vault.chainfinity.internal:8201"

# Cluster listener for replication
listener "tcp" {
  address = "0.0.0.0:8201"
  cluster_address = "0.0.0.0:8201"
  tls_cert_file = "/opt/vault/tls/vault-cert.pem"
  tls_key_file  = "/opt/vault/tls/vault-key.pem"
  tls_ca_file   = "/opt/vault/tls/vault-ca.pem"
  tls_min_version = "tls12"
}

# Seal configuration using AWS KMS for additional security
seal "awskms" {
  region     = "us-west-2"
  kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  endpoint   = "https://kms.us-west-2.amazonaws.com"
}

# Telemetry configuration for monitoring
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true

  # Send metrics to monitoring system
  statsd_address = "localhost:8125"

  # Enable detailed metrics for financial compliance
  enable_hostname_label = true
  usage_gauge_period = "10m"
  maximum_gauge_cardinality = 500
}

# UI configuration
ui = true

# Logging configuration for audit compliance
log_level = "INFO"
log_format = "json"
log_file = "/var/log/vault/vault.log"
log_rotate_duration = "24h"
log_rotate_max_files = 30

# Disable mlock for containerized environments (adjust based on deployment)
disable_mlock = false

# Plugin directory
plugin_directory = "/opt/vault/plugins"

# Default lease TTL and maximum lease TTL
default_lease_ttl = "768h"
max_lease_ttl = "8760h"

# Disable clustering for single node (adjust for production)
disable_clustering = false

# Raw storage endpoint (disable in production)
raw_storage_endpoint = false

# Introspection endpoint (disable in production)
introspection_endpoint = false

# Disable performance standby (enable for enterprise)
disable_performance_standby = true

# License path for Vault Enterprise
license_path = "/opt/vault/license/vault.hclic"
