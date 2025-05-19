# ChainFinity Infrastructure

This directory contains the infrastructure configuration for the ChainFinity project.

## Directory Structure

```
infrastructure/
├── ansible/           # Ansible playbooks and configurations
├── terraform/         # Terraform configurations
├── kubernetes/        # Kubernetes manifests
│   ├── monitoring/    # Monitoring configurations
│   ├── logging/       # Logging configurations
│   └── backup/        # Backup configurations
└── jenkins/           # Jenkins pipeline configurations
```

## Prerequisites

1. AWS Account with appropriate permissions
2. Terraform v1.0.0 or later
3. Ansible v2.9 or later
4. kubectl configured with EKS cluster access
5. Jenkins server with necessary plugins
6. Docker and Docker Compose

## Setup Instructions

### 1. Terraform Setup

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Ansible Setup

```bash
cd ansible
ansible-playbook -i inventory.ini playbook.yml
```

### 3. Kubernetes Setup

```bash
cd kubernetes
kubectl apply -f deployment.yaml
kubectl apply -f monitoring/
kubectl apply -f logging/
kubectl apply -f backup/
```

### 4. Jenkins Setup

1. Install required plugins:
   - Pipeline
   - Docker Pipeline
   - Kubernetes
   - Git
   - Credentials

2. Configure credentials:
   - Docker Hub credentials
   - AWS credentials
   - Kubernetes configuration
   - Database credentials

3. Create a new pipeline job pointing to the Jenkinsfile

## Monitoring

The infrastructure includes:
- Prometheus for metrics collection
- Grafana for visualization
- AlertManager for alerting

Access the monitoring dashboard at: `http://monitoring.chainfinity.example.com`

## Logging

The infrastructure includes:
- Elasticsearch for log storage
- Kibana for log visualization
- Filebeat for log collection

Access the logging dashboard at: `http://logging.chainfinity.example.com`

## Backup

Database backups are configured to run daily at midnight and are stored in S3.

## Security

- All sensitive data is stored in Kubernetes secrets
- Network access is restricted using security groups
- SSL/TLS is enforced for all external communications
- Regular security scans are performed on Docker images

## Maintenance

### Database Backup

```bash
kubectl create job --from=cronjob/db-backup db-backup-manual
```

### Monitoring Alerts

Check the AlertManager dashboard for active alerts.

### Log Rotation

Logs are automatically rotated and archived after 30 days.

## Troubleshooting

### Common Issues

1. **Terraform Apply Fails**
   - Check AWS credentials
   - Verify resource limits
   - Check for existing resources

2. **Ansible Playbook Fails**
   - Check SSH access to servers
   - Verify inventory file
   - Check Python dependencies

3. **Kubernetes Deployment Issues**
   - Check pod logs: `kubectl logs <pod-name>`
   - Check pod status: `kubectl describe pod <pod-name>`
   - Check resource usage: `kubectl top pods`

4. **Jenkins Pipeline Issues**
   - Check build logs
   - Verify credentials
   - Check Docker build context

## Support

For infrastructure-related issues, contact the DevOps team at devops@chainfinity.example.com 