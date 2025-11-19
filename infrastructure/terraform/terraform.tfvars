# ChainFinity Infrastructure Configuration
# Financial Grade Security Variables

# Environment Configuration
environment = "production"
region      = "us-west-2"

# Network Security Configuration
allowed_cidr_blocks = [
  "10.0.0.0/8",      # Private networks
  "172.16.0.0/12",   # Private networks
  "192.168.0.0/16",  # Private networks
  # Add specific public IP ranges for your organization
  # "203.0.113.0/24",  # Example: Office network
  # "198.51.100.0/24", # Example: VPN network
]

# Domain Configuration
domain_name = "chainfinity.com"
manage_dns  = true

# Database Configuration (Use AWS Secrets Manager in production)
db_name           = "chainfinity"
db_username       = "chainfinity_admin"
db_password       = "CHANGE_ME_USE_SECRETS_MANAGER"  # Replace with Secrets Manager reference
db_instance_class = "db.r6g.large"
db_allocated_storage     = 100
db_max_allocated_storage = 1000

# EKS Configuration
kubernetes_version         = "1.28"
eks_endpoint_public_access = false  # Private endpoint for security

# Node Group Configuration
node_instance_type  = "m6i.large"
node_instance_types = ["m6i.large", "m6i.xlarge", "c6i.large", "c6i.xlarge"]
node_capacity_type  = "ON_DEMAND"
node_desired_size   = 3
node_min_size       = 1
node_max_size       = 10
node_disk_size      = 50

# Security Configuration
enable_waf         = true
enable_shield      = false  # Set to true for DDoS protection (additional cost)
enable_guardduty   = true
enable_config      = true
enable_cloudtrail  = true
enable_security_hub = true

# Monitoring and Alerting
alert_email_addresses = [
  "admin@chainfinity.com",
  "security@chainfinity.com",
  "devops@chainfinity.com"
]
enable_detailed_monitoring = true
log_retention_days         = 2555  # 7 years for financial compliance

# Backup Configuration
backup_retention_days         = 2555  # 7 years for financial compliance
enable_point_in_time_recovery = true
backup_window                 = "03:00-04:00"
maintenance_window           = "sun:04:00-sun:05:00"

# Compliance Configuration
compliance_frameworks = [
  "SOC2",
  "PCI-DSS",
  "GDPR",
  "SOX",
  "ISO27001"
]
data_classification_level = "confidential"
enable_encryption_at_rest  = true
enable_encryption_in_transit = true

# Cost Management
enable_cost_anomaly_detection = true
cost_budget_limit            = 5000  # USD per month

# Disaster Recovery
enable_multi_region = false  # Set to true for multi-region deployment
dr_region          = "us-east-1"
rto_hours          = 4   # Recovery Time Objective
rpo_hours          = 1   # Recovery Point Objective

# Development Configuration
enable_development_tools = false  # Set to true for development environment
enable_bastion_host     = false  # Set to true if secure access is needed

# Feature Flags
feature_flags = {
  enable_api_gateway        = false
  enable_elasticsearch      = true
  enable_redis_cluster      = true
  enable_message_queue      = true
  enable_cdn               = true
  enable_container_insights = true
}

# Additional Tags
additional_tags = {
  CostCenter     = "Engineering"
  Owner          = "DevOps Team"
  BusinessUnit   = "Financial Technology"
  Criticality    = "High"
  DataRetention  = "7-years"
  BackupRequired = "true"

  # Compliance tags
  "compliance:soc2"    = "required"
  "compliance:pci-dss" = "required"
  "compliance:gdpr"    = "required"
  "compliance:sox"     = "required"

  # Security tags
  "security:level"           = "high"
  "security:encryption"      = "required"
  "security:monitoring"      = "required"
  "security:access-control"  = "strict"

  # Operational tags
  "ops:monitoring"     = "24x7"
  "ops:backup"         = "daily"
  "ops:patching"       = "automated"
  "ops:log-retention"  = "7-years"
}
